# Gateway: Network Information Center (`gateway-nic`)

Previously gateway-nic used CentOS 7 to 8 to Stream, to "avoid putting all eggs in one basket". This VM was replaced by a newly setup Debian Bullseye VM on January 2022 during migration from ESXi to Proxmox VE.

The virtual disk of the old gateway-nic was copied onto pve-5, located at ZFS Zvol `rpool/data/gateway-nic`. The current VM uses `rpool/data/vm-200-disk-0` instead (Proxmox naming convention).

## Config file management

Git repositories exist for these directories:

```text
/etc/nginx
/etc/systemd/network
/etc/tinc
```

## Networking

We use systemd-networkd to configure network on gateway-nic. This replaces both `ifupdown` (config file `/etc/network/interfaces`)

```ini title="$ systemctl edit systemd-networkd.service"
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

### Interfaces

Systemd-networkd has built-in capability to rename interfaces, so there's no need to use udev rules.

For example, to assign a name for the cernet interface, we use:

```ini title="/etc/systemd/network/12-Cernet.link"
[Match]
PermanentMACAddress=00:50:56:a2:02:8c

[Link]
Name=Cernet
```

We then configure addresses and routing rules for this interface:

??? example "/etc/systemd/network/12-Cernet.network"

    ```ini
    [Match]
    Name=Cernet

    [Network]
    Address=202.38.95.102/25
    Address=2001:da8:d800:95::102/64
    IPv6AcceptRA=no

    [Route]
    Gateway=202.38.95.126
    Table=253
    Metric=2

    [Route]
    Gateway=2001:da8:d800:95::1
    Table=253
    Metric=2

    [Route]
    Gateway=202.38.95.126
    Table=1002

    [Route]
    Gateway=2001:da8:d800:95::1
    Table=1002

    [RoutingPolicyRule]
    From=202.38.95.102
    Table=1002
    Priority=3

    [RoutingPolicyRule]
    From=2001:da8:d800:95::102
    Table=1002
    Priority=3

    [RoutingPolicyRule]
    Family=both
    OutgoingInterface=Cernet
    Table=1002
    Priority=3

    [RoutingPolicyRule]
    Family=both
    FirewallMark=0x2
    Table=1002
    Priority=4
    ```

This config file assigns one IPv4 and one IPv6 address to the interface, as well as one IPv4 route and one IPv6 route for both the default routing table and an interface-specific routing table. It then adds three routing rules in both IPv4 and IPv6 for replying on the same interface, for sockets bound to this interfaces, and for firewall mark routing.

Other interfaces are configured similarly, so just refer to their configuration files for details.

### Routes

Outgoing connections are routed through different ISPs. We use ISP IP data from [gaoyifan/china-operator-ip](https://github.com/gaoyifan/china-operator-ip). Relevant files are located under `/usr/local/network_config`.

The said repository (branch `ip-lists`) is cloned and we symlink select files to `iplist` directory for consumption. A custom script converts these IP data into additional systemd-networkd config files (under `/run/systemd`).

```text title="$ ls -l /usr/local/network_config/iplist/"
lrwxrwxrwx cernet.txt -> ../china-operator-ip/cernet.txt
lrwxrwxrwx cernet6.txt -> ../china-operator-ip/cernet6.txt
lrwxrwxrwx china.txt -> ../china-operator-ip/china.txt
lrwxrwxrwx china6.txt -> ../china-operator-ip/china6.txt
lrwxrwxrwx cstnet.txt -> ../china-operator-ip/cstnet.txt
lrwxrwxrwx cstnet6.txt -> ../china-operator-ip/cstnet6.txt
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
  local DEVFILE="$1"
  local DEV="$(awk -F = '/^Name=/{print $2; exit}' "$ROOT_CONF/$DEVFILE.network")"
  local GW="$2" FAMILY=ipv4 V6
  if [[ "$GW" =~ : ]]; then
    FAMILY=ipv6
    V6="-v6"
  fi
  # Convert table to number
  local TABLENAME="$3"
  local TABLE="$(awk 'substr($0, 1, 1) != "#" && $2 == "'"$TABLENAME"'" { print $1 }' /etc/iproute2/rt_tables | head -1)"
  local PRIORITY="$4"
  shift 4

  F="$ROOT_RT/$DEVFILE.network.d"
  mkdir -p "$F"
  F="$F/route-${TABLENAME,,}${V6}.conf"
  echo -e "[RoutingPolicyRule]\nFamily=$FAMILY\nTable=$TABLE\nPriority=$PRIORITY\n" > "$F"

  awk '{ print "[Route]\nDestination=" $1 "\nGateway='"$GW"'\nTable='"$TABLE"'\n" }' "${@/#/$ROOT_IP_LIST/}" >> "$F"
}

gen_route 12-Cernet 202.38.95.126 ustcnet 5 ustcnet.txt
gen_route 12-Cernet 2001:da8:d800:95::1 ustcnet 5 ustcnet6.txt
gen_route 12-Cernet 202.38.95.126 cernet 6 cernet.txt cstnet.txt
gen_route 12-Cernet 2001:da8:d800:95::1 cernet 6 cernet6.txt cstnet6.txt
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

```text title="$ ip rule"
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

### Tinc VPN

Gateway-NIC connects to intranet with Tinc. There's no special Tinc configuration other than those described at the [Tinc VPN](../infrastructure/tinc.md) page.

Because Tinc now uses systemd services instead of System V `init.d` scripts, we need to `systemctl enable tinc@ustclug.service` to make it start on boot. Everything is managed through this templated systemd service.

### systemd-networkd-wait-online.service

We also override systemd-networkd's online detection for goodness' sake, so it doesn't block booting. Note that it may interfere with services depending on `network-online.target`, though we have yet to discover any issues.

```ini title="$ systemctl edit systemd-networkd-wait-online.service"
[Service]
ExecStart=
ExecStart=/bin/sleep 1
```

### iptables

All iptables firewall rules are managed manually. We use `iptables-persistent` to automatically load firewall rules on boot.

To change the rules, manually edit `/root/iptables/rules.v4` or `rules.v6` and then run `apply.sh` to apply the changes.

## Fail2ban

We use fail2ban to stop SSH scanning and brute-force attempts.

Because fail2ban relies on changing iptables to work, to improve its performance as well as minimize its tampering of iptables rules, we use ipsets for fail2ban.

After stock installation of `fail2ban` package, remove `defaults-debian.conf` and add this file to secure SSH daemon:

```ini title="/etc/fail2ban/jail.d/sshd.conf"
[sshd]
enabled = true
mode    = aggressive
filter  = sshd[mode=%(mode)s]
logpath = /var/log/auth.log
backend = pyinotify
action  = iptables-ipset-proto6[chain="fail2ban"]
```

We provide a pre-created empty chain named `fail2ban` for fail2ban to manipulate (see [iptables](#iptables) above).

To make sure fail2ban rules can be re-applied after reloading iptables manually, we override the systemd service so that fail2ban is restarted whenever the iptables service is restarted.

```ini title="$ systemctl edit fail2ban.service"
[Unit]
BindsTo=netfilter-persistent.service
After=netfilter-persistent.service
```
