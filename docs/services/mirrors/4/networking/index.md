# Networking on mirrors4

<s>出于好用的考虑</s>，mirrors4 上的网络使用 systemd-networkd 配置。作为入门，下面是两个参考链接：

- [Systemd-networkd - Arch Wiki](https://wiki.archlinux.org/index.php/Systemd-networkd)
- [SystemdNetworkd - Debian Wiki](https://wiki.debian.org/SystemdNetworkd)

Debian 默认用的是 ifupdown，把它直接卸掉就行了。全部配置完毕之后需要 `systemctl enable systemd-networkd.service` 并且 start 一下（或者直接重启）。

!!! tip "/etc/systemd/network 目录下有个 Git 仓库，方便保存与恢复"

## Bond

Bond 用于将多个网卡聚合当作一个使用。

### 子网卡

向 `/etc/systemd/network/ens41f0.network` 写入如下内容：

```ini
[Match]
Name=ens41f0

[Network]
Bond=bond1

[Link]
RequiredForOnline=no
```

即可将其设置为 bond1 的一个子网卡。用同样方式把 ens41f1 也设为子网卡。

!!! info "一个小坑"

    systemd-networkd 有一个默认的 bond0 聚合网卡，模式永远是 round-robin，而且尝试设置这个网卡很容易出问题，所以我们避开这个名字，用 bond1。

### bond1 聚合网卡

写入 `/etc/systemd/network/bond1.netdev`：

```ini
[NetDev]
Name=bond1
Kind=bond

[Bond]
Mode=balance-tlb
MIIMonitorSec=1
```

关于 bond 模式（`balance-tlb` vs `balance-alb`），参考[这个 Server Fault 上的回答](https://serverfault.com/a/739550/450575)。

然后创建 VLAN，写入 `/etc/systemd/network/bond1.network`：

```ini
[Match]
Name=bond1

[Network]
DHCP=no
VLAN=cernet
VLAN=telecom
VLAN=mobile
VLAN=unicom
```

## VLAN

NIC 机房有 4 个 VLAN，分别是

- ID 95，教育网 202.38.95.0/25
- ID 10，电信 202.141.160.0/25
- ID 400，移动 202.141.176.0/25
- ID 11，联通 218.104.71.96/28, 218.104.71.160/28

注意这几个网段都没有 DHCP，只有教育网 VLAN 有 IPv6 RA。

下面以教育网 VLAN 为例。

因为 VLAN 在物理上属于一个网卡，因此向对应网卡的 `.network` 文件的 `[Network]` 段追加一行（见上面一节 `bond1.network` 文件）：

```ini
VLAN=cernet
```

创建 VLAN 界面，创建 `cernet.netdev` 并写入

```ini
[NetDev]
Name=cernet
Kind=vlan

[VLAN]
Id=95
```

然后就可以指定 IP 地址等具体信息了，创建一个名字相同，后缀换成 `.network` 的文件并写入

```ini
[Match]
Name=cernet

[Network]
DHCP=no
Address=202.38.95.110/25
#Gateway=202.38.95.126
Address=2001:da8:d800:95::110/64
#Gateway=2001:da8:d800:95::1
IPv6AcceptRA=false
```

保存后重启 `systemd-networkd.service` 就可以看到效果了。

!!! question "为什么 Gateway 被注释掉了"

    根据 [systemd 官方文档](https://www.freedesktop.org/software/systemd/man/systemd.network.html#Gateway=)，在 `[Network]` 一节出现的 `Gateway=` 等价于一个单独的、仅包含一行 `Gateway=` 的 `[Route]` 节。由于我们需要深度[自定义路由](route.md)，这里不方便采用这个过于简洁的设定（例如各种默认值 `Table=main` 等）。

## Docker network

针对个别不支持 bind address 的同步工具，我们通过将其放入特定的 docker network 来实现选择线路的功能。

```shell title="创建命令"
docker network create --driver=bridge --subnet=172.17.4.1/24 -o "com.docker.network.bridge.name=dockerC" cernet
docker network create --driver=bridge --subnet=172.17.5.1/24 -o "com.docker.network.bridge.name=dockerT" telecom
docker network create --driver=bridge --subnet=172.17.6.1/24 -o "com.docker.network.bridge.name=dockerM" mobile
docker network create --driver=bridge --subnet=172.17.7.1/24 -o "com.docker.network.bridge.name=dockerU" unicom
docker network create --driver=bridge --ipv6 --subnet=172.17.8.1/24 --subnet=fd00:6::/64 -o "com.docker.network.bridge.name=dockerC6" cernet6
docker network create --driver=bridge --subnet=172.17.9.1/24 -o "com.docker.network.bridge.name=dockerV" lugvpn
```

然后使用 systemd-networkd 对创建好的 docker network 网段配置规则路由。

```ini title="/etc/systemd/network/cernet.network"
# Docker Cernet
[RoutingPolicyRule]
From=172.17.4.0/24
Table=1011
Priority=5

[RoutingPolicyRule]
From=172.17.8.0/24
Table=1011
Priority=5
```

其他几个文件类似，只需要修改网段和 Table 即可。
