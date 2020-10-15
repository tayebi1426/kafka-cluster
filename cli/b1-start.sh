#!/bin/bash

clear
export SERVER_IP=192.168.138.130
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.broker-1"
sh ./brokers/b1/bin/kafka-server-start.sh ./brokers/b1/config/server.properties --override listeners=SSL://$SERVER_IP:9013
