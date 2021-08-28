# Create new server in LUGi

## Create VM on vCenter

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

## Install OS

Notes:

将网络改为 cernet，以便用 DHCP 获得 IP 地址，用 PXE 安装系统。

几个关键配置：

- hostname: 主机名，如 vpnhc
- domain name: 搜索域，一般设为 s.ustclug.org
- 用户设置：先设置一个临时用户（尽量不与之后要配置的 ldap 账号冲突），用于初始登陆配置，之后删除
- 磁盘设置：使用整个硬盘，只留一个主分区，不留 swap 等分区，方便扩容

## Configure network

- 增加 hostname.s.ustclug.org 的 DNS 解析。（ustclug.intranet）
- 在 vCenter 中更改网络为 ustclug （如果不需要源 MAC 地址检查，选 ustclug-bridge）
- 在虚拟机中重启网络接口，改为静态 IP，并更改网关 （10.254.0.254）
  - ifdown
  - edit interface coonfig files
  - ifup
- 更改虚拟机的 DNS 和 domain/search：
  - DNS:
    - neat-dns (10.254.0.253)
    - dns backup (202.38.93.94)
  - domain/search:
    - s.ustclug.org

## Install tools

- 根据需要换源，加入安全更新源等
- 安装 open-vm tools
- 安装 openssh

## Configure LDAP and SSH CA

见 [LDAP 服务使用及配置说明](../../infrastructure/ldap.md) 和 [为服务器设置 SSH CA](../../infrastructure/sshca/#issue-a-server-certificate)
