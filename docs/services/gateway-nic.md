# Network Information Center Gateway (`gateway-nic`)

Previously gateway-nic used CentOS 7 to 8 to Stream, to "avoid putting all eggs in one basket". This VM was replaced by a newly setup Debian Bullseye VM on January 2022 during migration from ESXi to Proxmox VE.

## Networking

We use systemd-networkd to configure network on gateway-nic.

```ini title="systemctl edit systemd-networkd.service"
[Service]
ExecStartPre=-/sbin/ip -4 rule flush
ExecStartPre=-/sbin/ip -6 rule flush

[Install]
Alias=networkd.service
```

The `ExecStartPre=` commands flush (clear) existing rules so that systemd-networkd can fully manage all rules. This is because `ManageForeignRoutingPolicyRules` is a new setting in systemd 249, while Debian Bullseye uses systemd 247, so we have to do this manually.

We then load the regular "main" and "default" rules on the loopback interface (routing rules aren't bound to interfaces, but are added/removed when the configured interface is brought up/turned down).

```ini title="/etc/systemd/network/00-lo.network"
[Match]
Name=lo

# Route "main"
[RoutingPolicyRule]
Family=both
Table=254
Priority=2
SuppressPrefixLength=1

# Route "Special"
[RoutingPolicyRule]
Family=both
Table=1000
Priority=5
SuppressPrefixLength=1

# Route "default"
[RoutingPolicyRule]
Family=both
Table=253
Priority=32767
```

Other interfaces are configured normally, so refer to their config files for details.

### Routes

Outgoing connections are routed through different ISPs. We use ISP IP data from [gaoyifan/china-operator-ip](https://github.com/gaoyifan/china-operator-ip). Relevant files are located under `/usr/local/network_config`.

The said repository (branch `ip-lists`) is cloned and we symlink select files to `iplist` directory for consumption. A custom script converts these IP data into additional systemd-networkd config files (under `/run/systemd`).

```text title="/usr/local/network_config/iplist"
total 8
lrwxrwxrwx cernet.txt -> ../china-operator-ip/cernet.txt
lrwxrwxrwx cernet6.txt -> ../china-operator-ip/cernet6.txt
lrwxrwxrwx china.txt -> ../china-operator-ip/china.txt
lrwxrwxrwx china6.txt -> ../china-operator-ip/china6.txt
lrwxrwxrwx cstnet.txt -> ../china-operator-ip/cstnet.txt
lrwxrwxrwx mobile.txt -> ../china-operator-ip/cmcc.txt
lrwxrwxrwx telecom.txt -> ../china-operator-ip/chinanet.txt
lrwxrwxrwx unicom.txt -> ../china-operator-ip/unicom.txt
-rw-r--r-- ustcnet.txt
-rw-r--r-- ustcnet6.txt
```

```sh title="/usr/local/network_config/route-all.sh"
#!/bin/bash

[ -n "$BASH_VERSION" ] || exit 1

WD="$(dirname "$0")"
ROOT_IP_LIST="$WD/iplist"
ROOT_CONF=/etc/systemd/network
ROOT_RT=/run/systemd/network

gen_route() {
  DEVFILE="$1"
  DEV="$(grep '^Name=' "$ROOT_CONF/$DEVFILE.network" | head -1 | cut -d= -f2)"
  GW="$2"
  # Convert table to number
  TABLENAME="$3"
  TABLE="$(awk 'substr($0, 1, 1) != "#" && $2 == "'"$TABLENAME"'" { print $1 }' /etc/iproute2/rt_tables | head -1)"
  PRIORITY="$4"
  shift 4

  F="$ROOT_RT/$DEVFILE.network.d"
  mkdir -p "$F"
  F="$F/route-${TABLENAME,,}.conf"
  echo -e "[RoutingPolicyRule]\nFamily=both\nTable=$TABLE\nPriority=$PRIORITY\n" > "$F"

  awk '{ print "[Route]\nDestination=" $1 "\nGateway='"$GW"'\nTable='"$TABLE"'\n" }' "${@/#/$ROOT_IP_LIST/}" >> "$F"
}

gen_route 12-Cernet 202.38.95.126 ustcnet 5 ustcnet.txt
gen_route 12-Cernet 2001:da8:d800:95::1 ustcnet 5 ustcnet6.txt
gen_route 12-Cernet 202.38.95.126 cernet 6 cernet.txt cstnet.txt
gen_route 13-Telecom 202.141.160.126 telecom 6 telecom.txt unicom.txt
gen_route 14-Mobile 202.141.176.126 mobile 6 mobile.txt
gen_route 12-Cernet 202.38.95.126 china 7 china.txt
gen_route 12-Cernet 2001:da8:d800:95::1 china 7 china6.txt
```

We then use a systemd service to ensure additional files for systemd-networkd are generated before it starts.

```ini title="/etc/systemd/system/route-all.service"
[Unit]
Description=Generate routes for systemd-networkd
Before=systemd-networkd.service

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/local/network_config/route-all.sh
#ExecStart=/usr/local/network_config/special.rb
RemainAfterExit=true

[Install]
WantedBy=network.target systemd-networkd.service
Wants=systemd-networkd.service
```

Updating routes from upstream is easy:

```sh title="/usr/local/network_config/update.sh"
#!/bin/sh

cd "$(dirname "$0")"

( cd china-operator-ip; git pull )
systemctl restart route-all.service
```

The resulting routing policies look like this:

```text title="ip rule"
0:      from all lookup local
2:      from all lookup main suppress_prefixlength 1
3:      from 172.16.0.2 lookup Warp
3:      from all oif Warp lookup Warp
3:      from 202.141.176.102 lookup Mobile
3:      from all oif Mobile lookup Mobile
3:      from 202.141.160.102 lookup Telecom
3:      from all oif Telecom lookup Telecom
3:      from 202.38.95.102 lookup Cernet
3:      from all oif Cernet lookup Cernet
4:      from all fwmark 0x5 lookup Warp
4:      from all fwmark 0x4 lookup Mobile
4:      from all fwmark 0x3 lookup Telecom
4:      from all fwmark 0x2 lookup Cernet
5:      from all lookup Special suppress_prefixlength 1
5:      from all lookup Ustcnet
6:      from all lookup mobile
6:      from all lookup telecom
6:      from all lookup cernet
7:      from all lookup china
32767:  from all lookup default
```

### systemd-networkd-wait-online.service

We also override systemd-networkd's online detection for goodness' sake, so it doesn't block booting. Note that it may interfere with services depending on `network-online.target`, though we have yet to discover any issues.

```ini title="systemctl edit systemd-networkd-wait-online.service"
[Service]
ExecStart=
ExecStart=/bin/sleep 1
```
