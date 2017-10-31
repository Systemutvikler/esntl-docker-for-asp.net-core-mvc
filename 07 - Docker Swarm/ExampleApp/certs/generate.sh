#!/bin/sh
set -x
openssl req -newkey rsa:4096 -nodes -sha256 -keyout host/myswarmregistry.key -x509 -days 3650 -out host/myswarmregistry.crt -subj '//O=Myswarm docker sample\CN=myswarmregistry'
