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
TRUSTSTORE_PATH="${WORKING_DIR}/${CLIENT_NAME}.truststore.jks"
VALIDITY_IN_DAYS=3650


ROOT_KEY_PATH="./root-ca.key"
ROOT_CRT_PATH="./root-ca.crt"

CSR_FILE="csr-cert"
#CSR_SRL="ca-cert.srl"
SIGNED_CERT_FILE="signed-cert"

ROOT_CERT_ALIAS="root-ca"

CN=$CLIENT_NAME
PASS=$2

KAFKA_SERVER_CRT_PATH="./kafka-server-ca.crt"

rm -rf ./$WORKING_DIR
mkdir $WORKING_DIR

keytool -genkey -keystore $KEYSTORE_PATH \
  -alias $CLIENT_CERT_ALIAS -validity $VALIDITY_IN_DAYS -keyalg RSA \
  -storetype pkcs12 -noprompt -dname "CN=$CN" -storepass $PASS

keytool -certreq -keystore $KEYSTORE_PATH -alias $CLIENT_CERT_ALIAS \
  -file $WORKING_DIR/$CSR_FILE -storepass $PASS

openssl x509 -req -CAkey $ROOT_KEY_PATH -CA $ROOT_CRT_PATH \
  -in $WORKING_DIR/$CSR_FILE -out $WORKING_DIR/$SIGNED_CERT_FILE \
  -days $VALIDITY_IN_DAYS -CAcreateserial

keytool -import -noprompt -keystore $KEYSTORE_PATH -alias $ROOT_CERT_ALIAS  \
  -file $ROOT_CRT_PATH -storepass $PASS

keytool -import -noprompt -keystore $KEYSTORE_PATH -alias $CLIENT_CERT_ALIAS  \
  -file $WORKING_DIR/$SIGNED_CERT_FILE -storepass $PASS

keytool -export -rfc -keystore $KEYSTORE_PATH -alias $CLIENT_CERT_ALIAS  \
  -file $WORKING_DIR/"${CLIENT_CERT_ALIAS}.crt" -storepass $PASS

keytool -importcert -keystore $TRUSTSTORE_PATH -alias kafka-server-ca  \
  -file $KAFKA_SERVER_CRT_PATH -storepass $PASS -noprompt

rm $WORKING_DIR/$CSR_FILE
rm $WORKING_DIR/$SIGNED_CERT_FILE
rm ./root-ca.srl
