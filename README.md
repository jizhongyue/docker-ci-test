# Docker For dcrpool

* OS: `Ubuntu 16.04 LTS`
* Docker Image OS: `Ubuntu 16.04 LTS`
* Monerod: `v0.12.0.0`

## Install Docker

```shell
apt-get update
apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce

docker version
```

## Build Docker Image

1. Download dcrpool source code
2. Make a dcrpool.tar.gz file
3. Build docker image

```shell
# download
git clone git@github.com:iblockin/dcrpool.git
# tar
tar jcvf dcrpool.tar.gz dcrpool/
# build
docker build -t dcrpool:1.2.0 .
```

## Push To Docker Hub

***Replace: yourname***

```shell
# Login Docker Hub
docker login --username=yourname@blockin registry.cn-beijing.aliyuncs.com

# Push to Docker Hub
docker tag dcrpool:1.2.0 registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
docker push registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

## Deployment

### 1. Pull Docker Image From Hub

```shell
# Login Docker Hub
docker login --username=yourname@blockin registry.cn-beijing.aliyuncs.com

# Pull Docker Image
docker pull registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

### 2. Set Config File

**Notice:**

1. RPC_ADDR in docker MUST be a LAN IP not 127.0.0.1;
2. PAYOUT_ADDRESS MUST be a corresponding valid address;

```shell
cp docker_env_demo /work/config/docker_env_dcrpool
vim /work/config/docker_env_dcrpool
```

Init MySQL database tables.

```shell
#
# Create database `pool_main_db` and `pool_stats_db`
#
# pool_main_db
mysql -uxxxx -p -h xxx.xxx.xxx dcr_pool_main_db  < dcrpool/install/pool_main_db.sql

# pool_stats_db
mysql -uxxxx -p -h xxx.xxx.xxx dcr_pool_stats_db < dcrpool/install/pool_stats_db.sql
```

### 3. Run Service in Dockers

You MUST have done the `Step 2: Set Config File`, before starting the following steps.

#### Node Machines

`gbtmaker` Service

```shell
docker run -it --restart always -d \
--env-file /work/config/docker_env_dcrpool \
--env EXEC_FILE=gbtmaker \
-v /work/dcrpool:/root/.pool \
--name dcrpool_gbtmaker \
registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

#### Common Machines

`jobmaker` Service

```shell
docker run -it --restart always -d \
--env-file /work/config/docker_env_dcrpool \
--env EXEC_FILE=jobmaker \
-v /work/dcrpool:/root/.pool  \
--name dcrpool_jobmaker \
registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

`sharelogger` Service

```shell
docker run -it --restart always -d \
--env-file /work/config/docker_env_dcrpool \
--env EXEC_FILE=sharelogger \
-v /work/dcrpool:/root/.pool  \
--name dcrpool_sharelogger \
registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

`blkmaker` Service

```shell
docker run -it --restart always -d \
--env-file /work/config/docker_env_dcrpool \
--env EXEC_FILE=blkmaker \
-v /work/dcrpool:/root/.pool  \
--name dcrpool_blkmaker \
registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

`slparser` Service

```shell
docker run -it --restart always -d \
--env-file /work/config/docker_env_dcrpool \
--env EXEC_FILE=slparser \
-v /work/dcrpool:/root/.pool  \
--name dcrpool_slparser \
registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

`statshttpd` Service

```shell
docker run -it --restart always -d \
--env-file /work/config/docker_env_dcrpool_statshttpd \
--env EXEC_FILE=statshttpd \
-v /work/dcrpool:/root/.pool \
--name dcrpool_statshttpd \
-p 8080:8080 \
registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

#### SS Machine

***Notice***: `The Second Port(1800) in Docker MUST be same with sserver port in pool.cfg`

`sserver` Service

```shell
docker run -it --restart always -d \
--env-file /work/config/docker_env_dcrpool \
--env EXEC_FILE=sserver \
-v /work/dcrpool:/root/.pool \
--name dcrpool_sserver \
-p 1800:1800 -p 1801:1801 \
registry.cn-beijing.aliyuncs.com/poolin/dcrpool:1.2.0
```

### Validation

See Logs.

```shell
# From Docker
docker exec -it dcrpool_gbtmaker bash
tail log_gbtmaker/gbtmaker.INFO

# From Physical Machine Log
tail /work/dcrpool/log_gbtmaker/gbtmaker.INFO
```

### Stop Docker Service

```shell
docker stop dcrpool_gbtmaker
docker rm dcrpool_gbtmaker
```
