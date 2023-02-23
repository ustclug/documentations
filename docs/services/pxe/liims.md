# LIIMS

Short for **Libray Independent Inquery Machine System**.

Server: pxe.s.ustclug.org

Git Repository:

- [liimstrap](https://github.com/ustclug/liimstrap)

It is strongly advised to clone liimstrap and read through it when reading this document.

## 启动配置 {#add-machine}

配置文件在 `/home/pxe/tftp/grub/grub.cfg.d`，若要允许新机器启动 liims 镜像，创建一个符号链接到对应的配置文件。例如：

```shell
ln -s common_el 02:23:45:67:89:ab
```

目前我们通过几个符号链接将配置文件“分组”，MAC 地址对应的符号链接应该链接到这些分组上。已有的分组如下：

- `common_el`：EL 即 East-campus Library（东图）
- `common_wl`：WL 即 West-campus Library（西图）
- `common_sl`：SL 即 South-campus Library（南图）
- `common_iat`：IAT 即先研院
- `common_gx`：GaoXin 高新校区
- `test`：测试镜像

除此之外，还需要在查询机监控程序中添加该 MAC 地址，见下方[查询机监控](#monitor)。

### 为图书馆老师开放的接口 {#lib-api}

图书馆老师可以通过 SSH 登录机器直接创建所需的符号链接（但是还需要我们来改监控程序的 json）。相关配置如下：

```conf title="/etc/sudoers.d/sonnie"
sonnie ALL=(pxe) NOPASSWD: /home/pxe/tftp/grub/grub.cfg.d/add_host.py *
```

```conf title="/etc/ssh/sshd_config"
Match User sonnie
    AllowUsers sonnie
    PubkeyAuthentication yes
    AuthorizedKeysFile .ssh/authorized_keys
```

!!! abstract "/etc/nsswitch.conf"

    把 sudoers 一行中的 ldap 移到 files 前面。

    默认情况下 ldap 在 files 后面，那么来自 LDAP 的 sudo rules 会排在 sudoers 文件中的 rules 的后面，而 sudo 是后面的规则优先级更高，会导致无法 NOPASSWD 运行脚本。

## 启动镜像

位于 `/home/pxe/nfsroot/<category>/<name>`，其中 `<name>` 就是镜像名称（例如 `liims160909`）。目前有两种部署方式：一种是 NFS as rootfs，文件夹中就是整个 rootfs，直接修改这里的文件，机器重启后就会载入。（注意：覆盖文件可能导致已有的机器运行错误）

另一种是打包压缩为 squashfs，此时文件夹下三个文件分别为 vmlinuz（kernel）, initrd.img 和 root.sfs（squashfs 镜像）。如果需要修改，可以使用 `unsquashfs` 解压缩，修改完成后参考仓库中 deploy 文件再压缩为 squashfs。

IP 白名单采用 iptables 实现，修改 rootfs 下的 `etc/iptables/rules.v4` 和 `rules.v6` 可修改策略。注意：防火墙策略仅在机器启动时会载入一次。

## 镜像构建

!!! note "备注"

    此节的内容仅适用于 2022 之前的老版本，新版本有关构建、调试等内容请直接阅读 liimstrap 仓库 README。

使用 liimstrap 在 ArchLinux 下进行构建，liimstrap 使用方法参考仓库中的说明。

构建后需要推送到服务器上的 `/nfsroot/liims` 下，并设置 /usr 的所有者为 liims。机器的默认 pxe 启动配置在 `/home/pxe/tftp/pxelinux.cfg/` 下

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

2022 年前，提供服务的是一个 Docker 容器。在 iBug 用 Go 重写之后，目前直接跑在 host 上。

!!! tip "添加新机器"

    ~~修改 <https://github.com/ustclug/liimstrap/blob/master/monitor/clients.json> 后，在 pxe 上 clone 并在当前目录 build。使用 docker-run-script 中对应脚本执行容器即可。~~

    修改 `/etc/liims-monitor/clients.json` 之后 `systemctl reload liims-monitor.service` 即可。

    ```json title="/etc/liims-monitor/clients.json"
    {
        "name": "东区三楼东01",
        "mac": "0223456789ab"
    }
    ```
