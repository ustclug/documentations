# Create new server in LUGi

!!! note "We no longer have a vSphere cluster, so the vSphere section is left only for references."

## Create VM in vCenter

vCenter 地址：vcenter2.vm.ustclug.org

按照提示创建虚拟机

- Step 7: Customize hardware
  - Network:
    - ustclug: intranet
    - ustclug-bridge: 没有 MAC 源地址检查
    - cernet: 教育网（先选这个，以便于通过网络安装系统）
  - VM options
    - VMware Tools
      - 打开 Sync time with Host

### Install OS

Notes:

将网络改为 cernet，以便用 DHCP 获得 IP 地址，用 PXE 安装系统。

几个关键配置：

- hostname: 主机名，如 vpnhc
- domain name: 搜索域，一般设为 s.ustclug.org
- 用户设置：先设置一个临时用户（尽量不与之后要配置的 ldap 账号冲突），用于初始登陆配置，之后删除
- 磁盘设置：使用整个硬盘，只留一个主分区，不留 swap 等分区，方便扩容

## Create VM on Proxmox VE

在 Proxmox VE 上，通过 web 界面创建新虚拟机后，可以使用普通方式安装系统，也可以直接导入发行版提供的虚拟机镜像（需要通过 SSH 登录 Proxmox VE 或 NFS 服务器）。

下面以 Debian 为例，创建一个新虚拟机，然后打开 <https://mirrors.ustc.edu.cn/debian-cdimage/cloud/bullseye/>，点击最新的目录（出于未知原因 latest 链接是坏的），复制 `debian-11-genericcloud-amd64-<date>-<rev>` 的链接（推荐使用 genericcloud 而不是 generic，其预装 `linux-image-cloud-amd64`，相比于“完整版”内核精简掉了大部分物理设备的驱动程序，适用于虚拟机环境），然后登录 Proxmox VE 或 vdp（NFS 服务器），使用以下命令直接下载镜像至虚拟机磁盘：

```shell
# Proxmox VE (ZFS / LVM), use RAW
wget -O /dev/zvol/rpool/data/vm-<id>-disk-0 https://<...>/<...>.raw

# vdp, use QCOW2
wget -O /media/vdp/pve/images/<path>.qcow2 https://<...>/<...>.qcow2
```

然后在 web 界面指定虚拟机的磁盘（如有需要）。

### Reset password

由于 Debian 提供的 cloud image 默认禁用了 root 用户，需要手动挂载磁盘，编辑磁盘中的 `/etc/shadow` 文件，将第一行的 `root:*:...` 改为 `root::...`（即删掉星号）。**注意不要误改主机的 shadow 文件**。

此步骤也可以替换为 chroot 进去后使用 `passwd` 修改或清空密码。

### Extra configurations for cloud images

The first two or three boots may hang or end up in kernel panic - **this is completely normal**. The cloud image will grow the root partition and filesystem to the virtual disk size. After it's all set, purge everything related to `cloud-init`.

For better console experiences, install and configure `console-setup`, and add `vga=792` to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`. Then run `update-grub` and reboot.

## Configure network

- 增加 hostname.s.ustclug.org 的 DNS 解析。（ustclug.intranet）
- 在 vCenter 中更改网络为 ustclug （如果不需要源 MAC 地址检查，选 ustclug-bridge）
- 在虚拟机中重启网络接口，改为静态 IP，并更改网关 （东图虚拟机设置为 10.254.0.254，NIC 虚拟机设置为 10.254.0.245）
  - `ifdown -a`
  - edit `/etc/network/interfaces`
  - `ifup -a`
- 更改虚拟机的 DNS 和 domain/search：
  - DNS:
    - neat-dns (10.254.0.253)
    - dns backup (202.38.93.94)
  - domain/search:
    - s.ustclug.org

## Install software

- 根据需要换源，加入安全更新源等
- 安装虚拟机工具
  - 对于 Proxmox VE 的虚拟机：安装 `qemu-guest-agent`
  - 对于 VMware vSphere 的虚拟机：安装 `open-vm-tools`
- 安装 openssh

## Configure LDAP and SSH CA

见 [LDAP 服务使用及配置说明](../../infrastructure/ldap.md) 和 [为服务器设置 SSH CA](../../infrastructure/sshca.md#issue-a-server-certificate)
