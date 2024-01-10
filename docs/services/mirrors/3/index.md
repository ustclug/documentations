# mirrors3

2020 年初从图书馆技术部获得的一台旧服务器，为戴尔 PowerEdge R510，负载比较杂乱,主要是一些既冷门又大的仓库的 HTTP + rsync 流量。

| 参数  |                                                                        配置                                                                         |
| :---: | :-------------------------------------------------------------------------------------------------------------------------------------------------: |
|  CPU  |                                                                   双路至强 E5620                                                                    |
| 内存  |                                                                     32 GB DDR3                                                                      |
| 存储  | ~~1 TB\*2 (HDD), 2 TB\*5 (HDD), 3 TB\*1 (HDD)~~ <br> 1 TB (SAS HDD), 1.8 TB \* 3 (SATA HDD), 1 TB (SATA HDD) <br> 同友 iSCSI 阵列，4 TB \* 16 (HDD) |
| 网络  |                                                                     1 Gbps \* 2                                                                     |

存储结构：

!!! warning "注意事项"

    由于 PERC 6/i 阵列卡的限制，物理磁盘大小最大支持 2TB（SAS 4TB 盘无法识别大小）。在将 SAS 坏盘移除后，目前（2022/5/10）rootfs VD 处于 degraded 状态。

    PERC H700 阵列卡由于缺少两根 SAS 转接线，并且 mirrors3 机架前右侧轨道处无法解除锁定，且更换阵列卡需要将其他扩展卡全部移除（参见 [PowerEdge R510 硬件用户手册](https://dl.dell.com/manuals/all-products/esuprt_ser_stor_net/esuprt_poweredge/poweredge-r510_owner's%20manual_zh-cn.pdf)），给新阵列卡安装带来了很大的难度。

1 TB \* 2

:   位于机身，组成 RAID1 安装操作系统，挂载为 rootfs

2 TB \* 5 + 3 TB \* 1

:   同样位于机身，组成 RAID6 存放资料（所以唯一一块 3 TB 的硬盘实际上当做 2 TB 的来用）

外部阵列，4 TB \* 16

:   通过 SFP+ 光纤挂载为 iSCSI 设备，分为两组 RAID60（可用容量为 12 块盘）存储资料
