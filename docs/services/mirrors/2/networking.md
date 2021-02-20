# Networking on mirrors2

mirrors2 上的网络使用默认的 ifupdown 配置。

在 `/etc/network/interfaces.d` 中存放着接口配置，使用 `ifup`/`ifdown` 来启用/停用某一接口。

!!! question "重启所有网络接口"

    在某次 mirrors2 离线故障中，误操作的 `systemctl restart networking` 返回了失败的结果，从而导致了 mirrors2 从某一网络接口断开（猜测），重启所有接口修复了问题：`ifdown -a && ifup -a`
