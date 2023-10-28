# Docker 相关问题

## Debian 11 中不再支持 aufs

从 Debian 10 升级到 Debian 11 时，`aufs-dkms` 不再包含在新内核中：

> aufs-dkms 软件包将不作为 bullseye 的一部分出现。大多数 aufs-dkms 用户应当切换至 overlayfs，后者提供了相似的功能且具有内核的支持。然而，某些 Debian 安装实例可能使用了不兼容 overlayfs 的文件系统，如不带有 d_type 的 xfs。我们建议需要使用 aufs-dkms 的用户在升级至 bullseye 之前先进行迁移。

(<https://www.debian.org/releases/bullseye/amd64/release-notes/ch-information.zh-cn.html>)

对于老机器来说需要提前确认 Docker 的 storage driver：

```console
$ sudo docker info
// ...
Server:
 // ...
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Native Overlay Diff: true
  userxattr: false
```

这里如果是 overlay2 那么就没问题，如果是 aufs 的话就需要提前确认，因为切换到 overlay2 之后现有的容器和容器镜像都会丢失，需要重新创建。所以需要确保容器（container）和镜像（image）是可复现的。

在升级系统后，编辑 `/etc/docker/daemon.json`，加上：

```json
"storage-driver": "overlay2"
```

然后启动 docker，重新创建容器。
