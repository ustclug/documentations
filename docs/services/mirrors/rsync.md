# Rsync

## rsyncd

经过 2024 年夏季的 [ZFS rebuild](https://lug.ustc.edu.cn/planet/2024/12/ustc-mirrors-zfs-rebuild/) 之后，我们观测到 ZFS ARC cache 能够很好地缓存仓库文件的元数据，因此我们在 2025 年 1 月抛弃了 rsync-huai，改用原生的 rsync。

我们的 systemd service 文件：

```ini title="/etc/systemd/system/rsync@.service"
--8<-- "mirrors/rsync@.service"
```

??? info "rsync-huai (discontinued)"

    rsync-huai 是坏人的元数据加速版的 rsync，原始代码在 <https://github.com/tuna/rsync>。

    由于 TUNA 现在使用全闪的方案，不再需要这个 patch 了，因此我们自己维护对应的版本：<https://github.com/ustclug/rsync/tree/rsync-3.2.7>。

    特别地，systemd service 内容如下：

    ```ini title="/etc/systemd/system/rsyncd-huai@.service"
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
