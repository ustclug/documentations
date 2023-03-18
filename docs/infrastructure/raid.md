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

## ESXi

<https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-07_MegaCLI.zip>

ESXi 5 的 binary 和 ESXi 6.0 兼容。

```
esxcli software vib install -v=/tmp/vmware-esx-MegaCli-8.07.07.vib --no-sig-check
```

然后进入 `/opt/lsi/MegaCLI` 目录执行 `MegaCli`.

## ssacli (HPE Smart Array)

pve-6 的 RAID 方案是 HPE Smart Array。对应使用方法可以参考 <https://gist.github.com/mrpeardotnet/a9ce41da99936c0175600f484fa20d03>。

对应主机需要安装 <https://downloads.linux.hpe.com/SDR/repo/mcp/Debian/pool/non-free/ssacli-5.30-6.0_amd64.deb>（HPE 源实在太慢了）。
