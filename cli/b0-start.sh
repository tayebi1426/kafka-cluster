#!/bin/bash

clear
export SERVER_IP=192.168.138.130
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.broker0"
sh ./brokers/b0/bin/kafka-server-start.sh ./brokers/b0/config/server.properties --override listeners=SSL://$SERVER_IP:9003
