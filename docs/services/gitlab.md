# GitLab

Server: gitlab.s.ustclug.org (management ssh port 2222)

Git Repository: [gitlab-scripts](https://git.lug.ustc.edu.cn/ustclug/gitlab-scripts)

## GitLab & Security

GitLab 维护者需要订阅：

1. GitLab Security Notices 邮件列表 (<https://about.gitlab.com/company/contact/> 右侧 "Sign up for security notices")
2. [:octicons-mark-github-16: sameersbn/docker-gitlab Releases](https://github.com/sameersbn/docker-gitlab/releases) (Watch → Custom → Releases)

在 GitLab 有 Security Release 且 docker-gitlab 发布新版本之后需要安排时间更新。尤其 Critical Security Release 需要尽快找时间更新。

## 更新

（建议阅读 <https://docs.gitlab.com/ee/update/index.html>，以及 GitLab 官方的升级路径分析工具：<https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/>）

GitLab 16.0 起移除了对 CAS3 的支持，因此我们切换到了 OAuth2 来对接中国科学技术大学统一身份认证。为了实现自定义 OAuth2 登录参数，我们 fork 了 [sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab)，仓库位于 [ustclug/docker-gitlab](https://github.com/ustclug/docker-gitlab)。更新时，需要首先按照 [ustclug/docker-gitlab](https://github.com/ustclug/docker-gitlab) 的 `README.md` 所述的步骤更新镜像，一般只需更改所述的两个位置的版本号，推送到仓库后，GitHub Actions 将自动完成镜像的构建，并上传到 ghcr.io。需要注意的是，若上游更新包含对 `assets/runtime` 目录的变更，则需先将上游更新合并到我们的仓库，否则可能出现构建或运行时错误。

由于已经 docker 化，因此我们的更新是通过拉取 [ustclug/docker-gitlab](https://github.com/ustclug/docker-gitlab) 的 docker image，进行数据库准备以及启动镜像实例来进行更新，Zack Zeng 学长已经写好了一套脚本系统：[gitlab-scripts](https://git.lug.ustc.edu.cn/ustclug/gitlab-scripts)，因此更新时只要跑脚本就可以了。

由于更新需要停止服务，因此请于更新前至少几小时发布更新公告（包括具体时间等），并检查 Admin -> Monitoring -> Background Migrations 中所有 migration 是否都已经成功完成。

更新前请先提前于 [Proxmox VE](https://pve-6.vm.ustclug.org:8006/) 上对虚拟机打快照（打快照时服务会暂时停止）

打完快照之后使用脚本进行更新（目前脚本位于 `/home/sirius/gitlab-scripts`），首先使用 `./gitlab.sh db` 进行数据库的准备工作。之后可以通过 `./gitlab.sh run <版本号>` 来进行 docker container 的替换。更换前脚本会自动拉取相应版本号的 docker 镜像，如果担心拉取时间过长可以在打快照前提前通过 `docker pull ghcr.io/ustclug/docker-gitlab:<版本号>` 来拉取相应的镜像。

一般情况下经以上操作后更新就正常结束，如果长时间无法启动，可以通过 `docker logs gitlab` 查看日志，如果发现更新后的启动出现问题，可以到 [sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab/) 的 issue 区等地查看相关 issue，以及通过对出错日志进行 Google 可能会发现是 gitlab 上游等出现的问题。如果有解决办法，可以按照相应解决办法解决，如果没有。可以通过找到有相应问题前的正常版本号，回滚快照，之后更到表现正常的版本。（最近的更新会在启动之后短暂出现 502 的情况，但很快就会恢复，遇到这种情况时不要惊慌）。

由于更新可能会出现问题导致服务不可用，因此不建议通过 cron 等方式自动进行更新。

## postgresql 与 redis 的更新

由于 gitlab 更新后可能对 postgresql 与 redis 的版本有要求，因此有可能需要定期更新 redis 与 postgresql。

更新前请先停止 gitlab 的 container。

更新时可以按照官网教程 [docker-postgresql](https://github.com/sameersbn/docker-postgresql/blob/master/README.md) 进行更新，可以通过拉取 latest 标签的镜像，删除原来的 container，再通过脚本 `./gitlab.sh db` 自动启动，数据库更新时可能会需要一定时间来迁移数据，请通过 `docker logs -f gitlab-postgresql` 命令来查看迁移进度，待迁移完成后再运行 GitLab 的 container。

## 访问 Rails console

Rails console 可以完成一些高级的维护任务。在 gitlab 容器中执行 `bin/rails console` 启动。注意 console 的启动时间很长（:octicons-clock-16: 1 分钟以上），需要有耐心。

可以执行的命令可参考 <https://docs.gitlab.com/ee/administration/troubleshooting/gitlab_rails_cheat_sheet.html>。

### 查询

#### 查询 Hashed storage 下仓库对应的项目

```ruby
ProjectRepository.find_by(disk_path: '@hashed/23/33/2333333333333333333333333333333333333333333333333333333333333333').project
```

如果存在，会返回类似以下的内容：

```text
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
docker exec --user git -it gitlab bundle exec rake gitlab:env:info RAILS_ENV=production
```

### 清理

参考 <https://github.com/gitlabhq/gitlabhq/blob/master/doc/raketasks/cleanup.md>。

不过作用有限。

#### 清理上传目录

查看会被清理的文件：

```shell
docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production
```

清理（移动到 /-/project-lost-found/）：

```shell
docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production DRY_RUN=false
```

#### 清理未被引用的 artifact 文件

查看会被清理的 artifact 数量：

```shell
docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:orphan_job_artifact_files RAILS_ENV=production
```

清理：

```shell
docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:orphan_job_artifact_files RAILS_ENV=production DRY_RUN=false
```

注意，新设置的 expire 期限不会影响以前的 artifact，这里的命令也无法清理。

#### 清理无效的 LFS reference

```shell
for i in `cat projectid_lfs`; do docker exec --user git -it gitlab bundle exec rake gitlab:cleanup:orphan_lfs_file_references PROJECT_ID=$i RAILS_ENV=production DRY_RUN=false; done
```

`projectid_lfs` 是上文中「获取所有包含 LFS 的项目 ID」的去重后的输出。

无 reference 的 LFS 文件每日 GitLab 会自动清除。如果需要立刻删除，可以使用 `gitlab:cleanup:orphan_lfs_files`。

### 修复

#### 重建 authorized_keys

如果发现用户的 pubkey 在 GitLab 中有，但是 `/home/git/.ssh/authorized_keys` 中没有或者有重复的，使用以下命令：

```shell
docker exec --user git -it gitlab bundle exec rake gitlab:shell:setup RAILS_ENV=production
```

(<https://docs.gitlab.com/administration/raketasks/maintenance/#rebuild-authorized_keys-file>)

## 紧急操作

### 设置为只读

Ref: <https://docs.gitlab.com/ee/administration/read_only_gitlab.html>

```shell
docker exec --user git -it gitlab bin/rails console
```

之后执行

```ruby
Project.all.find_each { |project| puts project.name; project.update!(repository_read_only: true) }
```

将所有仓库设置为只读。如果中间出现错误（特殊的项目名可能会导致运行中断），重命名最后输出对应的项目。

在设置前，需要添加 Messages 通知用户。

此时数据库仍然可写入。如果需要数据库只读，参考以上链接配置。

### 部署 Anubis

2025 年 8 月 8 日，由于偶尔但长期有人疑似 DDoS 我们导致 gitlab 虚拟机 CPU 占用过高，GitLab 服务响应缓慢，我们部署了 [Anubis](https://github.com/TecharoHQ/anubis) 阻止异常请求。
这些异常请求都使用浏览器 UA，大量请求各种仓库的 tree 和 blob，使 GitLab 花费大量 CPU 资源在处理这些请求上，非常适合用 Anubis 拦截。

部署过程（留作记录）：

1. 从 Anubis 的 GitHub Releases 页面获取合适的安装包安装（很不错，还提供了 deb）：

    ```shell
    wget https://github.com/TecharoHQ/anubis/releases/download/v1.21.3/anubis_1.21.3_amd64.deb
    apt install ./anubis_1.21.3_amd64.deb
    ```

2. 观察软件包内容决定操作方式：

    ```console
    # dpkg -L anubis
    /etc
    /etc/anubis
    /etc/anubis/default.env
    /usr
    /usr/lib
    /usr/lib/systemd
    /usr/lib/systemd/system
    /usr/lib/systemd/system/anubis@.service
    [...]
    ```

    配置 Anubis：

    ```shell
    cd /etc/anubis
    cp default.env gitlab.env
    vim gitlab.env
    ```

    ```shell title="/etc/anubis/gitlab.env"
    BIND=127.0.0.1:8923
    POLICY_FNAME=/etc/anubis/policy.yaml
    METRICS_BIND=127.0.0.1:9090
    SERVE_ROBOTS_TXT=1
    TARGET=https://127.0.0.1:10443

    TARGET_INSECURE_SKIP_VERIFY=true
    ```

    其中最后一行是因为 GitLab 用自签证书监听 HTTPS，可以在 Anubis 的 issue 区搜到（[#353](https://github.com/TecharoHQ/anubis/issues/353) → [#426](https://github.com/TecharoHQ/anubis/pull/426)）。

    然后将 <https://github.com/TecharoHQ/anubis/blob/main/data/botPolicies.yaml> 的内容复制到 `/etc/anubis/policy.yaml`，根据需要修改。

    其中难度参考（HASH 前 x 位需要为 0，因此难度是指数提升的）：

    - 默认的 2 太小了
    - 4 比较合适
    - 5 需要等待几秒钟
    - 6 需要等待几分钟，除非情况非常严重，否则不建议设置
    - 7 以上可以看作是拒绝

3. 更新 Nginx:

    仅更新了一行：将 `proxy_pass` 的目标设为 Anubis。

    ```shell
    systemctl reload nginx
    ```
