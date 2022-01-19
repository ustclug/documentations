# Proxmox Backup Server

PBS 现在部署在原来的 esxi-5 上面，用作备份用途。其端口号为 8007。

## 创建新用户

PBS 自己的账号体系 (@pbs) 与 PVE (@pve) 不同，如果需要创建新用户，参考以下步骤：

1. `proxmox-backup-manager user create 用户名@pbs --email 邮箱地址@ustclug.org`
2. `proxmox-backup-manager user update 用户名@pbs --password '一个临时的密码'`
3. 使用该用户登录 PBS（此时用户无权限），修改密码；
4. 赋予权限。超级管理员对应的命令是 `proxmox-backup-manager acl update / Admin --auth-id 用户名@pbs`
5. 使用 `proxmox-backup-manager acl list` 确认权限列表。

参考：<https://pbs.proxmox.com/docs/user-management.html>