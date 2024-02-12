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

创建 rootfs，这里以 RAID1 的方式（`--type mirror` 或 `--type raid1`）创建这个分区，这样即使 sda / sdb 坏掉一整组之后还有 rootfs 可以用。注意 `-m 1` 表示 1 份**额外**的镜像。

```shell
lvcreate -n root -L 32G --type mirror -m 1 lug
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
lvconvert --type cache-pool --poolmetadata ssd/mcache_meta --cachemode writethrough -c 1M --config allocation/cache_pool_max_chunks=2000000 ssd/mcache
```

<del>这里的缓存模式采用 passthrough，即写入动作绕过缓存直接写回原设备（当然啦，写入都是由从上游同步产生的），另外两种 writeback 和 writethrough 都会写入缓存，不是我们想要的。</del> passthrough 模式中，读写都会绕过 cache，唯一的作用是 write hit 会使得 cache 对应的块失效。

<del>这里使用 writeback 模式，因为仓库数据没了还能再同步，使用 writeback 提升性能更合适。</del>

出于稳定考虑，使用 writethrough 模式。（我们的 Cache 太大了，writeback 可能会弄坏不少东西，如果 metadata 坏了就更麻烦了）

!!! danger "坑"

    直接使用 lvconvert(8) 尝试合并会导致吐槽，这是上面 lvreduce(8) 的原因。

    ```text
    Volume group "ssd" has insufficient free space (0 extents): 2048 required.
    ```

!!! note "iBug 备注"

    LVM 推荐的是一个缓存池里不超过 100 万个 chunk（这也是 allocation/cache_pool_max_chunks 的默认值），但是这样每个 chunk 的最小大小为 1.84 MiB 太大了，考虑到我们有足够的 CPU 和内存，这里就<s>铤而走险</s>尝试一下较大的 chunk count。

!!! danger "坑 2"

    缓存盘（cache pool）和被缓存的卷必须在同一个 VG 中。

