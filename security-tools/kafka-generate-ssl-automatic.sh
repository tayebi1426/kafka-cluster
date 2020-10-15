#!/usr/bin/env bash

set -eu

KEYSTORE_WORKING_DIRECTORY="keystore"
TRUSTSTORE_WORKING_DIRECTORY="truststore"

KEYSTORE_FILENAME="kafka.keystore.jks"
TRUSTSTORE_FILENAME="kafka.truststore.jks"
VALIDITY_IN_DAYS=3650

ROOT_KEY_FILE="root-ca.key"
ROOT_CERT_FILE="root-ca.crt"
ROOT_CERT_ALIAS="CAroot"

KEYSTORE_SIGN_REQUEST="csr-file"
KEYSTORE_SIGN_REQUEST_SRL="root-ca.srl"
KEYSTORE_SIGNED_CERT="cert-signed"


CN=root
PASS=123456
CA_SAN="dns:kafka-server,ip:192.168.138.130"

function file_exists_and_exit() {
  echo "'$1' cannot exist. Move or delete it before"
  echo "re-running this script."
  exit 1
}

if [ -e "$KEYSTORE_WORKING_DIRECTORY" ]; then
  file_exists_and_exit $KEYSTORE_WORKING_DIRECTORY
fi

if [ -e "$ROOT_CERT_FILE" ]; then
  file_exists_and_exit $ROOT_CERT_FILE
fi

if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi

if [ -e "$KEYSTORE_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST_SRL
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi

if [ -e "$TRUSTSTORE_WORKING_DIRECTORY" ]; then
    file_exists_and_exit $TRUSTSTORE_WORKING_DIRECTORY
fi

clear

echo "Welcome to the Kafka SSL keystore and trust store generator script."

keystore_path="$KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME"
keystore_root_key_path="$KEYSTORE_WORKING_DIRECTORY/$ROOT_KEY_FILE"

truststore_path="$TRUSTSTORE_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME"
truststore_root_crt_path="$TRUSTSTORE_WORKING_DIRECTORY/$ROOT_CERT_FILE"

mkdir $KEYSTORE_WORKING_DIRECTORY
mkdir $TRUSTSTORE_WORKING_DIRECTORY

openssl req -new -x509 \
	-keyout $keystore_root_key_path \
	-out $truststore_root_crt_path -days $VALIDITY_IN_DAYS -nodes \
	-subj "/CN=$CN"

keytool -importcert \
	-keystore $truststore_path \
	-alias $ROOT_CERT_ALIAS -file $truststore_root_crt_path \
	-dname "CN=$CN" -noprompt -keypass $PASS -storepass $PASS 


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
	-alias localhost -validity $VALIDITY_IN_DAYS \
	-dname "CN=$CN" -ext "SAN=$CA_SAN" \
	-noprompt -keypass $PASS -storepass $PASS


#read -n1 -r -p "Press any key to continue..." key

keytool -certreq -keystore $keystore_path -alias localhost \
	-file $KEYSTORE_SIGN_REQUEST \
	-dname "CN=$CN" -ext "SAN=$CA_SAN" \
	-keypass $PASS -storepass $PASS


openssl x509 -req -CAkey $keystore_root_key_path -CA $truststore_root_crt_path \
	-in $KEYSTORE_SIGN_REQUEST -out $KEYSTORE_SIGNED_CERT \
	-extfile openssl.cnf -extensions v3_req
	-days $VALIDITY_IN_DAYS -CAcreateserial


echo
echo "Now the CARoot will be imported into the keystore."
echo
keytool -importcert -keystore $keystore_path -alias $ROOT_CERT_ALIAS \
-file $truststore_root_crt_path -keypass $PASS -storepass $PASS -noprompt


echo
echo "Now the keystore's signed certificate will be imported back into the keystore."
echo
keytool -importcert -keystore $keystore_path -alias localhost \
	-file $KEYSTORE_SIGNED_CERT \
	-dname "CN=$CN" -ext "SAN=$CA_SAN" \
	-keypass $PASS -storepass $PASS

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
rm $TRUSTSTORE_WORKING_DIRECTORY/$KEYSTORE_SIGN_REQUEST_SRL

