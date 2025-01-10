#!/bin/bash
mongosqld --addr=0.0.0.0:3307 --mongo-uri "mongodb://${MONGODB_HOST}:${MONGODB_PORT}/?socketTimeoutMS=360000&connectTimeoutMS=360000" --schemaRefreshIntervalSecs=3600 --auth -u "${MONGODB_USERNAME}" -p "${MONGODB_PASSWORD}" --sslMode "allowSSL" --sslPEMKeyFile "/ssl/kayakwiseDE.pem" --sslAllowInvalidCertificates --minimumTLSVersion "TLS1_0" --mongo-authenticationMechanism "${MONGODB_AUTH_MECHANISM}" --mongo-authenticationSource "${MONGODB_AUTH_SOURCE}" --sampleNamespaces ''${MONGODB_SAMPLE}''

