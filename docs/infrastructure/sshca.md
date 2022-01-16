# SSH Certificate Authentication

discussion: [SSH 升级到证书登陆方案讨论](https://groups.google.com/d/topic/lug-internal/K7bDLKTGHXw/discussion)

usage: [SSH 证书认证的使用方法](https://groups.google.com/d/topic/lug-internal/2iQQ30qhbQ8/discussion)

## Introduction

There are two types of SSH Certificate:

- Root certificate
- Host certificate

Root certificate can be used to issue a host certificate and has the same format as a regular SSH private-public key pair. Host certificate can be used for authentication on both server side and client side. But certificates cannot issue new certificates (i.e. no chains), it is the very difference from X.509 certificate system.

## Trust all LUG servers in one go

Add the following line to your `known_hosts`:

```text
@cert-authority * ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1Bxw9AXoZvc9HTe5o4f7/qOROcmzvlcO5oofoF3pewtRnhNpcd/DwmxSblqpj/cjLYkE32mSCzMYY8X0CRFyMJsgSIDC4i4LXDNU0e8PbB2NIQAAeyfJEU5m/Dn1tPw9WvPtPqHCRvgSwnRfzYngMVWROgV2Qe6pOqTTgetEYfb5gkDc2i1M7yfTp3H3ExfrDKwOKPc/9UYOADMFU6u1fJN+4epLETilHC1ubtBeVi23pn1K+LDy06Gwhq1MLljCM7gFBMrmv894HrOHU4WrzLUlfkiDt2cyXLb4qPWYqilBFLUjU92kjmiI/EwB/8pR1WmdU7FoYpdgBHNr3NT53 LUG-CA
```

And when you log in to a LUG server, it is automatically trusted. If you find a machine that does not support this setup, report it to CTO.

## Issue a server certificate

!!! warning "Warning"

    When signing certificates using OpenSSH &lt;= 8.1, add `-t rsa-sha2-512` to the `ssh-keygen` command. More details can be found here: <https://ibug.io/p/35>

!!! warning "Warning 2"

    Some of our servers are still running Debian Jessie, which has OpenSSH version 6.7 that does not support SHA-2 certificate algorithms (OpenSSH 7.2 required). Sign with `-t ssh-rsa` instead if you want to log in to such servers.

Copy the file `/etc/ssh/ssh_host_rsa_key.pub` from target server.

Then, run `ssh-keygen` to issue a public key. For example:

```sh
ssh-keygen -s /path/to/ssh_ca -I blog -h -n blog.s.ustclug.org,blog.p.ustclug.org,10.254.0.15,202.141.176.98,202.141.160.98 ssh_host_rsa_key.pub
```

Then, copy the certificate file `ssh_host_rsa_key-cert.pub` back to target server.

At last, add the following lines to `/etc/ssh/sshd_config`:

```con
HostKey /etc/ssh/ssh_host_rsa_key
HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
```

Certificate will take effect after SSH daemon is reloaded (`systemctl reload ssh`).

## Issue a client certificate

```sh
ssh-keygen -s /path/to/ssh_ca -I certificate_identity -n principals -O option -V validity_interval public_key_file
```

For example:

```
ssh-keygen -s /path/to/ssh_ca -I "Yifan Gao" -n yifan -V +365d yifan.pub
```

In general, _certificate\_identity_ is user full name, and _principals_ is the user name. In addition, one user can own multiply _principals_ in one certificate, like:

```
ssh-keygen -s /path/to/ssh_ca -I "Yifan Gao" -n yifan,root,liims -V +365d yifan.pub
```

It authorizes the certificate owner to login to any server with `yifan`, `root` or `liims` username.

!!! tip

    `liims` principal is used to login to library inquiring machine.
