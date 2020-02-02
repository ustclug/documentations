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
zfs create -o mountpoint=$mountpoint $filesystem
```

example:

```shell
zfs create -o mountpoint=/srv/repo/debian pool0/repo/debian
```

### Destory ZFS file system

```shell
zfs destroy $filesystem
```

example:

```shell
zfs destroy pool0/repo/debian
```

### 