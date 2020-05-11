# Docker services

Server: docker2.s.ustclug.org

## Special configurations

### Docker "pingd"

出于未知原因有时候外部主机会无法主动连通 Docker 容器（可能与 ARP 有关），但是如果某个容器先 ping 了一下外部主机，就能双向连通了。

由于我们暂未找到正常的解决方案，因此使用 “ping daemon” 作为一个 workaround，在容器中运行 ping 保持外部主机的连通性。

Systemd 服务 `docker-pingd@.service`:

```ini
[Unit]
Description=Docker pingd service %I
Documentation=man:ping(8)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
Group=root
ExecStart=/bin/sh -c 'IVAR="%i"; exec /usr/bin/docker exec "$${IVAR%:*}" ping -q -s 32 "$${IVAR#*:}"'
ExecStop=/bin/kill -s INT $MAINPID
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
Alias=docker-ping@.service
```

使用方式：`systemctl enable docker-pingd@container:host.service`，`container` 换成容器名，`host` 换成 ping 的目标。

Trick 介绍：Systemd service 配置暂不支持多个模板参数 `%i`，因此调用 shell 来解析参数。Ref: <https://github.com/systemd/systemd/issues/14895#issuecomment-612270690>