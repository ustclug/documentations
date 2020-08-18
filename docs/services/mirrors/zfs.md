# ZFS

## Configuration

*/etc/modprobe.d/zfs.conf*

```
options zfs zfs_arc_max=137438953472
options zfs l2arc_write_max=52428800
options zfs zfs_arc_meta_min=17179869184
options zfs l2arc_noprefetch=0
```

refer to `man zfs-module-parameters`.

## Common Operations

### Get zpool status

```shell
zpool status
```

### Get IO status

```shell
zpool iostat -v 1
```

### Replace Disk

```shell
zpool replace pool0 old-disk new-disk
```

### New ZFS file system

```sh
zfs create [-o mountpoint=$mountpoint] $filesystem
```

Example:

```shell
zfs create -o mountpoint=/srv/repo/debian pool0/repo/debian
```

If mountpoint is not specified, then it's inherited from the parent with a subpath appended, e.g. when `pool0/example` is mounted on `/mnt/haha` then `pool0/example/test` will by default mount on `/mnt/haha/test`.

### Destory ZFS file system

```shell
zfs destroy $filesystem
```

Example:

```shell
zfs destroy pool0/repo/debian
```

### Traps

<del>Do **NOT** install `zfs-dkms` and related packages from Debian backports repositories. They'll easily break when upgrading.</del>

<del>As of Debian Buster the ZFS packages from the mainstream repository is stable and new enough for our use.</del>

仍然建议安装 Backports 版本的 ZFS。「Stable 越往后（对 ZFS 相关软件包的）维护越弱」，从而导致 stable 的 ZFS 反而质量不如 backports 版本的。