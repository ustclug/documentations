# 监控系统使用及配置说明

监控系统由以下几个组件组成：

- telegraf: agent，运行在每个被监控的机器上
- influxdb: 数据库，运行在 influxdb.ustclug.org (docker2.s.ustclug.org)
- ganglia: 可视化工具，监控报警，地址：monitor.ustclug.org (docker2.s.ustclug.org)

## Install telegraf

安装方法见：

https://docs.influxdata.com/telegraf/v1.6/introduction/installation

一个典型的安装命令是：

```shell
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.6.1-1_amd64.deb
sudo dpkg -i telegraf_1.6.1-1_amd64.deb
```

## Configure telegraf

配置文件在 `/etc/telegraf/` 目录下，用 root 权限修改：

在 `/etc/telegraf/telegraf.d/` 下增加 `net.conf` 用来开启网络监控，内容如下：

```shell
# /etc/telegraf/telegraf.d/net.conf
[[inputs.net]]
```

在 `/etc/telegraf/telegraf.conf` 中的`[[outputs.influxdb]]` 中**增加** influxdb 的地址：

```shell
[[outputs.influxdb]]
  urls = ["http://influxdb.ustclug.org:8086"]
```

其他配置保持默认即可，配置完成之后，重启 telegraf 服务，并确保服务运行正常。

```shell
sudo systemctl restart telegraf
sudo systemctl status telegraf
```

## Web

Web 端监控位于： https://monitor.ustclug.org ，登陆账号同 ldap，可以在这里设置预警提示等。
