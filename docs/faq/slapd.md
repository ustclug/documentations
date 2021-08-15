# Slapd

Slapd 是 openldap 的服务端 daemon。正常情况下不需要碰，但是如果要碰的时候，你会发现它的配置极其复杂麻烦。

**修改前一定要先打虚拟机快照！！！**

~~小心延毕~~

## Migrate hdb to mdb

`slapd-hdb` 在 Debian 11 即将被 deprecate，所以在 2021/08/15 组织了一次 migrate。

网上资料很少，参考了：

1. <https://github.com/osixia/docker-openldap/issues/97>
2. <https://gist.github.com/wenzhixin/4705697206cdbf61bc88>

步骤：

0. 虚拟机快照打好。
1. 备份数据库：`slapcat -v -l dump.ldif`
2. 备份 `/etc/ldap` 以及 `/var/lib/ldap`
3. 把 `/etc/ldap/slapd.d` 以及 `/var/lib/ldap` 删掉（或者改名）
4. 运行 `dpkg-reconfigure slapd`
5. 创建 `/tmp/ldapconvert` 目录，运行 `slaptest -f /etc/ldap/convert.conf -F /tmp/ldapconvert`
6. 清空 `/etc/ldap/slapd.d/cn=config/cn=schema/` 下的文件，将 `/tmp/ldapconvert/slapd.d/cn=config/cn=schema/` 下的文件复制到 `/etc/ldap/slapd.d/cn=config/cn=schema/`，并且修改 owner 为 `openldap:openldap`
7. 重启 `slapd`，如果启动失败，看 `systemctl status slapd` 的日志输出 debug。
8. 恢复数据库：`slapadd -l dump.ldif`。注意，mdb **没有事务**！如果中间出错了，清空 `/var/lib/ldap`，重启 `slapd` 重来。

