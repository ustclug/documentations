---
icon: material/note-check
---

# New Server Setup Checklist

## NTP Date

Install either `chrony` or `systemd-timesyncd`. Usually chrony comes pre-installed so it's easily forgot.

Replace the default NTP pool with USTC's NTP server `time.ustc.edu.cn`, like this:

```shell title="/etc/chrony/chrony.conf" linenums="7"
# Use Debian vendor zone.
#pool 2.debian.pool.ntp.org iburst
server time.ustc.edu.cn iburst
```

## Time zone

Run `dpkg-reconfigure tzdata` and select Asia/Shanghai as the timezone. Reboot the server.

## Use nft-backend for iptables

```shell
update-alternatives --set iptables /usr/sbin/iptables-nft
update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
```

## Update resolv.conf

## Install console-setup

This may have already come with the base system. It's more likely missed if the system is installed from scratch (bootstrapped).
