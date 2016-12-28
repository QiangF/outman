#!/bin/bash

## TODO
## 1. pgrep + port check
## 2. fast_open default False for BSD / OpenVZ

if [[ $# -ne 2 ]]
then
    echo "usage: $0 user_name port"
    exit 2
fi

pub_key="/home/${1}/.ssh/authorized_keys"
#passwd=`tr -cd '[:graph:]' < /dev/urandom|head -c16|sed 's/["'"'"'\`]/./g'|paste`
 passwd=$(cat /dev/urandom | tr -cd '[:alnum:]' | head -c16 | paste)
 config="/home/${1}/${1}.json"

## --------------------------------------------


cat > /tmp/ss.sh <<- EOF
#!/bin/bash

## */5 * * * * bash /usr/local/bin/ss.sh

datetime=\`date --date=now +"%F %T"\`
username=\`whoami\`
  config="\${HOME}/\${username}.json"
pid_file="/tmp/\${username}.pid"
## XXX ls -lh /|egrep 'run|tmp'
## drwxr-xr-x 15 root root  560 Feb  5 09:36 run/
## drwxrwxrwt 13 root root  700 Feb 29 22:52 tmp/

## Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
#exec > >(tee "/tmp/\${username}.ss.log")
#exec 2>&1

if pgrep -af "\$config"
then
    echo "__OK: \$datetime \$username ss-server is running"
else
    ss-server -c "\$config" -f "\$pid_file" && echo "__OK: \$datetime \$username ss-server is started"
fi

#pgrep -af "\${username}.json"


EOF

[ -s /tmp/ss.sh ] || { echo "__ERROR: /tmp/ss.sh NOT exist"; exit 2; }

chmod 755 /tmp/ss.sh

tmpfile_hash=`md5sum /tmp/ss.sh|awk '{print $1}'|xargs`

if [ -s /usr/local/bin/ss.sh ]
then
    usrfile_hash=`md5sum /usr/local/bin/ss.sh|awk '{print $1}'|xargs`
    if [ "$tmpfile_hash"x != "$usrfile_hash"x ]
    then
        echo "__UPDATE: update /usr/local/bin/ss.sh"
        cp -fv /tmp/ss.sh /usr/local/bin/ss.sh
    fi
    ls -lhF /usr/local/bin/ss.sh  
else
    mv -v /tmp/ss.sh /usr/local/bin/ss.sh   
fi

## --------------------------------------------

if id "$1" 
then
    echo "__WARNING: $1 user was exist"
else
    useradd -m "$1" || { echo "__ERROR: create user $1 failed"; exit 2; }
    groups cron && gpasswd -a "$1" cron
    echo "${1}:${passwd}"|chpasswd
fi

if ! test -f "$pub_key"
then
    if [ -s /root/.ssh/authorized_keys ]
    then
    ssh_dir="/home/${1}/.ssh"
    if [ ! -d "$ssh_dir" ]
    then
        mkdir -v "$ssh_dir"
        chown "${1}:${1}" "$ssh_dir"
        chmod 700 "$ssh_dir"
        stat -c "%a %A %n" "$ssh_dir"
    fi
    cp -v /root/.ssh/authorized_keys "$pub_key"
    chown -R "${1}:${1}" "$ssh_dir"
    else
    echo "__WARNING: /root/.ssh/authorized_keys NOT exit"
    fi
fi

ls -lhF "/home/$1/.ssh/" "$config"

public_ip=`curl -s whatismyip.akamai.com`

echo "__PUBLIC_IP: $public_ip"

[ -n "$public_ip" ] || { echo "__ERROR: curl PUBLIC IP address failed"; exit 2; }

if [ -s "$config" ]
then
    echo "__WARNING: $config file EXIST, NOT create"
else
    echo "__CREATE: creating $config ..."
cat > "$config" <<- EOF
{
    "server":"$public_ip",
    "server_port":$2,
    "local_port":9090,
    "password":"$passwd",
    "timeout":600,
    "fast_open": true,
    "method":"rc4-md5"
}
EOF
    ## NOTE: openvz NOT support fast_open
    [ -d /proc/vz ] && sed -i '/fast_open/d' $config
fi

cat "$config"

## crontab -l | { cat; echo "0 0 0 0 0 some entry"; } | crontab -
## XXX no no crontab for username
{ crontab -l -u "$1" 2>/dev/null | grep -v 'ss.sh'; echo '*/5 * * * * bash /usr/local/bin/ss.sh'; } | crontab -u "$1" -



