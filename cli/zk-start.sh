#!/bin/bash

clear

echo "Starting Zookeeper server"

nohup ./server/bin/zookeeper-server-start.sh ./server/config/zookeeper.properties >/dev/null 2>&1 &
