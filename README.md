# 在 Docker 上安装MongoDB BI Connector

公司项目采用的 Mongo DB 其实一个 NoSQL 数据库,那么在做图表时就比较麻烦. 好在 Mongo BI 提供了 一个中间层 可以将 SQL 语句转换为 MongoDB 接口.在官方文档中只提供了在本地安装的教程,但是我的应用是部署在 `Kubernetes` 中的每次有一个应用就要部署一次 BI Connector 也比较麻烦所以打算将 MongoDB BI 转为 Docker 方式.

## 方案

使用在 `Docker` 上安装 `Mongo BI Connector` 并使用 `start.sh` 脚本进行启动 参数采用环境变量进行设置.

### 创建start.sh

```sh
#!/bin/bash
mongosqld --addr=0.0.0.0:3307 --mongo-uri "mongodb://${MONGODB_HOST}:${MONGODB_PORT}/?socketTimeoutMS=360000&connectTimeoutMS=360000" --schemaRefreshIntervalSecs=3600 --auth -u ${MONGODB_USERNAME} -p ${MONGODB_PASSWROD} --sslMode "allowSSL" --sslPEMKeyFile "/ssl/kayakwiseDE.pem" --sslAllowInvalidCertificates --minimumTLSVersion "TLS1_0" --mongo-authenticationSource admin --sampleNamespaces "${MONGODB_SAMPLE}"
```

该命令将 `mongosqld` 暴露出 `3307` 端口并采样 `${MONGODB_HOST}:${MONGODB_PORT}` 认证采用 Mongo账户密码使用 admin 数据库进行认证,最终采样 `"${MONGODB_SAMPLE}"`数据库.

[官方命令详细解释](https://www.mongodb.com/zh-cn/docs/bi-connector/current/reference/mongosqld/#std-label-mongosqld-command-line-options)

### 创建Dockerfile

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl vim

ENV MONGODB_HOST=127.0.0.1
ENV MONGODB_PORT=27017
ENV MONGODB_USERNAME=admin
ENV MONGODB_PASSWROD=123456
ENV MONGODB_SAMPLE=sample.*

RUN openssl req -nodes -newkey rsa:2048 -keyout kayakwiseDE.key -out kayakwiseDE.crt -x509 -days 365 -subj "/C=US/ST=kayakwiseDE/L=kayakwiseDE/O=kayakwiseDE Security/OU=IT Department/CN=kayakwise.com"
RUN cat kayakwiseDE.crt kayakwiseDE.key > kayakwiseDE.pem

COPY start.sh /root
RUN chmod +x /root/start.sh

ADD mongodb-bi-linux-x86_64-ubuntu2204-v2.14.20.tgz /opt/
RUN mv /opt/mongodb-bi-linux-x86_64-ubuntu2204-v2.14.20 /opt/mongo-bi-connector && rm -rf /opt/mongo-bi-connector/mongodb-bi-linux-x86_64-ubuntu2204-v2.14.20
RUN install -m755 /opt/mongo-bi-connector/bin/mongo* /usr/bin/

WORKDIR /ssl
RUN openssl req -nodes -newkey rsa:2048 -keyout kayakwiseDE.key -out kayakwiseDE.crt -x509 -days 365 -subj "/C=US/ST=kayakwiseDE/L=kayakwiseDE/O=kayakwiseDE Security/OU=IT Department/CN=kayakwise.com"
RUN cat kayakwiseDE.crt kayakwiseDE.key > kayakwiseDE.pem

WORKDIR /root
CMD [ "/bin/sh","-c","/root/start.sh" ]
```

### 编译镜像

```sh
docker build -t mongo-bi .
```

### 运行镜像

```sh
root@ecs-c76d:~# docker run -it --rm -p 3307:3307 -e MONGODB_HOST=123.60.2.50 -e MONGODB_USERNAME=admin -e MONGODB_PASSWROD=123456 -e MONGODB_SAMPLE="sample.*" mongo-bi

2025-01-09T07:23:01.938+0000 I CONTROL    [initandlisten] mongosqld starting: version=v2.14.20 pid=8 host=fd80fa24c929
2025-01-09T07:23:01.938+0000 I CONTROL    [initandlisten] git version: da6c06666b2ba76337c713630c2dc1c121e9f31e
2025-01-09T07:23:01.938+0000 I CONTROL    [initandlisten] OpenSSL version OpenSSL 3.0.2 15 Mar 2022 (built with OpenSSL 3.0.2 15 Mar 2022)
2025-01-09T07:23:01.938+0000 I CONTROL    [initandlisten] options: {schema: {refreshIntervalSecs: 3600, sample: {namespaces: [sample.*]}}, net: {bindIp: [0.0.0.0], ssl: {mode: "allowSSL", allowInvalidCertificates: true, PEMKeyFile: "/ssl/kayakwiseDE.pem", minimumTLSVersion: "TLS1_0"}}, security: {enabled: true}, mongodb: {net: {uri: "mongodb://123.60.2.50:27017/?socketTimeoutMS=360000&connectTimeoutMS=360000", auth: {username: "admin", password: "<protected>", source: "admin"}}}}
2025-01-09T07:23:01.940+0000 I NETWORK    [initandlisten] waiting for connections at [::]:3307
2025-01-09T07:23:01.940+0000 I NETWORK    [initandlisten] waiting for connections at /tmp/mysql.sock
2025-01-09T07:23:01.955+0000 I SCHEMA     [sampler] sampling MongoDB for schema...
2025-01-09T07:23:01.965+0000 I SCHEMA     [sampler] mapped schema for 1 namespace: "sample" (1): ["student"]
```

> sample.*  代表 sample 库下的全部collections

### 尝试连接

![](https://halo-oos.oss-cn-hangzhou.aliyuncs.com/blog202501091523777.png)

![](https://halo-oos.oss-cn-hangzhou.aliyuncs.com/blog202501091523760.png)

## FAQ

### 登录后发现Mysql数据库只有Mysql和INFORMATRION库

请检查 登录的账户是否有采样目标的数据权限. 在以上系统中就是需要检查 `admin` 账户是否有 `sample` 数据库的查看权限...



## 附件

* [Dataease 安装 Mongo BI Connector](https://kb.fit2cloud.com/?p=143) 
* [Mongo BI Cpmmector 下载地址](https://www.mongodb.com/try/download/bi-connector)
* [Mongo DB 安装文档](https://www.mongodb.com/zh-cn/docs/manual/tutorial/install-mongodb-on-ubuntu/#std-label-install-mdb-community-ubuntu)
* [Mongo DB 配置文档](https://www.mongodb.com/zh-cn/docs/manual/administration/configuration/)
* [Mongo DB BI 配置文档](https://www.mongodb.com/zh-cn/docs/bi-connector/current/tutorial/install-bi-connector-rhel/)
* [Mongo DB BI 启动](https://www.mongodb.com/zh-cn/docs/bi-connector/current/launch/)



