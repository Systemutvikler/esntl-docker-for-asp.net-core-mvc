#!/bin/sh
set -x
#openssl genrsa -out ca/myswarmrootCA.key 2048
#openssl req -x509 -new -nodes -key ca/myswarmrootCA.key -days 3651 -out ca/myswarmrootCA.crt -subj '//O=Myswarm docker Sample\CN=Myswarm Root CA'
#openssl genrsa -out host/myswarmregistry.key 2048
#openssl req -new -key host/myswarmregistry.key -out myswarmregistry.csr -subj '//O=Myswarm docker sample\CN=myswarmregistry'
#openssl x509 -req -in myswarmregistry.csr -CA ca/myswarmrootCA.crt -CAkey ca/myswarmrootCA.key -CAcreateserial -out host/myswarmregistry.crt -days 3650
#rm -f myswarmregistry.csr
openssl req -newkey rsa:4096 -nodes -sha256 -keyout host/myswarmregistry.key -x509 -days 365 -out host/myswarmregistry.crt -subj '//O=Myswarm docker sample\CN=myswarmregistry'
exec bash # dont close window when done