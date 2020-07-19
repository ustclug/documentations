# 在 LDAP 中添加新用户

## 新建 LDAP 用户

1. 登陆[网页界面](http://ldap.lug.ustc.edu.cn)
1. Users > Actions > Create > User
1. Generic: 输入 Last name，First name，Login（登录名）
1. POSIX > Generic：输入 Home directory。使用 Force UID/GID ，具体说明详见 [LDAP Users 和 Groups](../../infrastructure/ldap.md#ldap-users-and-groups)

## 添加 LDAP 用户权限

1. POSIX > Group membership > Add：根据需要添加的权限选择对应的组，具体说明详见 [LDAP Users 和 Groups](../../infrastructure/ldap.md#ldap-users-and-groups)
