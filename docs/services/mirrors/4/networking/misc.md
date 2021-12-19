# mirrors 网络配置杂项

## sniproxy

Sniproxy 用于为 Docker 容器提供方便的 HTTP(S) 网络分流。目前在 mirrors 上用于为 dockerhub 容器提供（到 Cloudflare 的）IPv6 接入（Docker 做 IPv6 NAT 非常不方便，所以以此为权宜之举），以提高校内访问时的速度。

### 配置

安装 sniproxy，并且 mask 原服务配置（我们自己写一个）：

```
sudo apt install sniproxy
sudo mkdir -p /etc/sniproxy
sudo systemctl mask sniproxy.service
```

创建 `/etc/systemd/system/sniproxy@.service`：

```
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

```
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

```
sudo systemctl enable sniproxy@配置文件名.service
sudo systemctl start sniproxy@配置文件名.service
```
