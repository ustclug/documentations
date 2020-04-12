# Repositories

mirrors4 上的仓库和 mirrors2/3 一样，位于 `/srv/repo`。仓库容量使用 XFS 的 quota 功能监视。

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

### 添加同步配置

照着 `/home/mirror/repos` 下的现有文件自己研究一下吧，这个不难。需要注意的就一点，文件名结尾必须是 `.yaml`（而不能是 `.yml`），这是 Yuki 代码里写的。

写好新仓库的配置文件之后运行 `yuki reload`，然后 `yuki sync <repo>` 就可以开始初次同步了。

### 查看 quota 情况

运行以下命令：

```
xfs_quota -c 'df -h'
```
