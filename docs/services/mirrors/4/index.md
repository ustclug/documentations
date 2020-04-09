# mirrors4

mirrors4 是 2020 年 3 月 24 日网络信息中心提供给 LUG 的新机器，是一台浪潮 NF5280M5。

## 硬件配置

CPU

:   双路 Intel Xeon Gold 6230

内存

:   256 GB DDR4 2933 (8 \* 32 GB SKHynix)

硬盘

:   一块三星 PM883 2TB

    12 块 HGST HUH721010AL (10 TB)

    两个硬盘控制器 MegaRAID SAS-3 3108

    !!! bug "硬盘控制器"

        由于不能跨控制器组 RAID，且每个控制器只有 8 个插槽，因此将 12 块 HDD 分为 6 块一组插在两个控制器上组成 RAID6，以两个逻辑卷呈现给操作系统。SSD 单独创建一个逻辑卷给操作系统。

网卡

:   板载 Intel X722 GbE (4 个千兆网口)

    PCI-e 扩展卡：Intel X520 (82599ES) SFP+ (2 个万兆光口)
