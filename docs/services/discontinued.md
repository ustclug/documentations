---
icon: material/cancel
---

# Discontinued Services

本页面记载曾经提供的服务，但是由于架构改变或服务迁移，这些服务不再以原来的形式提供，并可能在原处有残留的配置文件。

通常情况下残留的配置文件可以直接删除，但是保险起见，仍然建议在 Internals 群里先询问一下再处理。

## Docker Registry

曾经运行在 docker2 上，现在 LUG 的 Docker 镜像已转移至 Docker Hub。

## Freeshell

（未完待续，配置文件先保留）

## USTC Blog

Refer to [Gitlab Wiki](https://git.lug.ustc.edu.cn/ustc-blog/ustc-blog/wikis/home).

## Telegram Web

Service：[telegram.ustclug.org](https://telegram.ustclug.org)

Repository：[github.com/ustclug/telegram-web](https://github.com/ustclug/telegram-web)

DockerHub：[ustclug/telegram-web](https://hub.docker.com/r/ustclug/telegram-web)

Deployment：[telegram-web.sh](https://git.lug.ustc.edu.cn/ustclug/docker-run-script/blob/master/telegram-web/telegram-web.sh)

Servers：

* swarm.s.ustclug.org（Docker Container）
* revproxy-el.s.ustclug.org（reverse proxy）

Blog：[add-telegram-web-service](https://servers.blog.ustc.edu.cn/2016/10/add-telegram-web-service/)

## USTC Life

USTC Life is a navigation page, which included useful sites in USTC.

Service: [ustc.life](https://ustc.life)

!!! note "2020-04-09 更新信息"

    目前，USTC Life 服务托管在 GitHub Pages 上，仓库也已转移至 [:octicons-mark-github-16: SmartHypercube/ustclife](https://github.com/SmartHypercube/ustclife)，由 Hypercube 负责维护。以下内容仅为历史记录。

Git Repository: [github.com/ustclug/ustclife](https://github.com/ustclug/ustclife)

DockerHub: [ustclug/ustclife](https://hub.docker.com/r/ustclug/ustclife/builds/)

server: docker2.s.ustclug.org

deploy: /srv/webhook/ustclife.sh

webhook from DockerHub: /srv/webhook/hooks.json
