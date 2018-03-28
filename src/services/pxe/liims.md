# LIIMS

perhaps short for Libray Independent Inquery Machine System

server: pxe.s.ustclug.org

Git Repository:

- [liimstrap](https://github.com/ustclug/liimstrap)


使用liimstrap在ArchLinux下进行构建，liimstrap使用
方法参考仓库中的说明。

构建后需要推送到服务器上的/nfsroot/liims下，并设置/usr的所有者为liims。
机器的默认pxe启动配置在/home/pxe/tftp/pxelinux.cfg/下

## 示例qemu调试方法

创建并挂载临时镜像:

```sh
dd if=/dev/zero of=liims.img bs=4k count=1200000
mkfs.ext4 liims.img
mount -o loop liims.img /mnt
```

假设当前路径为liimstrap，修改`initcpio/mkinitcpio.conf`，
去掉HOOKS中的`liims_root`，增加`block`（仅调试时需要）。
使用liimstrap制作镜像`./liimstrap /mnt`。完成后使用
qemu打开调试:
```sh
qemu -kernel /mnt/boot/vmlinuz-lts\
     -initrd /mnt/boot/initramfs-linux-lts.img\
     -hda liims.img\
     -netdev user,id=mynet0,net=114.214.188.0/24,dhcpstart=114.214.188.9\
     -device i82557a,netdev=mynet0\
     -append "root=/dev/sda rootflags=rw"
```

注：其中netdev中的ip段可以自由选取，`device`中的设备名通过`qemu -device \?`查看后选择任一网络设备即可
