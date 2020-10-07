#!/usr/bin/env bash

set -eu

KEYSTORE_FILE="client.keystore.jks"
VALIDITY_IN_DAYS=3650
WORKING_DIR="wd"

PRIVATE_KEY_FILE="ca-key"
ROOT_CERT_FILE="ca-crt"

CSR_FILE="csr-cert"
CSR_SRL="ca-cert.srl"
SIGNED_CERT_FILE="signed-cert"

ROOT_CERT_ALIAS="root"
CLIENT_CERT_ALIAS="producer"

CN=producer
PASS=123456

rm -rf ./$WORKING_DIR
mkdir $WORKING_DIR

keytool -genkey -keystore $WORKING_DIR/$KEYSTORE_FILE \
  -alias $CLIENT_CERT_ALIAS -validity $VALIDITY_IN_DAYS -keyalg RSA \
   -noprompt -dname "CN=$CN" -keypass $PASS -storepass $PASS

keytool -certreq -keystore $WORKING_DIR/$KEYSTORE_FILE -alias $CLIENT_CERT_ALIAS \
  -file $WORKING_DIR/$CSR_FILE -keypass $PASS -storepass $PASS

openssl x509 -req -CA $ROOT_CERT_FILE -CAkey $PRIVATE_KEY_FILE \
  -in $WORKING_DIR/$CSR_FILE -out $WORKING_DIR/$SIGNED_CERT_FILE \
  -days $VALIDITY_IN_DAYS -CAcreateserial

keytool -import -noprompt -keystore $WORKING_DIR/$KEYSTORE_FILE -alias $ROOT_CERT_ALIAS  \
  -file $ROOT_CERT_FILE -keypass $PASS -storepass $PASS

keytool -import -noprompt -keystore $WORKING_DIR/$KEYSTORE_FILE -alias $CLIENT_CERT_ALIAS  \
  -file $WORKING_DIR/$SIGNED_CERT_FILE -keypass $PASS -storepass $PASS


keytool -export -rfc -keystore $WORKING_DIR/$KEYSTORE_FILE -alias $CLIENT_CERT_ALIAS  \
  -file $WORKING_DIR/"$CLIENT_CERT_ALIAS.crt" -keypass $PASS -storepass $PASS

rm $WORKING_DIR/$CSR_FILE
rm $WORKING_DIR/$SIGNED_CERT_FILE
rm $WORKING_DIR/$CSR_SRL

