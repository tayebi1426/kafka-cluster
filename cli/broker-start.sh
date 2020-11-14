#!/bin/bash

clear

if [ $# -lt 1 ] || [ $1 -lt 0 ] || [ $1 -gt 2 ];
then
  echo "Wrong use: this command needs the broker id where id is 0..2"
  exit 1
fi

BROKER_ID=$1
PORT="9${BROKER_ID}93"
JMX_PORT="9${BROKER_ID}99"
KAFKA_LOG4J_DIR="./logs/b${BROKER_ID}"
MESSAGE_LOGS_DIR="/kafka-data/logs/b${BROKER_ID}"

export LOG_DIR=$KAFKA_LOG_DIR
export KAFKA_HEAP_OPTS="-Xms128M -Xmx4g -Dkafka.broker${BROKER_ID}"

echo "Starting Broker with id ${BROKER_ID} on port ${PORT}"

sh ./server/bin/kafka-server-start.sh ./server/config/server.properties --override listeners=SSL://:$PORT --override broker.id=$BROKER_ID --override port=$PORT --override log.dirs=$MESSAGE_LOGS_DIR
