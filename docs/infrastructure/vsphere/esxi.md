# ESXi

现役的 ESXi 有 3 台：esxi-2 和 esxi-6 位于东图机房，esxi-5 位于网络信息中心机房。

esxi-2 上运行东图网关等服务，esxi-6 上运行 ustclug gitlab。esxi-5 上运行诸如 vcenter, 邮件网关, ldap, 备用网关, vSphereDataProtection 备份服务等。

目前，有计划将东图虚拟化方案更改为 Proxmox Virtual Environment。

## 关于快照 {#about-snapshot}

Best practices: <https://kb.vmware.com/s/article/1025279>，管理虚拟机前务必阅读。

## 机器配置细节

### esxi-5

esxi-5 上于 2021/8 发现自带阵列有两块坏盘，在更换后发现 storage "root"（存放 vcenter 虚拟机，组 RAID 1 后大小 1.8TB）无法正常 rebuild，并且 vcenter 虚拟机的 vmdk 文件有 4 个出现 I/O error。目前 vcenter 虚拟机已经迁移到 storage "data" (RAID10, 7.2 TB)，工作正常。