!!! danger "坑 3 (taoky 备注)"

    LVM Cache 的底层是在内核实现的 dm-cache。目前已知的坑如下：

    1. 当出现 dirty blocks（且 cache policy 为 cleaner 时），无法正常 flush。网络上可以找到的这个 [bug](https://bugzilla.redhat.com/show_bug.cgi?id=1668163) 的解决方法是增大 migration_threshold 的值（在新版本 LVM 中，migration_threshold 默认至少会是 chunk size 的 8 倍，在我们的配置下就是 16384 = 2048 * 8。这个版本的 LVM 暂时不在 Buster 中），但是经过测试，单纯增大 migration_threshold 没有任何效果。Jiahao 翻了一下 dm-cache 的源代码，发现 flush 的条件在 <https://elixir.bootlin.com/linux/latest/source/drivers/md/dm-cache-target.c#L1649>，只在状态为 IDLE 时才会 flush。IDLE 的第一个条件需要 inflight io = 0，比较苛刻，可能是无法正常 flush 的原因。

        一个扭曲的解决方法是：先把 migration_threshold 设置得很大（设大小为 x），然后马上缩小，这样就能把 x 那么多大小的脏块弄掉（原理暂时不明，需要补充）。基于这个方法，可以写一个脚本来做 flush 的工作：

        ```sh
        # dirty hack
        sudo lvchange --cachepolicy cleaner lug/repo
        for i in `seq 1 1500`; do sudo lvchange --cachesettings migration_threshold=2113536 lug/repo && sudo lvchange --cachesettings migration_threshold=16384 lug/repo && echo $i && sleep 15; done;
        # 需要确认没有脏块。如果还有的话继续执行（次数调小一些）
        # 如果是从 writeback 切换，需要先把模式切到 writethrough
        # 然后再修改 cachepolicy 到 smq
        sudo lvchange --cachepolicy smq lug/repo
        ```

        在执行时，可以查看：

        ```sh
        sudo dmsetup status lug-repo
        # 在 "metadata2" 前面的前面的数字就是 dirty block 的数量
        # 如果不在执行 lvchange（没有进程抢占了 LVM 的锁），可以执行以下命令确认脏块数量以及其他一些参数。
        sudo lvs -o name,cache_policy,cache_settings,chunk_size,cache_used_blocks,cache_dirty_blocks /dev/mapper/lug-repo
        ```

    2. 每次 unclean shutdown 之后，cache 中所有块都会被标记为 dirty。尽管不太可能阻塞系统启动，这可能会给 HDD 一定的压力。
    3. 扩大 lug/repo 的大小前需要 uncache，且 uncache 的前提条件是没有脏块。

!!! danger "坑 4"

    修改 `migration_threshold` 等设置会导致目前版本的 GRUB 无法正确识别 LVM 元数据。

    临时修复版本：<https://github.com/taoky/grub/releases/tag/2.02%2Bdfsg1-20%2Bdeb10u4taoky3_amd64>。目前已部署，且设置了 `apt hold`。

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

### repo 扩容

查看当前逻辑卷信息：

```
# lvs -a -o +devices
  LV              VG  Attr       LSize   Pool     Origin       Data%  Meta%  Move Log         Cpy%Sync Convert Devices
  backup          lug -wi-ao----   8.00g                                                                       /dev/sda3(6307840)
  docker          lug -wi-ao----  64.00g                                                                       /dev/sdc1(0)
  docker2         lug -wi-a----- 300.00g                                                                       /dev/sda3(7925248)
  home            lug -wi-ao----  64.00g                                                                       /dev/sda3(8192),/dev/sdb3(8193)
  log             lug -wi-ao---- 300.00g                                                                       /dev/sda3(6309888),/dev/sdb3(6307841)
  log             lug -wi-ao---- 300.00g                                                                       /dev/sda3(7888896),/dev/sdb3(7882753)
  [lvol0_pmspare] lug ewi-------  16.00g                                                                       /dev/sda3(7884800)
  [mcache]        lug Cwi---C---   1.50t                       99.99  0.12                    0.00             mcache_cdata(0)
  [mcache_cdata]  lug Cwi-ao----   1.50t                                                                       /dev/sdc1(20480)
  [mcache_cmeta]  lug ewi-ao----  16.00g                                                                       /dev/sdc1(16384)
  repo            lug Cwi-aoC---  60.00t [mcache] [repo_corig] 99.99  0.12                    0.00             repo_corig(0)
  [repo_corig]    lug owi-aoC---  60.00t                                                                       /dev/sda3(16384),/dev/sdb3(16385)
  [repo_corig]    lug owi-aoC---  60.00t                                                                       /dev/sda3(6311936),/dev/sdb3(6309889)
  root            lug mwi-aom---  32.00g                                          [root_mlog] 100.00           root_mimage_0(0),root_mimage_1(0)
  [root_mimage_0] lug iwi-aom---  32.00g                                                                       /dev/sda3(0)
  [root_mimage_1] lug iwi-aom---  32.00g                                                                       /dev/sdb3(0)
  [root_mlog]     lug lwi-aom---   4.00m                                                                       /dev/sdb3(8192)
```

检查 cache 是否有 dirty block：

```
$ sudo lvs -o name,cache_policy,cache_settings,chunk_size,cache_used_blocks,cache_dirty_blocks /dev/mapper/lug-repo
  LV   CachePolicy CacheSettings Chunk CacheUsedBlocks  CacheDirtyBlocks
  repo smq                       1.00m          1048551                0
```

（正常重启之后可能会出现 dirty block，原因不明。如果看到有的话，那只能 ~~再次进入痛苦的轮回~~ 用上述的方法清除，并且清除的时候对系统负载影响很大，因为落盘的时候其他进程对应的 IO 会被暂停，在相对平衡时间和负载的命令下，估计需要 10 小时的时间。）

然后 uncache、扩容：

```
# lvconvert --uncache lug/repo
# lvextend -L +5T lug/repo
# xfs_growfs /srv
```

然后恢复 cache（参考上面 mcache_meta 和 mcache 逻辑卷的配置，**请注意在理解命令后再执行**！）：

```
# lvcreate -L 16G -n mcache_meta lug /dev/sdc1  # SSD 设备路径重启后可能会变化
# lvcreate -l 100%FREE -n mcache lug /dev/sdc1
# lvreduce -l -2048 lug/mcache
# lvconvert --type cache-pool --poolmetadata lug/mcache_meta --cachemode writethrough -c 1M --config allocation/cache_pool_max_chunks=2000000 lug/mcache
# lvconvert --type cache --cachepool lug/mcache lug/repo
```

!!! danger "坑 5"

    新建时在倒数第二步的 `lvconvert` 可能会卡死超过半小时（但是最后还是能完成的），栈的信息显示栈顶函数是 `submit_bio_wait()`，在清零对应的 block range，因为 RAID 卡不支持下传 discarding 所以会很慢，需要等一段时间。

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
