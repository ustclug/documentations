# Proxmox Virtual Environment (PVE)

LUG 目前服役的 Proxmox VE 主机有：

- pve-5 是 james 在 2021 年底给我们的，用于替换已运行多年的 esxi-5（因此命名为 pve-5）
- esxi-5 是 [2011 年][mirrors-2011]的 mirrors 服务器，于 2016 年退役后改装为 ESXi，现在已替换为 Proxmox VE
    - esxi-5 上面额外加装了 Proxmox Backup Server 用于提供备份功能，详情参见 [Proxmox Backup Server](pbs.md)
    - PVE 的 web 端口为 8006，而 PBS 的端口为 8007，因此在一台主机上同时安装 PVE 和 PBS 互不冲突，访问时需要使用 HTTPS 并指定端口。

        !!! info "PVE 和 PBS 的端口都是固定的，无法更改"

- pve-6 是一台较老的服务器，在改装前运行 ESXi 6.0，因此主机名曾经是 esxi-6。

    !!! question "pve-1 到 pve-4 去哪了？"

        esxi-1 和 esxi-3 已经坏掉很多年了，同批次 5 台机器已经坏掉了 3 台（另外一个是 vm-nfs，esxi-6 不属于该批次）。

        pve-2 和 pve-4 由 esxi-2 和 esxi-4 改装而来，由于过于古老（2007 年），即使没坏，我们也将它们下架处理掉了。

- pve-7 是宋老师给我们的一台 Oracle x86 服务器，原先在西图机房尝试用作 docker3，后来发现没需求+不方便后，经宋老师允许搬到了东图机房用作 PVE，替代了 pve-{2,4} 的功能运行一些虚拟机。

    机器原装内存为 64G（但是有损坏），在图书馆和网络信息中心找了一些旧内存后扩充到了 128G。

这些 PVE 主机配置为一个集群，可以共享一些配置信息并互相迁移虚拟机。特别地，Proxmox VE Authentication Server（Realm 为 pve）的账号在 PVE 主机之间是共享的，并且添加的 PBS 存储后端也是共享的，即大家都可以往相同的 PBS 上备份虚拟机。

另有暂未加入 PVE 集群的机器如下：

- pve-{8,9,10} 是宋老师给我们的三台同批次的 R740xd，是我们目前最新、配置最高的 PVE 主机，具有 Skylake CPU 和多达 80 TB 的 HDD 存储（已组 ZFS pool），但目前我们没有这么多高配虚拟机需要跑。

!!! warning "不同主机之间的 Linux PAM 用户是不相通的"

所有 Proxmox 主机的主机名（hostname）都设为 `<hostname>.vm.ustclug.org`，对应的 IP 地址记录在 DNS 中。

  [mirrors-2011]: https://lug.ustc.edu.cn/news/2011/04/mirrors-ustc-edu-cn-comes/

## 公用配置 {#common}

### root 账户

!!! danger "已废弃的内容"

    ~~为了便于通过 IPMI 等方式维护，我们约定**所有 Proxmox 主机的 root 账户密码保持为空**。若有操作需要使用 root 密码（如创建和加入集群时），请通过 SSH 或 IPMI 登录，临时设置一个 root 密码，并在修改完 PVE / PBS 的配置后将密码删除（`passwd -d`）。PVE / PBS 没有依赖于固定不变的 root 密码才能正常运行的组件，因此这样做对 PVE / PBS 来说是没问题的。~~

### 网络配置 {#networking}

安全起见，PVE / PBS 主机使用 [RFC 1918 段][rfc-1918]的校园网 IP，不连接公网。

- 东图可用的 IP 段为 192.168.93.0/24（网关 93.254）
- 网络信息中心可用的 IP 段为 10.38.95.0/24（网关 95.254）

  [rfc-1918]: https://en.wikipedia.org/wiki/Private_network#Private_IPv4_addresses

Debian 和 Proxmox 的软件更新使用 mirrors.ustc.edu.cn 即可，若有需要访问校外（如 GitHub 等），请写 hosts 并配置路由，以 GitHub 为例：

```shell
echo "20.205.243.166 github.com" >> /etc/hosts
ip route replace 20.205.243.166 via (?) dev (?)
```

其中 `via` 选择 gateway-el 或 gateway-nic 的内网地址，`dev` 选择桥接内网的 vmbr（见下）。

