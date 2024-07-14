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

### Routing

一些同步程序不支持 bindIP 的配置，对于这些同步程序，我们通过创建多个 Docker network，然后在主机上根据 Docker network 进行策略路由，达到选择出口的效果。

创建 Docker network 的命令如下：

```shell
docker network create --driver=bridge --subnet=172.17.4.0/24 --gateway=172.17.4.1 -o "com.docker.network.bridge.name=dockerC" cernet
docker network create --driver=bridge --subnet=172.17.5.0/24 --gateway=172.17.5.1 -o "com.docker.network.bridge.name=dockerT" telecom
docker network create --driver=bridge --subnet=172.17.6.0/24 --gateway=172.17.6.1 -o "com.docker.network.bridge.name=dockerM" mobile
docker network create --driver=bridge --subnet=172.17.7.0/24 --gateway=172.17.7.1 -o "com.docker.network.bridge.name=dockerU" unicom

docker network create --driver=bridge --subnet=172.17.8.0/24 --gateway=172.17.8.1 \
  --ipv6 --subnet=fd00:6::/64 --gateway=fd00:6::1 \
  -o "com.docker.network.bridge.name=dockerC6" cernet6
```

对应地，主机上也配置好了策略路由，例如：

```ini title="/etc/systemd/network/cernet.network"
# Docker Cernet
[RoutingPolicyRule]
From=172.17.4.0/24
Table=1011
Priority=5
[RoutingPolicyRule]
From=172.17.8.0/24
Table=1011
Priority=5
```

```ini title="/etc/systemd/network/telecom.network"
# Docker Telecom
[RoutingPolicyRule]
From=172.17.5.0/24
Table=1012
Priority=5
```

`mobile.network` 和 `unicom.network` 也类似。

需要使用这种方式进行路由的同步镜像，可以在 YAML 中指定 `network`，例如：

```yaml title="adoptium.yum.yaml"
network: telecom
```
