# Mail Agent

可以配置机器通过 mail.ustclug.org 发件，实现警报的邮件提醒（收件人设置为 alert AT ustclug DOT org）。配置时需要在 mail.s.ustclug.org 上设置 postfix 白名单。

## 常用命令

从队列中删除邮件：`sudo postsuper -d <邮件 ID>`（邮件 ID 可以日志中看到）

更新 `virtual` 表映射：`sudo postmap /etc/postfix/virtual` 后重启 `postfix` 服务。

## mail.ustclug.org 的 DKIM 签名

编辑 `/etc/opendkim/TrustedHosts`，添加内部服务对应的 IP（段）到其中，并 reload `opendkim` 即可。
