<div align="center">
  <h1>[ The Linux🔐CA Servers Configuration - ECDSA ]</h1>
</div>

###### 📚 Elliptic Curve CA setup guide that mirrors the RSA flow [ *Written by NullBins* ]
- By default, the commands are executed as a root user.

<br/>

- *1) Elliptic Curve (ECDSA) CA Configuration*

<br/>

```vim
apt install -y openssl
```
```vim
vim /etc/ssl/openssl.cnf
```
>```vim
>[ CA_default ]
>dir = /etc/ssl/CA
>x509_extensions = v3_req
>policy = policy_anything
>default_md = sha256
>
>[ req_distinguished_name ]
>countryName_default = KR
>#stateOrProvinceName = Some-State
>0.organizationName_default = VDI
>
>[ v3_req ]
>crlDistributionPoints = URI:https://crl.vdi.local/vdi-CA.crl
>authorityInfoAccess = OCSP;URI:http://ocsp.vdi.local:8080
>
>[ v3_ca ]
>crlDistributionPoints = URI:https://crl.vdi.local/vdi-CA.crl
>authorityInfoAccess = OCSP;URI:http://ocsp.vdi.local:8080
>
>[ v3_ocsp ]
>basicConstraints = CA:FALSE
>keyUsage = nonRepundiation, digitalSignature, keyEncipherment
>extendedKeyUsage = OCSPSigning
>```
```vim
mkdir -p /etc/ssl/CA/private /etc/ssl/CA/newcerts
touch /etc/ssl/CA/index.txt
echo 1000 > /etc/ssl/CA/serial
openssl ecparam -name prime256v1 -genkey -noout -out /etc/ssl/CA/private/ca.key
openssl req -new -x509 -key /etc/ssl/CA/private/ca.key -out /etc/ssl/CA/cacert.pem -days 3650 -config /etc/ssl/openssl.cnf -subj "/C=KR/O=VDI/CN=VDI-ECDSA-CA"
cp /etc/ssl/CA/cacert.pem /usr/local/share/ca-certificates/ca.crt
update-ca-certificates
mkdir -p /CERT/; cd /CERT/; cp /etc/ssl/CA/cacert.pem /CERT/vdi-CA.crt
```
```vim
vim /CERT/extlist
```
>```vim
>crlDistributionPoints = URI:https://crl.vdi.local/vdi-CA.crl
>authorityInfoAccess = OCSP;URI:http://ocsp.vdi.local:8080
>subjectAltName = DNS:*.vdi.local
>```
```vim
cp ./SRC/cert_ecdsa.sh /CERT/cert_ecdsa.sh
chmod 700 /CERT/cert_ecdsa.sh
```
```vim
vim /root/.bashrc
```
>```vim
>alias cert-ecc='/CERT/cert_ecdsa.sh'
>```
```vim
source /root/.bashrc
```

<br/>

- *2) Enable to CRL Service for ECDSA CA*

<br/>

```vim
cd /CERT/
cert-ecc
  Input the filename: crl-ecc      📌 CN=crl.vdi.local
apt install -y apache2
openssl ca -gencrl -out /var/www/html/vdi-CA.crl -config /etc/ssl/openssl.cnf
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/vdi-crl.conf
```
```vim
vim /etc/apache2/sites-available/vdi-crl.conf
```
>```vim
>ServerName crl.vdi.local
>
>DocumentRoot /var/www/html
>
>SSLCertificateFile /CERT/crl-ecc.crt
>SSLCertificateKeyFile /CERT/crl-ecc.key
>
>SSLCACertificatePath /CERT/
>SSLCACertificateFile /CERT/vdi-CA.crt
>```
```vim
a2enmod ssl
a2ensite vdi-crl.conf
systemctl restart apache2
```

<br/>

- *3) Enable to OCSP Service for ECDSA CA*

<br/>

```vim
cd /CERT/
openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -pkeyopt ec_param_enc:named_curve -keyout ocsp-ecc.key -out ocsp-ecc.req -sha256  📌 CN=ocsp.vdi.local
openssl ca -in ocsp-ecc.req -out ocsp-ecc.crt -extensions v3_ocsp -config /etc/ssl/openssl.cnf
rm -f ocsp-ecc.req
```
```vim
vim ./ocsp-ecc.sh
```
>```vim
>#!/bin/bash
>### OCSP
>openssl ocsp -CA /CERT/vdi-CA.crt -rsigner /CERT/ocsp-ecc.crt -rkey /CERT/ocsp-ecc.key -port 8080 -index /etc/ssl/CA/index.txt
>```
```vim
chmod 700 ocsp-ecc.sh
```
```vim
vim /etc/crontab
```
>```vim
>@reboot  root    sleep 20; nohup /CERT/ocsp-ecc.sh &
>```
```vim
systemctl restart cron
reboot
ss -antp4 | grep openssl
```
