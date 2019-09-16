# SSH Certificate Authentication

discussion:  [SSH升级到证书登陆方案讨论](https://groups.google.com/d/topic/lug-internal/K7bDLKTGHXw/discussion)

usage: [SSH证书认证的使用方法](https://groups.google.com/d/topic/lug-internal/2iQQ30qhbQ8/discussion)

## Introduction

There are two types of SSH Certificate:

* Root certificate
* Host certificate

Root certificate can only be used to issue a host certificate. Host certificate can be used for authentication on both server side and client side. But host certificate cannot issue a new certificate, it is the very difference from x509 certificate.

Root certificate is stored in [cuihaoleo](https://github.com/cuihaoleo)'s loongson laptop. And [knight42](https://github.com/knight42) have another backup.

## Trust all LUG servers in one go

Add the following line to your `known_hosts`:

```text
@cert-authority * ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1Bxw9AXoZvc9HTe5o4f7/qOROcmzvlcO5oofoF3pewtRnhNpcd/DwmxSblqpj/cjLYkE32mSCzMYY8X0CRFyMJsgSIDC4i4LXDNU0e8PbB2NIQAAeyfJEU5m/Dn1tPw9WvPtPqHCRvgSwnRfzYngMVWROgV2Qe6pOqTTgetEYfb5gkDc2i1M7yfTp3H3ExfrDKwOKPc/9UYOADMFU6u1fJN+4epLETilHC1ubtBeVi23pn1K+LDy06Gwhq1MLljCM7gFBMrmv894HrOHU4WrzLUlfkiDt2cyXLb4qPWYqilBFLUjU92kjmiI/EwB/8pR1WmdU7FoYpdgBHNr3NT53 LUG-CA
```

And when you log in to a LUG server, it is automatically trusted. If you find a machine that does not support this setup, report it to CTO.

## issue a server certificate

copy the `/etc/ssh/ssh_host_rsa_key.pub` from target server. (salt is your friend)

Then, run `ssh-keygen` to issue a public key. For example:

```sh
ssh-keygen -s /path/to/ssh_ca -I blog -h -n blog.s.ustclug.org,blog.p.ustclug.org,10.254.0.15,202.141.176.98,202.141.160.98 ssh_host_rsa_key.pub
```

Then, copy the certificate file `ssh_host_rsa_key-cert.pub` back to target server.

At last, add the following line to `/etc/ssh/sshd_config`:

```con
HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
```

Certificate will take effect after ssh daemon is restarted.

## issue a client certificate

```sh
ssh-keygen -s /path/to/ssh_ca -I certificate_identity -n principals -O option -V validity_interval public_key_file
```

For example:

```
ssh-keygen -s /path/to/ssh_ca -I "Yifan Gao" -n yifan -V +365d yifan.pub
```

In general,  *certificate_identity* is user full name, and *principals* is the LDAP user name. In addition, one user can own multiply *principals* in one certificate, like:

```
ssh-keygen -s /path/to/ssh_ca -I "Yifan Gao" -n yifan,root,liims -V +365d yifan.pub
```

It authorizes the certificate owner to login server with yifan, root and liims username.

*tip: "liims" principal is used to login to library inquiring machine.*

