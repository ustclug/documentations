# mirrors1

mirrors1 是 2011 年网络信息中心提供给 LUG 用作初代 mirrors.ustc.edu.cn 服务的机器，是一台曙光 i620r-G

| 参数  |                   配置                   |
| :---: | :--------------------------------------: |
|  CPU  | Intel(R) Xeon(R) CPU E5620 @ 2.40GHz x 2 |
| 内存  |                  48 GB                   |
| 存储  |    LSI Logic MegaRAID SAS 8708EM2 x 2    |
|       |       DFT RS-3016I-S/D30 磁盘阵列        |
| 网络  |    Ethernet Intel 82574L Gigabit x 2     |

[用户手册](https://ftp.ustclug.org/misc/Dawning-I620r-G.pdf)

由于本文编写时（2020 年）该服务器早已不再用作 mirrors（现在是 esxi-5），因此更多的信息暂无从考察。

## IPMI

这台机器的 IPMI 使用条件较为苛刻，特别是它的 Java 控制台只能在 Windows XP，IE 6 和 Java 6 环境下运行。因此我们配置了一个虚拟机镜像[放在 LUG FTP 上](https://ftp.lug.ustc.edu.cn/software/images/old-mirrors-ipmi-runtime.ova)。

使用现代的 HTTP 客户端（包括浏览器和 cURL 等）尝试下载 `viewer.jnlp` 时会遇到问题，原因在于 IPMI 会返回一个错误的 `Content-Length`（约 3 KiB），但 jnlp 文件实际只有 1.6 KiB，使客户端认为文件未完整下载。奇妙的是，IE 6 似乎会忽略这个问题，然后正常打开 Java 控制台。
