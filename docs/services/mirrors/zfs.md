# ZFS

## Common Operations

```shell title="Get zpool status"
zpool status
```

```shell title="Get IO status"
zpool iostat -v 1
```

```shell title="Replace Disk"
zpool replace pool0 old-disk new-disk
```

```shell title="New ZFS file system"
zfs create [-o option=value ...] <filesystem>

# Example
zfs create pool0/repo/debian
```

If `mountpoint` is not specified, then it's inherited from the parent with a subpath appended. E.g. when `pool0/example` is mounted on `/mnt/haha` then `pool0/example/test` will by default mount on `/mnt/haha/test`.

```shell title="Destory ZFS file system"
zfs destroy <filesystem>

# Example
zfs destroy pool0/repo/debian
```

### Create new repository {#new-repo}

```shell
zfs create pool0/repo/example
```

Contrary to XFS, no other steps are needed.

## Setup

!!! note "This section is recorded for reference only."

### Pool setup (mirrors2)

```shell
zpool create pool0 \
  -O canmount=off \
  -O xattr=sa \
  -O relatime=on \
  -O compress=zstd \
  raidz2 \
  ata-HGST_HUS726060ALE610_K1GKVAAD \
  ata-HGST_HUS726060ALE610_K1GHTLND \
  ata-HGST_HUS726060ALE610_K1GHTVWD \
  ata-HGST_HUS726060ALE610_K1GKNJUD \
  ata-HGST_HUS726060ALE610_K1GK5KND \
  ata-HGST_HUS726060ALE610_K1GK9GXD \
  raidz2 \
  ata-HGST_HUS726060ALE610_NCH13D2V \
  ata-HGST_HUS726T6TALE6L4_V9KWJ1PL \
  ata-HGST_HUS726T6TALE6L4_V9HU810L \
  ata-HGST_HUS726060ALE610_NCH141WV \
  ata-HGST_HUS726060ALE610_K1GKPDSD \
  ata-HGST_HUS726T6TALE6L4_V9KTTT5L \
  cache nvme0n1
```

!!! note

    The `-O` option applies to the root dataset.

??? example "Create ZFS (2016)"

    ```shell
    zpool create -f pool0 \
      raidz3 \
      ata-HGST_HUS726060ALE610_K1GHTLND \
      ata-HGST_HUS726060ALE610_K1GHTVWD \
      ata-HGST_HUS726060ALE610_K1GK5KND \
      ata-HGST_HUS726060ALE610_K1GK9GXD \
      ata-HGST_HUS726060ALE610_K1GKNJUD \
      ata-HGST_HUS726060ALE610_K1GKNP5D \
      ata-HGST_HUS726060ALE610_K1GKNR6D \
      ata-HGST_HUS726060ALE610_K1GKPDSD \
      ata-HGST_HUS726060ALE610_K1GKVAAD \
      ata-HGST_HUS726060ALE610_NCH04T5V \
      ata-HGST_HUS726060ALE610_NCH13D2V \
      spare \
      ata-HGST_HUS726060ALE610_NCH141WV \
      log mirror \
      ata-INTEL_SSDSC2BB240G6_PHWA64410400240AGN-part1 \
      ata-INTEL_SSDSC2BB240G6_PHWA6441041N240AGN-part1 \
      cache \
      ata-INTEL_SSDSC2BB240G6_PHWA64410400240AGN-part2 \
      ata-INTEL_SSDSC2BB240G6_PHWA6441041N240AGN-part2
    ```

### ZFS kernel module

For OpenZFS 2.2:

```shell title="/etc/modprobe.d/zfs.conf"
# Set ARC size to 160-200 GiB, keep 16 GiB free for OS
options zfs zfs_arc_max=214748364800
options zfs zfs_arc_min=171798691840
options zfs zfs_arc_sys_free=17179869184

# Favor metadata to data by 20x (OpenZFS 2.2+)
options zfs zfs_arc_meta_balance=2000

# Allow up to 80% of ARC to be used for dnodes
options zfs zfs_arc_dnode_limit_percent=80

# Allow every block to be written to ZIL
options zfs zfs_immediate_write_sz=16777216

# See man page section "ZFS I/O Scheduler"
options zfs zfs_vdev_async_read_max_active=8
options zfs zfs_vdev_async_read_min_active=2
options zfs zfs_vdev_scrub_max_active=5
options zfs zfs_vdev_max_active=20000

# Never throttle the ARC
options zfs zfs_arc_lotsfree_percent=0

# Tune L2ARC
options zfs l2arc_headroom=8
options zfs l2arc_write_max=67108864
options zfs l2arc_noprefetch=0
```

