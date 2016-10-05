# PGP Key Server

service: [sks.ustclug.org](http://sks.ustclug.org)

server: docker2.s.ustclug.org

## Deploy

* Dockerfile: https://github.com/zhsj/dockerfile/tree/master/sks
* Web Front: https://git.ustclug.org/ustclug/sks-index

运行时需要将容器内的 `/var/lib/sks` 挂载出来，第一次运行请在 `/var/lib/sks/dump/` 目录放初始数据库，网页前端相关的文件请放
`/var/lib/sks/web/`。

服务需要暴露 11370 端口，11371 端口则请不要直接暴露。11370 端口是和别的服务器做 peer 用的。
11371 端口提供 HTTP 服务，所以请经过 Nginx 反代。同时 Nginx 通过给 11371 端口反代提供 80, 443 端口的 HTTP 服务。

## Maintenance

`/var/lib/sks/sksconf` 是 SKS 服务参数配置，`/var/lib/sks/membership` 是 peer 信息。这两个文件更新后需要重启 container 才能生效。

Web Front 的 Git 仓库未配置 Webhook，所以需要更新前端的话，先 push 到 Git 仓库，然后到 `/var/lib/sks/web/` 下 `git pull`，这个更新
不需要重启服务。

## 注意事项

membership 由 [@zhsj](https://sks.ustclug.org/pks/lookup?op=vindex&search=0xCF0E265B7DFBB2F2) 维护，任何改动请**务必**事先联系。

由于要和别人做 peer，所以对 sks.ustclug.org 域名的解析、docker 服务的部署有一定要求。假设 sks.ustclug.org 解析的 A 记录和 AAAA 记录
集为 SetA，那么 container 内部访问外部的出口 ip 需在 SetA 里。这是因为做 peer 的对方会把 SetA 加入访问白名单。

外部的服务器访问 `[ip for ip in SetA]:11370` 至少有一个 ip 能访问通（最好是都可以）。
同时 `[ip for ip in SetA]:11371` 是提供 HTTP 服务的，所以所有 ip 都要能访问通。80,443 端口同 11371 端口。
