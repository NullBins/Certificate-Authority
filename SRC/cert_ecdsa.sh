#!/bin/bash

### A NEW ECDSA CERTIFICATE SIGN UP
read -p "Input the filename: " in
openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -pkeyopt ec_param_enc:named_curve -keyout /CERT/$in.key -out /CERT/$in.req -sha256
openssl ca -config /etc/ssl/openssl.cnf -in /CERT/$in.req -out /CERT/$in.crt -extfile extlist
rm -f /CERT/$in.req

exit 0
