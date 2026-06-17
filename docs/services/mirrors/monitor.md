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

mirrors 的日志会每日备份至 mirrorlog 虚拟机上，方式（方向）为 mirrorlog 从 mirrors4 上 rsync 拉取。

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

存储路径 `/mnt/data` 为从 PVE host 上挂载的 virtiofs。
