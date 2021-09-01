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
  PRIORITY="$5"

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
ExecStart=-/usr/sbin/ip rule flush
RemainAfterExit=true

[Install]
WantedBy=network.target systemd-networkd.service
Wants=systemd-networkd.service
```

这个文件存到 `/etc/systemd/system/route-all.service`，reload 再 enable 就可以了。

!!! bug "不要尝试改 systemd-networkd.service"

    这个自带的服务有一个 `User=systemd-networkd`，你既不能 `ip rule` 也不能写入 `/run/systemd` 等，会导致服务炸掉，然后网也炸了。。。

## Special routing

部分 IP 需要配置特殊路由规则时（而不是使用默认），编辑 `/usr/local/network_config/special.yml`，其格式如下：

```yaml
routes: # Root key，保留
  lugvpn: # /etc/systemd/network 中对应的 .network 文件名
    # 下面是一个路由文件的配置，一个文件共享一个 table 和 gateway 设置
    - name: route-special # 将要创建的 .conf 文件名，可以随意
      table: Special # 路由表，即 ip route add table 后面的参数，数字或表名
      gateway: false # 是否包含网关，或者 ip route 的 via 参数
      routes: # 所有的路由条目
        - 1.2.3.4
        - 5.6.7.8/28
        - 2001:db8::2333/64

  cernet: # 更多的配置
    - ...
```

修改 `special.yml` 之后重启 `route-all.service`。该服务会自动导致 `systemd-networkd.service` 重启并载入新的路由配置信息。

??? tips "special.rb 处理脚本（放在这备份）"

    ```ruby
    #!/usr/bin/ruby

    require 'fileutils'
    require 'yaml'

    BASEDIR = '/run/systemd/network'
    RT_TABLES = '/etc/iproute2/rt_tables'

    rt_tables = Hash.new
    File.readlines(RT_TABLES).each do |l|
      next if l =~ /^\s*#/
      id, name = l.split
      rt_tables[name] = id
    end

    data = YAML.load_file File.join(__dir__, 'special.yml')
    data['routes'].each do |fn, setups|
      confdir = File.join(BASEDIR, "#{fn}.network.d")
      FileUtils.mkdir_p confdir

      setups.each do |config|
        table = config['table']
        gateway = config['gateway']
        File.open File.join(confdir, "#{config['name']}.conf"), 'w' do |f|
          config['routes'].each do |dst|
            t = "[Route]\nDestination=#{dst}\n"
            t += "Table=#{rt_tables.fetch table, table}\n" if table
            t += "Gateway=#{gateway}\n" if gateway
            f.write t + "\n"
          end
        end
      end
    end
    ```

!!! bug "route-all.service 有很多注意事项"

    为了清理开机自动产生的 32766 和 32767 两条路由规则，`route-all.service` 包括执行 `ip rule flush`，因此该服务重启之后必须立刻重启 systemd-networkd。

    目前做法是在 `route-all.service` 中添加 `RequiredBy=systemd-networkd.service` 制造依赖关系，让 systemd 完成“牵连重启”。

    完整 service 文件：

    ```ini
    [Unit]
    Description=Generate routes for systemd-networkd
    Before=systemd-networkd.service

    [Service]
    Type=oneshot
    ExecStart=/bin/bash /usr/local/network_config/route-all.sh
    ExecStart=/usr/local/network_config/special.rb
    ExecStart=-/usr/sbin/ip rule flush
    RemainAfterExit=true

    [Install]
    WantedBy=network.target systemd-networkd.service
    RequiredBy=systemd-networkd.service
    Wants=systemd-networkd.service
    ```
