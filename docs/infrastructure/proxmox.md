# Proxmox VE

LUG 目前服役的 Proxmox VE 主机只有一台，是 james 在 2021 年底给我们的，命名为 `pve-5`，用于替换已运行多年的 esxi-5（因此编号为 5）。

## pve-5.vm

pve-5 位于网络中心，配置为 2× Xeon E5-2603 v4 (Broadwell 6C6T, 1.70 GHz, no HT, no Turbo Boost)，128 GB 内存和一大堆 SSD（2× 三星 240 GB SATA + 10x Intel DC S4500 1.92 TB SATA）。我们将两块 240 GB 的盘组成一个 LVM VG，分配 16 GB 的 rootfs（LVM mirror）和 8 GB 的 swap，其余空间给一个 thinpool。十块 1.92 TB 的盘组成一个 RAIDZ2 的 zpool，用于存储虚拟机等数据。

出于安全性考虑使用 10.38 段的校园网 IP，不连接公网，软件更新使用 mirrors.ustc.edu.cn 即可。其连接的单根 10 Gbps 的光纤，桥接出 `vmbrCernet`, `vmbrTelecom`, `vmbrUnicom`, `vmbrMobile` 四个不同 VLAN 的网桥，另有一个 `vmbrUstclug` 的无头网桥用于桥接 Tinc，因此在使用和维护上也与 esxi-5 相似。
