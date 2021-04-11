# SSL Certificates

Discussion: [#224](https://github.com/ustclug/discussions/issues/224)

Our SSL certificates are automatically renewed on GitHub [ustclug/ssl-cert](https://github.com/ustclug/ssl-cert).

We delegate the subdomain `ssl-digitalocean.ustclug.org` to DigitalOcean DNS hosting, and use [acme.sh DNS alias mode](https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode) to issue certificates. For this to work, we have the following CNAME records in place:

```text
_acme-challenge.lug.ustc.edu.cn    ->  lug.ssl-digitalocean.ustclug.org
_acme-challenge.ustclug.org        ->  lug.ssl-digitalocean.ustclug.org
_acme-challenge.proxy.ustclug.org  ->  lug.ssl-digitalocean.ustclug.org

_acme-challenge.mirrors.ustc.edu.cn  ->  mirrors.ssl-digitalocean.ustclug.org
```

Individual machines that use SSL certificates should pull from the said repository (branch `cert`). Certificates may be loaded via symbolic links (for processes running on the host system directly), or copied around from within the updater script (when there are path constraints, e.g. in a Docker container). The update task is managed by cron.

Update script for reference:

```shell
#!/bin/sh

cd "/etc/ssl/private"

git remote update > /dev/null
if [ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ]; then
  exit 0
fi

echo "Cert has been updated."
systemctl reload openresty.service
# Other `cp -a` or `docker restart` commands, etc.
```

The DigitalOcean account we use is owned by iBug and has nothing else running.

!!! note "Plan B"

    Hurricane Electric provides [hosted DNS](https://dns.he.net/) zones **for free**, which is also [supported by `acme.sh`](https://github.com/acmesh-official/acme.sh/wiki/dnsapi). This makes HE DNS a feasible alternative should our current Dependency (DigitalOcean) fails for whatever reason.
