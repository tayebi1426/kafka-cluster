#!/bin/bash

SIGNAL=${SIGNAL:-TERM}

BROKER_ID=$1

if [ $# -lt 1 ] || [ $BROKER_ID -lt 0 ] || [ $BROKER_ID -gt 3 ];
then
  echo "Wrong use: this command needs the broker id where id is 0..3"
  exit 1
fi

if [[ $(uname -s) == "OS/390" ]]; then
    if [ -z $JOBNAME ]; then
        JOBNAME="KAFKSTRT"
    fi
    PIDS=$(ps -A -o pid,jobname,comm | grep -i $JOBNAME | grep java | grep -v grep | awk '{print $1}')
else
    PIDS=$(ps ax | grep -i 'kafka\.Kafka' | grep java | grep kafka.broker${BROKER_ID}| grep -v grep | awk '{print $1}')
fi

if [ -z "$PIDS" ]; then
  echo "No kafka server to stop"
  exit 1
else
  kill -s $SIGNAL $PIDS
fi
