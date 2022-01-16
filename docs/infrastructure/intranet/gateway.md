# Intranet Gateway

We run gateways in each colocation to provide internet access to intranet-only hosts (VMs and containers).

When configuring VMs and containers, set their gateway according to their colocation:

- East Campus Library (EL): gateway-el (10.254.0.254)
- Network Information Center (NIC): gateway-nic (10.254.0.245)

Gateway-JP is mainly used for HTTP reverse proxy, so that we can provide HTTP services in compliance with PRC regulations.

For server configuration on each gateway, refer to their corresponding documentation:

- [Gateway EL](../../services/gateway-el.md)
- [Gateway NIC](../../services/gateway-nic.md)
- Gateway JP (missing)
