#!/bin/bash

### A NEW CERTIFICATE SIGN UP
read -p "Input the filename: " in
openssl req -new -out /CERT/$in.req -newkey rsa:2048 -keyout /CERT/$in.key
openssl ca -in /CERT/$in.req -out /CERT/$in.crt -extfile extlist
rm -f /CERT/$in.req

exit 0
