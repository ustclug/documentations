# 镜像服务

## 首页生成

镜像站主页是静态的，由 <https://git.lug.ustc.edu.cn/mirrors/mirrors-index> 脚本生成。

crontab 会定时运行该脚本，生成首页和 [mirrorz 项目](https://mirrorz.org/)需要的数据。

在首页展示的「获取安装镜像」、「获取开源软件」、「反向代理列表」分别由 config 内配置指定，「文件列表」内容则会从[同步程序 yuki](https://github.com/ustclug/yuki) 的 API 中获取。

## HTTP 服务

Mirrors 使用 OpenResty（一个打包 Nginx 和一堆有用的 Lua 模块的软件包）提供 HTTP 服务。

配置文件位于 LUG GitLab 上的 [:fontawesome-solid-lock: nginx-config](https://git.lug.ustc.edu.cn/mirrors/nginx-config) 仓库中，此仓库对应 mirrors 上的 `/etc/nginx` 目录。

### 请求限制策略

见[限制策略](limiter.md)。

### 每日流量统计 {#repo-stats}

访问路径：<https://mirrors.ustc.edu.cn/status/stats.json>

脚本位于 <https://git.lug.ustc.edu.cn/mirrors/sync/-/blob/scripts/repo_stats.py>

每天在 logrotate 滚完 nginx 日志后，通过分析刚滚出来的日志文件，统计每个仓库的访问量与输出流量（因此仅包含 HTTP 流量统计），然后输出到 json 文件，并且额外输出一份 json 到 `/var/log/nginx/stats` 作为归档存储，方便以后分析。

需要注意的是这个脚本是由 logrotate 在 nginx 的 postrotate script 里运行的，而不是由 cron 或者 systemd timer，因此调用入口在这里：

```shell title="/etc/logrotate.d/nginx"
postrotate
    # [...]
    sudo -iu mirror ~mirror/scripts/repo_stats.py
endscript
```

## Rsync 服务

### rsyncd

经过 2024 年夏季的 [ZFS rebuild](https://lug.ustc.edu.cn/planet/2024/12/ustc-mirrors-zfs-rebuild/) 之后，我们观测到 ZFS ARC cache 能够很好地缓存仓库文件的元数据，因此我们在 2025 年 1 月抛弃了 rsync-huai，改回原生的 rsync。
这样就不需要自己维护一个 fork，还需要时不时跟进最新的 security patch 了。

由于面向用户的服务程序实际上是 rsync-proxy（见下），因此我们在各个机器上实际启用的 instance 为：

|  服务器  |          systemd 服务          |                     备注                      |
| :------: | :----------------------------: | :-------------------------------------------: |
| mirrors2 |      rsync@cernet.service      |              供 rsync-proxy 反代              |
| mirrors4 | rsync.socket<br>rsync@.service | 由 systemd socket 启动<br>供 rsync-proxy 反代 |

??? abstract "我们的 systemd socket 和 service 文件"

    [Download link](../../assets/mirrors/rsync@.service)

    ```ini title="/etc/systemd/system/rsync.socket"
    --8<-- "mirrors/rsync.socket"
    ```

    ```ini title="/etc/systemd/system/rsync@.service"
    --8<-- "mirrors/rsync@.service"
    ```

??? info "rsync-huai (discontinued)"

    rsync-huai 是坏人的元数据加速版的 rsync，原始代码在 <https://github.com/tuna/rsync>。

    由于 TUNA 现在使用全闪的方案，不再需要这个 patch 了，因此我们自己维护对应的版本：<https://github.com/ustclug/rsync/tree/rsync-3.2.7>。

    特别地，systemd service 内容如下：

    ```ini title="/etc/systemd/system/rsyncd-huai@.service"
    --8<-- "mirrors/rsyncd-huai@.service"
    ```

!!! info "曾经的连接数限制"

    见 [Limiters](limiters.md) 页面。

### rsync-proxy

详参 <https://github.com/ustclug/rsync-proxy>。为了让服务器能够记录 IP 与访问路径的关系，我们为 rsyncd 打开了 proxy protocol 特性。

## 反向代理服务

未完待续。

## Git 服务 {#git}

Mirrors 上的 Git over HTTP 服务经过 Nginx 和 fcgiwrap 由 `git-http-backend` 提供。考虑到 fcgiwrap 主要用于 Git，我们将其放入同一个 slice 与 Git daemon 共享内存限制：

??? info "已停止服务：Git 协议（`git://`）"

    Git 协议（TCP 9418 端口）由 `git-daemon` 直接提供。Git daemon 由我们自己写的一个 systemd service 运行：

    ```ini title="/etc/systemd/system/git-daemon.service"
    [Unit]
    Description=Git Daemon
    After=network.target

    [Service]
    Type=exec
    Nice=19
    IOSchedulingClass=best-effort
    IOSchedulingPriority=6
    ExecStart=/usr/lib/git-core/git-daemon --user=gitdaemon --reuseaddr --verbose --export-all --forbid-override=receive-pack --timeout=180 --max-connections=32 --base-path=/srv/git

    Slice=system-cgi.slice

    [Install]
    WantedBy=multi-user.target
    ```

```ini title="systemctl edit fcgiwrap.service"
[Service]
Type=exec
Nice=19
IOSchedulingClass=best-effort
IOSchedulingPriority=6

Slice=system-cgi.slice
```

Nginx 配置如下：

```nginx title="snippets/git-http"
fastcgi_read_timeout 5m;
fastcgi_pass    unix:/var/run/fcgiwrap.socket;
fastcgi_buffering off;

fastcgi_param   SCRIPT_FILENAME /usr/local/bin/homebrew-git-http-backend;
fastcgi_param   GIT_HTTP_EXPORT_ALL "";
fastcgi_param   GIT_PROJECT_ROOT    /srv/git;
fastcgi_param   PATH_INFO           $uri;
fastcgi_param   NO_BUFFERING "";
fastcgi_param   GIT_PROTOCOL $http_git_protocol;
fastcgi_param   GIT_CONFIG_GLOBAL "/dev/null";
fastcgi_param   GIT_CONFIG_SYSTEM "/etc/gitconfig.cgi";

# https://github.com/ustclug/discussions/issues/432
client_max_body_size 16m;

include         fastcgi_params;
```

在 git 仓库对应的 `location` 里面 `include` 这个配置片段即可。

其中 `system-cgi.slice` 是我们自己定义的一个 slice，用于限制 CGI 服务的资源使用。

```ini title="/etc/systemd/system/system-cgi.slice"
[Unit]
Description=Slice for CGI services (notably Git daemon)

[Slice]
MemoryMax=32G
MemoryHigh=28G

IOAccounting=true
```

### Git 服务配置 {#git-config}

由于 Git 服务相比于系统中日常使用的 Git 需要一些额外的配置，为了避免全局 Git 配置（`/etc/gitconfig`）对日常使用 Git 产生影响，我们将 Git 服务专用配置放在了 `/etc/gitconfig.cgi` 中。

利用 `fcgiwrap` 会将 `fastcgi_params` 中的参数变成 CGI 程序的环境变量这一特点，我们[在 Nginx 中设置](services.md#git) `fastcgi_params GIT_CONFIG_SYSTEM` 参数指定该配置文件的位置，即可让 `git-http-backend` 使用该配置。

- 部分克隆配置 ([discussions#432](https://github.com/ustclug/discussions/issues/432))：

    ```ini title="/etc/gitconfig.cgi"
    [uploadpack]
        allowfilter = true
    ```

- 由于 git daemon/fcgiwrap 的用户不是 mirror，所以需要设置绕过 Git 新的安全限制：

    ```ini title="/etc/gitconfig.cgi"
    [safe]
        directory = /srv/repo/*
    ```

- 为了限制 pack object 的内存使用，根据 [GitLab gitaly 的参数](https://gitlab.com/gitlab-org/gitaly/-/blob/7b6c44c6d5df11072c7e87b8e85beb773bba8765/internal/git/gitcmd/command_description.go#L541)，添加了以下配置：

    ```ini title="/etc/gitconfig.cgi"
    [pack]
        threads = 6
        windowMemory = 100m
        allowPackReuse = multi
        window = 0
    ```

### Homebrew Git

由于 Debian Trixie 提供的 Git 2.47 在处理 `crates.io-index` 仓库时会 segfault，因此我们以 mirror 用户安装了 Homebrew on Linux（a.k.a. Linuxbrew），并且通过 Homebrew 安装了最新版本的 Git。

Homebrew 没有将 `git-http-backend` 软链接至固定的路径（例如 `/home/linuxbrew/.linuxbrew/libexec/git-core/git-http-backend`），而 Cellar 中的 Git 路径带有版本号，可能会因 `brew upgrade` 发生变化，因此我们编写了一个包装脚本，通过 Homebrew 的 `git` 命令来调用 `git-http-backend`：

```shell title="/usr/local/bin/homebrew-git-http-backend"
#!/bin/sh

exec /home/linuxbrew/.linuxbrew/bin/git http-backend "$@"
```

对应地，Nginx 配置中的 `SCRIPT_FILENAME` 参数也改为指向这个包装脚本（见上文）。

## FTP 服务（已废弃）

Mirrors 曾经提供 FTP 服务，由 vsftpd 提供。在将主力服务器从 mirrors2 迁移至 mirrors4 时废弃，即 mirrors4 上从未安装配置过 vsftpd（但 mirrors2 上还留存有配置文件）。

由于年代久远且我们不再打算恢复 FTP 服务，这部分文档也就咕咕咕了。
