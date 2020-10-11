#!/bin/bash

clear

export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.broker0"
sh ./brokers/b0/bin/kafka-server-start.sh ./brokers/b0/config/server.properties 
