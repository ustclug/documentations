# vCenter

vCenter 为维护人员提供了方便的管理所有 ESXi 服务器的界面。需要注意：

- HTML5 版可以完成大多数任务，但是诸如配置警报（可配置邮件警告）、查看 VDP 备份情况等需要 Flash 版本。
- 如果某个同学只有管理某个虚拟机的需求，建议新建账户，单独配置权限。
- vCenter 本身也是一个虚拟机，目前运行在 esxi-5 上。

## 安装 patch

当出现严重的 CVE 且无法简单 workaround 时，建议安装 patch，大致方法：

1. 打快照，最好能手动备份一下。
2. 前往 <https://my.vmware.com/group/vmware/patch> 下载最新版 patch ISO 文件（分类为 VC，需要注册免费账号）；
3. 上传 ISO 文件到 esxi-5 某个 datastore 中，将 ISO 挂载到 VMware vCenter Server Appliance 虚拟机中；
4. 登录 esxi-5 管理界面（不是 vcenter 界面，因为更新的时候 vcenter 会下线），进入 vcenter console。
5. `software-packages stage --iso` 加载补丁文件（实质是一堆 rpm）。
6. `software-packages install --iso` 安装补丁文件。
7. `shell` 进入 bash，`reboot` 重启。
8. 重启后如果进入 5480 端口发现服务状态为未知，手动重启所有服务：`service-control --start --all`
9. 等待一段时间（比较长），期间可能 503/显示服务正在加载中，等等，之后就应该正常了。
10. 别忘了手动备份。

升级时遇到的问题：

1. 无法识别 ISO 为更新的版本：<https://kb.vmware.com/s/article/59659?lang=zh_CN>
2. 「环境尚未准备好更新」：使用 console 的 `software-packages` 更新，查看原因。如果是 root 密码过期，进入 bash，使用 passwd 先重置成新的（然后再改回来），使用 `chage -I -1 -m 0 -M 99999 -E -1 root` 设置永不过期。
