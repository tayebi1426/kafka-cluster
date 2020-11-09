#!/bin/bash

clear
SERVER_IP=192.168.138.130
BROKER_ID=1
PORT="9${BROKER_ID}93"
JMX_PORT="9${BROKER_ID}99"
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.broker0"
sh ../server/bin/kafka-server-start.sh ../server/config/server.properties --override listeners=SSL://$SERVER_IP:9003 --override broker.id=$BROKER_ID --override port=$PORT