# Docker

## Networking

Docker 默认创建一个名为 bridge 的网络，主机界面为 `docker0`，IP 地址段为 172.17.0.0/16。

我们将 Docker Registry 的反代挂在另外一个子网下，需要先行创建。

```shell
docker network create \
  --opt com.docker.network.bridge.name=docker1 \
  --subnet=172.18.0.0/16 \
  --gateway=172.18.0.1 \
  docker-registry
```
