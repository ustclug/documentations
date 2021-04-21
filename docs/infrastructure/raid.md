# RAID

## MegaRAID 常用命令

MegaRAID 源里没有，需要从官网下载 RPM 包后手动解压。Debian 10 安装 libncurses5 后可使用。

```
sudo /opt/MegaRAID/MegaCli/MegaCli64 -adpallinfo -aAll  # 查看所有信息
sudo /opt/MegaRAID/MegaCli/MegaCli64 -pdlist -aall  # 查看物理盘信息
```