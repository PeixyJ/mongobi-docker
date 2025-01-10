FROM hengyun-docker.pkg.coding.net/enterprise-platform/docker-warehouse/ubuntu:22.04
RUN apt-get update && apt-get install -y curl vim

ENV MONGODB_HOST=127.0.0.1
ENV MONGODB_PORT=27017
ENV MONGODB_USERNAME=admin
ENV MONGODB_PASSWORD=123456
ENV MONGODB_SAMPLE=sample.*
# MongoDB 4.0 以上使用 SCRAM-SHA-256
# MongoDB 4.0 以下使用 SCRAM-SHA-1
ENV MONGODB_AUTH_MECHANISM=SCRAM-SHA-256
ENV MONGODB_AUTH_SOURCE=admin


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

