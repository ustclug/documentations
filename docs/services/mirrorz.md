---
icon: material/alpha-z-circle
---

# MirrorZ CERNET server

MirrorZ 项目在 CERNET 北京节点有一个虚拟机，通过 \*.mirrors.cernet.edu.cn 的域名提供 302 跳转和帮助页面等服务。

由于 CentOS 7 在 2024 年 6 月结束支持，iBug 和 taoky 在 2024 年 2 月配置了一个运行 Debian 12 的新虚拟机。新虚拟机镜像基于 debian-cdimage 提供的 `debian-12-genericcloud-amd64.qcow2`。

## 系统配置 {#system}

### 网络 {#network}

虚拟机的网络采用 systemd-networkd 配置，配置文件在 `/etc/systemd/network` 下，v4/v6 均使用静态 IP 配置。其中 `[Match]` 块使用 `MACAddress=...` 来匹配网卡。

### SSH

```shell title="/etc/ssh/sshd_config.d/ibug.conf"
PasswordAuthentication no
PermitRootLogin prohibit-password
```

### NTP

```ini title="/etc/systemd/timesyncd.conf.d/ibug.conf"
[Time]
NTP=ntp.tuna.tsinghua.edu.cn
```

## 软件 {#software}

etckeeper（不知道怎么配置的，装好即用？）

- Nginx (使用 [n.wtf](https://n.wtf) 的版本)
- Node.js 18
- InfluxDB 2
- Grafana 9

以上四个软件分别从四个不同的 APT 源安装，对应的 APT 公钥都存在 `/etc/apt/keyrings` 中。

!!! abstract "APT 源配置"

    ```shell title="/etc/apt/sources.list.d/docker.list"
    deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.ustc.edu.cn/docker-ce/linux/debian bookworm stable
    ```

    ```shell title="/etc/apt/sources.list.d/grafana.list"
    deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://mirrors.tuna.tsinghua.edu.cn/grafana/apt stable main
    ```

    ```shell title="/etc/apt/sources.list.d/influxdata.list"
    deb [signed-by=/etc/apt/keyrings/influxdata.asc] https://mirrors.ustc.edu.cn/influxdata/debian stable main
    ```

    ```shell title="/etc/apt/sources.list.d/nodesource.list"
    deb [arch=amd64 signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_18.x nodistro main
    ```

    ```shell title="/etc/apt/sources.list.d/sb-nginx.list"
    deb [arch=amd64 signed-by=/etc/apt/keyrings/sb-nginx.asc] https://mirror.xtom.com.hk/sb/nginx/ bookworm main
    ```

## 数据目录

MirrorZ 主项目和帮助页面等可以通过浏览器访问的页面都在 `/var/www` 下。
