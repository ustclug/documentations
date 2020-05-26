# LDAP 服务使用及配置说明

LDAP 是轻量目录访问协议，我们用的软件是 OpenLDAP。

LDAP 的配置很麻烦，所以装了一个网页前端来配置它，网页前端是 GOsa²。

## 密码修改

登录任意一台服务器使用 `passwd` 就可以修改密码，修改的密码在所有机器上实时生效（因为实际是存在 LDAP 数据库里的）。

## GOsa 使用

网页界面位于 [ldap.lug.ustc.edu.cn](https://ldap.lug.ustc.edu.cn/gosa)。

用你的账号登录进去之后，可以在右上角退出，右上角还有两个按钮分别是修改账号信息和修改密码。账号信息第一页大部分是没用的，只有一个登录名是有用的，这是你登录任何地方的用户名。

### Users 和 Groups

Users 是用来添加和配置用户信息的地方。最主要的功能位于每个 User 的第二页 POSIX，这里可以设置用户的家目录，UID，GID，以及所属的用户组。这里需要注意的地方如下：

* UID，GID 从 2000 开始计数，由于 gosa 不能对 UID 自动增长，所以管理员需要人工增长。方法是登录任意一台机器，运行 `getent passwd` 并观察输出，取最大的 UID +1 就行了。

    !!! danger "坑"

        小心输出的顺序，最大的 UID 不一定是最后一个（而且事实上经常不是），建议配合 sed, awk, sort 之类的命令妥善处理，例如

        ```shell
        getent passwd | cut -d: -f3 | sort -n
        ```

  GID 建议不要每人一个，我们建一个 member 组，给大家都加进来，这样就只需要考虑 UID 的增长了。

* 建账号之前先注意一下各个服务器上有没有相同的用户名，有的话把原家目录 chown 到新的 UID GID，删除同名用户。

### Access Control

这里可以配置 gosa 的编辑权限，现在这里面只有一个组，是完全权限的。另外，每个项可以设置专门针对这个项的 ACL。

### Sudo rules

这里配置 sudo 权限。这里的语法和 sudoers 一样（请无视 System trust）。特别要说的一点是通过在 System 中加入主机名可以针对每个主机配置权限，这里要填的是主机名而不是域名，具体范例请看里面的 lugsu wikimanager 等项。

其它我没提到的项我也没搞明白怎么用。。。

gosa 的配置文件在 `/etc/gosa/gosa.conf`，它是在第一次运行 gosa 时候自动生成的，但在之后就只能通过手动编辑来修改。由于配置文件几乎没有文档，官方的 FAQ 有好多是错的，所以我基本没动:-D。

### 维护备注

如果发现更新 GOsa 之后，`/gosa` 没有正常工作（比如说直接显示了 PHP 的源代码），可以尝试删除 `/var/spool/gosa/` 中的所有文件，详见 [Gosa broken in Debian stretch](https://github.com/gosa-project/gosa-core/issues/10)。

## LDAP 客户端配置

### Debian 配置方法

#### 软件包安装

Debian 7 以上系统安装 libnss-ldapd libpam-ldapd sudo-ldap

注 ：更新这些软件包时，注意保留一个root终端，更新后可能需要重启daemon进程

在安装过程中会被问一些问题（不同版本的 Debian 的问题可能不同）：

- LDAP 服务器地址是 `ldaps://ldap.lug.ustc.edu.cn`
- Base DN 为 `dc=lug,dc=ustc,dc=edu,dc=cn`
    - 协议为版本 3
    - 配置 libnss-ldapd 时有个选 Name services to configure 的，全部选上

#### /etc/ldap/ldap.conf

编辑 `/etc/ldap/ldap.conf` 内容如下

```
BASE dc=lug,dc=ustc,dc=edu,dc=cn
URI ldaps://ldap.lug.ustc.edu.cn
SSL yes
TLS_CACERT /etc/ldap/slapd-ca-cert.pem
TLS_REQCERT demand
SUDOERS_BASE ou=sudoers,dc=lug,dc=ustc,dc=edu,dc=cn
```

为了安全性考虑，要以 ldaps 的方式连接 ldap 服务器,同时应配置好证书 (`/etc/ldap/slapd-ca-cert.pem`, 从其它服务器复制一个)

#### /etc/sudo-ldap.conf

这个文件应该直接软链接到 `/etc/ldap/ldap.conf`，通常 dpkg 已经为你创建好了。

#### /etc/nslcd.conf

注意检查一下此配置文件是否与 `/etc/ldap/ldap.conf` 下的内容相一致，如

```
uid nslcd
gid nslcd
uri ldaps://ldap.lug.ustc.edu.cn
base dc=lug,dc=ustc,dc=edu,dc=cn
ssl on
tls_reqcert demand
tls_cacertfile /etc/ldap/slapd-ca-cert.pem
```

#### /etc/nsswitch.conf

安装软件包时，安装脚本已经处理过该文件。检查一下内容，大致为：

```
passwd:         compat ldap
group:          compat ldap
shadow:         compat ldap
......
sudoers:        files ldap
```

注意每一项后面的 `ldap`，如果没有要手动加上。不太清楚具体含义，反正给每一项都加上 `ldap` 是没有问题的。

重启一下 `nscd` 和 `nslcd` 服务，此时运行 `getent passwd`，应该可以看到比 `/etc/passwd` 更多的内容，这就说明配置正确了。

#### PAM 配置

如果 PAM 配置错误，可能导致用户无法使用 SSH 登录，甚至连 sudo 也可能挂掉。所以修改 PAM 配置时：

1. 请做好文件备份；
2. 请另开一个 root 终端以防万一。

对于 Debian 7+，只需设置一处。为了登录时自动创建家目录，在 `/etc/pam.d/common-session` 中添加下面这句：

```
session required    pam_mkhomedir.so skel=/etc/skel umask=0022
```

对于 Debian 5，请查阅本文档的 Git 记录。

### CentOS 配置方法

通过 yum 安装 openldap openldap-clients nss_ldap nss-pam-ldap

以 root 身份执行

```shell
authconfig --enablecache \
       --enableldap \
       --enableldapauth \
       --ldapserver="ldaps://ldap.lug.ustc.edu.cn/" \
       --ldapbasedn="dc=lug,dc=ustc,dc=edu,dc=cn" \
       --enableshadow \
       --enablemkhomedir \
       --enablelocauthorize \
       --update
```

注意，由于 authconfig 的 bug，上一条命令的执行环境必须是 `LC_ALL=en_US.UTF-8`

Sudo 的配置是通过 sssd 实现的，参考 <https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/sssd-ldap-sudo.html>

安装 sssd libsss\_sudo
将 `/usr/share/doc/sssd-common-xxx/sssd-example.conf` 复制到 `/etc/sssd/sssd.conf` 并修改权限为 600。

```diff
[zguangyu@pxe ~]$ sudo diff /usr/share/doc/sssd-common-1.14.0/sssd-example.conf /etc/sssd/sssd.conf
3c3
< services = nss, pam
---
> services = nss, pam, sudo
8c8
< ; domains = LDAP
---
> domains = LDAP
15,17c15,17
< ; [domain/LDAP]
< ; id_provider = ldap
< ; auth_provider = ldap
---
> [domain/LDAP]
> id_provider = ldap
> auth_provider = ldap
22,24c22,25
< ; ldap_schema = rfc2307
< ; ldap_uri = ldap://ldap.mydomain.org
< ; ldap_search_base = dc=mydomain,dc=org
---
> ldap_schema = rfc2307
> ldap_uri = ldaps://ldap.lug.ustc.edu.cn/
> ldap_search_base = dc=lug,dc=ustc,dc=edu,dc=cn
> ldap_sudo_search_base = ou=sudoers,dc=lug,dc=ustc,dc=edu,dc=cn
30c31
< ; cache_credentials = true
---
> cache_credentials = true
```

另外记得像前面在 Debian 中安装介绍到的那样修改 `/etc/nsswitch.conf` 以及 `/etc/nslcd.conf`.

### NSCD 使用说明

NSCD 是用于 LDAP 缓存的服务，目前在 mirrors 上的配置是保持 30 天。这导致的问题是每当 ldap 服务器上做出修改的时候需要在 mirrors 上执行 <s>(目前 mirrors 服务器暂未配置 LDAP 认证。)</s>

```shell
nscd -i passwd
nscd -i group
```

参考：<https://wiki.debian.org/LDAP/NSS>

## 部署情况

目前所有服务器均已部署 LDAP

## 已知的 GID

| GID  | 名称            | 说明       |
| ---- | --------------- | ---------- |
| 2001 | ldap\_users     | 所有用户都在这个组里 |
| 1001 | ssh\_docker2    | -          |
| 2013 | ssh\_bbs        | -          |
| 2014 | ssh\_linode     | -          |
| 2101 | ssh\_ldap       | -          |
| 2102 | ssh\_blog       | -          |
| 2103 | ssh\_dns        | -          |
| 2104 | ssh\_gitlab     | -          |
| 2105 | ssh\_lug        | -          |
| 2106 | ssh\_vpn        | -          |
| 2107 | ssh\_mirrors    | -          |
| 2108 | ssh\_pxe        | -          |
| 2109 | ssh\_freeshell  | -          |
| 2110 | ssh\_backup     | -          |
| 2112 | ssh\_vmnfs      | -          |
| 2113 | ssh\_homepage   | -          |
| 2201 | sudo\_ldap      | -          |
| 2202 | sudo\_blog      | -          |
| 2203 | sudo\_dns       | -          |
| 2204 | sudo\_gitlab    | -          |
| 2205 | sudo\_lug       | -          |
| 2206 | sudo\_vpn       | -          |
| 2207 | sudo\_mirrors   | -          |
| 2208 | sudo\_pxe       | -          |
| 2209 | sudo\_freeshell | -          |
| 2210 | sudo\_backup    | -          |
| 2212 | sudo\_vmnfs     | -          |
| 2213 | sudo\_homepage  | -          |
| 2000 | super\_manager  | -          |
| 2999 | nologin         | 不确定这个组有没有用 |


* 从上文的规范来讲，应该从 2000 开始编号 GID，但有些组可能创建者没注意，不过后期再改就不方便了。
* ssh\_* 这些组，是在每个主机的 sshd\_config 里只允许相应的组登陆。
* sudo\_* 这些组，是在 LDAP sudo rules 里允许了相应的组。

---

本文档原始版本复制自 LUG wiki，由张光宇、崔灏、朱晟菁、左格非撰写。
