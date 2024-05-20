# PXE 镜像

## UEFI Shell

<https://github.com/ustclug/simple-pxe/blob/master/menu.d/tool.sh>

依赖于 Arch Linux 提供的 EFI 文件。

## Memtest86+

<https://github.com/memtest86plus/memtest86plus>

此外 memtest86 有个[闭源实现](https://www.memtest86.com/download.htm)，不考虑继续维护。

以下步骤参考了 <https://gitlab.archlinux.org/archlinux/packaging/packages/memtest86plus/-/blob/main/PKGBUILD?ref_type=heads>。

```shell
git clone https://github.com/memtest86plus/memtest86plus.git
cd memtest86plus/build64
make
```

得到的 `memtest.bin` 是 BIOS 版的，`memtest.efi` 是 UEFI 版的。

启动菜单：<https://github.com/ustclug/simple-pxe/blob/master/menu.d/tool.sh>。

## GParted

<https://github.com/ustclug/simple-pxe/blob/master/menu.d/gparted.sh>。

启动参数不能加 `ip=`：<https://gitlab.gnome.org/GNOME/gparted/-/issues/141>。
