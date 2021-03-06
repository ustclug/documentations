# 限制策略

由于 mirrors 属于 I/O、网络密集型服务，在部分的负载场景下极易出现 I/O 或网络过载。限制策略主要是为了减弱以下几类请求对 mirrors 整体服务质量的影响：

1. 突发性的高并发请求
2. 爬虫类流量
3. 不合理的请求（如：极少数用户的大量请求）

## 白名单

一般而言，科大校内的地址位于限制规则的白名单中，不受到限制策略的影响。如果没有特殊说明，科大地址默认不受限制。

白名单位于：

* `/usr/local/network_config/ipset.list`
* `/etc/nginx/conf.d/geo-ustcnet.conf`

## 防火墙级别限制

防火墙 (iptables) 目前只负责限制单 IP 的并发链接数。这是为了防止同时涌入大量并发连接，导致后端应用耗费大量 CPU 和 I/O 资源处理这些不合常理的请求。

| 序号 |       端口        |    服务    | 最大连接数 | IPv4 CIDR | IPv6 CIDR |
| :--: | :---------------: | :--------: | :--------: | :-------: | :-------: |
|  1   |      80,443       | HTTP/HTTPS |     12     |    29     |    64     |
|  2   | 20,21,50100:50200 |    FTP     |     4\*    |    32     |    64     |
|  3   |        873        |   Rsync    |     5\*    |    32     |    64     |
|  4   |       9418        |    Git     |     10     |    32     |    64     |

!!! warning "注意事项"

    连接数限制仅限制瞬时并发（connlimit）。

请注意，同组内的连接共享连接数配额。如：

- 10.0.0.1 与 10.0.0.2 共享 HTTP 限额
- 1.1.1.1 发起的 HTTP 与 HTTPS 连接共享 12 个连接数限额

超过配额的连接会返回 TCP Reset。

\* FTP 服务已停止提供，Rsync 仅从 mirrors2 提供，mirrors4 上的 Rsync 端口限制只能从 mirrors2 上访问。

## 应用级别限制

此类限制规则位于应用程序内。由于在用户态程序中实现，因此更加灵活。

### Nginx LUA组件

