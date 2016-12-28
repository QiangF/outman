#!/bin/bash

CA_PATH=/etc/ocserv/certs
CA_CN='outman'
CA_ORG='outman org'
CA_KEY="${CA_PATH}/ca-key.pem"
CA_CRT="${CA_PATH}/ca.crt"
KEY_SIZE=2048

## man ocserv

## 1. create CA key
## 2. use CA key self sign CA cert

[ -d "$CA_PATH" ] || mkdir -pv "$CA_PATH"

cd "$CA_PATH"

if [ -s "$CA_CRT" ]
then
    echo "__NOTE: '${CA_CRT}' file exist, nothing todo, exit function"
    exit 1
fi

if [ ! -s "$CA_KEY" ]
then
    ## 1. create CA key
    echo '__INFO: create CA ------------------------------------------------------------------'
    certtool --generate-privkey --bits "$KEY_SIZE" --outfile "$CA_KEY" --debug 9999
fi

echo "cn = '${CA_CN}'
      organization = '${CA_ORG}'
      serial = 1
      expiration_days = 3650
      ca
      signing_key
      cert_signing_key
      crl_signing_key"|sed 's/^\s\+//g' > ca.tmpl

echo '__INFO: CA config ------------------------------------------------------------------'
cat ca.tmpl

echo '__INFO: self sign ------------------------------------------------------------------'
## 2. use CA key self sign CA cert
certtool --generate-self-signed --load-privkey "$CA_KEY" --template ca.tmpl --outfile "$CA_CRT"

