#!/usr/bin/env bash

if [ $# -lt 2 ]; then
	echo "please, enter client's name & storepass !"
	exit 1
fi

set -eu
CLIENT_NAME="$1"
CLIENT_CERT_ALIAS="$1-ca"
WORKING_DIR=$CLIENT_NAME
KEYSTORE_PATH="${WORKING_DIR}/${CLIENT_NAME}.keystore.jks"

VALIDITY_IN_DAYS=3650

ROOT_KEY_PATH="./root-ca.key"
ROOT_CRT_PATH="./root-ca.crt"

CSR_FILE="csr-cert"
CSR_SRL="root-ca.srl"

CLIENT_CRT_PATH="${WORKING_DIR}/${CLIENT_CERT_ALIAS}.crt"

ROOT_CERT_ALIAS="root-ca"

CN=$CLIENT_NAME
PASS=$2

KAFKA_SERVER_CRT_PATH="./kafka-server-ca.crt"

function file_exists_and_exit() {
  echo "'$1' cannot exist. Move or delete it before"
  echo "re-running this script."
  exit 1
}

if [ -e "$WORKING_DIR" ]; then
  file_exists_and_exit $WORKING_DIR
fi

mkdir $WORKING_DIR

keytool -genkey -keystore $KEYSTORE_PATH \
  -alias $CLIENT_CERT_ALIAS -validity $VALIDITY_IN_DAYS -keyalg RSA \
  -storetype PKCS12 -noprompt -dname "CN=$CN" -storepass $PASS

keytool -certreq -keystore $KEYSTORE_PATH -alias $CLIENT_CERT_ALIAS \
  -file $WORKING_DIR/$CSR_FILE -storepass $PASS

openssl x509 -req -CAkey $ROOT_KEY_PATH -CA $ROOT_CRT_PATH \
  -in $WORKING_DIR/$CSR_FILE -out $CLIENT_CRT_PATH \
  -days $VALIDITY_IN_DAYS -CAcreateserial

keytool -import -noprompt -keystore $KEYSTORE_PATH -alias $ROOT_CERT_ALIAS  \
  -file $ROOT_CRT_PATH -storepass $PASS

keytool -import -noprompt -keystore $KEYSTORE_PATH -alias $CLIENT_CERT_ALIAS  \
  -file $CLIENT_CRT_PATH -storepass $PASS


rm $WORKING_DIR/$CSR_FILE
rm $CSR_SRL
