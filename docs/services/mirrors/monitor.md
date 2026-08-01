# Mirrors-specific monitoring

## Connections (Users online)

```toml title="ustclug/telegraf-config:mirrors-opt-monitor.conf"
--8<-- "mirrors/mirrors-opt-monitor.conf"
```

```shell title="/opt/monitor/telegraf/connection.sh"
--8<-- "mirrors/connection.sh"
```

```shell title="/opt/monitor/telegraf/nfacct.sh"
--8<-- "mirrors/nfacct.sh"
```

```shell title="/opt/monitor/telegraf/process.sh"
--8<-- "mirrors/process.sh"
```

## Log backup {#mirrorlog}

mirrors 的日志会以两种方式备份至 mirrorlog 虚拟机上。

### 文件级备份 {#mirrorlog-file}

第一种方式为 mirrorlog 从 mirrors4 上通过 rsync over SSH 拉取 xz 或 zstd 压缩后的日志文件。

- Nginx 日志：

    触发方式为同目录下的 `m4log.timer`。

    ```ini title="/etc/systemd/system/m4log.service"
    # [Unit] 部分省略
    [Service]
    Type=exec
    User=mirror
    Group=mirror
    ExecStart=/usr/bin/rsync -rltpv --include=*/ --include=*.xz --include=*.zst --exclude=* m4log:/ /mnt/data/m4log/
    Restart=on-failure
    RestartSec=1000
    ```

- Rsync 日志：

    触发方式为同目录下的 `m4log-rsync.timer`。

    ```ini title="/etc/systemd/system/m4log-rsync.service"
    # [Unit] 部分省略
    [Service]
    Type=exec
    User=mirror
    Group=mirror
    ExecStart=/usr/bin/rsync -rltpv --include=*/ --include=*.xz --include=*.zst --exclude=* m4log-rsync:/ /mnt/data/rsync-proxy/
    Restart=on-failure
    RestartSec=1000
    ```

两个 service 类型均使用 `exec` 而非 `oneshot`，目的是：

- 避免服务启动超时。`Type=oneshot` 的服务在 ExecStart 执行期间会被视为“启动中”，显然如果以这种方式运行 rsync 的话很容易 `Start operation timed out`。
- 在 rsync 进程意外退出时自动重启，重新尝试同步。

存储路径 `/mnt/data` 为从 PVE host 上 bind mount 的 ZFS dataset。

### ClickHouse 与 Vector {#mirrorlog-clickhouse}

#### ClickHouse（mirrorlog） {#mirrorlog-clickhouse-mirrorlog}

ClickHouse 运行在 mirrorlog 虚拟机上，通过 Docker Compose 部署。
Docker Compose 的 project 路径可以通过 `docker compose ls` 查看，或者使用以下命令：

```shell
docker inspect --format='{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' clickhouse
```

ClickHouse 的 Docker Compose 配置和 ClickHouse 的一些额外 XML 配置也在 `docker-run-script` 仓库中的 `mirrorlog/clickhouse` 目录中有 Git 追踪。
例如，`config/users.xml` 定义了 `mirrors` 和 `grafana` 两个用户，包括访问权限、密码和来源 IP 限制等设置。

!!! warning "ClickHouse 初始化 SQL 参考"

    Docker Compose project 中的 [`init/01-mirrors.sql`](https://github.com/ustclug/docker-run-script/blob/master/mirrorlog/clickhouse/init/01-mirrors.sql) 仅在第一次启动 ClickHouse 时执行，但为了方便参考和进行版本管理，每次更新 ClickHouse 配置时都应当将修改的部分**手工同步**进 `init/01-mirrors.sql` 中。

!!! note "ZFS"

    为了方便在 mirrorlog 容器内快速查看 ClickHouse 的磁盘占用量，`/mnt/data/clickhouse` 目录是在 PVE host 上创建的一个额外的 ZFS dataset。因此 `df`（`duf`）命令可以直接显示 ClickHouse 的磁盘占用量，但诸如 `compressratio` 等更多的 ZFS 属性仍然需要在 PVE host 上使用 `zfs` 命令查看。

#### Vector（mirrors） {#mirrorlog-clickhouse-mirrors}

mirrors4 上面通过 Docker 部署的 Vector 会将 Nginx JSON 日志实时采集到 mirrorlog 上的 ClickHouse 数据库中。

Vector 的 Docker Compose 配置和 Vector 本身的 YAML 配置也在 `docker-run-script` 仓库中的 `mirrors/vector` 目录中有 Git 追踪。

```shell title="重新载入 Vector 配置"
docker kill -s SIGHUP vector
```

有关 ClickHouse 和 Vector 的更多信息，可以参阅 Linux 201 关于 [ClickHouse](https://201.ustclug.org/advanced/clickhouse/) 的内容。
