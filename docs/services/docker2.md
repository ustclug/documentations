# Docker services

Server: docker2.s.ustclug.org

Provides Docker container environment for other services. All non-system services should be run as Docker containers on this host.

Methods to run individual containers are maintained in the [:fontawesome-solid-lock: ustclug/docker-run-script](https://github.com/ustclug/docker-run-script) repository.

## Special configurations

### Network interfaces

We use udev rules to assign consistent names to network interfaces, identified by their MAC addresses.

```ini title="/etc/udev/rules.d/70-persistent-net.rules"
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:50:56:9f:00:22", NAME="Telecom"
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:50:56:9f:00:5b", NAME="Mobile"
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:50:56:9f:00:5d", NAME="Policy"
```

We then refer to these interfaces using their new names in `/etc/network/interfaces` to ensure consistent network configuration.

### Docker daemon service

docker2 上面的 Docker 使用 macvlan 来将虚拟机接入 lugi 内网，因此将 macvlan 的主端口 Policy 配置为 `docker.service` 的强依赖。

```ini title="systemctl edit docker.service"
[Unit]
BindsTo=sys-subsystem-net-devices-Policy.device
After=sys-subsystem-net-devices-Policy.device
```

实际上 `After=network-online.target` 就够了，但是出于历史原因使用了 `BindsTo` 强依赖内网端口，这是因为 docker2 曾经单独运行 tinc 接入内网，而 tinc 的端口只在 tinc 启动后才会出现（才能分出 macvlan 子端口），因此使用 `BindsTo` 保证 docker 随该端口的出现和消失而启动/停止。

2022 年 1 月 15 日以后 docker2 与其他虚拟机一样通过 gateway-nic 桥接的 tinc 接入内网，不再单独运行 tinc。

## Workflows & Troubleshooting

### Docker "pingd"

!!! tip "更新"

    问题已经查明为 Debian 的 Linux 内核 bug (<https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=952660>)，已经通过更新内核并重启而解决。**以下内容仅作存档。**

出于未知原因有时候外部主机会无法主动连通 Docker 容器（可能与 ARP 有关），但是如果某个容器先 ping 了一下外部主机，就能双向连通了。

由于我们暂未找到正常的解决方案，因此使用 “ping daemon” 作为一个 workaround，在容器中运行 ping 保持外部主机的连通性。

```ini title="docker-pingd@.service"
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

!!! note "taoky"

    很麻烦，建议 lug 以后再也别用（别开新的）wordpress 了。

servers 与旧 planet 使用 WordPress，托管在 docker2 上。<s>因为 docker2 现在磁盘 IO 很慢，所以可能会出现一些额外的问题。</s>

推荐使用 <https://wp-cli.org/#installing>。命令：

```shell
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
DELETE FROM wp_options WHERE option_name = 'core_updater.lock';
```

### 看起来正在运行但是没有进程的 Docker 容器

2021/10/25 发现某容器显示正在运行，但是实际没有进程。后发现为 Docker 的 bug，在容器进程被 cgroups 干掉之后可能会出现此情况。

对应 issue：<https://github.com/moby/moby/issues/38501>

解决方法：将容器 ID 对应的 `containerd-shim` 杀死即可让 Docker 更新其状态为已停止，然后重新开启即可。
