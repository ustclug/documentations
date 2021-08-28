# NFS

NFS 服务器（"vdp"）是东图两个 ESXi 机器的虚拟机存储，型号为 DELL PowerEdge R510。磁盘阵列由于在 2021 年 3 月初损坏，目前容量缩减到 8T（4 块 4T 蓝盘 RAID10）。除虚拟机外，NFS 也存储 LUG 成员的个人数据及 USTCLUG FTP。NFS 服务恢复后，为了保证数据冗余性，使用[科大 Office365 A1 账号](http://staff.ustc.edu.cn/~wf0229/office365/)和 Rclone 每天增量备份 USTCLUG FTP 和 LUG 成员的公开数据。

vdp 的内网依赖于东图网关。

!!! warning "可能的网络问题"

    近期东图的 ESXi 与 NFS 连接会出现不稳定的问题，原因目前不明。在连接方式从 NFS 4.1 更换到 NFS 3 之后，连接的不稳定不会导致虚拟机被关闭。
