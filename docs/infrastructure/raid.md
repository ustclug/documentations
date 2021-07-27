# RAID

## MegaRAID 常用命令

MegaRAID 源里没有，需要从官网下载 RPM 包后手动解压。Debian 10 安装 libncurses5 后可使用。

```
sudo /opt/MegaRAID/MegaCli/MegaCli64 -adpallinfo -aAll  # 查看所有信息
sudo /opt/MegaRAID/MegaCli/MegaCli64 -pdlist -aall  # 查看物理盘信息
```

## 监控

现在部署的方案是由 telegraf 执行解析脚本，将数据发送到 influxdb，由 grafana 报警。

脚本：
- 解析 megacli & storcli <https://github.com/taoky/raid-telegraf>
- 解析 zpool <https://github.com/taoky/telegraf-exec-zpool-status/releases>
