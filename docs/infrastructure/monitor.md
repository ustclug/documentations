# 监控系统使用及配置说明

监控系统由以下几个组件组成：

- Telegraf: agent，运行在每个被监控的机器上
- InfluxDB: 数据库，运行在 influxdb.ustclug.org (docker2.s.ustclug.org)
- Grafana: 可视化工具，监控报警，地址：[monitor.ustclug.org](https://monitor.ustclug.org) (docker2.s.ustclug.org)

## Configure InfluxDB

**特别注意** ：InfluxDB 默认没有开启认证。

首次运行时，创建好管理账号（`admin`），只读账号（`grafana`）和写入账号（`telegraf`）。

然后修改位于 `/srv/docker/influxdb/conf/influxdb.conf` 的配置，修改以启用认证：

```shell title="/srv/docker/influxdb/conf/influxdb.conf"
[http]
# ...
# Determines whether HTTP authentication is enabled.
auth-enabled = true
```

此外，参考 <https://docs.influxdata.com/influxdb/v1.8/administration/authentication_and_authorization/#set-up-authentication>，考虑关闭部分功能：

```shell title="/srv/docker/influxdb/conf/influxdb.conf"
[http]
# Determines whether the pprof endpoint is enabled.  This endpoint is used for
# troubleshooting and monitoring.
pprof-enabled = false
```

## Install telegraf

官方文档见 <https://docs.influxdata.com/telegraf/v1/install/>

典型的安装方式是从 APT 源安装：

```shell
wget -O /etc/apt/trusted.gpg.d/influxdb.asc https://repos.influxdata.com/influxdata-archive_compat.key
echo "deb https://mirrors.ustc.edu.cn/influxdata/debian bullseye stable" > /etc/apt/sources.list.d/influxdb.list
apt update
apt install --no-install-recommends telegraf
```

??? note "手动安装方式（不推荐）"

    ```shell
    wget https://dl.influxdata.com/telegraf/releases/telegraf_1.28.2-1_amd64.deb
    sudo dpkg -i telegraf_1.28.2-1_amd64.deb
    ```

## Configure telegraf

配置文件在 `/etc/telegraf/` 目录下，用 root 权限修改：

在 `/etc/telegraf/telegraf.d/` 下增加 `net.conf` 用来开启网络监控，内容如下：

```shell title="/etc/telegraf/telegraf.d/net.conf"
[[inputs.net]]
```

在 `/etc/telegraf/telegraf.conf` 中的`[[outputs.influxdb]]` 中**增加** influxdb 的地址：

```shell title="/etc/telegraf/telegraf.conf"
[[outputs.influxdb]]
  urls = ["http://influxdb.ustclug.org:8086"]
  username = "${INFLUX_USERNAME}"
  password = "${INFLUXDB_PASSWORD}"
```

其中 `INFLUX_USERNAME` 和 `INFLUXDB_PASSWORD` 应使用对 `telegraf` 数据库写权限的账号，否则无法写入数据。

配置完成之后，重启 telegraf 服务，并确保服务运行正常。

```shell
sudo systemctl restart telegraf
sudo systemctl status telegraf
```

!!! tip "建议在被监控机器上配置 NTP（可以使用 `systemd-timesyncd`，设置 NTP 服务器为 time.ustc.edu.cn），以避免时间不同步可能带来的问题。"

## Web

Web 端监控位于 <https://monitor.ustclug.org>，账号系统使用 LDAP，可以在这里设置预警提示等。

!!! warning

    配置 InfluxDB 数据源时，只能使用只读账号，否则会带来严重的安全问题。

## 更新记录

### 迁移到 Unified Alerting

Grafana 11 起将完全删除旧的报警系统，全面使用新的（难用的）Unified Alerting。

外卖原先运行的是 Grafana 9.3.8，根据更新记录，发现 v10.4 提供了一个迁移工具，可以将原先的报警迁移到新的 Unified Alerting 系统，因此先将 Grafana 更新到 10.4.3，准备迁移。

![1](https://ftp.lug.ustc.edu.cn/misc/grafana-alert-upgrade/upgrade-list.png)

在 Alerting (legacy) 菜单下有个 Upgrade rules 界面，点进去就可以使用迁移向导。首先迁移我们唯一的一个 Notification Channel，变成一个 Contact Point。由于 **:fontawesome-solid-trash-can: 垃圾**的新 alerting 方案没有提供默认的消息模板，因此我们需要自己写一个（文档也晦涩难懂）。

??? abstract "Notification template `telegram.message`"

    ```htmldjango
    {{ define "alert_list" -}}
    {{ range . }}[{{ .Labels.alertname }}] {{ .Annotations.description }}
    {{ if or (gt (len .GeneratorURL) 0) (gt (len .SilenceURL) 0) (gt (len .DashboardURL) 0) (gt (len .PanelURL) 0) }}|{{- end }}
    {{- if gt (len .GeneratorURL) 0 }} <a href="{{ .GeneratorURL }}">Source</a> | {{- end }}
    {{- if gt (len .SilenceURL) 0 }} <a href="{{ .SilenceURL }}">Silence</a> | {{- end }}
    {{- if gt (len .DashboardURL) 0 }} <a href="{{ .DashboardURL }}">Dashboard</a> | {{- end }}
    {{- if gt (len .PanelURL) 0 }} <a href="{{ .PanelURL }}">Panel</a> | {{- end }}
    {{ end }}
    {{ end }}

    {{- define "telegram.message" }}
    {{- if gt (len .Alerts.Firing) 0 }}<strong>Firing</strong>
    {{ template "alert_list" .Alerts.Firing }}
    {{ if gt (len .Alerts.Resolved) 0 }}
    {{ end }}
    {{- end }}

    {{- if gt (len .Alerts.Resolved) 0 }}<strong>Resolved</strong>
    {{ template "alert_list" .Alerts.Resolved }}
    {{ end }}
    {{- end }}
    ```

然后回到 Contact point 编辑，展开 Optional Telegram settings，在 Message 中填入 `{{ template "telegram. Message" . }}` 来引用我们刚刚写的模板，并将 Parse mode 设为 HTML。

接下来回到迁移 Alerting 的地方，逐个迁移 Alerting：

- 点击右边的加号，然后点击 New alert rule 下面对应的新 rule，进入编辑界面（[如图](https://ftp.lug.ustc.edu.cn/misc/grafana-alert-upgrade/auto-upgrade-result.png)）。
- 检查表达式 A（应该是一个 InfluxDB query），确保内容正常（一般不需要修改）。
    - 可选：将 query 的 Min interval 设置为 10s 或更长。
- 观察表达式 B（应该是一个 Classic condition）的内容和参数（一般是 `avg()` 和一个数值），然后把它删掉
- 新建 B 为一个 Reduce，选择 Input = A，Function = Mean（或者 Last，看上面原来的函数），Mode 大多数时候需要改成 Drop Non-numeric Values。
- 新建 C 为一个 Threshold，选择 Input = B，其他继续参考原来的设置。
- 将 C "Set as alert condition"，[如图](https://ftp.lug.ustc.edu.cn/misc/grafana-alert-upgrade/rewrite-conditions-and-evaluation.png)
- 在下面的 Evaluation behavior 中把 Folder 和 Evaluation group 都换成默认值，删掉那个奇怪的 label
- 在 Description 中填入一个合适的模板（见下），然后删掉那个空的 Custom annotation，保存即可

??? abstract "Description 模板"

    在 Go template 中可用的帮助函数参见 <https://grafana.com/docs/grafana/latest/alerting/alerting-rules/templating-labels-annotations/>。

    ```django
    {{ index $labels "host" }}: {{ humanize (index $values "B").Value }}

    {{ index $labels "host" }}: {{ humanizePercentage (index $values "D").Value }}

    {{ index $labels "host" }}: {{ humanizeDuration (index $values "B").Value }}
    ```

    其中 `index $labels` 后面的参数可以是前面 InfluxDB query 中 GROUP BY 的 tag，可以灵活使用。

手工处理完全部 18 个 alert rules 之后（累死我了），就可以开始测试了。

先启用新的 unified alerting：

```ini title="/srv/docker/grafana/conf/grafana.ini"
[alerting]
enabled = false

[unified_alerting]
enabled = true

[unified_alerting.screenshots]
capture = true
```

然后找个机器重启一下，触发 Reboot alert，去 Telegram 群里看消息和图片都正确冒出来了，就说明迁移成功了。
