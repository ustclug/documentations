# Nginx 相关配置

## 文件打开数大小限制

在默认设置中，nginx 的最大文件打开数上限并不大。当有大量访问时，文件打开数可能会超过限额，导致网站响应缓慢。在新配置服务器时，这一项设置很容易被忽略掉。

解决方法：

1. `sudo systemctl edit nginx.service`（部分机器上的服务名可能为 `openresty.service`）
2. 在打开的 override 文件的 `[Service]` 下方添加 `LimitNOFILE=524288`（视情况这个值可以相应调整）

## 关于 gateway 配置中的 `/tmp/mem` 路径

错误表现是 `systemctl start nginx.service` 失败，使用 status 或 journalctl 可以看到以下信息：

    [emerg] mkdir() "/tmp/mem/nginx_temp" failed (2: No such file or directory)

这是因为[我们的 `nginx.conf`](https://git.lug.ustc.edu.cn/ustclug/nginx-config/-/blob/d6f9bf7443117b4d6ebe0a566dc6bb48753a8f58/nginx.conf#L34) 中钦点了 `proxy_temp /tmp/mem/nginx_temp`，而 `/tmp/mem` 是我们自己建的一个 tmpfs 挂载点，它不是任何发行版的默认配置，所以新装的系统如果直接 pull 了这份 nginx config 就会报以上错误。

（使用 `/tmp/mem` 的原因是，由于 nginx 反代需要频繁读写临时文件，为了减少磁盘 IO 占用，故将其临时文件放入内存中）

正确的解决方法是补上对应的 fstab 行：

    tmpfs   /tmp/mem    tmpfs   0   0

如果创建/挂载了 /tmp/mem 后，启动仍然出错，则需要检查 openresty.service/nginx.service 文件中是否包含 `PrivateTmp=yes`。如果包含，则需要 `systemctl edit`，将此项设置为 `false`。
