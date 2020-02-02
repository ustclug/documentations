# Authoritative DNS

Services:

* ns-a.ustclug.org
* ns-b.ustclug.org
* ns-c.ustclug.org

Servers:

* ns-a.s.ustclug.org
* ns-b.s.ustclug.org
* (not ns-c)

## Deploy

* Bind configuration:
  <https://github.com/ustclug/auth-dns>
* Bind Dockerfile:
  <https://github.com/zhsj/dockerfile/tree/master/bind9>

The bind configuration repository is only visible to admins because private key is
included.

```
# copy the ssh key https://git.lug.ustc.edu.cn/ustclug/auth-dns/blob/master/git_pull_key
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

Just commit your change to the configuartion repository.
More details can be found in the repository.

## Webhook

Please add a webhook in the configuration repository, so that the DNS record
can be automatically updated when we commit.

The webhook endpoint is http://<server_ip>:9000/hooks/bind, see
<https://github.com/ustclug/auth-dns/settings/hooks> for example.
