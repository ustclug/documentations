# NFS

NFS 服务器（"vdp"）是东图三个 PVE 机器的虚拟机存储，型号为 DELL PowerEdge R510。磁盘阵列由于在 2021 年 3 月初损坏，目前容量缩减到 8T（4 块 4T 蓝盘 RAID10）。除虚拟机外，NFS 也存储 LUG 成员的个人数据及 LUG FTP。NFS 服务恢复后，为了保证数据冗余性，使用 Rclone 和 Rsync 每天增量备份 LUG FTP 和 LUG 成员的公开数据（`public_html` 目录）到以下位置：

- ~~[科大 Office 365 A1 账号](http://staff.ustc.edu.cn/~wf0229/office365/)~~ （已下线）
- 学校睿客网后端的对象存储
- pve-10 的 ZFS pool

具体的备份方式和命令参见机器上的 `rclone-backup.timer` 和 `rclone-backup.service`。

vdp 的内网连接依赖于 gateway-el。

!!! warning "可能的网络问题"

    在 2021 年九月份东图的 ESXi 与 NFS 连接会出现不稳定的问题，原因目前不明。在连接方式从 NFS 4.1 更换到 NFS 3 之后，连接的不稳定不会导致虚拟机被关闭。

    2021/09/29 更新：这两天再次出现了严重的连接问题。调试后发现 192.168.93.0/24 的网关 192.168.93.254 (Cisco 设备) 丢包严重，而 NFS 的出口 IP 错误被设置到了与图书馆交换机相连接的 eno1，导致请求需要绕路。将此 IP 移动至 eno2，修改 sysctl 设置 ARP 过滤并重启后，目前暂时解决了问题。

!!! warning "Debian Bookworm 内核问题"

    6.1.x 开始的内核的 NFSv4 服务器实现可能存在潜在的问题，导致在某些情况下死锁，见 <https://lore.kernel.org/all/50d62fc9-206b-4dbc-9a9b-335450656fd0@aixigo.com/T/>。从 Buster 升级到 Bookworm 之后被坑了一次。

    由于这个问题目前尚未解决，在升级 Bookworm 之后 vdp 仍使用 Bullseye 的内核（5.10.x）。

    ```yaml title="/etc/apt/preferences.d/linux-image-amd64"
    Package: linux-image-amd64
    Pin: release n=bullseye-security
    Pin-Priority: 900
    ```

    我们创建了如上文件（以便能够继续从 bullseye-security 获得内核的安全更新），然后手动删掉了所有 6.1 的内核包。

## PVE 磁盘路径与挂载参数

在 storage.cfg 设置中，NFS 挂载到 `/mnt/nfs-el`，设置的参数为 `soft,noexec,nosuid,nodev`。设置为 `hard` 会导致 NFS 下线时重试无限次，大概率导致系统卡死，其他几个参数主要是为了安全。

其中，根据 PVE 的要求，虚拟机磁盘文件需要放在 `images/<vmid>` 目录下才会被自动检测到。若一开始没有按要求放置文件或添加了新文件，可以使用 `qm rescan` 扫描新的磁盘文件。也可以直接使用 `qm set` 命令或手动编辑虚拟机配置文件指定磁盘文件的路径，这两种方法没有此限制。

另外，由于整个 storage.cfg 文件在集群中共享，需要手动指定 `nodes` 以免 NIC 的两台 PVE 主机尝试挂载。

```text title="/etc/pve/storage.cfg"
nfs: nfs-el
        export /media/vdp/pve
        path /mnt/nfs-el
        server nfs-el.vm.ustclug.org
        options soft,noexec,nosuid,nodev
        content iso,images
        nodes pve-2,pve-4,pve-6
        shared 1
        prune-backups keep-all=1
```

storage.cfg 的全部配置内容可以参考 <https://pve.proxmox.com/wiki/Storage>。
