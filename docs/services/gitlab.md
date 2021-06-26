# GitLab
Server: gitlab.s.ustclug.org (ssh Port 2222)
Git Repository:
- [gitlab-scripts](https://git.lug.ustc.edu.cn/ustclug/gitlab-scripts)

## 更新

由于已经 docker 化，因此我们的更新是通过拉取 [sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab/) 的 docker image，进行数据库准备以及启动镜像实例来进行更新，Zack Zeng 学长已经写好了一套脚本系统：[gitlab-scripts](https://git.lug.ustc.edu.cn/ustclug/gitlab-scripts)，因此更新时只要跑脚本就可以了。

由于更新需要停止服务，因此请于更新前至少几小时发布更新公告（包括具体时间等）

更新前请先提前于 [VCenter](https://vcenter2.vm.ustclug.org/) 上对虚拟机打快照（打快照时服务会暂时停止）

打完快照之后使用脚本进行更新（目前脚本位于 `/home/sirius/gitlab-scripts`），首先使用 `./gitlab.sh db` 进行数据库的准备工作。之后可以通过 `./gitlab.sh run <版本号>` 来进行 docker container 的替换。更换前脚本会自动拉取相应版本号的 docker 镜像，如果担心拉取时间过长可以在打快照前提前通过 `docker pull sameersbn/gitlab:<版本号>` 来拉取相应的镜像。

一般情况下经以上操作后更新就正常结束，如果长时间无法启动，可以通过 `docker logs gitlab` 查看日志，如果发现更新后的启动出现问题，可以到 [sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab/) 的 issue 区等地查看相关 issue，以及通过对出错日志进行 Google 可能会发现是 gitlab 上游等出现的问题。如果有解决办法，可以按照相应解决办法解决，如果没有。可以通过找到有相应问题前的正常版本号，回滚快照，之后更到表现正常的版本。（最近的更新会在启动之后短暂出现 502 的情况，但很快就会恢复，遇到这种情况时不要惊慌）。

由于更新可能会出现问题导致服务不可用，因此不建议通过 cron 等方式自动进行更新。

**建议在更新完成 72 小时内删除快照，详见 [关于快照](/infrastructure/vsphere/esxi/#about-snapshot)。**

!!! warning "升级至 GitLab 14 的注意事项"

    目前我们仍然使用 GitLab 13.x，但是已知升级到 GitLab 14（可能要到 GitLab 14.3 生效？）中影响我们的 breaking changes 是：仓库 storage 类型需要是 hashed storage (而不是 legacy storage)，新的仓库都已经使用了 hashed storage，但是旧的仓库没有被搬走。所以可能需要参考 <https://docs.gitlab.com/ee/administration/raketasks/storage.html#migrate-to-hashed-storage> 进行迁移。

## postgresql 与 redis 的更新

由于 gitlab 更新后可能对 postgresql 与 redis 的版本有要求，因此有可能需要定期更新 redis 与 postgresql。

更新前请先停止 gitlab 的 container

更新时可以按照官网教程 [docker-postgresql](https://github.com/sameersbn/docker-postgresql/blob/master/README.md) 进行更新，可以通过拉取 latest 标签的镜像，删除原来的 container，再通过脚本 `./gitlab.sh db` 自动启动，数据库更新时可能会需要一定时间来迁移数据，请通过 `docker logs -f gitlab-postgresql` 命令来查看迁移进度，待迁移完成后再运行 GitLab 的 container。

## 访问 Rails console

Rails console 可以完成一些高级的维护任务。在 gitlab 容器中执行 `bin/rails console` 启动。注意 console 的启动时间很长，需要有耐心。

可以执行的命令可参考 <https://docs.gitlab.com/ee/administration/troubleshooting/gitlab_rails_cheat_sheet.html>。

### 查询

#### 查询 Hashed storage 下仓库对应的项目

```ruby
ProjectRepository.find_by(disk_path: '@hashed/23/33/2333333333333333333333333333333333333333333333333333333333333333').project
```

如果存在，会返回类似以下的内容：

```
=> #<Project id:23333 username/project>>
```

#### 查询无项目且邮箱满足条件的用户 (SQL `like`)

```ruby
users = User.where('id NOT IN (select distinct(user_id) from project_authorizations)')
users = users.where('email like ?', '%.ru')
users.count

users.each do |user|
    puts user.last_activity_on
end
```

### 刷新某个项目的统计信息

```ruby
p = Project.find_by_full_path('<namespace>/<project>')
pp p.statistics
p.statistics.refresh!
pp p.statistics
```

### 获取所有包含 LFS 的项目 ID

```ruby
LfsObject.all.each do |lo|
    puts LfsObjectsProject.find_by_lfs_object_id(lo.id).project_id
end
```

输出较多。可以使用 `rails r xxx.rb` 运行，重定向到文件，去重后查看所有包含 LFS 的项目。

## 使用 Rake tasks

详见 <https://github.com/sameersbn/docker-gitlab#rake-tasks>。和 Rails console 一样，初始化很慢。

当前实例信息：

```shell
sudo docker exec --user git -it gitlab bundle exec rake gitlab:env:info RAILS_ENV=production
```

### 清理

参考 <https://github.com/gitlabhq/gitlabhq/blob/master/doc/raketasks/cleanup.md>。

不过作用有限。

#### 清理上传目录

查看会被清理的文件：

```shell
sudo docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production
```

清理（移动到 /-/project-lost-found/）：

```shell
sudo docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production DRY_RUN=false
```

#### 清理未被引用的 artifact 文件

查看会被清理的 artifact 数量：

```shell
sudo docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:orphan_job_artifact_files RAILS_ENV=production
```

清理：

```shell
sudo docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:orphan_job_artifact_files RAILS_ENV=production DRY_RUN=false
```

注意，新设置的 expire 期限不会影响以前的 artifact，这里的命令也无法清理。

#### 清理无效的 LFS reference

```shell
for i in `cat projectid_lfs`; do sudo docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:orphan_lfs_file_references PROJECT_ID=$i RAILS_ENV=production DRY_RUN=false; done
```

`projectid_lfs` 是上文中「获取所有包含 LFS 的项目 ID」的去重后的输出。

无 reference 的 LFS 文件每日 GitLab 会自动清除。如果需要立刻删除，可以使用 `gitlab:cleanup:orphan_lfs_files`。

## 紧急操作

### 设置为只读

https://docs.gitlab.com/ee/administration/read_only_gitlab.html

```console
# docker exec --user git -it gitlab bin/rails console
```

之后执行

```ruby
Project.all.find_each { |project| puts project.name; project.update!(repository_read_only: true) }
```

将所有仓库设置为只读。如果中间出现错误（特殊的项目名可能会导致运行中断），重命名最后输出对应的项目。

在设置前，需要添加 Messages 通知用户。

此时数据库仍然可写入。如果需要数据库只读，参考以上链接配置。