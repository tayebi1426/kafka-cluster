#!/bin/bash

clear

echo "Starting Zookeeper server"

./server/bin/zookeeper-server-start.sh ./server/config/zk-ssl.properties
