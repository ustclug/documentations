# LUG VPN

## iptables 防火墙管理 {#iptables}

!!! note "本节内容适用于包括 VPN 在内的多个服务器"

    - mirrors2
    - mirrors4
    - gateway-el
    - gateway-nic

### TFTP helper

目前仅对 IPv4 启用。

```shell
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -p udp --dport 69 -j CT --helper tftp
COMMIT
```

```shell title="/etc/modules"
nf_conntrack_tftp
nf_nat_tftp
```

## SSL Certificates {#ssl-certs}

The certificate for `*.vpn.lug.ustc.edu.cn` + `*.vpn.ustclug.org` is acquired with our [certificate infrastructure](../infrastructure/ssl.md) and the vpn server runs `updater.sh` with cron.

Two services running in Docker (strongswan and ocserv) use the certificate, so another cron job exists to copy the certificate files into the Docker volume (`vpn-certs`). The second updater script is listed below:

```shell title="/usr/local/docker_sh/vpn-cert-updater.sh"
--8<-- "vpn/vpn-cert-updater.sh"
```

## DNS

We use AdGuard Home to provide DNS service for the VPN intranet.
The AdGuard Home instance runs in a Docker container (see `lugvpn` directory in `docker-run-script` repo) and is started as:

```shell
cd /root/docker
docker compose up -d
```

### Querylog

AdGuard Home produces *a lot* of content in query log, so we add our custom logrotate configuration to avoid filling up the disk.

```shell title="/etc/logrotate.d/AdGuardHome"
/mnt/vpnlog/AdGuardHome/*.json {
    daily
    rotate 180
    missingok
    copytruncate
    compress
    delaycompress
    sharedscripts
    # use Zstd to compress logfiles
    compresscmd /usr/bin/zstd
    uncompresscmd /usr/bin/unzstd
    # compress options
    compressoptions -12 --long -T0
    # Let extension to be right
    compressext .zst
    create 640 root root
    postrotate
    endscript
}
```
