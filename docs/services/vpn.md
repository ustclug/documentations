# LUG VPN

## iptables 防火墙管理 {#iptables}

!!! note "本节内容适用于包括 VPN 在内的多个服务器"

    - mirrors2
    - mirrors4
    - gateway-el
    - gateway-nic

## SSL Certificates {#ssl-certs}

The certificate for `*.vpn.lug.ustc.edu.cn` + `*.vpn.ustclug.org` is acquired with our [certificate infrastructure](../infrastructure/ssl.md) and the vpn server runs `updater.sh` with cron.

Two services running in Docker (strongswan and ocserv) use the certificate, so another cron job exists to copy the certificate files into the Docker volume (`vpn-certs`). The second updater script is listed below:

```shell title="/usr/local/docker_sh/vpn-cert-updater.sh"
--8<-- "vpn/vpn-cert-updater.sh"
```
