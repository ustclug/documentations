# Repositories

mirrors4 上的仓库和 mirrors2/3 一样，位于 `/srv/repo`。仓库容量使用 XFS 的 quota 功能监视。

!!! todo TODO
    需要调研：快速删除仓库与重命名仓库 (mv 和 rm 可能太慢了)

## 添加一个新仓库

### 创建目录

在 `/srv/repo/` 下创建对应的目录。注意对应目录的所有者和所有组均应该是 `mirror`。

```shell
chown mirror: /srv/repo/example
```

### 创建 XFS project

为新仓库创建 XFS quota 以便于监视容量。首先检查 `/etc/projects` 和 `/etc/projid`，找到大于 1000 的 ID 序列，找出下一个 ID（例如 1111，下面使用这个作为例子）。

```shell
mkdir /srv/repo/example
```

编辑 `/etc/projects`，加入如下一行

```text
1111:/srv/repo/example
```

然后执行：

```shell
xfs_quota -x -c 'project -s 1111'
```

编辑 `/etc/projid`，加入如下一行

```text
example:1111
```

!!! info "信息"

    我们的镜像管理器 Yuki 根据镜像目录的最后一段名称（即 basename）来从 XFS 中获取容量信息，因此 `/etc/projid` 文件内容正确才能使 Yuki 得到正确的容量。

#### 便捷配置脚本

```shell
#!/bin/bash

# Determine largest project ID
next_id() {
  local PROJID=$(cut -d':' -f1 /etc/projects | sort -n | tail -1)
  echo $((++PROJID))
}

BASE="/srv/repo"
readonly BASE

if [ "$1" = "-m" ]; then
  MKDIR=yes
  shift
fi

while [ $# -ne 0 ]; do
  N="${1//\//}"
  shift
  if grep -q "$BASE/$N\$" /etc/projects; then
    echo "Repo $N exists, skipped." >&2
    continue
  fi

  if [ ! -e "$BASE/$N" ]; then
    if [ -n "$MKDIR" ]; then
      echo "Path $BASE/$N does not exist, creating directory." >&2
      mkdir -p "$BASE/$N"
    else
      echo "Path $BASE/$N does not exist, ignored." >&2
      continue
    fi
  elif [ ! -d "$BASE/$N" ]; then
    echo "Path $BASE/$N is not a directory, ignored." >&2
    continue
  fi

  ID="$(next_id)"
  echo "$ID:$BASE/$N" >> /etc/projects
  echo "$N:$ID" >> /etc/projid
  xfs_quota -x -c "project -s $ID" &>/dev/null
  echo "Added $N (ID $ID)"
done
```

### 添加同步配置

照着 `/home/mirror/repos` 下的现有文件自己研究一下吧，这个不难。需要注意的就一点，文件名结尾必须是 `.yaml`（而不能是 `.yml`），这是 Yuki 代码里写的。

