
# shadowsocks-libev

    mdkir -pv ~/rpmbuild/{SPECS,SOURCES}
    yum install -y gcc make openssl-devel rpm-build rpmdevtools
    spectool -l -A -R ~/rpmbuild/SPECS/shadowsocks-libev.spec
    spectool -g -A -R ~/rpmbuild/SPECS/shadowsocks-libev.spec
    rpmbuild -bb --clean ~/rpmbuild/SPECS/shadowsocks-libev.spec

# net_speeder

定义 crontab ：

    MAILTO=''
    */15 * * * * bash /root/net-speeder/net_speeder.cron.sh