### 虚拟机网桥 {#vmbr}

Proxmox VE 要求为虚拟机接入的网桥必须命名为 `vmbrN`，其中 N 是 0-4094 之间的整数。方便起见，我们在两个机房分别统一 vmbr 的编号：

| 编号 | 东图 | 网络中心 |
| :--: | :--- | :------- |
| vmbr0 | 校园网（教育网） | 校园网（教育网） |
| vmbr1 | 内网 | 内网 |
| vmbr2 | 电信+移动 | 电信 |
| vmbr3 | - | 联通 |
| vmbr4 | - | 移动 |
| vmbr5 | - | 特殊用途 |
| vmbr10 | 备用 | - |

### 防火墙 {#pve-firewall}

我们不使用 Proxmox 自带的防火墙功能，但 pve-firewall 仍然会尝试部署或恢复防火墙设置，因此需要禁用相关设置及服务：

```ini title="/etc/pve/nodes/$(hostname -s)/host.fw"
[OPTIONS]
enable: 0
```

```shell
systemctl stop pve-firewall.service
systemctl disable pve-firewall.service
systemctl mask pve-firewall.service
```

**可选内容**：同时安装 `iptables-persistent` 软件包，并利用 iptables 将 443 端口转发到 8006 端口方便使用。

```shell
update-alternatives --set iptables /usr/sbin/iptables-nft
update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
```

```shell title="/etc/iptables/rules.v4"
*nat
PREROUTING ACCEPT [0:0]
INPUT ACCEPT [0:0]
OUTPUT ACCEPT [0:0]
POSTROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 443 -m addrtype --dst-type LOCAL -j REDIRECT --to-ports 8006
COMMIT
```

删掉 `rules.v6` 文件，然后运行 `systemctl restart netfilter-persistent.service` 载入 iptables 规则。

### NTP 时间

Proxmox 默认使用 chrony 软件和 Debian 提供的 NTP pool，这些服务器都在校外，使用校园网 IP 无法连通，需要改成校园网的 NTP 服务器：

```shell title="/etc/chrony/chrony.conf"
# Use Debian vendor zone.
#pool 2.debian.pool.ntp.org iburst
server time.ustc.edu.cn iburst
```

然后运行 `systemctl restart chrony.service` 重启服务。

### SSL 证书

参见 [SSL 证书](../ssl.md)，正好 vdp 上面运行了 LUG FTP 而因此配置了证书的自动更新，利用 vdp 提供的 NFS 服务，我们在 vdp 上的证书更新脚本中添加了将 vm 证书复制到 NFS 目录的功能，然后由 pve-6 部署到各个主机上。

下面是 pve-6 上的脚本：

```sh title="/etc/cron.daily/sync-cert"
#!/bin/bash -e

SRC="/etc/pve/nodes/$(hostname -s)"
DSTROOT="/etc/pve/nodes"
CERTSRC="/mnt/nfs-el/cert"

cp -u "$CERTSRC/privkey.pem" "$SRC/pveproxy-ssl.key"
cp -u "$CERTSRC/fullchain.pem" "$SRC/pveproxy-ssl.pem"
systemctl reload pveproxy.service

for DST in "$DSTROOT"/*; do
  [ "$DST" = "$SRC" ] && continue
  node="$(basename "$DST")"
  cp "$SRC/pveproxy-ssl.key" "$SRC/pveproxy-ssl.pem" "$DST/"
  ssh "$node" 'systemctl reload pveproxy.service' &
done
wait
```

由于 PVE 和 PBS 的数据不互通，因此 esxi-5 上的相同位置有**另一个**脚本为 PBS 部署证书：

```sh title="/etc/cron.daily/sync-cert"
#!/bin/bash

SRC="/etc/pve/nodes/$(hostname -s)"
DST="/etc/proxmox-backup"

if ! cmp -s "$SRC/pveproxy-ssl.pem" "$DST/proxy.pem"; then
  cp "$SRC/pveproxy-ssl.key" "$DST/proxy.key"
  cp "$SRC/pveproxy-ssl.pem" "$DST/proxy.pem"
  systemctl reload proxmox-backup-proxy.service
fi
exit 0

# Unreachable code, leaving here for reference
if command -v openssl 2>/dev/null; then
  FP="$(openssl x509 -noout -fingerprint -sha256 -inform pem -in "$DST/proxy.pem")"
  FP="${FP##*=}"
  pvesm set esxi-5-data --finerprint "$FP"
  pvesm set esxi-5-vdp2 --finerprint "$FP"
fi
```

