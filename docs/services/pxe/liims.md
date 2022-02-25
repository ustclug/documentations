# LIIMS

Short for **Libray Independent Inquery Machine System**.

Server: pxe.s.ustclug.org

Git Repository:

- [liimstrap](https://github.com/ustclug/liimstrap) （注意仓库内容的更改时间，可能严重过时了）

## 启动配置

配置文件在 `/home/pxe/tftp/grub/grub.cfg.d`，若要允许新机器启动 liims 镜像，创建一个符号链接到对应的配置文件（目前的镜像是 `liims160909`）：

```shell
ln -s liims160909 01:23:45:67:89:ab
```

## 启动镜像

位于 `/home/pxe/nfsroot/<category>/<name>`，其中 `<name>` 就是镜像名称（例如 `liims160909`）。这是整个 rootfs，直接修改这里的文件，机器重启后就会载入。

IP 白名单采用 iptables 实现，修改 rootfs 下的 `etc/iptables/*.rules` 可修改策略。

## 镜像构建

!!! note "iBug 备注"

    此节及以下的内容可能严重过时，pxe.s 上的很多配置都被手动更新过了。

使用 liimstrap 在 ArchLinux 下进行构建，liimstrap使用方法参考仓库中的说明。

构建后需要推送到服务器上的 /nfsroot/liims 下，并设置 /usr 的所有者为 liims。机器的默认 pxe 启动配置在 /home/pxe/tftp/pxelinux.cfg/ 下

### 示例 qemu 调试方法

创建并挂载临时镜像:

```sh
dd if=/dev/zero of=liims.img bs=4k count=1200000
mkfs.ext4 liims.img
mount -o loop liims.img /mnt
```

假设当前路径为 liimstrap，修改 `initcpio/mkinitcpio.conf`，去掉 HOOKS 中的 `liims_root`，增加 `block`（仅调试时需要）。 使用 liimstrap 制作镜像 `./liimstrap /mnt`。完成后使用 qemu 打开调试:

```shell
qemu -kernel /mnt/boot/vmlinuz-lts\
     -initrd /mnt/boot/initramfs-linux-lts.img\
     -hda liims.img\
     -netdev user,id=mynet0,net=114.214.188.0/24,dhcpstart=114.214.188.9\
     -device i82557a,netdev=mynet0\
     -append "root=/dev/sda rootflags=rw"
```

注：其中 netdev 中的 ip 段可以自由选取，`device` 中的设备名通过 `qemu -device \?` 查看后选择任一网络设备即可

## 查询机监控 {#monitor}

<http://pxe.ustc.edu.cn:3000/>

提供服务的是一个容器。

添加新机器：修改 <https://github.com/ustclug/liimstrap/blob/master/monitor/clients.json> 后，在 pxe 上 clone 并在当前目录 build。使用 docker-run-script 中对应脚本执行容器即可。
