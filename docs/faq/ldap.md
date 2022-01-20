# LDAP 套件问题

## GOsa 问题

!!! bug "User 界面打开时报错"

    如果在 GOsa 中创建了一个新用户，却没有在最后为他设置密码，就会出现此问题，打开 User 界面后会有报错：

    ```
    Fatal error: Uncaught ArgumentCountError: Too few arguments to function userManagement::filterLockLabel(), 0 passed in /usr/share/gosa/include/class_listing.inc on line 856 and exactly 1 expected in /usr/share/gosa/plugins/admin/users/class_userManagement.inc:856
    Stack trace:
    #0 /usr/share/gosa/include/class_listing.inc(856): userManagement::filterLockLabel()
    #1 /usr/share/gosa/include/class_listing.inc(980): listing->processElementFilter('%{filter:lockLa...', Array, 50)
    #2 /usr/share/gosa/include/class_listing.inc(853): listing->filterActions('cn=...,ou=...', 50, Array)
    #3 /usr/share/gosa/include/class_listing.inc(764): listing->processElementFilter('%{filter:action...', Array, 50)
    #4 /usr/share/gosa/include/class_listing.inc(407): listing->renderCell('%{filter:action...', Array, 50)
    #5 /usr/share/gosa/include/class_management.inc(233): listing->render()
    #6 /usr/share/gosa/include/class_management.inc(222): management->renderList()
    #7 /usr/share/gosa/plugins/admin/users/main.inc(44): management->execute()
    #8 /usr/sh in /usr/share/gosa/plugins/admin/users/class_userManagement.inc on line 856
    ```

    这是因为 GOsa 无法读取到用户密码的 Hash，而 LDAP 却允许用户没有密码。
    只需为新的用户设置密码或删除新的用户即可。

## Slapd

Slapd 是 openldap 的服务端 daemon。正常情况下不需要碰，但是如果要碰的时候，你会发现它的配置极其复杂麻烦。

**修改前一定要先打虚拟机快照！！！**

~~小心延毕~~

### Migrate hdb to mdb

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
5. ~~创建 `/tmp/ldapconvert` 目录，运行 `slaptest -f /etc/ldap/convert.conf -F /tmp/ldapconvert`~~
6. ~~清空 `/etc/ldap/slapd.d/cn=config/cn=schema/` 下的文件，将 `/tmp/ldapconvert/slapd.d/cn=config/cn=schema/` 下的文件复制到 `/etc/ldap/slapd.d/cn=config/cn=schema/`~~ 将 slapd.d 备份中 `cn=config/cn=schema/` 的文件复制到新的 `slapd.d` 对应的目录下，并且修改 owner 为 `openldap:openldap`
7. 重启 `slapd`，如果启动失败，看 `systemctl status slapd` 的日志输出 debug。
8. 恢复数据库：`slapadd -l dump.ldif`。注意，mdb **没有事务**！如果中间出错了，排查问题后，清空 `/var/lib/ldap`，重启 `slapd` 重来。

恢复成功后，有些配置需要手动设置：

1. TLS/SSL

```
# ldapmodify -H ldapi:/// -Y EXTERNAL << EOF
> dn: cn=config
> changetype: modify
> replace: olcTLSCertificateFile
> olcTLSCertificateFile: /etc/ldap/ssl/slapd-server.crt
> -
> replace: olcTLSCACertificateFile
> olcTLSCACertificateFile: /etc/ldap/ssl/slapd-ca-cert.pem
> -
> replace: olcTLSCertificateKeyFile
> olcTLSCertificateKeyFile: /etc/ldap/ssl/slapd-server.key
>
> EOF
```

2. 加载 pw-sha2.la

```
# ldapmodify -H ldapi:/// -Y EXTERNAL << EOF
> dn: cn=module,cn=config
> cn: module
> objectClass: olcModuleList
> olcModulePath: /usr/lib/ldap/
> olcModuleLoad: pw-sha2.la
>
> EOF
```

3. 为 sudoUser 设置 index

```
# ldapadd -Y EXTERNAL -H ldapi:/// << EOF
> dn: olcDatabase={1}mdb,cn=config
> changetype: modify
> add: olcDbIndex
> olcDbIndex: sudoUser eq,sub
>
> EOF
```
