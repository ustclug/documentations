---
icon: fontawesome/solid/certificate
---

# LUG 服务总览

!!! warning "注意"

    LUG 的主页上还有一份[《网络服务列表》 :octicons-link-external-16:](https://lug.ustc.edu.cn/wiki/lug/services/)，如果有服务状态改变，记得同步更新主页上的列表。

## Mirrors 镜像站

服役中的服务器：

- 主：[mirrors4](mirrors/4/index.md)
    - 主服务器存储绝大部分仓库，对外提供 HTTP(S)、Git 与 Rsync 服务。
        - HTTP(S) 对应 nginx，Rsync 对应 rsync-proxy，两者均支持反向代理（因此可以将仓库放在别的机器上，同时通过 mirrors4 向外提供对应的服务）。
        - 接入了包括教育网等在内的多个 ISP。
    - 状态页面通过 SSH 隧道与 mirrors2 暴露 Yuki 公开的状态查询 API。
- 副：[mirrors2](mirrors/2/index.md)
    - mirrors2 存储较大的存档类仓库、较冷门且空间极大与有需要但是 mirrors4 放不下的仓库。
    - 截至 2025/02 的仓库：centos-vault, mysql-repo, openeuler, percona, trisquel, ubuntu-old-releases

已淘汰的服务器：

- [mirrors3](mirrors/3/index.md)
    - 由于该机器过于老旧，在图书馆老师的建议下，我们已于 2025 年初将其清空并下架。
    - mirrors3 连接的 SAN 的管理口已经损坏，需要定期线下检查磁盘状态。
- [mirrors1](mirrors/1/index.md)

镜像站日志会备份至 mirrorlog 虚拟机上。

## [权威 DNS](../infrastructure/auth-dns.md) {#auth-dns}

!!! abstract "以下内容由 GPT-4 生成"

    User: 向新手运维介绍什么是权威 DNS

    Assistant: 权威 DNS（Authoritative DNS）服务是因特网域名系统（DNS）的一部分，它负责处理关于其负责管理的一组域名的查询。这些 DNS 服务器带有关于他们所负责域的所有必要数据，并从管理该域的人或组织中收到更新。

    比如，如果你在浏览器中输入一个网站地址，你的请求首先发送到递归 DNS 服务器，然后递归服务器查询权威 DNS 服务器来获取对应的 IP 地址。权威服务器就是“权威”资源，能够告诉递归服务器对应的 IP 地址是什么。这个过程被称为 DNS 解析。

    总的来说，权威 DNS 服务器就是存储、管理并响应特定域名信息的“权威”来源。

我们的权威 DNS 服务器提供了与 LUG 有关的域名的相关解析信息，同时也是一个（通过域名）可以概览 LUG 曾经与目前有的服务的地方。

## [LUG FTP](ftp.md)

主服务器：`vdp.s.ustclug.org`，SSH 端口 2222。对外提供 HTTP(S)（文件列表）与 FTP 服务。同时接入 LDAP，每个 LDAP 用户都可以使用 LUG FTP 存储自己的文件。

与此同时，vdp 也承担了使用 NFS 向 PVE 服务器提供一部分存储的任务。

## [LUG GitLab](gitlab.md) {#gitlab}

主服务器：`gitlab.s.ustclug.org`，SSH 端口 2222。

## 主页反代 {#revproxy}

是多个 HTTP 服务的入口。

由于政策和合规性原因，我们对使用主页反代的域名采用了分线路解析的方案，其中绝大部分域名在校外都解析到 [gateway-jp](gateway-jp.md)，在校内解析到 [gateway-nic](gateway-nic.md)。这两台服务器均[接入 tinc 内网](../infrastructure/intranet/index.md)，采用同一套 Nginx 配置，为内网服务器提供 HTTP 反代。

完整列表请在 auth-dns 仓库内寻找 CNAME 到 `gateway.cname.ustclug.org.` 的域名。

一些例外：

- 镜像站、LUG FTP、GitLab 和 PXE 网络启动（它们分别各自独立运行 Nginx）
- GOsa²（运行在 `ldap` 服务器上，并且使用 Apache2，建议别动）
- [Light](light.md)
- [技术文档](documentations.md)、Linux 101 文档的海外版（<https://101.ustclug.org>）和其他指向 `*.cdn.cloudflare.net.` 的域名
- 其他指向 `web-cf.cname.ustclug.org.` 的域名

### LUG 主页 {#homepage}

后端是 docker2 上的 `website` 容器。

见 [:octicons-mark-github-16: ustclug/website](https://github.com/ustclug/website) 仓库的 README。

tky: planet 现在缺乏维护，希望能有人把它搞起来。

### Linux 101

后端是 docker2 上的 `linux101` 容器。

见 [:octicons-mark-github-16: ustclug/Linux101-docs](https://github.com/ustclug/Linux101-docs) 仓库的 README。

### 申请系统 {#getvpn}

一个使用 Flask 编写的 web 应用，部署了两套，分别提供 LUG VPN 和 Light 的申请服务。其中：

- LUG VPN 的申请系统运行在 docker2 上（`lugvpn-web`）；
- Light 的申请系统运行在 swarm 上。

### 各路反向代理 {#proxy}

域名：`*.proxy.ustclug.org`

作为镜像站服务的一部分，gateway-jp/nic 也分别为校外内提供反向代理列表的反向代理服务。

### Qt Guide 和 openSUSE Guide

由 [@winland0704](https://github.com/winland0704) 负责编写内容，我们帮助托管，平时放着不动就行。

后端是 docker2 上的两个容器 `qtguide` 和 `opensuse-guide`。

### 服务运行状态服务器黑板报

TODO: servers 与 status 的合并工作。

## [LUG VPN](vpn.md)

主服务器：`vpnstv.s.ustclug.org`（虚拟机，NIC 机房）

RADIUS 认证服务器：`radius.s.ustclug.org`，同时运行了 FreeRADIUS 和它的 MySQL 数据库。

另有旧的 `vpn.s.ustclug.org` 运行在东图，暂不需要关注。

## Hackergame

相关内容见 hackergame 内部文档。

## [各类 Docker 服务](docker2.md) {#docker2}

Docker2 是专职负责运行容器的机器。

### Adrain

ustcflyer（科大飞跃手册网站）的前身，目前保持运行。

tky: ustcflyer 没有实现给 session 删对应评论的功能，所以 adrain 没有下线。

### [Grafana](../infrastructure/monitor.md)

LUG 的监控站点。

## [LDAP](../infrastructure/ldap.md)

## [Mail](../infrastructure/mail.md)

为服务器、IPMI 等提供的内部邮件服务。

\[WIP\]: 需要补充

## [虚拟化：PVE 与 PBS](../infrastructure/proxmox/pve.md) {#pve}

PVE: 提供虚拟化支持；PBS: PVE 的虚拟机备份。

## [PXE](pxe/index.md)

网络启动服务，负责为全校机器提供插网口即可安装系统的功能，以及为图书馆查询机提供镜像。

## 其他 {#others}

此处所列出的“服务”没有使用我们自己的服务器资源，都托管在外部平台上，仅域名（即 DNS）由我们维护。

### [技术文档](documentations.md) {#documentations}

也就是本文档，运行在 Cloudflare Pages 上。

### GHAuth

<https://ghauth.ustclug.org>

用于双向验证 GitHub 账号与科大学号的服务（类似于 <https://qq.ustc.life>），目前处于闲置，运行在 iBug 的 AWS Lambda 上。

## [已废弃服务](discontinued.md) {#discontinued}
