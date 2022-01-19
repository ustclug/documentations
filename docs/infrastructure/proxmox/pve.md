# Proxmox VE

LUG 目前服役的 Proxmox VE 主机只有一台，是 james 在 2021 年底给我们的，命名为 `pve-5`，用于替换已运行多年的 esxi-5（因此编号为 5）。

## pve-5.vm

pve-5 位于网络中心，配置为 2× Xeon E5-2603 v4 (Broadwell 6C6T, 1.70 GHz, no HT, no Turbo Boost)，128 GB 内存和一大堆 SSD（2× 三星 240 GB SATA + 10x Intel DC S4500 1.92 TB SATA）。我们将两块 240 GB 的盘组成一个 LVM VG，分配 16 GB 的 rootfs（LVM mirror）和 8 GB 的 swap，其余空间给一个 thinpool。十块 1.92 TB 的盘组成一个 RAIDZ2 的 zpool，用于存储虚拟机等数据。

出于安全考虑，主机使用 10.38 段的校园网 IP，不连接公网，软件更新使用 mirrors.ustc.edu.cn 即可。其连接的单根 10 Gbps 的光纤，桥接出 `vmbr0`（Cernet）, `vmbr2`（Telecom）, `vmbr3`（Unicom）, `vmbr4`（Mobile）四个不同 VLAN 的网桥，另有一个 `vmbr1`（Ustclug）的无头网桥用于桥接 Tinc，因此在使用和维护上也与 esxi-5 相似。

!!! danger "硬盘控制器不要使用 VirtIO SCSI Single 或 LSI 开头的选项"

    出于未知原因，使用这些模式在虚拟机重启时会导致整个 Proxmox VE 主机卡住而不得不重启。请使用 VirtIO SCSI（不带 Single）。同样原因创建虚拟机硬盘时不要勾选 iothread。

主机使用 ZFS（Zvol）作为虚拟机的虚拟硬盘，在虚拟机中启用 `fstrim.timer`（systemd 的 fstrim 定时任务，由 `util-linux` 提供）可以定期腾出不用的空间，帮助 ZFS 更好地规划空间。启用 fstrim 的虚拟硬盘需要在 PVE 上启用 `discard` 选项，否则 fstrim 不起作用。该特性是由于 ZFS 是 CoW 的，与 ZFS 底层使用 SSD 没有太大关联。

## 工作记录 {#records}

### 2021-12-31 迁移 docker2

docker2 原先使用 QEMU 直接运行在 mirrors2 上，下层存储为 ZFS Zvol（`pool0/qemu/docker2`），由于 ZFS 调参不当使其占用了 3 倍的硬盘空间（见[这个 Reddit 贴子][1]），加上 mirrors2 本身对外提供 Rsync 服务，硬盘负载极高，所以长期以来 docker2 的 I/O 性能*十分*低下。正好借这次全闪的新宿主机将其迁移过去。

迁移时需要保证完整性的主要内容就是虚拟机内的业务，因此需要在主机间传输的内容就是虚拟磁盘，其他配置（CPU、内存、网卡等）都可以直接在新平台上创建新虚拟机时修改。原本我们打算使用 rsync 或者 dd 的方式复制磁盘，但是考虑到两边都是 ZFS，使用 `zfs send` 是一个更好的方案。

我们在 pve-5 上运行 `nc -l -p 9999 </dev/null | pv | zfs recv rpool/data/docker2`，然后在 mirrors2 上对 zvol 先打个快照，运行 `zfs send pool0/qemu/docker2@20211230 > /dev/tcp/{pve-5}/9999` 将快照内容发送到 pve-5 上（300 GiB 的数据花费了 16 小时），然后再将 docker2 关机并增量传输，`zfs send -i @20211230 pool0/qemu/docker2 > /dev/tcp/{pve-5}/9999`（增量传输只发送了 10 GB 数据）。同时我们在 Proxmox 的 web 界面上创建一个新虚拟机，配好 CPU 内存网卡等，分配 300 GiB 的硬盘。

由于 zfs send 是原样发送的，因此接收到的 zvol 硬盘占用量仍然有 712 GB。Proxmox 新建的 zvol 参数就比较合理（`volblocksize=16k`），没有严重放大的问题，因此我们再将接收到的 zvol 给 dd 进新虚拟机的 zvol 而不是直接使用。dd 结果约 345 GiB（十分合理），开机进系统运行 fstrim 之后占用量约为 240 GiB（更加合理了）。

迁移过程没有遇到任何坑，仅有的注意事项就是 zvol 调参需要重新 dd 而不能直接改，以及创建网卡的顺序（会影响虚拟机内部 eth0 和 eth1 的顺序，除非虚拟机内部使用 udev persistent net 方式根据 MAC 地址将网卡改名）。

  [1]: https://www.reddit.com/r/zfs/comments/i2ypyy/til_zfs_ashift12_raidz2_zvol_with_4k_blocksize/
