# Proxmox Backup Server (PBS)

PBS 现在部署在 esxi-5 上面，用作虚拟机备份，web 界面的端口号为 8007（HTTPS only）。

!!! info

    本页面记录 Proxmox Backup Server 软件相关，以及 Proxmox VE 虚拟机相关的资料。关于 esxi-5 的系统配置信息记录在 [Proxmox VE](pve.md#esxi-5) 页面。

## 安装 PBS

PBS 可以使用安装光盘 iso 安装或直接加装在现有的对应版本的 Debian 系统上，这两种安装方式都有官方的[说明文档][pbs-installation]。

我们的 esxi-5 是使用 PVE 的安装盘先装成 PVE，再在上面额外加装 PBS 的。由于 PVE 和 PBS 共享了大量组件，因此在 PVE 上加装 PBS 就只剩下很简单的一些步骤了：

```shell
echo "deb http://mirrors.ustc.edu.cn/proxmox/debian/pbs bullseye pbs-no-subscription" > /etc/apt/sources.list.d/pbs.list
apt update
apt install proxmox-backup-server
```

该过程仅安装了总量为 150+ MB 的 7 个包，就有 PBS 可用了。

  [pbs-installation]: https://pbs.proxmox.com/docs/installation.html

## 创建新用户 {#pbs-new-user}

PBS 自己的账号体系 (Realm pbs) 与 PVE (Realm pve) 互相不通，如果需要创建新的 PBS 用户，可以通过 SSH 登录，然后参考以下步骤：

1. `proxmox-backup-manager user create 用户名@pbs --email 邮箱地址@ustclug.org`
2. `proxmox-backup-manager user update 用户名@pbs --password '一个临时的密码'`
3. 使用该用户登录 PBS（此时用户无权限），修改密码；
4. 赋予权限。超级管理员对应的命令是 `proxmox-backup-manager acl update / Admin --auth-id 用户名@pbs`
5. 使用 `proxmox-backup-manager acl list` 确认权限列表。

参考：<https://pbs.proxmox.com/docs/user-management.html>

!!! tip

    当然，你也可以 SSH 登录后修改 root 密码，再用 root@pam 的账号登录 web 界面进行操作。

特别地，由于 PBS 和 PVE 同时安装在 esxi-5 上，因此它们可以共享 esxi-5 上的 Linux 用户（即 Linux PAM standard authentication）。

## 设置 Datastore {#pbs-add-datastore}

PBS 上的虚拟机备份单元是小块的 chunk，也依赖这个设计实现增量备份，所以虚拟机备份（Datastore）的后端都是目录。添加 Datastore 只需要指定一个目录，取一个（简短的）名字就可以了。建议不要使用文件系统的根目录作为 Datastore，可以创建一个 `pbs` 文件夹用作 Datastore，参考下面所述的 esxi-5 上的配置。

目前在 esxi-5 上配置了以下 datastore：

- `/mnt/raid1/pbs`：挂载点为 `/mnt/raid1`，是 esxi-5 机身的两块快要坏掉的 2 TB HDD RAID-1，**已经挂了**；
- `/mnt/data/pbs`：挂载点为 `/mnt/data`，是一个容量为 7 TB 的机身 HDD 阵列；
- `/mnt/vdp2/pbs`：挂载点为 `/mnt/vdp2`，是一个容量为 14 TB 的 iSCSI 外置 HDD 阵列，是我们目前备份虚拟机的主要存储。