!!! tip "决定 `bindIP` 或 `network` 的值"

    镜像站有多个来自不同运营商的 IP 可用于同步任务。由于网络环境的不确定性，有时会出现某个 IP 同步速度极慢的情况。

    @taoky 的 [admirror-speedtest](https://github.com/taoky/admirror-speedtest/) 可以帮助决定最快速的 IP。

    另外，`bindIP` 不适用于所有的同步镜像（一部分程序不支持修改 `bind()` 的参数），此时可以使用基于 Docker Network 的 `network` 配置。

写好新仓库的配置文件之后运行 `yuki reload`，然后 `yuki sync <repo>` 就可以开始初次同步了。

### 为 Git 类型仓库添加软链接至 `/srv/git`

`git-daemon.service` 根据 `/srv/git` 下的内容对外提供 Git 服务。所以如果是 git 类型的仓库，需要添加软链接，否则无法使用 `git://` 的协议访问。（`http(s)://` 协议没有问题）

!!! info "Git 仓库服务的其他相关配置"

    部分克隆配置 (See <https://github.com/ustclug/discussions/issues/432>)：

    ```ini title="/etc/gitconfig "
    [uploadpack]
        allowfilter = true
    ```

### 查看 quota 情况

运行以下命令：

```console
xfs_quota -c 'df -h'
```

## 移动（删除）一个仓库

以下以 2023 年 12 月 27 日将 `.private/sb` 移动到 `sb` 的操作为例子，介绍我们需要做的事情。

### 创建 `sb` 目录

参考上文，创建目录，修改 `/etc/projects` 的路径（ID 不需要修改），然后执行上文对应的 `xfs_quota` 命令。

由于我们的例子是移动目录，可以直接使用 `mv` 命令（`sb` 仓库很小）。

### 修改 Yuki 配置

修改 `/home/mirror/repos/sb.yaml`，将 `path` 修改为 `/srv/repo/sb`。然后重新加载：

```console
yukictl reload sb
```

### 测试同步，并删除 rsync-attrs 中的旧目录

```console
yukictl sync --debug sb
```

确认同步无误后，检查 `/srv/rsync-attrs` 的内容，并删除旧目录 `/srv/rsync-attrs/.private`。

!!! tip "/srv/rsync-attrs"

    该目录的用途是为坏人修改版的 rsyncd（即 rsyncd-huai）提供快速的文件属性查询（对应使用 Reiserfs 格式化，挂载在 SSD 上）。
    同时该目录也用于主页生成。

### 修改 nginx 配置

由于我们这里是移动仓库，为了保证旧用户能够正常使用，需要修改 nginx 配置，将旧的路径重定向到新的路径。

相关的配置一般位于 `/etc/nginx/snippets/mirrors-locations`，本次我们新增的内容如下：

```nginx
location /.private/sb/ {
    rewrite ^/.private(/sb/.*$) $1 permanent;
}
```

Nginx rewrite 相关的语法知识需读者自行学习。

修改完成后，重载配置：

```console
nginx -t
nginx -s reload  # 或者 systemctl reload nginx
```

并且 commit 有关修改：

```console
git -c user.name=你的名字 -c user.email=你的邮箱 commit -m "..."
```

### 修改 rsync-proxy 与 rsyncd 配置

[rsync-proxy](https://github.com/ustclug/rsync-proxy) 为近年来我们自行编写的 rsync 反向代理服务。
修改了 `/etc/rsync-proxy/config.toml`，删除 mirrors2 中的 `".private"` 项，在 mirrors4 中新增 `"sb"` 项。

因为 rsync-proxy 最终还需要连接到后端的 rsyncd，因此 mirrors4 的 rsyncd 配置也需要修改。
在 `/etc/rsyncd` 下执行 `python common_generator.py --write` 写入配置，使用 `git diff` 检查无误后 `git commit`。
rsyncd 配置中包含不公开 rsync 的内容（如 git 目录）不会导致问题，因为所有用户接触到的都是 rsync-proxy。

确认后重载 rsync-proxy:

```console
systemctl reload rsync-proxy
```

Rsyncd 不需要重载：每个有效连接会启动新进程，而新进程会重新读取配置。

### 删除 mirrors2 上的仓库与相关项

执行 `yukictl rm sb`，然后删除 Yuki 同步配置（`~mirror/repos-etc/sb.yaml`），同样也需要 git commit。

之后删除存储的内容：执行 `/sbin/zfs list` 确认要下手删除的存储池，然后 `sudo zfs destroy pool0/repo/对应的名字` 删除。

同样，`/srv/rsync-attrs/.private` 的内容也需要删除。

### 关于 git push

目前配置的 git push 比较麻烦：需要用户在 USTCLUG GitLab 上为自己创建一个 Access Token，然后每次 git push 时输入密码。

我们有计划改进这一点：为每个仓库创建一个 ssh key，修改 git config，然后为在 USTCLUG GitLab 上为对应仓库新增 deploy key，这样就不需要密码了。
