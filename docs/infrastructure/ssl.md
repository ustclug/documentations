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

Individual machines that use SSL certificates should pull from the said repository (branch `cert`) and load certificates from there (possibly via symbolic links). The update task is managed by cron.

The DigitalOcean account we use is owned by iBug and has nothing else running.
