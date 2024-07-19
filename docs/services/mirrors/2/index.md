# mirrors2

2016 年底从网络信息中心获得的新机器，运行至今，承担了目前 mirrors 的 rsync 流量。

| 参数  |                配置                |
| :---: | :--------------------------------: |
|  CPU  |          双路 E5-2620 v4           |
| 内存  |            256 GB DDR4             |
| 存储  | 6 TB \* 12 (HDD), 250 GB \*2 (SSD) |
| 网络  |            1 Gbps \* 2             |

曙光 I620-G20 [导航光盘](https://ftp.lug.ustc.edu.cn/ebook/sugon-I620-G20.iso)

## Networking

mirrors2 上的网络配置自 2024-07-19 维护后也切换到了 systemd-networkd 方案，文档可以参考 [mirrors4](../4/networking/index.md)。

??? info "Old info"

    mirrors2 上的网络使用默认的 ifupdown 配置。

    在 `/etc/network/interfaces.d` 中存放着接口配置，使用 `ifup`/`ifdown` 来启用/停用某一接口。

    !!! question "重启所有网络接口"

        在某次 mirrors2 离线故障中，~~误操作的 `systemctl restart networking` 返回了失败的结果，从而导致了 mirrors2 从某一网络接口断开（猜测）~~（实际原因见下），重启所有接口修复了问题：`ifdown -a && ifup -a`

        实际原因是 bridge interface 连接的那个 interface 在 ifupdown 的 config 里的配置方式是 `static` 的，在启用 bridge interface 时会自动更改配置导致 offline。改成 `manual` 禁止它的自动行为之后就没事了。
