#!/bin/bash

## root user
## CentOS7

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [[ $EUID -ne 0 ]]; then
    echo "$0 must be run as root" 1>&2
    exit 1
fi

if fgrep -q ' 7' /etc/redhat-release
then
    :
else
    echo "__ERROR: $0 only support RHEL/CentOS 7" 1>&2
    exit 1
fi

version='2.5.5'
rpm_dir=/tmp/build_ss
src_md5='f4593a1ee28f4f8c5378662e0ab2764b'
src_tgz="${rpm_dir}/SOURCES/shadowsocks-libev-${version}.tar.gz"
src_url="https://github.com/shadowsocks/shadowsocks-libev/archive/v${version}.tar.gz"
spec_name="${rpm_dir}/SPECS/shadowsocks-libev.spec"

if [ ! -d "$rpm_dir" ]
then
    mkdir -pv "${rpm_dir}"/{SPECS,SOURCES}
fi

if [ -s "$src_tgz" ]
then
    md5_check=$(md5sum $src_tgz|awk '{print $1}')
    if [ x"$src_md5" != x"$md5_check" ]
    then
        rm -fv "$src_tgz"
        curl -# -L -C - "$src_url" -o "$src_tgz"
    fi
else
    curl -# -L -C - "$src_url" -o "$src_tgz"
fi

md5_check=$(md5sum $src_tgz|awk '{print $1}')

if [ x"$src_md5" != x"$md5_check" ]
then
    rm -fv "$src_tgz"
    echo "__ERROR: download '$src_tgz' FAILED, exit 1" 1>&2
    exit 1
fi

## save file at current dir, '-J' can not overwrite file
## curl -# -v -C - -LOJ "$src_url"
## curl -C - -LOJ -Ss "$src_url"

echo "__INFO: \$PWD $PWD"
pushd "$rpm_dir"

ls -lh $src_tgz

## README: yum install gcc autoconf libtool automake make zlib-devel openssl-devel asciidoc xmlto
## autoconf.noarch : A GNU tool for automatically configuring source code
## libtool.x86_64 : The GNU Portable Library Tool
## automake.noarch : A GNU tool for automatically creating Makefiles
## xmlto.x86_64 : A tool for converting XML files to various formats

dep_pkg='gcc openssl-devel libsodium rpm-build'
rpm -q $dep_pkg || yum install -y $dep_pkg

## 1. --disable-documentation or build depend 'asciidoc' a lot of X11 packages

echo "Name:shadowsocks-libev
Version:${version}
Release:1%{?dist}
Summary:A lightweight and secure socks5 proxy

Group:Applications/Internet
License:GPLv3+
URL:https://github.com/shadowsocks-libev/%{name}
Source0:${src_tgz}

BuildRequires:openssl-devel
Requires:openssl

%if 0%{?rhel} != 6
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd
BuildRequires: systemd
%endif

Conflicts:python-shadowsocks python3-shadowsocks

AutoReq:no

%description
shadowsocks-libev is a lightweight secured scoks5 proxy for embedded devices and low end boxes.

%prep
%setup -q

%build
%configure --enable-shared --disable-documentation
make %{?_smp_mflags}

%install
make install DESTDIR=%{buildroot}
mkdir -p %{buildroot}/etc/shadowsocks-libev
%if 0%{?rhel} == 6
mkdir -p %{buildroot}%{_initddir}
install -m 755 %{_builddir}/%{buildsubdir}/rpm/SOURCES/etc/init.d/shadowsocks-libev %{buildroot}%{_initddir}/shadowsocks-libev
%else
mkdir -p %{buildroot}%{_sysconfdir}/default
mkdir -p %{buildroot}%{_unitdir}
install -m 644 %{_builddir}/%{buildsubdir}/debian/shadowsocks-libev.default %{buildroot}%{_sysconfdir}/default/shadowsocks-libev
install -m 644 %{_builddir}/%{buildsubdir}/debian/shadowsocks-libev.service %{buildroot}%{_unitdir}/shadowsocks-libev.service
%endif
install -m 644 %{_builddir}/%{buildsubdir}/debian/config.json %{buildroot}%{_sysconfdir}/shadowsocks-libev/config.json

%post
%if 0%{?rhel} == 6
/sbin/chkconfig --add shadowsocks-libev
%else
%systemd_post shadowsocks-libev.service
%endif

%preun
%if 0%{?rhel} == 6
if [ $1 -eq 0 ]; then
    /sbin/service shadowsocks-libev stop
    /sbin/chkconfig --del shadowsocks-libev
fi
%else
%systemd_preun shadowsocks-libev.service
%endif

%if 0%{?rhel} != 6
%postun
%systemd_postun_with_restart shadowsocks-libev.service
%endif

%files
%{_bindir}/*
%{_libdir}/*
%config(noreplace) %{_sysconfdir}/shadowsocks-libev/config.json
%if 0%{?rhel} == 6
%{_initddir}/shadowsocks-libev
%else
%{_unitdir}/shadowsocks-libev.service
%config(noreplace) %{_sysconfdir}/default/shadowsocks-libev
%endif

%package devel
Summary:    Development files for shadowsocks-libev
License:    GPLv3+

%description devel
Development files for shadowsocks-libev

%files devel
%{_includedir}/*

%changelog" > "${spec_name}"

time rpmbuild -bb ${spec_name} --define "%_topdir $PWD"

popd
echo "__INFO: \$PWD $PWD"
