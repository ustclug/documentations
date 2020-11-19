# Repositories

mirrors4 上的仓库和 mirrors2/3 一样，位于 `/srv/repo`。仓库容量使用 XFS 的 quota 功能监视。

!!! todo TODO
    需要补充：删除仓库与重命名仓库 (mv 和 rm 可能太慢了)

## 添加一个新仓库

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

写好新仓库的配置文件之后运行 `yuki reload`，然后 `yuki sync <repo>` 就可以开始初次同步了。

### 为 Git 类型仓库添加软链接至 `/srv/git`

`git-daemon.service` 根据 `/srv/git` 下的内容对外提供 Git 服务。所以如果是 git 类型的仓库，需要添加软链接，否则无法使用 `git://` 的协议访问。（`http(s)://` 协议没有问题）

### 查看 quota 情况

运行以下命令：

```
xfs_quota -c 'df -h'
```
