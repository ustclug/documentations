# Tinc VPN 配置说明

Tinc VPN 是 LUG 内网的主要构成软件，LDAP 需要用到它（因为 ldap 服务器是个内网服务器）

## 安装

Debian 9+ 可以直接从 apt 源安装 `tinc` 包。

*不早说这玩意有个 Git 仓库？？*<https://git.lug.ustc.edu.cn/ustclug/tinc-configure>

既然有仓库所以要做的事情比较简单，进入 `/etc/tinc` 目录准备和 Git 仓库同步配置：

```shell
git init
git remote add origin https://git.lug.ustc.edu.cn/ustclug/tinc-configure.git
git fetch origin master
git reset --hard FETCH_HEAD
```

注意 `git reset` 会覆盖部分文件，建议在全新安装 `tinc` 之后进行同步配置。

### 加入主机

首先需要在新主机上生成密钥：

```shell
tincd -n ustclug -K
```

然后在 `/etc/tinc/ustclug/hosts/$HOST` 最后补上一行：

```text
Address = [这台机器的公网IP]
```

把新增的这个文件提交进 Git 仓库，并在 `{ldap,board,gateway-el,gateway-nic}.s.ustclug.org` 等多台机器上通过 `git pull` 更新，并 `systemctl reload tinc@ustclug.service`。

### 内网 IP

**测试的时候**，你可以直接通过 `ifconfig` 等方式指定一个临时的 IP，注意不要与已有的内网 IP 冲突：

```shell
ifconfig 10.254.0.xxx/21 ustclug
```

这时候应该能从其他机器 ping 通这个 IP。

指定静态内网 IP 的正确方法是在 DNS 中添加一条这样的记录：

```text
$ORIGIN s.ustclug.org
<HOST>  600     IN A    <Intranet IP>
```

然后在机器上重启 `systemctl restart tinc@ustclug.service` 就能自动获取了。

## 配置 SSH 侦听内网地址

!!! tip

    对于 Debian 11+ 的系统，建议保持 `sshd_config` 不动，将自定义的配置写入 `sshd_config.d/ustclug.conf`，以减少更新 ssh 软件包时的配置文件冲突。注意如果这么做的话需要把配置文件理的 `Subsystem sftp` 删掉，否则 sshd 会报错“重复指定了 Subsystem sshd”。

以下配置供参考，复制后注意修改 `Match LocalAddress` 后面的内容（内网地址和 AllowGroups 最后的名称）：

```text title="/etc/ssh/sshd_config"
AddressFamily inet
UseDNS no

HostKey /etc/ssh/ssh_host_rsa_key
HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
TrustedUserCAKeys /etc/ssh/ssh_user_ca
RevokedKeys /etc/ssh/ssh_revoked_keys

PasswordAuthentication no
PubkeyAuthentication no
ChallengeResponseAuthentication no
UsePAM yes # LDAP for Debian

AcceptEnv LANG LC_*
X11Forwarding yes
PrintLastLog no
PrintMotd no
Subsystem sftp /usr/lib/openssh/sftp-server

Match LocalAddress 10.254.0.0
    AllowGroups ssh_local super_manager ssh_groupname
    PasswordAuthentication yes
    PubkeyAuthentication yes

# Public IP access = root-only
Match LocalAddress 202.38.95.110,202.141.160.110,202.141.176.110,218.104.71.170
    AllowUsers root
    PubkeyAuthentication yes
    AuthorizedKeysFile /dev/null  # 屏蔽公钥，仅允许证书登录

# For SSH Push trigger
Match User mirror
    AllowUsers mirror
    AuthenticationMethods publickey
    PermitTTY no
    PermitTunnel no
    X11Forwarding no
```

注意 HostCertificate, TrustedUserCAKeys 和 RevokedKeys 这三个文件必须存在，否则 SSH 会出一些问题，例如不能密钥登录只能密码登录。

HostCertificate 需要手动签发一个，另外两个文件从别的机器上复制就行。
