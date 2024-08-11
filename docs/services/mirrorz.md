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

    ```sourceslist title="/etc/apt/sources.list.d/docker.list"
    deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.ustc.edu.cn/docker-ce/linux/debian bookworm stable
    ```

    ```sourceslist title="/etc/apt/sources.list.d/grafana.list"
    deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://mirrors.tuna.tsinghua.edu.cn/grafana/apt stable main
    ```

    ```sourceslist title="/etc/apt/sources.list.d/influxdata.list"
    deb [signed-by=/etc/apt/keyrings/influxdata.asc] https://mirrors.ustc.edu.cn/influxdata/debian stable main
    ```

    ```sourceslist title="/etc/apt/sources.list.d/nodesource.list"
    deb [arch=amd64 signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_18.x nodistro main
    ```

    ```sourceslist title="/etc/apt/sources.list.d/sb-nginx.list"
    deb [arch=amd64 signed-by=/etc/apt/keyrings/sb-nginx.asc] https://mirror.xtom.com.hk/sb/nginx/ bookworm main
    ```

### Go

从官方网站下载最新的 tar.gz 并解压到 `/usr/local/go`，然后将 `/usr/local/go/bin` 中的两个二进制文件软链接到 `/usr/local/bin`。

更新 Go 的快捷脚本位于 `/root/go/update.sh`，内容见 [iBug/shGadgets](https://github.com/iBug/shGadgets/blob/master/go-update.sh)。

## 数据目录

MirrorZ 主项目和帮助页面等可以通过浏览器访问的页面都在 `/var/www` 下。

### 自动更新

利用 GitHub 的 webhook 功能，部署了一份 [iBug/uniAPI](https://github.com/iBug/uniAPI)。相关文件如下：

```text
/usr/bin/uniAPI
/etc/uniAPI.yml
/etc/systemd/system/uniAPI.service
```

配置样例如下：

```yaml
services:
  uniAPI:
    type: server
    services:
      mirrorz-json-legacy:
        type: github.webhook
        path: /home/mirrorz/mirrorz-org/mirrorz-json-legacy
        branch: master
        secret: # empty
```

```nginx
location ^~ /uniAPI {
    proxy_pass http://127.0.1.1:1024;
}
```
