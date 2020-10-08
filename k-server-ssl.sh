#!/bin/bash

clear
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.server1"
sh ./bin/kafka-server-start.sh ./config/server-ssl.properties 
