---
icon: fontawesome/solid/certificate
---

# LUG 服务总览

!!! warning "注意"

    LUG 的主页上还有一份[《网络服务列表》 :octicons-link-external-16:](https://lug.ustc.edu.cn/wiki/lug/services/)，如果有服务状态改变，记得同步更新主页上的列表。

## Mirrors 镜像站

服务器：

- 主：[mirrors4](mirrors/4/index.md)
- 副：[mirrors3](mirrors/3/index.md)
- 副：[mirrors2](mirrors/2/index.md)
- 已废弃：[mirrors1](mirrors/1/index.md)

## 权威 DNS {#auth-dns}

见 [auth-dns](../infrastructure/auth-dns.md)。

## LUG FTP

主服务器：`vdp.s.ustclug.org`，SSH 端口 2222。

## LUG GitLab {#gitlab}

主服务器：`gitlab.s.ustclug.org`，SSH 端口 2222。

## 主页反代 {#revproxy}

是多个 HTTP 服务的入口。

由于政策和合规性原因，我们对使用主页反代的域名采用了分线路解析的方案，其中绝大部分域名在校外都解析到 [gateway-jp](gatewa-jp.md)，在校内解析到 [gateway-nic](gatewa-nic.md)。这两台服务器均[接入 tinc 内网](../infrastructure/intranet/index.md)，采用同一套 Nginx 配置，为内网服务器提供 HTTP 反代。

完整列表请在 auth-dns 仓库内寻找 CNAME 到 `gateway.cname.ustclug.org.` 的域名。

一些例外：

- 镜像站、LUG FTP、GitLab 和 PXE 网络启动（它们分别各自独立运行 Nginx）
- GOsa²（运行在 `ldap` 服务器上，并且使用 Apache2，建议别动）
- [Light](light.md)
- [技术文档](documentations.md)、Linux 101 文档的海外版（<https://101.ustclug.org>）和其他指向 `*.cdn.cloudflare.net.` 的域名
- 其他指向 `web-cf.cname.ustclug.org.` 的域名

### LUG 主页 {#homepage}

见 [:octicons-mark-github-16: ustclug/website](https://github.com/ustclug/website) 仓库的 README。

### Linux 101

见 [:octicons-mark-github-16: ustclug/Linux101-docs](https://github.com/ustclug/Linux101-docs) 仓库的 README。

### LUG VPN 申请系统 {#getvpn}

### 各路反向代理 {#proxy}

域名：`*.proxy.ustclug.org`

### Qt Guide 和 openSUSE Guide

放着不动就行。

## LUG VPN

主服务器：`vpnstv.s.ustclug.org`（虚拟机，NIC 机房）

RADIUS 认证服务器：`radius.s.ustclug.org`，同时运行了 FreeRADIUS 和它的 MySQL 数据库。

另有旧的 `vpn.s.ustclug.org` 运行在东图，暂不需要关注。

## 各类 Docker 服务 {#docker2}

## LDAP

见 [ldap](../infrastructure/ldap.md)。

## 已废弃服务 {#discontinued}

见 [discontinued](discontinued.md)。