Refer to [`zfs(4)`](https://openzfs.github.io/openzfs-docs/man/master/4/zfs.4.html).

!!! note

    `zfs_dmu_offset_next_sync` is 1 by default since OpenZFS v2.1.5, so it's omitted in the configuration.

### Dataset properties

On mirrors2:

```shell
zfs create -o compress=zstd-8 -o recordsize=1M -o atime=off pool0/backup

zfs create pool0/backup/rootfs # inherit everything
zfs create -o acltype=posix pool0/backup/oldlog

zfs create \
  -o mountpoint=/srv/repo \
  -o recordsize=1M \
  -o xattr=off \
  -o atime=off \
  -o setuid=off \
  -o exec=off \
  -o devices=off \
  -o sync=disabled \
  -o secondarycache=metadata \
  -o redundant_metadata=some \
  pool0/repo
```

Refer to [`zfsprops(7)`](https://openzfs.github.io/openzfs-docs/man/master/7/zfsprops.7.html).

#### Considerations

`mountpoint`

:   Self-explanatory.

`recordsize=1M`

:   This is the "block size" for ZFS, i.e. how large files are split into blocks. Each block (record) is stored contiguously on disk and is read/written as a whole.

    Since the typical read pattern on mirror sites is whole-file sequential read, it makes sense to set `recordsize` to the maximum value permitted[^recordsize]. Larger `recordsize` allows the compression algorithm to exploit more opportunities, while also reducing I/O count for large files.

    Note that files under a single `recordsize` will *not* be padded up and will be stored as a single block, so no space is wasted.

  [^recordsize]: Actually, there's the `zfs_max_recordsize` module parameter which can be increased to up to 16 MiB. There's a reason this is set to 1 MiB by default, so we're not going to blindly aim for the maximum.

`compression=zstd` (inherited from `pool0`)

:   Enable compression so anything will be tried to compress. The default algorithm (i.e. `compression=on`) is LZ4, which is very fast but not as effective. Zstd is a modern multi-threaded algorithm that is also very fast but compresses better. The default compression level is 3 (i.e. `zstd` = `zstd-3`).

    Since OpenZFS 2.2, there's an "early-abort" mechanism for Zstd level 3 or up: Every block is first tried with LZ4, then Zstd-1, and if and only if both algorithms suggest that the data block would compress well, the actual algorithm will be applied and the compressed result will be written to disk. This early-abort mechanism ensures minimal CPU wasted for incompressible data.

`xattr=off`

:   Apparently mirror data do not need extended attributes.

`atime=off`, `setuid=off`, `exec=off`, `devices=off`

:   These simply maps to the `noatime`, `nosuid`, `noexec`, and `nodev` mount options respectively. It's safe to assume we don't need these features for mirror data.

`sync=disabled`

:   Disable any "synchronous write" semantics. This means files will not respond to `open(O_SYNC)` and `sync(2)` calls. Pending writes will only be committed to disk after `zfs_txg_timeout` seconds (default 5) or when the write buffer is full.

    While normally this is a bad idea as it goes against data integrity (namely, the "D" in ACID), for mirror data that can be easily regenerated, this improves write performance and reduces fragmentation (also note that `zfs_dmu_offset_next_sync` is enabled by default).

`secondarycache=metadata`

:   As mirrors2 only serves Rsync requests, caching file content provides little benefit. Instead, we cache metadata only to reduce the number of disk seeks.

`redundant_metadata=some`

:   (Just read `zfsprops(7)` and you'll be able to reason about this.)

### Traps

<del>Do **NOT** install `zfs-dkms` and related packages from Debian backports repositories. They'll easily break when upgrading.</del>

<del>As of Debian Buster the ZFS packages from the mainstream repository is stable and new enough for our use.</del>

仍然建议安装 Backports 版本的 ZFS。「Stable 越往后（对 ZFS 相关软件包的）维护越弱」，从而导致 stable 的 ZFS 反而质量不如 backports 版本的。

## Notes

Since our ZFS rebuild in mid-2024 (writeups: [English](https://ibug.io/p/74), [中文版](https://lug.ustc.edu.cn/planet/2024/12/ustc-mirrors-zfs-rebuild/)), several extra changes have been made:

- We no longer install `zfs-dkms` from Debian backports. Instead we run `proxmox-default-kernel` from the corresponding Proxmox VE release (e.g. PVE 9 = Debian Trixie), with additial AppArmor profile tweaks to allow `rsync` to run normally (see the "AppArmor" section in the writeup articles).
- `recordsize` has been further increased to 4 MiB. However, minimal differences have been observed.
- `secondarycache` has been reduced from `all` to `metadata` on mirrors4 as it began serving Rsync traffic. L2ARC hit rate remained above 50%, though, which is surprisingly good.
- An additional ZFS module parameter has been added: `zfs_immediate_write_sz=16777216` (default value is 32 KiB).
- We have ditched the userspace deduplication solution (jdupes) in favor of OpenZFS 2.3 Fast Dedup feature. This is done by enabling `feature@fast_dedup` on the zpool level, *before* enabling `dedup` on each dedup'd dataset.
    - The datasets with `dedup` enabled are the same dataset listed in the writeup article, excluding `mysql-repo` (which was already excluded from the original jdupes plan) and `salt` (later structural changes in the repository rendered dedup ineffective), leaving 7 remaining.
