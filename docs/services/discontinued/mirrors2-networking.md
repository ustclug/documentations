# mirrors2 的网络配置

mirrors2 上的网络使用默认的 ifupdown 配置。

在 `/etc/network/interfaces.d` 中存放着接口配置，使用 `ifup`/`ifdown` 来启用/停用某一接口。

!!! question "重启所有网络接口"

    在某次 mirrors2 离线故障中，~~误操作的 `systemctl restart networking` 返回了失败的结果，从而导致了 mirrors2 从某一网络接口断开（猜测）~~（实际原因见下），重启所有接口修复了问题：`ifdown -a && ifup -a`

    实际原因是 bridge interface 连接的那个 interface 在 ifupdown 的 config 里的配置方式是 `static` 的，在启用 bridge interface 时会自动更改配置导致 offline。改成 `manual` 禁止它的自动行为之后就没事了。
