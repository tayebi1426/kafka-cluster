#!/usr/bin/env bash
clear

#./brokers/b0/bin/kafka-console-producer.sh --bootstrap-server 127.0.0.1:9003  --topic test --producer.config ./brokers/b0/config/producer-ssl.properties

../server/bin/kafka-console-consumer.sh --bootstrap-server=127.0.0.1:9003 --topic test --consumer.config ../server/config/consumer-ssl.properties
