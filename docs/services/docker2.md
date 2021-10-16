# Docker services

Server: docker2.s.ustclug.org

## Special configurations

### Docker "pingd"

**更新：问题已经查明为 Debian 的 Linux 内核 bug (<https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=952660>)，已经通过更新内核并重启而解决。以下内容仅作存档。**

---

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

### WordPress 升级

tky: 很麻烦，建议 lug 以后再也别用（别开新的）wordpress 了。

servers 与旧 planet 使用 WordPress，托管在 docker2 上。因为 docker2 现在磁盘 IO 很慢，所以可能会出现一些额外的问题。

推荐使用 https://wp-cli.org/#installing。命令：

```
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
cd /var/www/public/
sudo -u www-data -- wp core update --version=5.8.1 /tmp/wordpress-5.8.1.zip
```

容器里 sudo 要手动装。

以下内容仅供参考。

尝试升级时如果未出现升级提示，可以修改：

- 文件 `wp-includes/update.php`，将函数 `wp_version_check()` 中 `$doing_cron ? 3 : 30` 修改为 `$doing_cron ? 30 : 30`。
- 文件 `wp-admin/includes/update.php`，将函数 `get_core_checksums()` 中对应的部分修改为 `$doing_cron ? 30 : 30`。

如果出现「另一更新正在运行」，且确认不在更新，可以在数据库的 `wordpress` 表中执行：

```sql
delete from wp_options where option_name='core_updater.lock';
```

