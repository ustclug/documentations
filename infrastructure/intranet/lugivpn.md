# LUG Intranet VPN

service: intranet.ustclug.org

server: board.s.ustclug.org

## Introduction

Server intranet is a closed network, which cannot be accessed from Internet.  LUGI VPN helps maintainer get access to intranet temporarily.

LUGI VPN is running in Banana Pi, the only ARM architecture device we owned. Using OpenVPN protocal, authorizing via LDAP.

## Configuration

OpenVPN LDAP auth plugin config `/etc/openvpn/auth-ldap.conf`:

```
<LDAP>
	URL             ldaps://ldap.ustclug.org
	Timeout         15
	FollowReferrals yes
	TLSCACertFile   /etc/ldap/ssl/slapd-ca-cert.pem
</LDAP>

<Authorization>
	BaseDN          "ou=people,dc=lug,dc=ustc,dc=edu,dc=cn"
	SearchFilter    "(uid=%u)"
	RequireGroup    false
</Authorization>
```

In openvpn configuration:

```
...
plugin /usr/lib/openvpn/openvpn-auth-ldap.so /etc/openvpn/auth-ldap.conf
```

Servers intranet is a layer 2 network without default gateway. So NAT is needed:

```sh
iptables -t nat -A POSTROUTING -s 10.254.248.0/22 -d 10.254.0.0/21 -j MASQUERAD
```

