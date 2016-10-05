# Light Accelerator

service: [light.ustclug.org](https://light.ustclug.org)

Git Repositry: 

* [github.com/ustclug/lug-vpn-web:light](https://github.com/ustclug/lug-vpn-web/tree/light)
* [accelerate list](https://git.ustclug.org/lug-light/accelerate-list)
* [light doc](https://git.ustclug.org/lug-light/light-doc)

DockerHub: [ustclug/lug-vpn-web:light](https://hub.docker.com/r/ustclug/lug-vpn-web/)

mail list: [[公测] 轻量级网络加速服务](https://groups.google.com/forum/#!topic/ustc_lug/EZAL7OdJa_E)

server:

* swarm.s.ustclug.org (docker container)
* gateway-el.s.ustclug.org (port mapping)
* revproxy-el.s.ustclug.org (reverse proxy)

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

## Genterate PAC

```sh
git clone https://git.ustclug.org/lug-light/accelerate-list.git
cd accelerate-list
./tools/pac-generator.sh accelerate.list
```

