#!/usr/bin/env bash

if [ $# -lt 1 ]; then
	echo "please, enter storepass for keystore !"
	exit 1
fi

set -eu

WORKING_DIRECTORY="keystore"

KEYSTORE_PATH="${WORKING_DIRECTORY}/kafka.server.keystore.jks"
TRUSTSTORE_PATH="${WORKING_DIRECTORY}/kafka.server.truststore.jks"

SERVER_ALIAS="kafka-server-ca"
SERVER_CRT_PATH="./${SERVER_ALIAS}.crt"

VALIDITY_IN_DAYS=3650

ROOT_KEY_PATH="./root-ca.key"
ROOT_CRT_PATH="./root-ca.crt"
ROOT_CERT_ALIAS="root-ca"

KEYSTORE_SIGN_REQUEST="csr-file"
KEYSTORE_SIGN_REQUEST_SRL="root-ca.srl"

CN=root
PASS=$1


function file_exists_and_exit() {
  echo "'$1' cannot exist. Move or delete it before"
  echo "re-running this script."
  exit 1
}

if [ -e "$WORKING_DIRECTORY" ]; then
  file_exists_and_exit $WORKING_DIRECTORY
fi

#if [ -e "$ROOT_CRT_PATH" ]; then
  #file_exists_and_exit $ROOT_CRT_PATH
#fi

if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi

if [ -e "$KEYSTORE_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST_SRL
fi

if [ -e "$SERVER_CRT_PATH" ]; then
  file_exists_and_exit $SERVER_CRT_PATH
fi

clear

echo "Welcome to the Kafka SSL keystore and trust store generator script."

mkdir $WORKING_DIRECTORY

if [ ! \( -f "${ROOT_KEY_PATH}" -a -f "${ROOT_CRT_PATH}" \) ]; then

	openssl req -new -x509 \
		-keyout $ROOT_KEY_PATH \
		-out $ROOT_CRT_PATH -days $VALIDITY_IN_DAYS -nodes \
		-subj "/CN=$CN"
fi

keytool -importcert \
	-keystore $TRUSTSTORE_PATH \
	-alias $ROOT_CERT_ALIAS -file $ROOT_CRT_PATH \
	-storetype pkcs12 -noprompt -storepass $PASS 

echo
echo "Now, a keystore will be generated. Each broker and logical client needs its own"
echo "keystore. This script will create only one keystore. Run this script multiple"
echo "times for multiple keystores."
echo
echo "     NOTE: currently in Kafka, the Common Name (CN) does not need to be the FQDN of"
echo "           this host. However, at some point, this may change. As such, make the CN"
echo "           the FQDN. Some operating systems call the CN prompt 'first / last name'"

# To learn more about CNs and FQDNs, read:
# https://docs.oracle.com/javase/7/docs/api/javax/net/ssl/X509ExtendedTrustManager.html

keytool -genkey -keyalg RSA -keystore $KEYSTORE_PATH \
	-alias $SERVER_ALIAS -validity $VALIDITY_IN_DAYS \
	-dname "CN=$CN" \
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