### VirtIO FS {#virtiofs}

对于 mirrorlog 等重存储型的虚拟机，我们尝试把大量的数据文件放在 host 上，避免 ZFS（Zvol）和 ext4 的两层开销（以及在 ZFS 上也可以使用更大的 recordsize 获得更好的 I/O 体验和更低的 RAID-Z overhead），然后使用 virtiofs 供虚拟机访问。

Virtiofs 的配置过程主要参考了 <https://forum.proxmox.com/threads/virtiofsd-in-pve-8-0-x.130531/>：

首先配置虚拟机：

```yaml title="/etc/pve/qemu-server/230.conf"
args: -chardev socket,id=virtfs0,path=/run/virtiofsd-230.sock -device vhost-user-fs-pci,queue-size=1024,chardev=virtfs0,tag=mirrorlog -object memory-backend-file,id=mem,size=8192M,mem-path=/dev/shm,share=on -numa node,memdev=mem
```

其中 `path=` 指向 virtiofsd 的 socket 文件，`tag=` 可以任意指定，用于区分多个 virtiofsd 实例（对应虚拟机内的 mount source），`size=` 是共享内存大小。

然后安装 virtiofsd，直接 `apt install virtiofsd` 即可（PVE 打包了 Rust 重写的新版 virtiofsd）。

接下来需要配置 virtiofsd 在虚拟机开机前启动。注意一个 virtiofsd 只能供一个虚拟机访问一个主机上的目录，因此需要使用 PVE 的 hook script 来启动 virtiofsd。这个 hook script 放在 `/var/lib/vz` 目录下，接收两个命令行参数（VMID 和启动阶段）：

```shell title="/var/lib/vz/snippets/virtiofsd.sh"
--8<-- "pve/virtiofsd.sh"
```

相比于 Proxmox 论坛里的教程贴，这里最重要的修改是给 `systemd-run` 加上了 `--collect` 参数，这样 virtiofsd 退出时无论是否 failed，systemd 都会清理掉这个临时的 service unit。

然后通过命令行配置使用：

```shell
qm set 230 --hookscript local:snippets/virtiofsd.sh
```

然后将虚拟机关机，通过 `qm start` 或者 web 界面启动，即可在虚拟机内挂载 virtiofsd 提供的目录。

```shell
# Manual
mount -t virtiofs mirrorlog /mnt/mirrorlog

# via /etc/fstab
mirrorlog /mnt/mirrorlog virtiofs defaults 0 0
```

## pve-5

pve-5 位于网络中心，配置为 2× ~~Xeon E5-2603 v4 (Broadwell 6C6T, 1.70 GHz, no HT, no Turbo Boost)~~ Xeon E5-2667 v4 (Broadwell 8C16T, 3.20 GHz, Max 3.60 GHz)，256 GB 内存和一大堆 SSD（2× 三星 240 GB SATA + 10x Intel DC S4500 1.92 TB SATA）。我们将两块 240 GB 的盘组成一个 LVM VG，分配 16 GB 的 rootfs（LVM mirror）和 8 GB 的 swap，其余空间给一个 thinpool。十块 1.92 TB 的盘组成一个 RAIDZ2 的 zpool，用于存储虚拟机等数据。

