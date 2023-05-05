# SSH Certificate Authentication

Discussion: [SSH 升级到证书登陆方案讨论](https://groups.google.com/d/topic/lug-internal/K7bDLKTGHXw/discussion)

Usage: [SSH 证书认证的使用方法](https://groups.google.com/d/topic/lug-internal/2iQQ30qhbQ8/discussion) (See also: [iBug's blog](https://ibug.io/p/30))

## Introduction

An SSH Certificate Authority (CA) is a trusted key pair that issues certificates. It has the same format as a regular SSH private-public key pair (it *is*, in fact). 

Certificates can be used for authentication on both the server side and the client side. But certificates cannot issue new certificates (i.e. no chains), it is the very difference from X.509 certificate system.

## Server setup

### Configure server to accept client certificates {#trustedusercakeys}

First drop our public key to `/etc/ssh/ssh_user_ca`:

```text title="/etc/ssh/ssh_user_ca"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1Bxw9AXoZvc9HTe5o4f7/qOROcmzvlcO5oofoF3pewtRnhNpcd/DwmxSblqpj/cjLYkE32mSCzMYY8X0CRFyMJsgSIDC4i4LXDNU0e8PbB2NIQAAeyfJEU5m/Dn1tPw9WvPtPqHCRvgSwnRfzYngMVWROgV2Qe6pOqTTgetEYfb5gkDc2i1M7yfTp3H3ExfrDKwOKPc/9UYOADMFU6u1fJN+4epLETilHC1ubtBeVi23pn1K+LDy06Gwhq1MLljCM7gFBMrmv894HrOHU4WrzLUlfkiDt2cyXLb4qPWYqilBFLUjU92kjmiI/EwB/8pR1WmdU7FoYpdgBHNr3NT53 LUG-CA
```

Then add the following line to sshd config (Debian 11+):

```sh title="/etc/ssh/sshd_config.d/ustclug.conf"
TrustedUserCAKeys /etc/ssh/ssh_user_ca
```

!!! warning "Old version config (&lt;= Debian 10)"

    On Debian 10 (buster) or older, `sshd_config` does not support the `Include` directive. Thus any extra setting must be added in the main `sshd_config` file directly.

### Issue a server certificate

!!! warning "Warning"

    When signing certificates using OpenSSH &lt;= 8.1, add `-t rsa-sha2-512` to the `ssh-keygen` command. More details can be found here: <https://ibug.io/p/35>

!!! info "Note"

    Some of our servers *may* still be running Debian Jessie, which has OpenSSH 6.7 that does not support SHA-2 certificate algorithms (OpenSSH 7.2 required). Sign with `-t ssh-rsa` instead if you want to log in to such servers.

    **January 2022 update**: We believe we have got rid of all Jessie systems, so this should no longer be the case. 

Copy the file `/etc/ssh/ssh_host_rsa_key.pub` from target server.

Then, run `ssh-keygen` to issue a public key. For example:

```sh
ssh-keygen -s /path/to/ssh_ca \
           -I blog \
           -h \
           -n blog.s.ustclug.org,blog.p.ustclug.org,10.254.0.15,202.141.176.98,202.141.160.98 \
           ssh_host_rsa_key.pub
```

Then, copy the certificate file `ssh_host_rsa_key-cert.pub` back to target server.

At last, add the following lines to sshd config:

```sh title="/etc/ssh/sshd_config.d/ustclug.conf"
HostKey /etc/ssh/ssh_host_rsa_key
HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
```

!!! warning

    See the same warning block [above](#trustedusercakeys).

Certificate will take effect after SSH daemon is reloaded (`systemctl reload ssh`).

## Client setup

Add the following line to your `known_hosts`:

```text title="~/.ssh/known_hosts"
@cert-authority * ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1Bxw9AXoZvc9HTe5o4f7/qOROcmzvlcO5oofoF3pewtRnhNpcd/DwmxSblqpj/cjLYkE32mSCzMYY8X0CRFyMJsgSIDC4i4LXDNU0e8PbB2NIQAAeyfJEU5m/Dn1tPw9WvPtPqHCRvgSwnRfzYngMVWROgV2Qe6pOqTTgetEYfb5gkDc2i1M7yfTp3H3ExfrDKwOKPc/9UYOADMFU6u1fJN+4epLETilHC1ubtBeVi23pn1K+LDy06Gwhq1MLljCM7gFBMrmv894HrOHU4WrzLUlfkiDt2cyXLb4qPWYqilBFLUjU92kjmiI/EwB/8pR1WmdU7FoYpdgBHNr3NT53 LUG-CA
```

And when you log in to a LUG server, it is automatically trusted. If you find a machine that does not support this setup, report it to CTO.

### Issue a client certificate

```sh
ssh-keygen -s /path/to/ssh_ca \
           -I certificate_identity \
           -n principals \
          [-O options] \
          [-V validity_interval] \
           public_key_file
```

For example:

```sh
ssh-keygen -s /path/to/ssh_ca -I "Yifan Gao" -n yifan -V -5m:+365d yifan.pub
```

In general, _certificate\_identity_ is the user's full name, and _principals_ is the system username. The certificate identity is used to identify certificates and is logged in system logs. In addition, one certificate can carry multiply _principals_, like:

```sh
ssh-keygen -s /path/to/ssh_ca -I "Yifan Gao" -n yifan,root,liims -V -5m:+365d yifan.pub
```

It authorizes the certificate owner to login to any server as `yifan`, `root` or `liims` user.

!!! note

    The `liims` principal is used to log into **li**brary **i**nquiry **m**achine**s**.

!!! tip

    The validity interval by default starts at the current system time. Using `-5m:+365d` creates a certificate valid from 5 minutes ago to make up for offset times on other systems. Otherwise it's not much useful to have a validity period starting from a long time ago.

    For security purposes, avoid creating certificates without a defined validity period. It's also recommended to keep validity periods as short as necessary.
