#!/bin/bash

clear
BROKER_ID=0
SERVER_IP=192.168.138.130
PORT="9${BROKER_ID}93"
JMX_PORT="9${BROKER_ID}99"
KAFKA_LOGS_DIR="../logs/b${BROKER_ID}"
MESSAGE_LOGS_DIR="/kafka-cluster/logs/b${BROKER_ID}"

export LOG_DIR=$KAFKA_LOGS_DIR
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.broker${BROKER_ID}"

sh ../server/bin/kafka-server-start.sh ../server/config/server.properties --override listeners=SSL://$SERVER_IP:9003 --override broker.id=$BROKER_ID --override port=$PORT --override logs.dir=$MESSAGE_LOGS_DIR