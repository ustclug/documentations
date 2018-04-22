# PGP Key Server

service: [pgp.ustc.edu.cn](http://pgp.ustc.edu.cn)

server: pgp.ustc.edu.cn

## Deploy

* Dockerfile: https://github.com/zhsj/dockerfile/tree/master/sks-full
* Deployment: https://github.com/zhsj/sks-ustc

运行时需要将容器内的 `/var/lib/sks` 挂载出来，第一次运行请在 `/var/lib/sks/dump/` 目录放初始数据库。

`zhusj/sks:full` docker 镜像里面包含了 sks 和 caddy。暴露了 11370 端口，用于和别的服务器做 peer；还有 11371, 80, 443 端口，都是提供 HTTP 访问的，gpg 用的 hkp 协议其实是 HTTP 协议，只是规定了默认端口为 11371。

具体的部署流程可以参考 https://github.com/zhsj/sks-ustc/blob/master/deploy.sh

简单来说就是把配置文件（sksconf, membership, Caddyfile, web）拷贝到容器的卷上，然后运行容器就好了。



## Maintenance

如果要修改配置文件，先 commit 到 https://github.com/zhsj/sks-ustc 仓库，然后在服务器的 `/var/lib/sks-ustc` 目录运行 `git pull`
更新 git 仓库。最后再重新运行一遍 `deploy.sh` 脚本就可以了。

## 注意事项

membership 由 [@zhsj](https://sks.ustclug.org/pks/lookup?op=vindex&search=0xCF0E265B7DFBB2F2) 维护，任何改动请**务必**事先联系。

因为和其他服务器相互 peer 认证时，是用 ip 做互相校验的。所以为了方便起见，运行 docker 容器时直接使用了 host 网络。
