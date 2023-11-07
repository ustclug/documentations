# Authoritative DNS

Services (Servers):

* ns-a.ustclug.org (ns-a.s.ustclug.org)
* ns-b.ustclug.org (ns-b.s.ustclug.org)
* ns-c.ustclug.org (*something else*)

All three servers are dedicated to DNS service and run no other services.

## Deploy

* Bind configuration: :fontawesome-solid-lock:
  <https://github.com/ustclug/auth-dns>
* Bind Dockerfile:
  <https://github.com/zhsj/dockerfile/tree/master/bind9>

The bind configuration repository is only visible to admins because private key is included.

```sh
# copy the ssh key https://github.com/ustclug/auth-dns/blob/master/git_pull_key
# to ~/.ssh/id_ed25519

# now get the conf
git clone git@github.com:ustclug/auth-dns.git /var/lib/bind

# delete the ssh key
rm ~/.ssh/id_ed25519
```

```
docker run --restart=always -v /var/lib/bind/:/etc/bind \
       --net host -it -d --name=auth-dns zhusj/bind9
```

## Update DNS Record

Just commit your changes to the configuration repository.
More details can be found in the repository.

## Webhook

Please add a webhook in the configuration repository, so that the DNS record
can be automatically updated when commits are pushed.

The webhook endpoint is `http://<server_ip>:9000/hooks/bind`, see
<https://github.com/ustclug/auth-dns/settings/hooks> for examples.
