# Light Accelerator

service: [light.ustclug.org](https://light.ustclug.org)

Git Repositry: 

* [Server Daemon](https://github.com/ustclug/light-server)
* [Web UI](https://github.com/ustclug/lug-vpn-web/tree/light)
* [Accelerate list](https://github.com/ustclug/light-list)
* [Documentation](https://git.ustclug.org/lug-light/light-doc)

DockerHub: 

* [ustclug/light-server](https://hub.docker.com/r/ustclug/light-server/)
* [ustclug/lug-vpn-web:light](https://hub.docker.com/r/ustclug/lug-vpn-web/)

mail list: [轻量级网络加速服务](https://groups.google.com/d/topic/ustc_lug/EZAL7OdJa_E/discussion)

server:

* swarm.s.ustclug.org (docker container)
  * light-mysql
  * light-freeradius
  * light-server
  * light-web
* gateway-el.s.ustclug.org (port mapping)
  * 29979 -> light-server.d.ustclug.org:29979
  * 29980 -> light-server.d.ustclug.org:29980
* revproxy-el.s.ustclug.org (reverse proxy)
  * light.ustclug.org -> light-web.d.ustclug.org
* docker2.s.ustclug.org
  * LUG FTP:  [http://ftp.ustclug.org/light/](http://ftp.ustclug.org/light/)

## deploy

deploy script: [docker-run-script/light](https://git.ustclug.org/ustclug/docker-run-script/tree/master/light)

deploy order:

1. mysql
2. freeradius, light-web
3. squid

## Add new domain

```sh
git clone https://git.ustclug.org/lug-light/accelerate-list.git
cd accelerate-list
./tools/add-domain.sh accelerate.list www.example.com
git commit -v -a
git push origin master
```

Travis CI will update PAC files in LUG FTP automatically.
