# Gateway troubleshooting

## `gateway-el`

### tunnelmonitor

The tunnels used by `gateway-el` is mainly maintained by [tunnelmonitor](https://github.com/ustclug/tunnelmonitor). Its config files are in `/etc/tunnelmonitor`, service is `tunnelmonitor.service`, and log is `/var/log/tunnel_monitor.log`.

When starting, `netfilter-persistent.service` should be run before `tunnelmonitor`. `tunnelmonitor` generates new mangle chains when starting, and pings all tunnels periodically and selects all available tunnels, and generates `statistc` rules.

You check check `/var/log/tunnel_monitor.log` to see if one tunnel has been down. Currently (2021/09), only one tunnel is available among all tunnel settings in `/etc/tunnelmonitor/tunnel.ini`.

### iptables mangle, rt_tables and ip rule

**The following example is for demonstration purposes only.**

You can get current status by `iptables -t mangle -S`. It is expected to see something like this:

```
-A DemonstrateManglePrerouting -m statistic --mode nth --every 1 --packet 0 -j MARK --set-xmark 0x12345/0xffffffff
// ...
-A PREOUT -m mark --mark 0x0 -j DemonstrateManglePrerouting
```

In this case, all packages to `DemonstrateManglePrerouting` chain will get `fwmark` `0x12345` (= `74565`).

Check `ip rule` for that:

```
// ...
10:	from all fwmark 0x12345 lookup ExtraDemoTunnel
// ...
```

You can get tunnel information in `ip a`:

```
29: ExtraDemoTunnel: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none
    inet 192.168.252.17 peer 192.168.253.17/32 brd 192.168.252.17 scope global ExtraDemoTunnel
       valid_lft forever preferred_lft forever
```

Here `192.168.252.17` is the local server of tunnel, and `192.168.253.17` is the remote server.

Let's check `/etc/network/interfaces.d`:

```
$ cat /etc/network/interfaces.d/03ExtraDemoTunnel
auto ExtraDemoTunnel
iface ExtraDemoTunnel inet static
	address 192.168.252.17
	netmask 255.255.255.255
	pre-up ip link add dev $IFACE type wireguard
	post-down ip link del dev $IFACE
	up wg set $IFACE listen-port 4601 private-key /etc/wireguard/privkey peer pkeypkeypkeypkeypkeypkeypkeypkeypkeypkeypkey endpoint 23.3.3.3:4600 allowed-ips 0.0.0.0/0
	up ip route replace default dev $IFACE table $IFACE
	up ip rule add from all fwmark 74565 table $IFACE prio 10
	pointopoint 192.168.253.17
```

Here we know that this is a wireguard tunnel, and the endpoint is `23.3.3.3:4600`. The fwmark here is `74565` (in decimal).

Why is `74565` set? Let's check `/etc/iproute2/rt_tables`!

```
// ...
74565	ExtraDemoTunnel
// ...
```

For wireguard, you can use `wg` to check status. If you find that the "received" is 0 in transferred, something is going wrong.
