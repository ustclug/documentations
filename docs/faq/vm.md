# 虚拟化相关

## 扩盘

扩大虚拟磁盘的大小后，可以采用以下相对简单的方式扩展分区大小：

**请确保理解命令后再执行**

```bash
$ # 安装 growpart
$ sudo apt install cloud-guest-utils
$ # 扩展 /dev/sdb1
$ sudo growpart /dev/sdb 1
$ # 现在分区表以及分区扩展了，但是分区里面的文件系统的大小还没有扩展
$ # 以 ext4 为例
$ sudo resize2fs /dev/sdb1
```
