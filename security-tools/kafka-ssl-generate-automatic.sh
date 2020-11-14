#!/usr/bin/env bash

set -eu

WORKING_DIRECTORY="keystore"

KEYSTORE_FILENAME="kafka.server.keystore.jks"
TRUSTSTORE_FILENAME="kafka.server.truststore.jks"
VALIDITY_IN_DAYS=3650

ROOT_KEY_PATH="./root-ca.key"
ROOT_CRT_PATH="./root-ca.crt"
ROOT_CERT_ALIAS="root-ca"

KEYSTORE_SIGN_REQUEST="csr-file"
KEYSTORE_SIGN_REQUEST_SRL="root-ca.srl"
KEYSTORE_SIGNED_CERT="cert-signed"

CN=root
PASS=123456
SERVER_ALIAS="kafka-server-ca"

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

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi


clear

echo "Welcome to the Kafka SSL keystore and trust store generator script."

keystore_path="$WORKING_DIRECTORY/$KEYSTORE_FILENAME"
truststore_path="$WORKING_DIRECTORY/$TRUSTSTORE_FILENAME"

mkdir $WORKING_DIRECTORY

#openssl req -new -x509 \
#	-keyout $ROOT_KEY_PATH \
#	-out $ROOT_CRT_PATH -days $VALIDITY_IN_DAYS -nodes \
#	-subj "/CN=$CN"

keytool -importcert \
	-keystore $truststore_path \
	-alias $ROOT_CERT_ALIAS -file $ROOT_CRT_PATH \
	-dname "CN=$CN" -noprompt -storepass $PASS 


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

keytool -genkey -keyalg RSA -keystore $keystore_path \
	-alias $SERVER_ALIAS -validity $VALIDITY_IN_DAYS \
	-dname "CN=$CN" \
	-storetype pkcs12 -noprompt -storepass $PASS


#read -n1 -r -p "Press any key to continue..." key

keytool -certreq -keystore $keystore_path -alias $SERVER_ALIAS \
	-file $KEYSTORE_SIGN_REQUEST \
        -storepass $PASS \
	-dname "CN=$CN"


openssl x509 -req -CAkey $ROOT_KEY_PATH -CA $ROOT_CRT_PATH \
	-in $KEYSTORE_SIGN_REQUEST -out $KEYSTORE_SIGNED_CERT \
	-days $VALIDITY_IN_DAYS -CAcreateserial \
	-extfile openssl.cnf -extensions v3_req	


echo
echo "Now the CARoot will be imported into the keystore."
echo
keytool -importcert -keystore $keystore_path -alias $ROOT_CERT_ALIAS \
-file $ROOT_CRT_PATH -storepass $PASS -noprompt


echo
echo "Now the keystore's signed certificate will be imported back into the keystore."
echo
keytool -importcert -keystore $keystore_path -alias $SERVER_ALIAS \
	-file $KEYSTORE_SIGNED_CERT \
	-storepass $PASS\
	-dname "CN=$CN" -noprompt

keytool -exportcert -rfc -keystore $keystore_path -alias $SERVER_ALIAS \
	-file "${SERVER_ALIAS}.crt"  \
	-storepass $PASS

echo
echo "All done!"
echo
echo "Deleting intermediate files. They are:"
echo " - '$KEYSTORE_SIGN_REQUEST_SRL': CA serial number"
echo " - '$KEYSTORE_SIGN_REQUEST': the keystore's certificate signing request"
echo "   (that was fulfilled)"
echo " - '$KEYSTORE_SIGNED_CERT': the keystore's certificate, signed by the CA, and stored back"
echo "    into the keystore"

rm $KEYSTORE_SIGN_REQUEST
rm $KEYSTORE_SIGNED_CERT
rm $KEYSTORE_SIGN_REQUEST_SRL
