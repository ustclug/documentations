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

Slapd 是 OpenLDAP 的服务端 daemon。正常情况下不需要碰，但是如果要碰的时候，你会发现它的配置极其复杂麻烦。

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

    ```console
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

2. 加载 pw-sha2.la（若使用 ssha512/256 则需要加载）

    ```console
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

    ```console
    # ldapadd -Y EXTERNAL -H ldapi:/// << EOF
    > dn: olcDatabase={1}mdb,cn=config
    > changetype: modify
    > add: olcDbIndex
    > olcDbIndex: sudoUser eq,sub
    >
    > EOF
    ```

4. 更改默认密码存储选项（可选）

    更改为 crypt/yescrypt

    ```console
    # ldapmodify -Y EXTERNAL -H ldapi:/// << EOF
    > dn: olcDatabase={-1}frontend,cn=config
    > add: olcPasswordHash
    > olcPasswordHash: {CRYPT}
    > 
    > dn: cn=config
    > add: olcPasswordCryptSaltFormat
    > olcPasswordCryptSaltFormat: $y$j9T$%s
    ```

    更改为 ssha512（需要 pw-sha2.la，也可参照上述 yescrypt 的配置更改为 crypt/ssha512）

    ```console
    # ldapmodify -Y EXTERNAL -H ldapi:/// << EOF
    > dn: olcDatabase={-1}frontend,cn=config
    > add: olcPasswordHash
    > olcPasswordHash: {SSHA512}
    ```

    如果报错已经存在，可以用 replace 选项，以 crypt/yescrypt 为例：

    ```console
    # ldapmodify -Y EXTERNAL -H ldapi:/// << EOF
    > dn: olcDatabase={-1}frontend,cn=config
    > changetype: modify
    > replace: olcPasswordHash
    > olcPasswordHash: {CRYPT}
    > 
    > dn: cn=config
    > changetype: modify
    > replace: olcPasswordCryptSaltFormat
    > olcPasswordCryptSaltFormat: $y$j9T$%s
    ```

    注意在使用上述 hash 方式的时候进入 gosa 用户页面时可能会报错 Cannot find a suitable password method for the current hash

### 配置 lastbind overlay

lastbind 用于在用户登录时登记时间戳，以方便确认哪些用户长时间没有登录，便于清理。由于我们使用 OLC (cn=config) 配置，网络资料不多，特此记录。

1. 加载模块

    ```ldif
    dn: cn=module{0},cn=config
    changetype: modify
    add: olcModuleLoad
    olcModuleLoad: lastbind.la
    ```

    保存到 `load_lastbind.ldif`，然后：

    ```console
    $ sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f load_lastbind.ldif
    SASL/EXTERNAL authentication started
    SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
    SASL SSF: 0
    modifying entry "cn=module{0},cn=config"
    ```

2. 添加 lastbind overlay

    ```ldif
    dn: olcOverlay=lastbind,olcDatabase={1}mdb,cn=config
    objectClass: olcLastBindConfig
    objectClass: olcOverlayConfig
    olcOverlay: lastbind
    olcLastBindPrecision: 60
    ```

    保存到 `add_lastbind.ldif`，然后：

    ```console
    $ sudo ldapadd -Y EXTERNAL -H ldapi:/// -f add_lastbind.ldif
    SASL/EXTERNAL authentication started
    SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
    SASL SSF: 0
    adding new entry "olcOverlay=lastbind,olcDatabase={1}mdb,cn=config"
    ```

可以使用 `ldapsearch` 获取用户的 `authTimestamp`。从未登录过的用户无记录：

```shell
sudo ldapsearch -x -LLL -H ldapi:/// -b "dc=lug,dc=ustc,dc=edu,dc=cn" "(authTimestamp=*)" dn authTimestamp
```
