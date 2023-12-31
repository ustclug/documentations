# Mirrors-specific monitoring

## Connections (Users online)

```toml title="/etc/telegraf/telegraf.d/exec.conf"
--8<-- "mirrors/telegraf-exec.conf"
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
