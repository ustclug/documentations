# 不再使用的基础设施

!!! warning

    Content under this section is not necessarily up-to-date.

## SaltStack

目前不知 SaltStack 何时开始使用，但是我们没有任何依赖于 salt 的配置。出于考虑到 salt 出现过非常严重的 CVE，saltstack 已不再考虑使用，且在已知的机器上都已删除。如果你发现某台 lug 的机器上安装了 salt，请通知 CTO 以将其删除。

在自动化运维方面，未来会调研 ansible。

## vSphere 集群

我们从 2015 年（或更早）开始使用 vSphere 平台（ESXi + vCenter）运行虚拟机。由于 VMware 专有平台的复杂性难以维护，我们已于 2022 年 1 月全面迁移至开源的、基于 Debian GNU/Linux 的虚拟化平台 Proxmox VE。
