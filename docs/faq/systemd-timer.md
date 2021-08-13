# Systemd-timer 参考模板

Systemd-timer 作为 crontab 的替代品，有一系列的优点：

- 确保相同的任务未完成时不会被重复执行。
- 易于调试、管理。

当然相比于 crontab，缺点也很明显：

- 难写。

所以以下给出一个模板，方便在创建新定时任务的时候使用。这里的例子是 mirrors2 从 mirrors4 获取压缩后的日志。以下文件均放在 `/etc/systemd/system`。

`m4log.service`:

```systemd
[Unit]
Description=Mirrors4 log backup
Documentation=man:rsync(1)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=mirror
Group=mirror
ExecStart=rsync -rltpv --include=*/ --include=*.xz --exclude=* m4log:/ /var/m4log/
Restart=on-failure
RestartSec=3
```

`m4log.timer`:

```systemd
[Unit]
Description=Mirrors4 log backup timer
Documentation=man:rsync(1)
After=network.target
StartLimitIntervalSec=0

[Timer]
OnCalendar=*-*-* 7:13:00
RandomizedDelaySec=60s
Persistent=true
Unit=m4log.service

[Install]
WantedBy=timer.target
```

启用：`systemctl enable m4log.timer`

调试：`systemctl start m4log.service`

查看日志：`systemctl status m4log.service`

查看目前 timer：`systemctl list-timers`