其连接的单根 10 Gbps 的光纤，桥接出 `vmbr0` 至 `vmbr4` 等网桥（线路定义[见上](#vmbr)）。其中无头网桥用于从 [gateway-nic](../../services/gateway-nic.md) 桥接 Tinc。

!!! danger "硬盘控制器不要使用 VirtIO SCSI Single 或 LSI 开头的选项"

    可能由于 ZFS 模块的 bug 或者内存条故障，使用这些模式在虚拟机重启时会导致整个 Proxmox VE 主机卡住而不得不重启。请使用 VirtIO SCSI（不带 Single）。同样原因创建虚拟机硬盘时也不要勾选 iothread。

主机使用 ZFS（Zvol）作为虚拟机的虚拟硬盘，在虚拟机中启用 `fstrim.timer`（systemd 的 fstrim 定时任务，由 `util-linux` 提供）可以定期腾出不用的空间，帮助 ZFS 更好地规划空间。启用 fstrim 的虚拟硬盘需要在 PVE 上启用 `discard` 选项，否则 fstrim 不起作用。该特性是由于 ZFS 是 CoW 的，与 ZFS 底层使用 SSD 没有关联。

## esxi-5

esxi-5 也位于网络中心，配置为 2× Xeon E5620（Westmere-EP 4C8T, 2.40\~2.66 GHz），48 GB 内存，两块 240 GB SATA SSD 和一些不知道坏了多少的 1 TB 和 2 TB HDD（见下）。由于机身自带的 RAID 卡不支持硬盘直通（JBOD 模式），因此我们将两块 SSD 分别做成单盘“阵列”然后在系统里使用 LVM（LVM 规格与 pve-5 相同）

顾名思义本机器曾经运行的是 VMware ESXi，在 2022 年 1 月重装为 Proxmox VE 7.1，<s>因为咱们都是纠结怪所以决定不改名</s>，还叫 esxi-5。考虑到该机器配置了多个硬盘阵列，且阵列的可用容量比 pve-5 的硬盘的原始容量还大，我们在上面加装 Proxmox Backup Server 软件，主要用作虚拟机备份，替代原先运行在 ESXi 上的 vSphereDataProtection 虚拟机。

### 网络

网络配置与 pve-5 相似，其上有两个千兆网卡 enp3s0 和 enp4s0。enp3s0 连接网络中心的交换机，桥接不同的 VLAN 网络给虚拟机，并且各 vmbrX 的数字和端口与 pve-5 一致；而 enp4s0 连接一个外部阵列（vdp2），使用 iSCSI 访问该阵列。

由于我们只有一个 gateway-nic，而 pve-5 和 esxi-5 两个主机都依赖 gw-nic 桥接的 tinc 来接入内网，因此我们在 pve-5 和 esxi-5 之间拉了一条 GRETAP 隧道，并在两个主机上分别将 VTEP 桥接到 vmbr1。

参考配置：

```sh title="pve-5:/etc/network/interfaces"
auto gretap0esxi-5
iface gretap0esxi-5 inet manual
    pre-up ip link add name $IFACE mtu $IF_MTU type gretap local 10.38.95.115 remote 10.38.95.111
    post-down ip link delete $IFACE
    mtu 1500

auto vmbr1
iface vmbr1 inet static
    address 10.254.0.240/21
    bridge-ports gretap0esxi-5
    bridge-stp off
    bridge-fd 0
```

esxi-5 这端的配置则将对应的 iface 名称和 IP 地址等全部对换即可。

!!! note "MTU 问题"

    2022 年 2 月处理内网 tinc ARP 问题时发现 esxi-5 和 pve-5 的 vmbr1 MTU 都被设置成了 1462（GRETAP 的默认 MTU）。我们不确定 MTU 问题与 tinc 是否相关，但保险起见我们还是将该 GRETAP 界面的 MTU 设置成了 1500（GRE 具有分片功能）。

    ```diff
    -pre-up ip link add name $IFACE type gretap local 10.38.95.115 remote 10.38.95.111
    +pre-up ip link add name $IFACE mtu $IF_MTU type gretap local 10.38.95.115 remote 10.38.95.111
     post-down ip link delete $IFACE
    +mtu 1500
    ```

### iSCSI

设置 iSCSI 开机自动登录：

```shell
iscsiadm -m node -T iqn.2002-10.com.infortrend:raid.sn8223150.001 -p 192.168.10.1:3260 -o update -n node.startup -v automatic
iscsiadm -m node -T iqn.2002-10.com.infortrend:raid.sn8223150.001 -p 192.168.10.1:3260 -o update -n node.conn[0].startup -v automatic
```

参考链接：<https://library.netapp.com/ecmdocs/ECMP1654943/html/GUID-8EC685B4-8CB6-40D8-A8D5-031A3899BCDC.html>

??? warning "过时信息"

    由于我们没有研究清楚 open-iscsi 的开机自动挂载机制，因此我们选择直接 override 对应的 service 来完成这个任务：

    ```ini title="$ systemctl edit open-iscsi.service"
    [Service]
    ExecStart=
    ExecStart=/sbin/iscsiadm -d8 -m node -T iqn.2002-10.com.infortrend:raid.sn8223150.001 -p 192.168.10.1:3260 --login
    ExecStart=/lib/open-iscsi/activate-storage.sh
    ```

若 iSCSI 连接成功，应该可以在系统中看到一个新的硬盘，容量为 14.55 TiB，型号显示为 RS-3116I-S42-6。

### rootfs 备份 {#rootfs-backup}

尽管 esxi-5 的 rootfs 也使用了 LVM mirror 在两块 SSD 上镜像，但是我们不太信任这块 RAID 卡，因此我们将 esxi-5 的 rootfs 每天备份到 vdp2 上。为了避免在 vdp2 掉线的时候乱“备份”，我们使用一个 systemd 服务，设置了 [`RequiresMountsFor` 依赖][systemd-requiresmountsfor]：

```ini title="/etc/systemd/system/rootfs-backup.service"
[Unit]
Description=Backup rootfs to vdp2
RequiresMountsFor=/mnt/vdp2

[Service]
Type=oneshot
ExecStart=/usr/bin/rsync -aHAXx --delete / /mnt/vdp2/rootfs/
```

```text title="crontab"
21 4 * * * systemctl start rootfs-backup.service
```

  [systemd-requiresmountsfor]: https://www.freedesktop.org/software/systemd/man/systemd.unit.html#RequiresMountsFor=

### 其他记录 {#esxi-5-others}

esxi-5 于 2021/8 发现自带阵列有两块坏盘，在更换后发现 storage "root"（存放 vcenter 虚拟机，组建 RAID 1 后大小 1.8 TB）无法正常 rebuild，并且 vcenter 虚拟机的 vmdk 文件有 4 个出现 I/O error。此后 vcenter 虚拟机已经迁移到 storage "data" (RAID10, 7.2 TB) 并正常工作。

## pve-6

pve-6 位于东图，是一台 HP DL380G6，配置为 2× Xeon E5620 (Westmere 4C8T, 2.50 GHz), 72 GB 内存和l两块 300 GB 的 SAS 硬盘。曾经叫做 esxi-6，在 2022 年 1 月统一更换为 Proxmox VE。

机器有两个网卡，共有 4 个 1 Gbps 的接口，其中 3 个都接在 VLAN 交换机上（另一个不知道接了啥），通过 VLAN 同时连接图书馆的两个网段以及经由 gateway-el 桥接的内网，以及连接 vdp 挂载 NFS。

!!! note "HP Smart Array"

    HP 的自带 RAID 卡管理软件可以在 <http://downloads.linux.hpe.com/SDR/repo/mcp/Debian/pool/non-free/> 下载，安装 `ssacli` 软件包。相关使用方法可以参考 <https://sleeplessbeastie.eu/2017/03/06/how-to-use-hp-command-line-array-configuration-utility/>。

## 工作记录 {#records}

### 2021-12-31 迁移 docker2 {#migrate-docker2}

docker2 原先使用 QEMU 直接运行在 mirrors2 上，下层存储为 ZFS Zvol（`pool0/qemu/docker2`），由于 ZFS 调参不当使其占用了 3 倍的硬盘空间（见[这个 Reddit 贴子][1]），加上 mirrors2 本身对外提供 Rsync 服务，硬盘负载极高，所以长期以来 docker2 的 I/O 性能*十分*低下。正好借这次全闪的新宿主机将其迁移过去。

迁移时需要保证完整性的主要内容就是虚拟机内的业务，因此需要在主机间传输的内容就是虚拟磁盘，其他配置（CPU、内存、网卡等）都可以直接在新平台上创建新虚拟机时修改。原本我们打算使用 rsync 或者 dd 的方式复制磁盘，但是考虑到两边都是 ZFS，使用 `zfs send` 是一个更好的方案。

我们在 pve-5 上运行 `nc -l -p 9999 </dev/null | pv | zfs recv rpool/data/docker2`，然后在 mirrors2 上对 zvol 先打个快照，运行 `zfs send pool0/qemu/docker2@20211230 > /dev/tcp/{pve-5}/9999` 将快照内容发送到 pve-5 上（300 GiB 的数据花费了 16 小时），然后再将 docker2 关机并增量传输，`zfs send -i @20211230 pool0/qemu/docker2 > /dev/tcp/{pve-5}/9999`（增量传输只发送了 10 GB 数据）。同时我们在 Proxmox 的 web 界面上创建一个新虚拟机，配好 CPU 内存网卡等，分配 300 GiB 的硬盘。

由于 zfs send 是原样发送的，因此接收到的 zvol 硬盘占用量仍然有 712 GB。Proxmox 新建的 zvol 参数就比较合理（`volblocksize=16k`），没有严重放大的问题，因此我们再将接收到的 zvol 给 dd 进新虚拟机的 zvol 而不是直接使用。dd 结果约 345 GiB（十分合理），开机进系统运行 fstrim 之后占用量约为 240 GiB（更加合理了）。

迁移过程没有遇到任何坑，仅有的注意事项就是 zvol 调参需要重新 dd 而不能直接改，以及创建网卡的顺序（会影响虚拟机内部 eth0 和 eth1 的顺序，除非虚拟机内部使用 udev persistent net 方式根据 MAC 地址将网卡改名）。

  [1]: https://www.reddit.com/r/zfs/comments/i2ypyy/til_zfs_ashift12_raidz2_zvol_with_4k_blocksize/

### esxi-5 的 syslog 一直出现 zfs error: cannot open 'rpool': no such pool

这是因为 esxi-5 上面根本就没有使用 ZFS，而加入 pve-5 的集群时虚拟机的存储信息（`/etc/pve/storage.cfg`）也从 pve-5 同步过来合并了，因此 esxi-5 在根据 pve-5 的配置尝试启用 zfs 存储。

**解决办法**：由于 `/etc/pve` 下大多数内容在集群间是同步的，打开 `storage.cfg`，在 `zfspool: local-zfs` 下面加入一行，缩进一个 Tab 并加上 `nodes pve-5`，表示这个 storage 只在 pve-5 上使用。

## 备注：我们为什么从 VMware vSphere 迁移到 Proxmox VE {#why-proxmox}

我们原先跑着一个集群的 ESXi 6.0，并且还在 esxi-5 上运行着 vCenter 和 vSphereDataProtection，但是我们决定迁移到 Proxmox VE 上。主要原因有：

- ESXi 6.0 已 EOL，而能够原地升级的 ESXi 6.5 和 6.7 也即将（2022 年）EOL，并且 ESXi 7 无法原地升级 / 需要购买许可（ESXi 6 在一定规模以内可以免费使用）。
- vCenter 的界面还在用 Flash，很快我们就没法用了（现代的浏览器已经淘汰了 Flash）。
- 为了备份业务虚拟机，我们必须装 vDP 这一大坨厚重的东西（它自己就占了 4C 8G + 将近 1 TB 的硬盘），而且 vDP 也即将与 ESXi 6.x 一同 EOL。
    - 而且 vDP 还是很难用（
- ESXi 是一套私有的系统，不方便使用各种成熟的工具（如 `smartctl`）和不得不用的其他工具（如戴尔阵列卡的 `MegaCli`），也难以接入我们现有的 InfluxDB + Telegraf 监控系统，甚至有些东西还需要我们自己编译（如 `ipmitool`），编译环境又很难整。

相比之下：
- Proxmox VE 是基于 Debian 的，所有 Linux 软件和工具都可以直接使用，即使在最坏情况下我们也可以把它当作一个普通的 Debian 服务器来管理。
    - 配置 RAID 和监控等功能更加方便，不需要单独为 ESXi 整一套方案，直接把我们已经在 Debian 上配好的方案搬过来就行。
- 利用 Linux 下成熟的 QEMU/KVM 虚拟化方案，与 Linux 虚拟机无缝集成，各种诸如 VirtIO 等技术都可以直接使用。
- 比 ESXi 更轻量，所有功能都可以在一个主机上完成，不需要额外开个虚拟机跑厚重的 vCenter。即使有 web 界面不方便/无法完成的任务，我们也可以 SSH 处理。
- Host 上可以用 ZFS 等高端存储方案。
- 结合 Proxmox Backup Server，可以实现自动备份虚拟机，而且 PBS 与 Linux 相关功能集成也更好，比如可以直接查看备份中的文件内容等。
- 与 Debian 发行周期一致，可以像 Debian 一样长期维护和版本升级。
- 最重要的是，它是全套开源软件（AGPLv3），必要的时候我们可以看代码自己进行需要的 patch。
