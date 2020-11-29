#!/usr/bin/env bash

if [ $# -lt 1 ]; then
	echo "please, enter storepass for keystore !"
	exit 1
fi

set -eu

WORKING_DIRECTORY="keystore"

KEYSTORE_PATH="${WORKING_DIRECTORY}/zk.server.keystore.jks"
TRUSTSTORE_PATH="${WORKING_DIRECTORY}/zk.server.truststore.jks"

SERVER_ALIAS=$(hostname -f)
SERVER_CRT_PATH="./${SERVER_ALIAS}.crt"

VALIDITY_IN_DAYS=3650

ROOT_CERT_ALIAS="root-ca"
ROOT_CRT_PATH="./root-ca.crt"

CN=$SERVER_ALIAS
PASS=$1

clear

echo "Welcome to the Kafka SSL keystore and trust store generator script."

mkdir $WORKING_DIRECTORY

keytool -genkey -keyalg RSA -keystore $KEYSTORE_PATH \
	-alias $SERVER_ALIAS -validity $VALIDITY_IN_DAYS \
	-dname "CN=$CN" \
	-storetype pkcs12 -noprompt -storepass $PASS

keytool -importcert \
	-keystore $TRUSTSTORE_PATH \
	-alias $ROOT_CERT_ALIAS -file $ROOT_CRT_PATH \
	-storetype pkcs12 -noprompt -storepass $PASS 


keytool -certreq -keystore $KEYSTORE_PATH -alias $SERVER_ALIAS \
	-file $KEYSTORE_SIGN_REQUEST \
        -storepass $PASS

openssl x509 -req -CAkey $ROOT_KEY_PATH -CA $ROOT_CRT_PATH \
	-in $KEYSTORE_SIGN_REQUEST -out $SERVER_CRT_PATH \
	-days $VALIDITY_IN_DAYS -CAcreateserial \
	-extfile openssl.cnf -extensions v3_req	

echo
echo "Now the CARoot will be imported into the keystore."
echo

keytool -importcert -keystore $KEYSTORE_PATH -alias $ROOT_CERT_ALIAS \
-file $ROOT_CRT_PATH -noprompt -storepass $PASS

echo
echo "Now the keystore's signed certificate will be imported back into the keystore."
echo

keytool -importcert -keystore $KEYSTORE_PATH -alias $SERVER_ALIAS \
	-file $SERVER_CRT_PATH -storepass $PASS

echo
echo "All done!"
echo
echo "Deleting intermediate files. They are:"
echo " - '$KEYSTORE_SIGN_REQUEST_SRL': CA serial number"
echo " - '$KEYSTORE_SIGN_REQUEST': the keystore's certificate signing request"
echo "   (that was fulfilled)"

rm $SERVER_CRT_PATH
rm $KEYSTORE_SIGN_REQUEST
rm $KEYSTORE_SIGN_REQUEST_SRL
