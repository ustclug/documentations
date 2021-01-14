# Nginx 相关配置

## 文件打开数大小限制

在默认设置中，nginx 的最大文件打开数上限并不大。当有大量访问时，文件打开数可能会超过限额，导致网站响应缓慢。在新配置服务器时，这一项设置很容易被忽略掉。

解决方法：

1. `sudo systemctl edit nginx.service`
2. 在打开的 override 文件的 `[Service]` 下方添加 `LimitNOFILE=524288`（视情况这个值可以相应调整）
