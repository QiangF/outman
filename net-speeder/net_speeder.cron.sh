#!/bin/bash

/bin/pgrep -af 'net_speeder venet0' || /root/net-speeder-master/net_speeder venet0 "ip" 2>&1 > /dev/null &

