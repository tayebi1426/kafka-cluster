#!/usr/bin/env bash
clear

../server/bin/kafka-console-producer.sh --bootstrap-server 127.0.0.1:9093  --topic test --producer.config ../server/config/producer-ssl.properties
