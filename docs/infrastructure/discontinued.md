# 不再使用的基础设施

## SaltStack

目前不知 SaltStack 何时开始使用，但是我们没有任何依赖于 salt 的配置。出于考虑到 salt 出现过非常严重的 CVE，saltstack 已不再考虑使用，且在已知的机器上都已删除。如果你发现某台 lug 的机器上安装了 salt，请通知 CTO 以将其删除。

在自动化运维方面，未来会调研 ansible。