代码位于 [/etc/nginx/lua/access.lua](https://git.lug.ustc.edu.cn/mirrors/nginx-config/blob/master/lua/access.lua)

目前使用了 Nginx 的 lua 语言扩展实现对请求的限制。主要有以下三类限制方式：

1. 按连接数限制（即：并发请求数）
2. 按请求速率限制
3. 按累计请求数限制（周期性重置计数器）

目前，镜像站配置了以下几种功能的限制器：

1. 全局请求速率限制器：对所有请求，限制单IP的请求速率。
2. 全局请求数限制器：对于所有请求，**检测**单IP在一天内的累计请求数。超过阈值后，降低该IP的*全局请求速率限制器*的阈值。
3. HEAD请求数限制器：对于 HTTP Method == HEAD 类型的请求，**检测**单 IP 在一天内的累计请求数。超过阈值后，开启*HEAD请求速率限制器*。
4. HEAD请求速率限制器：对于 HTTP Method == HEAD 类型的请求，限制单 IP 的请求速率。**该限制器默认关闭。**
5. 断点续传请求速率限制器：对于断点续传类型的请求，限制单 IP 的请求速率。
6. 断点续传连接数限制器：对于断点续传类型的请求，限制单 IP **单 URI** 的连接数。
7. 目录请求速率限制器：对于列目录类型的请求，限制单 IP 请求速率。
8. 文件请求速率限制器：对于非目录类型的请求，限制**单文件**请求速率。即：所有用户之间共享同一个配额。
   * 例外：apt/yum 仓库的索引文件不受限制。
   * 案例：曾遇到过攻击者分布式请求同一个大文件，导致 IO、网络同时过载。 基于IP地址的限制措施对于源地址池很大的攻击往往没有效果，限制单文件的请求速率能够有效缓解这类攻击。
9. 文件连接数限制器：限制单文件的同时连接数。即：所有用户之间共享同一个配额。 这是下载速度限制器的依赖，详见下一小节。

具体参数参考下表：

|       限制器名称       | 阈值单位 | 阈值  | 突发量 | 计数器重置周期 |               动作               |
| :--------------------: | :------: | :---: | :----: | :------------: | :------------------------------: |
|   全局请求速率限制器   |  次/秒   |  40   |  100   |       /        |           返回429错误            |
|    全局请求数限制器    |    次    | 15000 |   /    |      1天       | 设置全局请求速率限制器阈值为 0.2 |
|    HEAD请求数限制器    |    次    |  300  |   /    |      1天       |      开启HEAD请求速率限制器      |
|   HEAD请求速率限制器   |  次/秒   | 0.05  |   5    |       /        |           返回429错误            |
| 断点续传请求速率限制器 |  次/秒   |   1   |   10   |       /        |           返回429错误            |
|  断点续传连接数限制器  |    条    |   1   |   0    |       /        |           返回429错误            |
|   目录请求速率限制器   |  次/秒   |  0.5  |   10   |       /        |           返回429错误            |
|   文件请求速率限制器   |  次/秒   |   5   |   25   |       /        |           返回429错误            |
|    文件连接数限制器    |    条    |  100  |   0    |       /        |           返回429错误            |

到达阈值后会发生什么？

* 当请求速率超过阈值，但未超过突发量时，限制器会计算出一个满足阈值条件的最小等待时间。连接会被丢入等待池，到达等待时间后再被处理。
* 当请求速率超过阈值，且超过突发请求量时，将会在等待 5 秒后返回 HTTP 429 错误。

限制器之间相互独立，当被触发的所有限制器产生不一致的等待时间时，应用最长的等待时间。

### 大文件下载速度限制

代码位于 [/etc/nginx/lua/header_filter.lua](https://git.lug.ustc.edu.cn/mirrors/nginx-config/blob/master/lua/header_filter.lua)

针对单一大文件，同时收到来自大量请求的情形，限制总带宽为 1Gbps，以避免单一文件流量占满总带宽。

!!! warning "注意事项"

    如果有多个文件面临高压力访问，总带宽依然可能被占满

具体做法为，设置下载速度阈值 = 1Gbps / (该文件的同时连接数+1)

当下载的文件无穷大时，将出现最差情形，即用户被分配到的下载速率服从类调和级数，函数发散。实际情况下，早期用户下载完成后连接释放，最终带宽将收敛到 1Gbps。

注：大文件定义为 HTTP Content-Length > 32M 的文件

### NGINX JS 挑战

代码位于 [/etc/nginx/sites-available/iso.mirrors.ustc.edu.cn](https://git.lug.ustc.edu.cn/mirrors/nginx-config/blob/master/sites-available/iso.mirrors.ustc.edu.cn)

为了抵抗“迅雷攻击”。对于特定类型的文件，开启了JS挑战。 如果客户端 User-Agent 为 Mozilla（即浏览器），则发送一段包含 JS 脚本的页面，检验运行的结果。如果挑战失败，则返回错误。

被保护的文件类型有：

* iso
* exe
* dmg
* run
* zip
* tar

### 爬虫限制

代码位于 [/etc/nginx/snippets/robots](https://git.lug.ustc.edu.cn/mirrors/nginx-config/blob/master/snippets/robots)

如果客户端 User-Agent 包含 Spider、Robot 关键字， 则禁止其访问仓库内容。避免由于频繁列目录带来大量 IO 负载。

### Rsync 总连接数限制

Rsync 服务设置了总连接数限制。即：当建立的连接数到达某个阈值后，拒绝之后收到的连接。

由于白天 HTTP 访问压力较大，夜晚 HTTP 访问量较小，为了实现错峰同步，因此针对不同时段设置了不同的阈值，具体如下：

* 23:00 ~ 8:00 ：最多 60 个连接
* 8:00 ~ 23:00：最多 30 个连接

在 2020 年 8 月 25 日后，由于更换了新服务器，Rsync 由单独机器提供服务，总连接数提升到了全天 60 个连接。

特别的，科大 IP 地址受到 rsync 连接数限制。

## 网络接口级别限制

mirrors 常态下没有网络接口限制，但在需要临时对某一接口进行限制时，可以使用 tc 来完成。

例如可以参考这份回答：[iptables - Limiting interface bandwidth with tc under Linux - Server Fault](https://serverfault.com/questions/452829/limiting-interface-bandwidth-with-tc-under-linux)，使用如下指令限制某一接口的网络速率为 1.5Gbps：

```bash
tc qdisc add dev <interface> root handle 1: tbf rate 1500Mbit burst 6500 latency 14ms
```

这里使用了 TBF（令牌桶）算法，在突发时速率可能会短暂超过设置的 1.5Gbps。
后面的 burst 和 latency 参数可以细调，具体调节规则和效果则需查阅文档了。

## IP 黑名单限制

对于滥用的 IP 段，可以使用 ipset 和 iptables 实现黑名单限制。
ipset 将某个 IP 匹配到一个集合中，iptables 再针对某一集合进行限制。

ipset 和 iptables 的使用可以参考：[使用ipset工具对iptables设置黑/白名单 – 孙希栋的博客](https://www.sunxidong.com/379.html) 。

我们已在 mirrors4 上配置了 `blacklist` 和 `blacklist6` 集合，若要封禁某个 IP 或网段，可以直接将该网段加入集合，例如：

```bash
ipset add blacklist 192.0.2.0/24
ipset add blacklist6 2001:db8:114:514::/64
```

与 iptables 类似，ipset 也需要持久化。封禁名单的文件位于（mirrors4）`/usr/local/network_config/ipset-blacklist.list`，可以在运行完 ipset 命令后手动编辑该文件添加相关条目，以确保服务器重启后相同的表项能够被载入。

### ipset 持久化

我们使用软件源里的 `ipset-persistent` 包来帮助 ipset 在开机时自动恢复，该软件包会在开机加载 iptables 前先从 `/etc/iptables/ipsets` 中恢复 ipset 以确保 iptables 中的引用能正确处理。

因为 ipset-persistent 在开机时自动加载，我们选择仅加载一个较小的子集，包含必要配置（create set）和较少发生变化的内容（如 ustcnet 的网段）。目前 `/etc/iptables/ipsets` 包含以下内容：

```shell
create ustcnet hash:net family inet hashsize 1024 maxelem 65536
create f2b-sshd hash:ip family inet hashsize 1024 maxelem 65536 timeout 3600
create blacklist hash:net family inet hashsize 1024 maxelem 65536
create blacklist6 hash:net family inet6 hashsize 1024 maxelem 65536

add ustcnet 202.38.64.0/19
# more ustcnet entries...
```
