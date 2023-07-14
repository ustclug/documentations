---
icon: material/account-plus
---

# 在 LDAP 中添加新用户

## 新建 LDAP 用户

1. 登陆[网页界面](http://ldap.lug.ustc.edu.cn/gosa)
2. Users > Actions > Create > User
3. Generic: 输入 Last name，First name，Login（登录名）
4. POSIX > Generic：输入 Home directory。使用 Force UID/GID ，具体说明详见 [LDAP Users 和 Groups](../../infrastructure/ldap.md#ldap-users-and-groups)

## 添加 LDAP 用户权限

POSIX > Group membership > Add：根据需要添加的权限选择对应的组，具体说明详见 [LDAP Users 和 Groups](../../infrastructure/ldap.md#ldap-users-and-groups)

??? info "LDAP 缓存"

    若发现用户无法登陆等情况，可能是缓存服务 NSCD 导致的，具体参考 [LDAP Users 和 Groups](../../infrastructure/ldap.md#nscd)：
