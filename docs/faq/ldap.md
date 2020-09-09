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
