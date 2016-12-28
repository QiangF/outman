#!/bin/bash

## */5 * * * * bash /usr/local/bin/ss.sh

datetime=`date --date=now +"%F %T"`
username=`whoami`
  config="${HOME}/${username}.json"
pid_file="/tmp/${username}.pid"
## XXX ls -lh /|egrep 'run|tmp'
## drwxr-xr-x 15 root root  560 Feb  5 09:36 run/
## drwxrwxrwt 13 root root  700 Feb 29 22:52 tmp/

## Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
#exec > >(tee "/tmp/${username}.ss.log")
#exec 2>&1

if pgrep -af "$config"
then
    echo "__OK: $datetime $username ss-server is running"
else
    ss-server -c "$config" -f "$pid_file" && echo "__OK: $datetime $username ss-server is started"
fi

#pgrep -af "${username}.json"


