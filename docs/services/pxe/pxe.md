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
