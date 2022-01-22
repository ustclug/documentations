# NFS

NFS 服务器（"vdp"）是东图两个 ~~ESXi~~ PVE 机器的虚拟机存储，型号为 DELL PowerEdge R510。磁盘阵列由于在 2021 年 3 月初损坏，目前容量缩减到 8T（4 块 4T 蓝盘 RAID10）。除虚拟机外，NFS 也存储 LUG 成员的个人数据及 LUG FTP。NFS 服务恢复后，为了保证数据冗余性，使用[科大 Office 365 A1 账号](http://staff.ustc.edu.cn/~wf0229/office365/)和 Rclone 每天增量备份 LUG FTP 和 LUG 成员的公开数据。

vdp 的内网依赖于东图网关。

!!! warning "可能的网络问题"

    在 2021 年九月份东图的 ESXi 与 NFS 连接会出现不稳定的问题，原因目前不明。在连接方式从 NFS 4.1 更换到 NFS 3 之后，连接的不稳定不会导致虚拟机被关闭。

    2021/09/29 更新：这两天再次出现了严重的连接问题。调试后发现 192.168.93.0/24 的网关 192.168.93.254 (Cisco 设备) 丢包严重，而 NFS 的出口 IP 错误被设置到了与图书馆交换机相连接的 eno1，导致请求需要绕路。将此 IP 移动至 eno2，修改 sysctl 设置 ARP 过滤并重启后，目前暂时解决了问题。

## PVE 磁盘路径与挂载参数

在 storage.cfg 设置中，NFS 挂载到 `/mnt/nfs-el`，设置的参数为 `soft,noexec,nosuid,nodev`（设置为 `hard` 会导致 NFS 下线时重试无限次，大概率导致系统卡死）。

其中，根据 PVE 的要求，虚拟机磁盘文件必须放在 `images/<vmid>` 目录下。之后可以使用 `qm rescan` 扫描新的磁盘文件。
