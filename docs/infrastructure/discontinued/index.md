# 不再使用的基础设施

!!! warning

    Content under this section is not necessarily up-to-date.

## SaltStack

目前不知 SaltStack 何时开始使用，但是我们没有任何依赖于 salt 的配置。出于考虑到 salt 出现过非常严重的 CVE，saltstack 已不再考虑使用，且在已知的机器上都已删除。如果你发现某台 lug 的机器上安装了 salt，请通知 CTO 以将其删除。

在自动化运维方面，未来会调研 ansible。

## vSphere 集群

我们从 2015 年（或更早）开始使用 vSphere 平台（ESXi + vCenter）运行虚拟机。由于 VMware 专有平台的复杂性难以维护，我们已于 2022 年 1 月全面迁移至开源的、基于 Debian GNU/Linux 的虚拟化平台 Proxmox VE。

## pve-2, pve-4

pve-2 和 pve-4 也位于东图，是两台未知品牌、未知型号的旧机器，配置为 2× Xeon E5420 (Very old 4C4T, 2.50 GHz), 16 GB 内存（DDR2 667 MHz）和一块 16 GB 的 SanDisk SSD。该型号机器**没有 IPMI**。

由于配置低下，我们手动安装了 Proxmox VE，没有使用 LVM，分配了 1 GB 的 swap，剩下全部给 rootfs。

机器的网卡有两个 1 Gbps 的接口，与 pve-6 相同，都接在同一个交换机上。
