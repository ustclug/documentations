---
icon: material/note-check
---

# New Server Setup Checklist

## NTP Date

Install either `chrony` or `systemd-timesyncd` (recommended). Usually chrony comes pre-installed so it's easily forgot.

=== "Chrony"

    Replace the default NTP pool with USTC's NTP server `time.ustc.edu.cn`, like this:

    ```shell title="/etc/chrony/chrony.conf" linenums="7"
    # Use Debian vendor zone.
    #pool 2.debian.pool.ntp.org iburst
    server time.ustc.edu.cn iburst
    ```

    Then restart the service:

    ```shell
    systemctl restart chrony
    ```

=== "systemd-timesyncd"

    For Debian 11 and up, we use an override file to configure the NTP server:

    ```shell title="/etc/systemd/timesyncd.conf.d/ustc.conf"
    [Time]
    NTP=time.ustc.edu.cn
    ```

    Then restart the service:

    ```shell
    systemctl restart systemd-timesyncd
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

## Must-installed packages

- systemd-oomd, to avoid OOM stopping admins accessing root shell.
- systemd-coredump, to collect core dumps.
- debug & diagnose tools listed in <https://www.brendangregg.com/blog/2024-03-24/linux-crisis-tools.html>. Specially, ensuring bpf-tools is installed and working.
