# Volumes on mirrors4

[介绍页](index.md)讲过了，控制器的坑导致不能直接把 12 块硬盘组成一个逻辑磁盘，因此我们在上层使用 LVM 来解决这个问题。

## 磁盘分区

!!! warning "注意"

    这里给出的命令仅用于展示分区（卷）的创建方式，除非完全重装，否则**不应该执行**其中任何一条有副作用的命令。

操作系统看到三个硬盘：两个 RAID6 大盘（40 TB / 36.4 TiB）和一个 SSD（2 TB / 1.86 TiB）。设两个大盘为 /dev/sda 和 /dev/sdb，SSD 为 /dev/sdc。

由于启动分区不能放在 LVM 上，因此以如下方式创建分区：

```text
root@mirrors4:~# fdisk -l /dev/sda
Disk /dev/sda: 36.4 TiB, 40001177911296 bytes, 78127300608 sectors
Disk model: MR9361-8i
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 262144 bytes / 262144 bytes
Disklabel type: gpt
Disk identifier: AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA

Device       Start         End     Sectors  Size Type
/dev/sda1     2048        4095        2048    1M BIOS boot
/dev/sda2     4096     1052671     1048576  512M EFI System
/dev/sda3  1052672 78127300574 78126247903 36.4T Linux LVM
```

sdb 的参数完全一样。

实际的启动分区为 /dev/sda2，将其 dd 到 /dev/sdb2 做备份。

然后是 SSD 的分区：

```text
Disk /dev/sdc: 1.8 TiB, 1919816826880 bytes, 3749642240 sectors
Disk model: MR9361-8i
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 65536 bytes / 65536 bytes
Disklabel type: gpt
Disk identifier: AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA

Device     Start        End    Sectors  Size Type
/dev/sdc1   2048 3749642206 3749640159  1.8T Linux LVM
```

## LVM

把 sda3 和 sdb3 都放进 LVM：

```shell
# fdisk 分区完毕，w 写入退出
pvcreate /dev/sda3 /dev/sdb3
vgcreate lug /dev/sda3 /dev/sdb3
```

创建 rootfs，这里以 RAID1 的方式（`--type mirror` 或 `--type raid1`）创建这个分区，这样即使 sda / sdb 坏掉一整组之后还有 rootfs 可以用。

```shell
lvcreate -n root -L 32G --type mirror -m 2 lug
mkfs.ext4 /dev/lug/root
```

创建 home，这里反正不怕坏，用 RAID0（`--type striped` 或 `--type raid0`）。

```shell
lvcreate -n root -L 64G --type striped -i 2 lug
mkfs.ext4 /dev/lug/home
```

创建放镜像的分区，这次要用 xfs

!!! warning "XFS 不支持缩小"

    因此我们在初装时选择为其分配 48 TiB 的空间，而不是 VG lug 的剩余全部——这样方便以后维护

```shell
lvcreate -n repo -L 48T --type striped -i 2 lug
mkfs.xfs /dev/lug/repo
```

其实本来要调一下参的，不过根据 [Arch Wiki](https://wiki.archlinux.org/index.php/XFS#Performance)，`mkfs.xfs` 的默认参数就是最优的，所以我们决定不动了。

### SSD

SSD 的用途为存放 Docker 数据 `/var/lib/docker`（8 GiB 就够了，但是 overlay2 的后端用 ext4 更好），剩下用作 lvmcache(7)。

!!! note "iBug 备注"

    虽然似乎没有这样做（先创建单独的 VG 再合并）的必要，但是这么做一定不会出错，就这样吧。

在 SSD 上新建一个 VG：

```shell
# fdisk 创建唯一一个分区 sdc1，保存退出
pvcreate /dev/sdc1
vgcreate ssd /dev/sdc1
```

创建 Docker 数据盘：

```shell
lvcreate -L 8G -n docker ssd
mkfs.ext4 /dev/ssd/docker
```

**重要**：创建缓存盘和缓存元数据盘。根据 [Red Hat Documentation][lvm.red-hat] 的介绍，先手动创建数据盘和元数据盘，然后将他们合并为一个 cache pool。大小方面，文章的参考是 2G data ↔ 12M meta，这里我们有接近 2 TB 的 data，就分配 16 GB 作为 meta 吧。

```shell
lvcreate -L 16G -n mcache_meta ssd
lvcreate -l 100%FREE -n mcache ssd
lvreduce -l -2048 ssd/mcache
lvconvert --type cache-pool --poolmetadata ssd/mcache_meta --cachemode writeback -c 1M --config allocation/cache_pool_max_chunks=2000000 ssd/mcache
```

<del>这里的缓存模式采用 passthrough，即写入动作绕过缓存直接写回原设备（当然啦，写入都是由从上游同步产生的），另外两种 writeback 和 writethrough 都会写入缓存，不是我们想要的。</del> passthrough 模式中，读写都会绕过 cache，唯一的作用是 write hit 会使得 cache 对应的块失效。

这里使用 writeback 模式，因为仓库数据没了还能再同步，使用 writeback 提升性能更合适。

!!! danger "坑"

    直接使用 lvconvert(8) 尝试合并会导致吐槽，这是上面 lvreduce(8) 的原因。

    ```text
    Volume group "ssd" has insufficient free space (0 extents): 2048 required.
    ```

!!! note "iBug 备注"

    LVM 推荐的是一个缓存池里不超过 100 万个 chunk（这也是 allocation/cache_pool_max_chunks 的默认值），但是这样每个 chunk 的最小大小为 1.84 MiB 太大了，考虑到我们有足够的 CPU 和内存，这里就<s>铤而走险</s>尝试一下较大的 chunk count。

!!! danger "坑 2"

    缓存盘（cache pool）和被缓存的卷必须在同一个 VG 中。

所以接下来要合并 VG，然后才能为仓库卷加上缓存。

```shell
lvchange -a n ssd/docker
vgmerge lug ssd
lvconvert --type cache --cachepool lug/mcache lug/repo
```

接下来挂上 Docker 卷（注意 VG 名已经从 ssd 变成了 lug）：

```shell
lvchange -a y lug/docker
mount /dev/lug/docker /var/lib/docker
```

## fstab

分区完毕后给 `/etc/fstab` 补上相关的内容并挂载：

```text
/dev/mapper/lug-home   /home           ext4 defaults             0 2
/dev/mapper/lug-docker /var/lib/docker ext4 defaults             0 2
/dev/mapper/lug-repo   /srv            xfs  defaults,pqnoenforce 0 2
/dev/mapper/lug-log    /var/log        ext4 defaults             0 2
```

（这个 log 分区前面没提，反正像模像样知道就行了）


  [lvm.red-hat]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/lvm_cache_volume_creation
