# Rsync

## rsync-huai

rsync-huai 是坏人的元数据加速版的 rsync，原始代码在 <https://github.com/tuna/rsync>。

由于 TUNA 现在使用全闪的方案，不再需要这个 patch 了，因此我们自己维护对应的版本：<https://github.com/ustclug/rsync/tree/rsync-3.2.7>。

特别地，`/etc/systemd/system/rsyncd-huai@.service` 内容如下：

```systemd
[Unit]
Description=fast remote file copy program daemon
ConditionPathExists=/etc/rsyncd/rsyncd-%i.conf
After=network.target network-online.target

[Service]
Type=simple
PIDFile=/run/rsyncd-%i.pid
ExecStart=/usr/bin/rsync-huai --daemon --no-detach --config=/etc/rsyncd/rsyncd-%i.conf
IOSchedulingClass=best-effort
IOSchedulingPriority=7
IOAccounting=true

[Install]
WantedBy=multi-user.target
```

## rsync-proxy

详参 <https://github.com/ustclug/rsync-proxy>。为了让服务器能够记录 IP 与访问路径的关系，我们打开了 proxy protocol 特性。
