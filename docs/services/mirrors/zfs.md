# ZFS

## Configuration

### ZFS kernel module

For OpenZFS 2.2:

```shell title="/etc/modprobe.d/zfs.conf"
options zfs zfs_arc_max=161061273600
options zfs zfs_arc_min=161061273600
options zfs l2arc_write_max=67108864
options zfs l2arc_noprefetch=0
```

Refer to [`zfs(4)`](https://openzfs.github.io/openzfs-docs/man/master/4/zfs.4.html).

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

### Traps

<del>Do **NOT** install `zfs-dkms` and related packages from Debian backports repositories. They'll easily break when upgrading.</del>

<del>As of Debian Buster the ZFS packages from the mainstream repository is stable and new enough for our use.</del>

仍然建议安装 Backports 版本的 ZFS。「Stable 越往后（对 ZFS 相关软件包的）维护越弱」，从而导致 stable 的 ZFS 反而质量不如 backports 版本的。
