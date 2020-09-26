#!/bin/bash
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M -Dkafka.server-2"
sh ./bin/kafka-server-start.sh ./config/server-2.properties 
