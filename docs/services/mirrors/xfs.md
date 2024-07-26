# XFS

对于使用 XFS 存储镜像仓库的服务器，我们使用 XFS 的 quota 功能监视仓库容量。`/srv/repo` 下的每个目录为一个仓库，有一个对应的 XFS project。此 XFS 文件系统需要使用 `pqnoenforce` 选项挂载，因为我们只使用容量统计功能，不需要限制仓库的磁盘使用。

!!! todo TODO
    需要调研：快速删除仓库与重命名仓库 (mv 和 rm 可能太慢了)

## 添加一个新仓库 {#new-repo}

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

### 查看 quota 情况

```shell
xfs_quota -c 'df -h'
```
