# SSD 固件

数据中心盘的 SSD 近年来有多起因为固件问题导致使用时间过长（几万小时）后盘坏掉的新闻。
这类事件一旦发生，后果极其严重，因为配置新服务器时，一般使用的盘型号是一样的，并且开机时间也是一样的，
因此出现问题之后，所有盘都会在短时间内坏掉，RAID 根本无力回天。
因此以下记录一些固件升级的方法。

## Intel

### 背景

2024 年 1 月 12 日凌晨，在发现两块 Intel SSD S4510/S4610 出现 SMART 错误并且 ZFS 提示读取错误之后紧急进行了固件升级（否则还有 8 块盘也会很快因为类似问题损坏）。由于缺少相关资料，并且 Intel 下架了大量信息，因此花费了很多时间，至凌晨七点完成升级。

??? note "Timeline"

    2024/01/11 04:21 - 收到 smartd 邮件称 `/dev/sdi` 出现 `End-to-End_Error_Count` 错误。

    之后未怀疑是固件问题，只认为是偶发的错误，并且 SSD 仍可正常读取，ZFS 正常纠错，因此当天开始准备采购新 SSD，未进行其他操作。

    2024/01/12 02:51 - 收到 smartd 邮件称 `/dev/sdh` 出现 `End-to-End_Error_Count` 错误。

    之后怀疑是固件问题，并从[浪潮的网站](https://www.inspur.com/lcjtww/2317452/2367100/2367106/472383/2487519/index.html)确认了这一点。
    Dell 提供了修复包，但是无法在 Debian 下安装。Intel/Solidigm 提供的升级工具有许多不同版本，其中 isdct 与 sst 提示升级失败，intelmas 提示当前产品已不再支持。

    在迁移部分重要虚拟机，并确认备份正常后（大致花费了 2 到 2.5 小时），重启对应服务器，尝试使用 Solidigm 提供的「升级启动盘」升级，提示找不到 SSD 而失败。
    之后从 [Solidigm 论坛](https://community.solidigm.com/t5/solid-state-drives-nand/update-s4520-from-7cv10100-to-7cv10111/m-p/23820)了解到需要关闭直通设置。先对 `/dev/sdi` 进行了测试（该盘有 SMART 错误，但是仍可读写），升级成功。之后升级了全部 Intel SSD。

相关涉问题固件版本为 XCV10100。XCV10110 及以上修复了问题。

### 升级方法

Intel 的存储业务已经被 SK Hynix 子公司 Solidigm 收购。其提供了相关工具进行升级。

<https://www.solidigm.com/us/en/support-page/product-doc-cert/ka-00099.html> 提供了 Solidigm 工具支持的产品列表。下载最新版本 Solidigm™ Storage Tool 之后（支持 Debian/Ubuntu），使用以下方法检查所有 SSD 的信息：

```console
sst show -ssd
```

关注每个 SSD 的 `FirmwareUpdateAvailable` 一行是否有更新信息。

使用以下命令升级：

```console
sst load -ssd <SSD 的编号>
```

请注意，该工具不支持 RAID 卡的直通模式。对于 Dell 服务器来说，需要设置如下：

1. 启用 LSI 支持：`sst set -system EnableLSIAdapter=True`
2. 重启进入 BIOS，将 RAID 卡从 HBA 模式切换为 RAID 模式（如果是的话）
3. 将需要升级的盘从 Non-RAID 模式切换为 RAID-Capable（注意不要点成清空所有数据！）
4. 重启进入 recovery 模式，使用 `sst` 进行升级。
5. 升级完成后重启，进入 BIOS 恢复之前的设置（同样注意不要点错！）

