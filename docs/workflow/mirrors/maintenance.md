---
icon: material/database-cog
---

# 开源软件镜像站维护方式

科大开源软件镜像站是 [LUG 最重要的服务之一](https://lug.ustc.edu.cn/wiki/lug/services/start)，因此维护操作必须谨慎。

## 重启系统

由于 mirrors 服务量大，重启应提前在 [LUG 服务器新闻站](https://servers.ustclug.org/) 发布公告。

## 安装更新

### 普通更新

多数更新可以直接从 apt 源安装，但是部分软件并非来自 Debian 官方仓库（例如 OpenResty），因此更新策略可能不像 Debian 那么稳定。如果遇到提示配置文件冲突，请尽量选择 3-way merge，如果失败的话可以先 keep local version，然后手动解决合并冲突。

### 内核更新

mirrors 使用了内核模块提供一些功能支持，如 ZFS。因此只要更新了内核，就一定要注意内核模块是否安装成功，如果 apt 安装失败可以手动运行 `dkms autoinstall`，以确保新内核重启时能正确加载必须的内核模块。

## IPMI

地址*暂无*，一般用浏览器直接访问就行了。如果需要接入终端，Dashboard 左边的 Remote Control 有 Launch 按钮。如果浏览器不支持 Java 就会下载一个 `jviewer.jnlp`，自行解决 Java 的安全警告即可使用。

当然如果会用 `ipmitool` 更好，那这一段的说明就交给你来补充了 :)

### `ipmitool` 简介

尽管几乎我们机器的 IPMI 都有 Web 界面，但是 Web 界面不一定靠谱，可能会出现故障。此时，我们可以使用 `ipmitool` 重置 IPMI 的状态（系统配置不会改变）

参考命令：

```
ipmitool -I lan -H IPMI的IP -U 用户名 -a mc reset cold
```

具体详情可以看 `ipmitool` 的 manpage。

另外:

- 据说还可以用它设置串口输出从而实现类似 KVM 的效果，但是没有测试过，也不知道如何实现。
- mirrors3 的 IPMI (iDRAC) 是 broken 的，就算 reset cold 了也没用。
