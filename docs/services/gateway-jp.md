# Gateway: Japan (`gateway-jp`)

!!! info "This page is currently a stub."

## Network configuration

### iptables

See [Gateway NIC](gateway-nic.md#iptables)

Blacklists are also managed with `ipset`, see `/root/iptables`.

### sysctl

When first applying iptables rules, we experienced severe performance degradation. Dmesg was flooded with messages like this:

```text
nf_conntrack: nf_conntrack: table full, dropping packet
```

So we increased this sysctl setting:

```shell title="/etc/sysctl.d/00-ustclug.conf"
net.nf_conntrack_max = 262144
```
