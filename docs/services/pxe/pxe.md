# PXE

对校园网用户与校外用户公开的 PXE 服务。LIIMS 与目前的 PXE 虽然运行在同一台服务器上，但是配置有所不同。

!!! todo "本文档需要大幅扩充"

## Intro

<https://lug.ustc.edu.cn/wiki/server/pxe/>

<https://lug.ustc.edu.cn/planet/2018/10/PXE-intro/>

!!! info "关于 FAQ"

    <https://lug.ustc.edu.cn/wiki/server/pxe/faq/> 太老了，如果有时间的话建议写个新的。

一般的启动流程是：

1. iPXE 加载 GRUB 相关文件。
2. GRUB 加载 Linux 内核与 initramfs。
3. Initramfs 从启动参数挂载 NFS 为 rootfs，进行下一步的启动。

## 使用/调试

PXE 在校园网中直接可用，因为学校的 DHCP 服务器经过了配置。

如果需要在虚拟机中调试，下载 IPXE 的 ISO（<http://boot.ipxe.org/ipxe.iso>），挂载在虚拟机中测试。

!!! todo "推荐使用的虚拟机方案"

    PXE 能够成功运行与否和虚拟机环境（特别是虚拟网卡型号）高度相关。需要找到一个稳定的配置方案（比如用 qemu？）

其中主要使用的是新 PXE 方案（pxelinux.0，simple-pxe）。老 PXE 方案（lpxelinux.0）目前仅用于图书馆查询机。

## 架构

新 PXE 方案的 HTTP 服务器为 Apache（Nginx 可能是以前弃用的配置）。URL 中的 boot2 对应 /nfsroot/pxe

如果出现问题需要调试，建议抓包（可以使用 Wireshark）看是否正常。

每天凌晨，pxe 用户的 crontab 任务会执行 <https://github.com/ustclug/simple-pxe/blob/master/simple-pxe-in-docker>（文件位于 pxe 用户的 home 中），实现 PXE 相关文件的更新。

## 故障 {#faults}

pxe 服务器在升级到 Debian Bullseye (11) 后无法正常开机，经过 GRUB 进入内核后每 5 秒刷出以下信息：

```text
DMAR: DRHD: handling fault status reg 2
DMAR: [DMA Read] Request device [03:00.0] PASID ffffffff fault addr cb2f0000 [fault reason 06] PTE Read access is not set
DMAR: DRHD: handling fault status reg 102
```

由于此时刚升级至 Debian Bullseye，所以系统仍然保留了 Debian Buster 的 4.19 版内核。重启进该内核可正常启动并运行服务，但只要进 5.10 的内核就会出现以上错误。经测试 Proxmox VE 提供的 pve-kernel-5.15 也是同样问题。

搜索发现主机使用的 RAID 卡 PERC H310 不支持直通（IOMMU 虚拟化），配置 GRUB 加入 `intel_iommu=off` 后可以正常进入 5.10 的内核，作为解决方案。

按说 IOMMU（VT-d）不应该默认启用，因此猜测 5.10+ 的内核会主动尝试开启 IOMMU，导致 RAID 卡出错。

参考链接：

- [DELLR730 server halts during boot-up when "intel_iommu=on" parameter is enabled in grub for SRIOV functionality. - Dell Community](https://www.dell.com/community/PowerEdge-OS-Forum/DELLR730-server-halts-during-boot-up-when-quot-intel-iommu-on/td-p/4632026)
- [:fontawesome-solid-file-pdf: Dell PowerEdge RAID Controller (PERC) H310, H710, H710P, and H810 - User's Guide](https://hg.flagshiptech.com/ebay/DellManuals/rc_h310_h710_h710p_h810_ug_en-us.pdf)（第 85 页）
