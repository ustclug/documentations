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

我们目前不使用 PVE 运行 LXC 容器，因此本文档只介绍创建 KVM 虚拟机的步骤。推荐使用 web 界面操作，除非你需要批量创建虚拟机（此时通过 SSH 登录后可以使用 `qm` 命令批处理）。

登录 web 界面，点击右上角的 Create VM，弹出创建虚拟机的对话框。

**General**

:   正确选择虚拟机所在的 Node（即 Host），并指定一个 VMID。目前 VMID 的分配方案是东图 300-399，NIC 200-299，在此基础上递增即可。给 VM 起个易于辨识的名称，不要与已有 VM 重复。Resource Pool 留空即可。

**OS**

:   除非你要使用 iso 镜像手动安装系统，否则请选择「Do not use any media」。正确选择 Guest OS 的类型和版本。

**System**

:   将 SCSI Controller 设为 VirtIO SCSI（注意**不要选 VirtIO SCSI Single**），勾上 Qemu Agent 选项，其他选项都选 Default 即可。

**Disks, CPU, Memory**

:   按需分配，磁盘容量建议控制在 10 GB 以内（仅系统盘，可另加数据盘），其中 Disk 勾选上 Discard，CPU Type 推荐选择 Host。

**Network**

:   按需选择，Model 选 VirtIO，然后取消勾选 Firewall。

!!! info "记得在虚拟机的 Options 里将 Start at boot 设为 Yes"

在 Proxmox VE 上，通过 web 界面创建新虚拟机后，可以使用普通方式安装系统，也可以直接导入发行版提供的虚拟机镜像（需要通过 SSH 登录 Proxmox VE 或 NFS 服务器）。

下面以 Debian 为例，创建一个新虚拟机，然后打开 <https://mirrors.ustc.edu.cn/debian-cdimage/cloud/bullseye/>，点击最新的目录（出于未知原因 latest 链接是坏的），复制 `debian-11-genericcloud-amd64-<date>-<rev>` 的链接（推荐使用 genericcloud 而不是 generic，其预装 `linux-image-cloud-amd64`，相比于“完整版”内核精简掉了大部分物理设备的驱动程序，适用于虚拟机环境），然后登录 Proxmox VE 或 vdp（NFS 服务器），使用以下命令直接下载镜像至虚拟机磁盘：

```shell
# Proxmox VE (ZFS / LVM), use RAW
wget -O /dev/zvol/rpool/data/vm-<id>-disk-0 https://mirrors.ustc.edu.cn/<...>.raw
wget -O /dev/<vg>/<lv> https://mirrors.ustc.edu.cn/<...>.raw

# vdp over NFS, use QCOW2
wget -O /media/vdp/pve/images/<path>.qcow2 https://mirrors.ustc.edu.cn/<...>.qcow2
```

然后在 web 界面指定虚拟机的磁盘（如有需要）。

### Reset password

由于 Debian 提供的 cloud image 默认禁用了 root 用户，需要手动挂载磁盘，编辑磁盘中的 `/etc/shadow` 文件，将第一行的 `root:*:...` 改为 `root::...`（即删掉星号）。**注意不要误改主机的 shadow 文件**。

!!! tip

    此步骤也可以替换为 chroot 进去后使用 `passwd` 修改或清空密码。如果你不够熟悉 shadow 文件的格式，这样做更安全。

对于 ZFS 和 LVM 存储的磁盘，可以直接挂载 `/dev/zvol/<...>` 或 `/dev/<vg>/<lv>`。对于 Qcow2 文件的磁盘，可以参考[这个 Gist][gist] 使用 `qemu-nbd` 工具来挂载。其中 `nbd` 是 Linux 原生的内核模块，可以放心 modprobe。

  [gist]: https://gist.github.com/shamil/62935d9b456a6f9877b5

你也可以在这一步同时修改别的配置文件，例如把 `/etc/apt/sources.list` 换掉等。修改完成后不要忘记 umount。

### Extra configurations for cloud images

The first two or three boots may hang or end up in kernel panic - **this is completely normal**. The cloud image will grow the root partition and filesystem to the virtual disk size. After it's all set, purge everything related to `cloud-init`.

For better console experiences, install and configure `console-setup`, and add `vga=792` to `GRUB_CMDLINE_LINUX` in `/etc/default/grub`. Then run `update-grub` and reboot.

## Configure network

- 增加 hostname.s.ustclug.org 的 DNS 解析。（文件 `db/ustclug/ustclug.intranet`）
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
    - <s>对于 VMware vSphere 的虚拟机：安装 `open-vm-tools`</s>
- 安装 `ssh`

## Configure LDAP and SSH CA

见 [LDAP 服务使用及配置说明](../../infrastructure/ldap.md) 和 [为服务器设置 SSH CA](../../infrastructure/sshca.md#issue-a-server-certificate)
