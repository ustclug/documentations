# Apparmor

## Proxmox kernel + Debian userspace

Proxmox 使用 Ubuntu kernel，但是 Ubuntu kernel 的 apparmor 相比于 Debian kernel 添加了一些 feature，诸如 Unix socket 管理。Debian 的 apparmor 包的 `/etc/apparmor/parser.conf` 默认配置限制了功能集合：

```conf
## Pin feature set (avoid regressions when policy is lagging behind
## the kernel)
policy-features=/usr/share/apparmor-features/features
```

Proxmox 的 lxc 支持包会覆盖 `/usr/share/apparmor-features/features` 为 Ubuntu 的版本，但是如果只安装 Proxmox/Ubuntu kernel，对应的 features 文件就不包含 Unix socket 支持，这会直接导致 Docker 等程序内部无法创建 unix socket 等。

一个 workaround 是注释掉 `/etc/apparmor/parser.conf` 的对应行。
