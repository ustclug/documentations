# 监控系统使用及配置说明

监控系统由以下几个组件组成：

- Telegraf: agent，运行在每个被监控的机器上
- InfluxDB: 数据库，运行在 influxdb.ustclug.org (docker2.s.ustclug.org)
- Grafana: 可视化工具，监控报警，地址：[monitor.ustclug.org](https://monitor.ustclug.org) (docker2.s.ustclug.org)

## Configure InfluxDB

**特别注意** ：InfluxDB 默认没有开启认证。

首次运行时，创建好管理账号（`admin`），只读账号（`grafana`）和写入账号（`telegraf`）。

然后修改位于 `/srv/docker/influxdb/conf/influxdb.conf` 的配置，修改以启用认证：

```shell title="/srv/docker/influxdb/conf/influxdb.conf"
[http]
# ...
# Determines whether HTTP authentication is enabled.
auth-enabled = true
```

此外，参考 <https://docs.influxdata.com/influxdb/v1.8/administration/authentication_and_authorization/#set-up-authentication>，考虑关闭部分功能：

```shell title="/srv/docker/influxdb/conf/influxdb.conf"
[http]
# Determines whether the pprof endpoint is enabled.  This endpoint is used for
# troubleshooting and monitoring.
pprof-enabled = false
```

## Install telegraf

安装方法见 <https://docs.influxdata.com/telegraf/v1.21/introduction/installation/>

一个典型的安装命令是：

```shell
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.21.2-1_amd64.deb
sudo dpkg -i telegraf_1.21.2-1_amd64.deb
```

更加**推荐**的做法是加入软件源后安装

```shell
curl -sL https://repos.influxdata.com/influxdb.key | sudo gpg --dearmor -o /usr/share/keyrings/influxdb.gpg
echo "deb [signed-by=/usr/share/keyrings/influxdb.gpg] https://mirrors.ustc.edu.cn/influxdata/debian buster stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt-get update && sudo apt-get install telegraf
```

## Configure telegraf

配置文件在 `/etc/telegraf/` 目录下，用 root 权限修改：

在 `/etc/telegraf/telegraf.d/` 下增加 `net.conf` 用来开启网络监控，内容如下：

```shell title="/etc/telegraf/telegraf.d/net.conf"
[[inputs.net]]
```

在 `/etc/telegraf/telegraf.conf` 中的`[[outputs.influxdb]]` 中**增加** influxdb 的地址：

```shell title="/etc/telegraf/telegraf.conf"
[[outputs.influxdb]]
  urls = ["http://influxdb.ustclug.org:8086"]
  username = "${INFLUX_USERNAME}"
  password = "${INFLUXDB_PASSWORD}"
```

其中 `INFLUX_USERNAME` 和 `INFLUXDB_PASSWORD` 应使用对 `telegraf` 数据库写权限的账号，否则无法写入数据。

配置完成之后，重启 telegraf 服务，并确保服务运行正常。

```shell
sudo systemctl restart telegraf
sudo systemctl status telegraf
```

!!! tip "建议在被监控机器上配置 NTP（可以使用 `systemd-timesyncd`，设置 NTP 服务器为 time.ustc.edu.cn），以避免时间不同步可能带来的问题。"

## Web

Web 端监控位于 <https://monitor.ustclug.org>，账号系统使用 LDAP，可以在这里设置预警提示等。

!!! warning

    配置 InfluxDB 数据源时，只能使用只读账号，否则会带来严重的安全问题。
