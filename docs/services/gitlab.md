# GitLab
Server: gitlab.s.ustclug.org (ssh Port 2222)
Git Repository:
- [gitlab-scripts](https://git.lug.ustc.edu.cn/ustclug/gitlab-scripts)

## 更新
由于已经 docker 化，因此我们的更新是通过拉取[sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab/)的 docker image，进行数据库准备以及启动镜像实例来进行更新，Zack Zeng 学长已经写好了一套脚本系统：[gitlab-scripts](https://git.lug.ustc.edu.cn/ustclug/gitlab-scripts)，因此更新时只要跑脚本就可以了。

由于更新需要停止服务，因此请于更新前至少几小时发布更新公告（包括具体时间等）

更新前请先提前于 [VCenter](https://vcenter2.vm.ustclug.org/) 上对虚拟机打快照（打快照时服务会暂时停止）

打完快照之后使用脚本进行更新，首先使用 `./gitlab.sh db` 进行数据库的准备工作。之后可以通过 `./gitlab.sh run <版本号>` 来进行 docker container 的替换。更换前脚本会自动拉取相应版本号的 docker 镜像，如果担心拉取时间过长可以在打快照前提前通过 `docker pull sameersbn/gitlab:<版本号>` 来拉取相应的镜像。

一般情况下经以上操作后更新就正常结束，如果长时间无法启动，可以通过 `docker logs gitlab` 查看日志，如果发现更新后的启动出现问题，可以到 [sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab/) 的 issue 区等地查看相关 issue，以及通过对出错日志进行 Google 可能会发现是 gitlab 上游等出现的问题。如果有解决办法，可以按照相应解决办法解决，如果没有。可以通过找到有相应问题前的正常版本号，回滚快照，之后更到表现正常的版本。（最近的更新会在启动之后短暂出现 502 的情况，但很快就会恢复，遇到这种情况时不要惊慌）。

由于更新可能会出现问题导致服务不可用，因此不建议通过 cron 等方式自动进行更新。

## postgresql 与 redis 的更新
由于 gitlab 更新后可能对 postgresql 与 redis 的版本有要求，因此有可能需要定期更新 redis 与 postgresql。

更新前请先停止 gitlab 的 container

更新时可以按照官网教程 [docker-postgresql](https://github.com/sameersbn/docker-postgresql/blob/master/README.md) 进行更新，可以通过拉取 latest 标签的镜像，删除原来的 container，再通过脚本 `./gitlab.sh db` 自动启动，数据库更新时可能会需要一定时间来迁移数据，请通过 `docker logs -f gitlab-postgresql` 命令来查看迁移进度，待迁移完成后再运行 GitLab 的 container。

到 [vcenter](vcenter2.vm.ustclug.org/) 上对虚拟机打快照。
