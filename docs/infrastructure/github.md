# GitHub Organization

[ustclug](https://github.com/ustclug) @ GitHub

## GitHub Actions

GitHub Actions 对公开仓库免费，对私有仓库每月有 3000 分钟的限额（注：我们是学校帮忙申请的 GitHub Education，所以我们在功能上相当于付费的 GitHub Team）。目前我们有多个项目使用 GitHub Actions 部署，例如 [Linux 101 的讲义](https://github.com/ustclug/Linux101-docs)。

我们曾经使用 Travis CI（现在也在部分公开仓库中使用），因为（不会定期重置的）数量限制而将私有仓库全部迁出，讨论见 [Discussion #308](https://github.com/ustclug/discussions/issues/308).

## 两步认证（2FA）

我们强烈建议加入 ustclug 组织的用户为自己的 GitHub 账号配置两步认证：

- GitHub 不支持 +86 手机号认证，但是可能可以通过修改前端绕过限制（不推荐）
- 使用 Authenticator：南大的 Yao Ge 老师整理了在移动设备（iOS 与 Android）可以使用的 TOTP 客户端，内容参见 <https://doc.nju.edu.cn/books/efe93/page/b1a59>。
    - iOS 设备可以使用 Google Authenticator 或 Microsoft Authenticator，Android 设备也可以从 Google Play 商店获取这两个应用；
    - 无法访问 Google Play 的 Android 设备也可以使用 FreeOTP Plus, andOTP, Aegis Authenticator, Red Hat FreeOTP, OTP Authenticator。
