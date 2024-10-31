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

    采用 ZFS 将 12 块 HDD 组成一个 pool。

网卡

:   板载 Intel X722 GbE (4 个千兆网口)

    PCI-e 扩展卡：Intel X520 (82599ES) SFP+ (2 个万兆光口)

## 磁盘分区

一块 SSD 分为 512M 的 EFI 分区，剩余空间建了一个 LVM（VG `lug`）。LVM 上装系统（`lug/root`）、swap（`lug/swap`）、Docker 数据（`lug/docker`）和 L2ARC（`lug/l2arc`，1.5 TB）。

全部 12 块 HDD 用 ZFS 做了一个 pool，每个控制器上面的 6 块盘作为一个 RAIDZ2 vdev，这个 ZFS pool 用于 `/home` 和 `/srv/repo`（仓库数据）等。

### Swap 与 OOM

这台服务器初装时是没有配置 swap 的，在 2024-10-31 17:12 左右由 git daemon 导致 OOM 后补充了 64G swap，此时 VG 剩余空间还有 100 多 GB 留给以后使用。

同时我们也给 git daemon 上了内存限制：

```ini title="systemctl edit git-daemon.service"
[Service]
MemoryMax=32G
MemoryHigh=28G
```
