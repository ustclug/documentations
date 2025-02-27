# SSL Certificates

Discussion: [#224](https://github.com/ustclug/discussions/issues/224)

Our SSL certificates are automatically renewed on GitHub [ustclug/ssl-cert](https://github.com/ustclug/ssl-cert) (:fontawesome-solid-lock: Private).

We delegate the subdomain `ssl-digitalocean.ustclug.org` to DigitalOcean DNS hosting, and use [acme.sh DNS alias mode](https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode) to issue certificates. For this to work, we have the following CNAME records in place:

```text
_acme-challenge.lug.ustc.edu.cn    ->  lug.ssl-digitalocean.ustclug.org
_acme-challenge.ustclug.org        ->  lug.ssl-digitalocean.ustclug.org
_acme-challenge.proxy.ustclug.org  ->  lug.ssl-digitalocean.ustclug.org

_acme-challenge.vpn.lug.ustc.edu.cn  ->  lugvpn.ssl-digitalocean.ustclug.org
_acme-challenge.vpn.ustclug.org      ->  lugvpn.ssl-digitalocean.ustclug.org

_acme-challenge.mirrors.ustc.edu.cn  ->  mirrors.ssl-digitalocean.ustclug.org
```

Individual machines that use SSL certificates should pull from the said repository (branch `cert`). Certificates may be loaded via symbolic links (for processes running on the host system directly), or copied around from within the updater script (when there are path constraints, e.g. in a Docker container). The update task is managed by cron.

Update script for reference:

```shell title="/etc/ssl/private/.git/update.sh"
#!/bin/sh

cd "/etc/ssl/private"

git fetch -q
if [ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ]; then
  exit 0
fi
git reset --hard '@{u}'

# Display certificate dates. This section is optional
if command -v openssl >/dev/null 2>&1; then
  echo "Cert has been updated. New expiry:"
  for f in */cert.pem; do
    echo "$f:"
    openssl x509 -in "$f" -noout -dates
  done
else
  echo "Cert has been updated."
fi

systemctl reload openresty.service
# Other `cp -a` or `docker restart` commands, etc.
```

For Proxmox VE hosts, as they (by default) don't have access to public internet and therefore cannot pull from GitHub directly, their SSL certificates are fetched with a small twist.
See [Proxmox VE](proxmox/pve.md#ssl) for details.

The DigitalOcean account we use is owned by iBug and has nothing else running.

!!! note "Plan B"

    Hurricane Electric provides [hosted DNS](https://dns.he.net/) zones **for free**, which is also [supported by `acme.sh`](https://github.com/acmesh-official/acme.sh/wiki/dnsapi). This makes HE DNS a feasible alternative should our current dependency (DigitalOcean) fails.

## Exceptions

PXE manages its own certificates with `acme.sh` and validates via HTTP-01 challenge. The certificates are stored in `/etc/acme.sh/pxe.ustc.edu.cn/`.
