# Light Accelerator

Service: [light.ustclug.org](https://light.ustclug.org)

Git Repository:

* [Server Daemon](https://github.com/ustclug/light-server)
* [Web UI](https://github.com/ustclug/lug-vpn-web/tree/light)
* [Accelerate list](https://github.com/ustclug/light-list)
* [Documentation](https://git.lug.ustc.edu.cn/lug-light/light-doc)

Docker Hub:

* [ustclug/light-server](https://hub.docker.com/r/ustclug/light-server/)
* [ustclug/lug-vpn-web:light](https://hub.docker.com/r/ustclug/lug-vpn-web/)

Mailing list: [轻量级网络加速服务](https://groups.google.com/d/topic/ustc_lug/EZAL7OdJa_E/discussion)

Servers:

* swarm.s.ustclug.org (docker containers)
    * light-mysql
    * light-freeradius
    * light-server
    * light-socks5
    * light-web
* gateway-el.s.ustclug.org (port mapping + reverse proxy)
    * 29979 → light-server.d.ustclug.org:29979
    * 29980 → light-server.d.ustclug.org:29980
    * light.ustclug.org → light-web.d.ustclug.org
* vdp.s.ustclug.org
    * LUG FTP: <https://ftp.lug.ustc.edu.cn/light/>

## Deploy

Deploy script: [:fontawesome-solid-lock: docker-run-script/light](https://github.com/ustclug/docker-run-script/tree/master/light)

Deploy order:

1. mysql
2. freeradius, light-web
3. squid

## Add new domain

```sh
git clone https://github.com/ustclug/light-list
cd accelerate-list
./tools/add-domain.sh accelerate.list www.example.com
git commit -v -a
git push origin master
```

GitHub Actions will update PAC files in LUG FTP automatically.

## Database maintenance

Example:

```sql
select count(*) from radacct where acctstoptime < '2021-01-01 00:00:00';
insert into radacct_backup select * from radacct where acctstoptime < '2021-01-01 00:00:00';
delete from radacct where acctstoptime < '2021-01-01 00:00:00';
delete from radacct_backup where acctstoptime < '2020-06-01 00:00:00';
optimize table radacct;
optimize table radacct_backup;
```

## Shutdown

1. Stop two containers: `light-server` & `light-socks`
2. Set restart policy to `no` (See [Docker Documentation](https://docs.docker.com/config/containers/start-containers-automatically/#use-a-restart-policy))

## Logs

Proxy related log is under `/srv/docker/light/log`. Container log (stdout & stderr) is under `/srv/docker/docker/containers/<container id>/*.log*` (use `docker logs <container>` to view).

Logrotate is configured to save logs for 180 days. Please manually backup logs when removing the container.
