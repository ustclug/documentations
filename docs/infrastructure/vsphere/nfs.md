# NFS

NFS 服务器（"vdp"）是东图两个 ESXi 机器的虚拟机存储，型号为 DELL PowerEdge R510。磁盘阵列由于在 2021 年 3 月初损坏，目前容量缩减到 8T（4 块 4T 蓝盘 RAID10），除虚拟机外，也存储 LUG 成员的个人数据，以及 USTCLUG FTP。

vdp 的内网依赖于东图网关。