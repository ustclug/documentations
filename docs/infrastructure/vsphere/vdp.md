# VDP

当我们说到 VDP 的时候，我们到底在指什么？为了避免歧义，以下做了一些定义：

- vdp -> 特指位于东图的 NFS 服务器。
- vdp2 -> 特指位于网络信息中心的虚拟机备份阵列。
- vdp 备份程序、vdp 备份虚拟机、vSphereDataProtection -> 特指运行在 esxi-5 上的 vdp 备份服务。

vdp2 挂接在 esxi-5 上，esxi-5 源于老 mirrors（mirrors2 之前的一代机器）。vSphereDataProtection 版本为 6.1.5。

当 vdp 备份程序出现奇怪的问题的时候，重启 vdp 备份虚拟机绝大多数时候能够解决问题。重启耗时非常长，需要做好心理准备。

备份时，vdp 备份程序会为虚拟机新建一个 snapshot，之后从 snapshot 传输备份。偶尔 snapshot 不会被正常删除，而大量或长时间存放的 snapshot 会给性能带来负面影响，所以如果发现此类情况，在确认备份不再进行后，需要删除 snapshot，同时保持机器在线（在关机情况下整合磁盘时无法开机！）。

参考资料：<https://docs.vmware.com/en/VMware-vSphere/6.5/rn/data-protection-615-release-notes.html>

**VDP 备份虚拟机已经 EOL。访问 vcenter 中的 VDP 插件需要使用 Adobe Flash。**

## 备份计划

目前的备份计划如下：

- 东图除 gitlab 以外的虚拟机，esxi-5 活跃的虚拟机，以及 hackergame web 虚拟机每日备份一次。
- gitlab 每周备份一次。（因为它太大了）

