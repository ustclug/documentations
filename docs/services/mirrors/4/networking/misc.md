# mirrors 网络配置杂项

## sniproxy

Sniproxy 用于为 Docker 容器提供方便的 HTTP(S) 网络分流。目前在 mirrors 上用于为 dockerhub 容器提供（到 Cloudflare 的）IPv6 接入（Docker 做 IPv6 NAT 非常不方便，所以以此为权宜之举），以提高校内访问时的速度。

### 配置

安装 sniproxy，并且 mask 原服务配置（我们自己写一个）：

```shell
sudo apt install sniproxy
sudo mkdir -p /etc/sniproxy
sudo systemctl mask sniproxy.service
```

创建 `/etc/systemd/system/sniproxy@.service`：

```ini
[Unit]
Description=SNIProxy (%i.conf)
After=network.target network-online.target
StartLimitIntervalSec=1

[Service]
Type=simple
ExecStart=/usr/sbin/sniproxy -f -c /etc/sniproxy/%i.conf
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

在 `/etc/sniproxy` 中创建配置。以下为 IPv6 + TLS (443) only 的配置例子：

```shell
resolver {
    nameserver 2001:da8:d800::1
    mode ipv6_only
}

access_log {
    filename /dev/null
}

listen <Bind 到的 IP 地址>:443 {
    proto tls
    reuseport yes
    table all
    source <IPv6 出口地址>
}

table all {
    .* *
}
```

最后启动服务：

```shell
sudo systemctl enable sniproxy@配置文件名.service
sudo systemctl start sniproxy@配置文件名.service
```

## nfacct

由于 iptables 中的 nfacct 类指令需要对应的 nfacct object 已存在，因此我们利用 `netfilter-persistent` 的插件机制，在防火墙规则加载前先创建所需的 nfacct objects。

```shell title="/usr/share/netfilter-persistent/plugins.d/01-nfacct"
#!/bin/bash

case "$1" in
  start|restart|reload|force-reload)
    for i in \
      ipv4-ftp ipv4-git ipv4-http ipv4-https ipv4-rsync \
      ipv6-ftp ipv6-git ipv6-http ipv6-https ipv6-rsync
    do
      nfacct add "$i" 2>/dev/null || true
    done
    ;;
  save)
    ;;
  stop)
    ;;
  flush)
    ;;
  *)
    echo "Usage: $0 {start|restart|reload|force-reload|save|flush}" >&2
    exit 1
    ;;
esac
```
