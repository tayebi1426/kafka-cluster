#!/bin/bash

clear

if [ $# -lt 1 ] || [ $1 -lt 0 ] || [ $1 -gt 2 ];
then
  echo "Wrong use: this command needs the broker id where id is 0..2"
  exit 1
fi
KAFKA_HOME="/kafka-cluster"
export KAFKA_HOME

BROKER_ID=$1
PORT="9${BROKER_ID}93"
JMX_PORT="9${BROKER_ID}99"
MESSAGE_LOGS_DIR="/kafka-data/logs/b${BROKER_ID}"
JMX_PORT="911${BROKER_ID}"

KAFKA_JMX_OPTS="-Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT} -Dcom.sun.management.jmxremote.port=${JMX_PORT} -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"

export KAFKA_JMX_OPTS=${KAFKA_JMX_OPTS}
export LOG_DIR="${KAFKA_HOME}/logs/b${BROKER_ID}"
export KAFKA_HEAP_OPTS="-Xms1G -Xmx1G -Dkafka.broker${BROKER_ID}"

echo "kafka home is ${KAFKA_HOME}"
echo "Starting Broker with id ${BROKER_ID} on port ${PORT}"

nohup sh \
	${KAFKA_HOME}/server/bin/kafka-server-start.sh \
	${KAFKA_HOME}/server/config/server.properties \
	--override listeners=SSL://kafka.istd.com:$PORT \
	--override broker.id=$BROKER_ID \
	--override port=$PORT \
	--override log.dirs=$MESSAGE_LOGS_DIR \
>/dev/null 2>&1 & # runs in background, doesn't create nohup.out
