# Routing on mirrors4

由于 mirrors4 没有使用 ifupdown 作为网络管理系统，而是采用 systemd-networkd，因此我们没有 `pre-up`, `up`, `down`, `post-down` 等运行命令的方式，所以 mirrors2 上使用的那套脚本（`ip-route.sh` 等）无法直接在 mirrors4 上继续使用。

好在我们使用 `up` 等运行命令只是为了配置路由，因此换了个办法，整了个新脚本把 IP 地址列表（来自 [gaoyifan/china-operator-ip](https://github.com/gaoyifan/china-operator-ip)）转换成 networkd 所使用的配置文件格式。代码不长：

```shell
#!/bin/bash

ROOT_IP_LIST=/usr/local/network_config/iplist
ROOT_RT=/run/systemd/network

gen_route() {
  IPLIST="$ROOT_IP_LIST/$1"
  GW="$2"
  DEV="$3"
  # Convert table to number
  TABLENAME="$4"
  TABLE="$(awk 'substr($0, 1, 1) != "#" && $2 == "'"$TABLENAME"'" { print $1 }' /etc/iproute2/rt_tables | head -1)"

  F="$ROOT_RT/$DEV.network.d"
  mkdir -p "$F"
  F="$F/route-${TABLENAME,,}.conf"

  echo -e "[RoutingPolicyRule]\nTable=$TABLE\nPriority=$PRIORITY\n" > "$F"
  awk '{ print "[Route]\nDestination=" $1 "\nGateway='"$GW"'\nTable='"$TABLE"'\n" }' "$IPLIST" >> "$F"
}

gen_route ustcnet.txt 202.38.95.126 cernet Ustcnet 5
gen_route cernet.txt 202.38.95.126 cernet Cernet 6
gen_route telecom.txt 202.141.160.126 telecom Telecom 6
gen_route mobile.txt 202.141.176.126 mobile Mobile 6
gen_route unicom.txt 218.104.71.161 unicom Unicom 6
gen_route china.txt 218.104.71.161 unicom China 7
```

这个仓库里有很多个 txt 文件，每个文件对应一个 ISP 的地址列表，每行一个 CIDR。脚本中的 `gen_route` 函数根据参数读取文件，并转换成下面这样的格式：

```ini
[Route]
Destination=1.0.0.0/24
Gateway=202.38.95.126
Table=1011
```

这样一个 `[Route]` 节对应**一条**路由规则，整个 txt 的转换结果输出到 `/run/systemd/network/cernet.network.d/route-example.conf`。其中 `cernet.network.d/*.conf` 用于向现有的配置中添加内容（与 systemd service 类似），而 `/run` 目录（按理来说）重启会清空，适合放置这些用于动态生成的内容。另外由于路由规则（`ip rule`）也由 networkd 管理和生成了，因此每个 `route-xxx.conf` 开头会包含一个 `[RoutingPolicyRule]` 节用于生成路由表对应的路由规则。

注意路由表是用名称指定的，从 `/etc/iproute2/rt_tables` 中查出对应的数字 ID。这个文件本来也是 `ip` 命令所使用的（注意它的目录名叫 `iproute2`）。

最后给这个脚本配个 service，让它在 networkd 之前运行：

```ini
[Unit]
Description=Generate routes for systemd-networkd
Before=systemd-networkd.service

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/local/network_config/route-all.sh
RemainAfterExit=true

[Install]
WantedBy=network.target systemd-networkd.service
```

这个文件存到 `/etc/systemd/system/route-all.service`，reload 再 enable 就可以了。
