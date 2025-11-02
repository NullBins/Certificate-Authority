<div align="center">
  <h1>[ The Linux🔐CA Servers Configuration ]</h1>
</div>

###### 📚 Repository for records of how to setup CA servers [ *Written by NullBins* ]
- By default, the commands are executed as a root user.
> [![Video](http://img.youtube.com/vi/jYXW3Qvwke4/0.jpg)](https://www.youtube.com/watch?v=jYXW3Qvwke4)

<br/>

- *1) Certificate Authority Server Configuration*

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
vim /usr/lib/ssl/misc/CA.pl
```
>```perl
>my $CATOP = "/etc/ssl/CA";
>```
```vim
/usr/lib/ssl/misc/CA.pl -newca          📌 CN=VDI-CA
cp /etc/ssl/CA/cacert.pem /usr/local/share/ca-certificates/ca.crt
update-ca-certificates
mkdir /CERT/; cd /CERT/; cp /etc/ssl/CA/cacert.pem /CERT/vdi-CA.crt
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
vim /CERT/cert.sh
```
>```vim
>#!/bin/bash
>
>### A NEW CERTIFICATE SIGN UP
>read -p "Input the filename: " in
>openssl req -new -out /CERT/$in.req -newkey rsa:2048 -keyout /CERT/$in.key
>openssl ca -in /CERT/$in.req -out /CERT/$in.crt -extfile extlist
>rm -f /CERT/$in.req
>
>exit 0
>```
```vim
chmod 700 /CERT/cert.sh
```
```vim
vim /root/.bashrc
```
>```vim
>alias cert='/CERT/cert.sh'
>```
```vim
source /root/.bashrc
```

<br/>

- *2) Enable to CRL Service*

<br/>

```vim
cd /CERT/
cert
  Input the filename: crl      📌 CN=crl.vdi.local
apt install -y apache2
openssl ca -gencrl -out /var/www/html/vdi-CA.crl
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
>SSLCertificateFile /CERT/crl.crt
>SSLCertificateKeyFile /CERT/crl.key
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

- *3) Enable to OCSP Service*

<br/>

```vim
cd /CERT/
openssl req -new -out ocsp.req -newkey rsa:2048 -keyout ocsp.key  📌 CN=ocsp.vdi.local
openssl ca -in ocsp.req -out ocsp.crt -extensions v3_ocsp
rm -f ocsp.req
```
```vim
vim ./ocsp.sh
```
>```vim
>#!/bin/bash
>### OCSP
>openssl ocsp -CA /CERT/vdi-CA.crt -rsigner /CERT/ocsp.crt -rkey /CERT/ocsp.key -port 8080 -index /etc/ssl/CA/index.txt
>```
```vim
chmod 700 ocsp.sh
```
```vim
vim /etc/crontab
```
>```vim
>@reboot  root    sleep 20; nohup /CERT/ocsp.sh &
>```
```vim
systemctl restart cron
reboot
ss -antp4 | grep openssl
```
