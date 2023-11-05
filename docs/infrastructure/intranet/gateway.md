# Intranet Gateway

We run gateways in each colocation to provide internet access to intranet-only hosts (VMs and containers).

When configuring VMs and containers, set their gateway according to their colocation:

- East Campus Library (EL): gateway-el (10.254.0.254)
- Network Information Center (NIC): gateway-nic (10.254.0.245)

Gateway-JP is mainly used for HTTP reverse proxy, so that we can provide HTTP services in compliance with PRC regulations.

For server configuration on each gateway, refer to their corresponding documentation:

- [Gateway EL](../../services/gateway-el.md)
- [Gateway NIC](../../services/gateway-nic.md)
- [Gateway JP](../../services/gateway-jp.md)

## Tinc "received packet on ustclug with own address as source address" workaround {#tinc-workaround-1}

After migrating to PVE, we found that sometimes tinc works abnormally within gateway-el and gateway-nic, with following kernel log:

```text
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
bridge: received packet on ustclug with own address as source address (addr:12:34:56:78:90:ab, vlan:0)
net_ratelimit: 2 callbacks suppressed
```

We still don't know the source of this issue. To workaround that, following self-check timer is deployed now:

```shell title="/opt/tinc-check.sh"
#!/bin/bash

restart() {
  systemctl stop tinc@ustclug.service
  sleep 3  # avoid race condition
  systemctl start tinc@ustclug.service
  echo "tinc restarted"
}

dmesg | tail -n 2 | grep 'received packet on ustclug with own address as source address' && restart ||  echo "tinc OK now";
```

```ini title="/etc/systemd/system/tinc-check.service"
[Unit]
Description=Tinc Check and Auto-Restart

[Service]
Type=oneshot
ExecStart=/opt/tinc-check.sh
```

```ini title="/etc/systemd/system/tinc-check.timer"
[Unit]
Description=Tinc Check and Auto-Restart Timer

[Timer]
OnCalendar=minutely
Persistent=true

[Install]
WantedBy=timers.target
```
