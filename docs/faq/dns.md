# DNS 域名解析问题

## 错误的解析结果 {#wrong-dns-result}

我们的 DNS 是分校内外、分 ISP 解析的。有时候会遇到校内访问解析到校外，可能的原因是

!!! bug "`/etc/resolv.conf` 顺序不对"

    iBug 在 2020 年 5 月 21 日修了 gw-el 和 mirrors2，这两个机器上原先排在最前面的 nameserver 就是 8.8.4.4 或者 1.1.1.1 之类的

    我们的权威服务器两个在校内一个在国内，因此校内机器应该优先从校内解析。把 202.38.64.1 / 2001:da8:d800::1（学校的 DNS）放最前面肯定没错

如果 IPv4 解析正确但是 IPv6 还是解析到校外的话，

!!! bug "`/etc/resolv.conf` 缺少 IPv6 条目"

    taoky 在 2020 年 5 月 29 日发现的，mirrors2 上访问 servers.ustclug.org 返回 Cloudflare 的 522 错误页面（此时[日本反代挂掉了](https://github.com/ustclug/discussions/issues/325)），经查尽管 IPv4 正确解析到了 gw-el 上，但是 IPv6 还是解析到了 Cloudflare 上，且 nslookup 和 dig 等工具输出看起来都是对的。

    排查发现 `/etc/resolv.conf` 里没有 IPv6 的服务器条目，在靠前的位置插入 `nameserver 2001:da8:d800::1` 后解决。

    手动清空本机的 DNS 缓存：`nscd -i hosts`

有时候可能会在 DNS 更新后随机解析出新旧结果，可能的原因是

!!! bug "ns-a 没更新"

    ns-a 机器比较老旧，网络可能不顺畅，手动把 ns-a 更新一下就行了（
