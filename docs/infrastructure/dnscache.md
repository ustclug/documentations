# DNS 缓存

本部分介绍使用 dnsmasq 配置本地 DNS 缓存的方式，适用于不便于使用 nscd 的场景，例如：

- 容器
- Nginx `proxy_pass`

安装后创建配置文件 `/etc/dnsmasq.d/ustclug`，内容如下：

``` title="/etc/dnsmasq.d/ustclug"
no-resolv
expand-hosts
listen-address=127.0.0.1
bind-interfaces

domain=s.ustclug.org
server=原来的 DNS 第一个服务器
server=原来的 DNS 第二个服务器
```

建议进行以下操作之前，启动一个 root shell。

**重启** `dnsmasq` 服务（`reload` 无效），之后确认解析工作，特别是自己的名字的解析：

```shell
dig @127.0.0.1 +short ustc.edu.cn
dig @127.0.0.1 +short 你的主机名
```

确认后修改 `/etc/resolv.conf`，`nameserver` 处仅包含 `127.0.0.1`。诸如 nginx 等程序可能需要单独设置。

如果更改了 `/etc/hosts` 设置，需要手动 `systemctl reload dnsmasq`。
