# AppArmor

## Proxmox kernel + Debian userspace

Proxmox 使用 Ubuntu kernel，但是 Ubuntu kernel 的 apparmor 相比于 Debian kernel 添加了一些 feature，诸如 Unix socket 管理。Debian 的 apparmor 包的 `/etc/apparmor/parser.conf` 默认配置限制了功能集合：

```conf
## Pin feature set (avoid regressions when policy is lagging behind
## the kernel)
policy-features=/usr/share/apparmor-features/features
```

Proxmox 的 lxc 支持包会覆盖 `/usr/share/apparmor-features/features` 为 Ubuntu 的版本，但是如果只安装 Proxmox/Ubuntu kernel，对应的 features 文件就不包含 Unix socket 支持，这会直接导致 Docker 等程序内部无法创建 unix socket 等。

一个 workaround 是注释掉 `/etc/apparmor/parser.conf` 的对应行。

### PVE 的解决方案

后续调查发现 `lxc-pve` 打包了自己的 `/usr/share/apparmor-features/features` 并覆盖了 Debian 的版本，因此我们模仿 `lxc-pve` 的做法把 Debian 的版本覆盖掉，然后下载 Proxmox 的版本：

```shell
dpkg-divert --package lxc-pve --rename --divert /usr/share/apparmor-features/features.stock --add /usr/share/apparmor-features/features
wget -O /usr/share/apparmor-features/features https://github.com/proxmox/lxc/raw/master/debian/features
```
