# 镜像服务

## 首页生成

镜像站主页是静态的，由 <https://git.lug.ustc.edu.cn/mirrors/mirrors-index> 脚本生成。

crontab 会定时运行该脚本，生成首页和 [mirrorz 项目](https://mirrorz.org/)需要的数据。

在首页展示的「获取安装镜像」、「获取开源软件」、「反向代理列表」分别由 config 内配置指定，「文件列表」内容则会从[同步程序 yuki](https://github.com/ustclug/yuki) 的 api 中获取。

## HTTP 服务

Mirrors 使用 OpenResty（一个打包 Nginx 和一堆有用的 Lua 模块的软件包）提供 HTTP 服务。

配置文件位于 LUG GitLab 上：<https://git.lug.ustc.edu.cn/mirrors/nginx-config>，此仓库对应 mirrors 上的 `/etc/nginx` 目录。

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

未完待续。

## 反向代理服务

未完待续。

## FTP 服务（已废弃）

Mirrors 曾经提供 FTP 服务，由 vsftpd 提供。在将主力服务器从 mirrors2 迁移至 mirrors4 时废弃，即 mirrors4 上从未安装配置过 vsftpd（但 mirrors2 上还留存有配置文件）。

由于年代久远且我们不再打算恢复 FTP 服务，这部分文档也就咕咕咕了。
