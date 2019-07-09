# tinc VPN 配置说明

tinc VPN → LUG 内网的主要构成软件，LDAP 需要用到它（因为 ldap 服务器是个内网服务器）

## 安装

Debian 9+ 可以直接从 apt 源安装 `tinc` 包。安装好后创建 `/etc/tinc/ustclug` 目录并编辑 `/etc/tinc/ustclug/tinc.conf` 如下：

```text
Name = $HOST
Mode = switch
ConnectTo = vm_nfs
ConnectTo = ldap
ConnectTo = board
ConnectTo = dns
```

在 `/etc/tinc/nets.boot` 加入一行 `ustclug`。

从另一台机器上复制 `/etc/tinc/ustclug` 目录中的以下内容：

```text
hosts route.d tinc-up*
```

### 生成密钥

```shell
tincd -n ustclug -K
```

并在 `/etc/tinc/ustclug/hosts/$HOST` 文件中加入一行

```text
Address = [本机的公网IP]
```

然后把这个文件复制到 `{ldap,board,dns}.s.ustclug.org` 三个机器上的对应目录中（显然这需要 root，可以联系 CTO）

### 指定内网 IP

这可咋整