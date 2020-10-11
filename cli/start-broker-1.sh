#!/bin/bash

clear
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.broker-1"
sh ../brokers/b1/bin/kafka-server-start.sh ../brokers/b1/config/server.properties 
