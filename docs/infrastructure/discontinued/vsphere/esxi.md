# ESXi

现役的 ESXi 还剩 2 台：esxi-2 和 esxi-6，都位于东图机房。

esxi-2 上运行东图网关等服务，esxi-6 上运行 LUG GitLab。esxi-5 上运行诸如 vcenter, 邮件网关, ldap, 备用网关, vSphereDataProtection 备份服务等。

我们正在计划将东图虚拟化方案替换为 Proxmox Virtual Environment。

## 关于快照 {#snapshot}

Best practices: <https://kb.vmware.com/s/article/1025279>，管理虚拟机前务必阅读。
