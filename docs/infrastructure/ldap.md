# LDAP 服务使用及配置说明

LDAP 是轻量目录访问协议，我们用的软件是 OpenLDAP。

LDAP 的配置很麻烦，所以装了一个网页前端来配置它，网页前端是 GOsa²。

## 密码修改

登录任意一台服务器使用 `passwd` 就可以修改密码，修改的密码在所有机器上实时生效（因为实际是存在 LDAP 数据库里的）。

## GOsa 使用

网页界面位于 [ldap.lug.ustc.edu.cn](https://ldap.lug.ustc.edu.cn/gosa)。

用你的账号登录进去之后，可以在右上角退出，右上角还有两个按钮分别是修改账号信息和修改密码。账号信息第一页大部分是没用的，只有一个登录名是有用的，这是你登录任何地方的用户名。

### Users 和 Groups {#ldap-users-and-groups}

Users 是用来添加和配置用户信息的地方。最主要的功能位于每个 User 的第二页 POSIX，这里可以设置用户的家目录，UID，GID，以及所属的用户组。这里需要注意的地方如下：

- UID，GID 从 2000 开始计数，由于 gosa 不能对 UID 自动增长，所以管理员需要人工增长。方法是登录任意一台机器，运行 `getent passwd` 并观察输出，取最大的 UID + 1 就行了。

    !!! danger "坑"

        小心输出的顺序，最大的 UID 不一定是最后一个（而且事实上经常不是），建议配合 sed, awk, sort 之类的命令妥善处理，例如

        ```shell
        getent -s ldap passwd | sort -t: -k 3n
        ```

        同时还有若干 UID 很大但是离散的特殊账号，很容易分辨。显然新 UID 是 2000 开始连续的最大 UID + 1.

    GID 建议不要每人一个，我们建一个 group，给大家都加进来，这样就只需要考虑 UID 的增长了。目前该 group 为 `ldap_users`，GID 为 2001。

- 建账号之前先注意一下各个服务器上有没有相同的用户名，有的话把原家目录 chown 到新的 UID GID，删除同名用户。

Groups 中以 ssh 开头的组控制对应机器的 ssh 权限，sudo 开头同理。`super_maneger` 组包含所有机器的权限，以及 LDAP 的 admin 身份。加入对应的组即授予相应权限。[已知的 GID](#ldap-known-gids)

### Access Control

这里可以配置 GOsa 的编辑权限，现在这里面只有一个组，是完全权限的。另外，每个项可以设置专门针对这个项的 ACL。

### Sudo rules

这里配置 sudo 权限。这里的语法和 sudoers 一样（请无视 System trust）。特别要说的一点是通过在 System 中加入主机名可以针对每个主机配置权限，这里要填的是主机名而不是域名，具体范例请看里面的 lugsu wikimanager 等项。

其它我没提到的项我也没搞明白怎么用。。。

gosa 的配置文件在 `/etc/gosa/gosa.conf`，它是在第一次运行 gosa 时候自动生成的，但在之后就只能通过手动编辑来修改。由于配置文件几乎没有文档，官方的 FAQ 有好多是错的，所以我基本没动 `:-D`。

### 维护备注

如果发现更新 GOsa 之后，`/gosa` 没有正常工作（比如说直接显示了 PHP 的源代码），可以尝试删除 `/var/spool/gosa/` 中的所有文件，详见 [Gosa broken in Debian stretch](https://github.com/gosa-project/gosa-core/issues/10)。

## LDAP 客户端配置

### Debian 配置方法

!!! warning

    Debian 13 Trixie 是最后一个支持 `sudo-ldap` 的版本，Debian 14 将完全移除 `sudo-ldap`，需要尽快迁移至 `sssd`。

    我们大部分现有的服务器仍在使用 `sudo-ldap`，在下次大版本升级前需要逐步迁移。以下提供使用 `sssd` 的配置方法。

    Ref: <https://packages.debian.org/trixie/sudo-ldap>

#### 软件包安装

Debian 系统安装 `libnss-ldapd`、`libpam-ldapd`、`sssd-ldap`、`libsss-sudo`

!!! note

    更新这些软件包时，注意保留一个 root 终端，更新后可能需要重启 daemon 进程。

!!! note

    如果已经安装了 `sudo-ldap`，请在全部配置完成**之后**运行 `apt install sudo`，迁移回原 `sudo`。

    如果已经安装了 `nscd`，可以在配置完成后将其删除，避免与 `sssd` 冲突。

在安装过程中会被问一些问题（不同版本的 Debian 的问题可能不同）：

- LDAP 服务器地址是 `ldaps://ldap.lug.ustc.edu.cn`
- Base DN 为 `dc=lug,dc=ustc,dc=edu,dc=cn`
    - 协议为版本 3
    - 配置 libnss-ldapd 时有个选 Name services to configure 的，全部选上

#### /etc/ldap/ldap.conf

编辑内容如下：

```shell title="/etc/ldap/ldap.conf"
BASE dc=lug,dc=ustc,dc=edu,dc=cn
URI ldaps://ldap.lug.ustc.edu.cn
SSL yes
TLS_CACERT /etc/ldap/slapd-ca-cert.pem
TLS_REQCERT demand
SUDOERS_BASE ou=sudoers,dc=lug,dc=ustc,dc=edu,dc=cn
```

为了安全性考虑，要以 ldaps 的方式连接 ldap 服务器，同时应配置好证书 (`/etc/ldap/slapd-ca-cert.pem`, 从其它服务器复制一个)

#### /etc/nslcd.conf

注意检查一下此配置文件是否与 `/etc/ldap/ldap.conf` 下的内容相一致，如

```shell title="/etc/nslcd.conf"
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

```yaml
passwd:         compat ldap
group:          compat ldap
shadow:         compat ldap
......
sudoers:        files
```

注意每一项后面的 `ldap`（`sudoers` 一行除外），如果没有要手动加上。

对于使用 sssd 的配置，**注意 `sudoers` 一行需要有 `sss`**，类似于下面这样：

```yaml
sudoers: files sss
```

而如果使用传统的 `sudo-ldap`，那么 `sudoers` 一行应该类似于这样：

```yaml
sudoers:        ldap [SUCCESS=return] files
```

重启一下 `nscd` 和 `nslcd` 服务，此时运行 `getent passwd -s ldap`，应该可以看到 LDAP 中的用户列表，这就说明配置正确了。

#### PAM 配置

如果 PAM 配置错误，可能导致用户无法使用 SSH 登录，甚至连 sudo 也可能挂掉。所以修改 PAM 配置时：

1. 请做好文件备份；
2. 请另开一个 root 终端以防万一。

对于 Debian 7+，只需设置一处。为了登录时自动创建家目录，在 `/etc/pam.d/common-session` 中添加下面这句：

```shell
session required    pam_mkhomedir.so skel=/etc/skel umask=0022
```

#### SSSD 配置

由于 `sudo-ldap` 未来被废弃，sudo 的配置通过 sssd 实现，参考 <https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/sssd-ldap-sudo.html>。

创建 `/etc/sssd/sssd.conf` 并**修改权限为 600**。

```ini title="/etc/sssd/sssd.conf"
--8<-- "sssd.conf"
```

!!! danger "坑"

    需要加上 `[sudo]`，否则 sudo 配置不会生效，这个配置问题导致了修改前在 gateway-nic 上用户无法使用 sudo。

!!! warning "AppArmor (Debian Bookworm)"

    Debian Bookworm 打包中的 SSSD 存在一个小 bug，会导致在有 AppArmor 的系统上 kernel log 刷满 dmesg。解决方法是在 `/etc/apparmor.d/usr.sbin.sssd` 中，`@{PROC} r,` 后面加一行：

    ```shell
    @{PROC}/[0-9]*/cmdline r,
    ```

    然后 `sudo systemctl reload apparmor`。

另外记得像前面在 Debian 中安装介绍到的那样修改 `/etc/nsswitch.conf` 以及 `/etc/nslcd.conf`.

### NSCD 使用说明

在 SSSD 未安装的情况下，NSCD 会提供 LDAP 缓存服务。如果在使用 NSCD 的机器上需要清空 LDAP 缓存，执行以下命令：

```shell
nscd -i passwd
nscd -i group
```

如果 SSSD 安装，`systemctl status sssd` 会显示 SSSD 与 NSCD 同时提供了相关缓存，可能存在冲突问题：

```log
NSCD socket was detected and seems to be configured to cache some of the databases controlled by SSSD [passwd,group,netgroup,services].
```

需要修改 `/etc/nscd.conf`，将提及的 `passwd`, `group`, `netgroup` 和 `services` 的 `enable-cache` 设置为 `no`。

## LDAP CLI 工具使用说明

这里以 `ldappasswd` 为例，其余 ldap 系列指令与其大致相同：

LDAP 利用 dn 来定位一个用户，以下指令可以列出所有用户及其 dn：

```shell
ldapsearch -x -LLL uid=* uid
```

`-x` 指定使用 Simple authentication，即使用密码认证。

如果要修改一个用户的密码，使用：

```shell
ldappasswd -x -D '<executor dn>' -W -S '<target user dn>'
```

`-D '<executor dn>'` 指定了执行者的身份，`-W`/`-S` 指定了接下来询问执行者/目标用户的密码/旧密码。

需要额外注意的是，在 CLI 中添加/删除用户或更改用户密码时需要以 LDAP admin 执行，否则会有报错：

```text
Insufficient access (50) additional info: no write access to parent
```

或是其他的权限不足的错误。

## 部署情况

目前所有服务器均已部署 LDAP

## 已知的 GID {#ldap-known-gids}

GID 信息已过时，以 LDAP 实际配置为准。

| GID  | 名称           | 说明                 |
| ---- | -------------- | -------------------- |
| 2001 | ldap_users     | 所有用户都在这个组里 |
| 1001 | ssh_docker2    | -                    |
| 2013 | ssh_bbs        | -                    |
| 2014 | ssh_linode     | -                    |
| 2101 | ssh_ldap       | -                    |
| 2102 | ssh_blog       | -                    |
| 2103 | ssh_dns        | -                    |
| 2104 | ssh_gitlab     | -                    |
| 2105 | ssh_lug        | -                    |
| 2106 | ssh_vpn        | -                    |
| 2107 | ssh_mirrors    | -                    |
| 2108 | ssh_pxe        | -                    |
| 2109 | ssh_freeshell  | -                    |
| 2110 | ssh_backup     | -                    |
| 2112 | ssh_vmnfs      | -                    |
| 2113 | ssh_homepage   | -                    |
| 2201 | sudo_ldap      | -                    |
| 2202 | sudo_blog      | -                    |
| 2203 | sudo_dns       | -                    |
| 2204 | sudo_gitlab    | -                    |
| 2205 | sudo_lug       | -                    |
| 2206 | sudo_vpn       | -                    |
| 2207 | sudo_mirrors   | -                    |
| 2208 | sudo_pxe       | -                    |
| 2209 | sudo_freeshell | -                    |
| 2210 | sudo_backup    | -                    |
| 2212 | sudo_vmnfs     | -                    |
| 2213 | sudo_homepage  | -                    |
| 2000 | super_manager  | -                    |
| 2999 | nologin        | 不确定这个组有没有用 |

- 从上文的规范来讲，应该从 2000 开始编号 GID，但有些组可能创建者没注意，不过后期再改就不方便了。
- ssh\_\* 这些组，是在每个主机的 sshd_config 里只允许相应的组登陆。
- sudo\_\* 这些组，是在 LDAP sudo rules 里允许了相应的组。

!!! warning "注意事项"

    LDAP 配置完成后，务必确认 sshd\_config 已经限制了公网登录。

---

本文档原始版本复制自 LUG wiki，由张光宇、崔灏、朱晟菁、左格非撰写。
