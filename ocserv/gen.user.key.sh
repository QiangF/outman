#!/bin/bash

if [[ -z "$1" ]]
then
    echo "$0 username"
    exit 2
fi

    user="$1"
   ca_cn='outman'
    ca_o='outman org'
   ca_ou='outman ou'
 crt_dir=/etc/ocserv/certs
  ca_key="${crt_dir}/ca-key.pem"
  ca_crt="${crt_dir}/ca.crt"
user_key="${crt_dir}/user-${user}-key.pem"
user_crt="${crt_dir}/user-${user}-crt.pem"
user_p12="${crt_dir}/user-${user}.p12"
    tmpl="${crt_dir}/user-${user}.tmpl"
key_size=2048

[ -d "$crt_dir" ] || mkdir -pv "$crt_dir"

if [[ -s "$ca_key" && -s "$ca_crt" ]]
then

    echo "--------------------------------------------"
    echo "__DO: create user private key: $user_key"
    echo "--------------------------------------------"

    [ -s "$user_key" ] || certtool --generate-privkey --bits "$key_size" --outfile "$user_key"

    echo "--------------------------------------------"
    echo "__DO: create user template file: $tmpl"
    echo "--------------------------------------------"

    echo "cn = '${ca_cn}'
    organization = '${ca_o}'
    unit = '${ca_ou}'
    uid = '${user}'
    expiration_days = 3650
    signing_key
    tls_www_client"|sed 's/^\s\+//g' > "$tmpl" && cat "$tmpl"

    ## |sed 's/^\s\+//g'

    echo "--------------------------------------------"
    echo "__DO: sign user cert file: $user_crt"
    echo "--------------------------------------------"

    certtool --generate-certificate \
             --load-ca-privkey "$ca_key" \
             --load-ca-certificate "$ca_crt" \
             --template "$tmpl" \
             --load-privkey "$user_key" --outfile "$user_crt"

    ## passwd=`tr -cd '[:alnum:]-/:;()$&@".,?!'\' < /dev/urandom | head -c16 | paste`
    passwd=$(cat /dev/urandom | tr -cd '[:alnum:](.\-:)' | head -c16 | paste)

    echo "--------------------------------------------"
    echo "__DO: gen user p12 key: $user_p12"
    echo "__PASSWORD: $passwd"
    echo "--------------------------------------------"

    certtool --to-p12 --pkcs-cipher 3des-pkcs12 \
             --load-privkey "$user_key" \
             --load-certificate "$user_crt" \
             --p12-name "$user" --password "$passwd" \
             --outfile "$user_p12" --outder

    echo "--------------------------------------------"

    ls -lh "$user_p12"
    chmod 644 "$user_p12"
    rm -fv "$tmpl"
    echo "$user $passwd" >> "${crt_dir}/p12pass"

else
    echo "__ERROR: $ca_key or $ca_crt NOT exist"
    exit 2
fi
