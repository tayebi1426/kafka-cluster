#!/bin/bash
export KAFKA_HEAP_OPTS="-Xms128M -Xmx512M"
nohup sh ./bin/kafka-server-start.sh ./config/server-3.properties &
