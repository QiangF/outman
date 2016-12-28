%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

Name:		shadowsocks-libev
Version:	2.5.6
Release:	1%{?dist}
Summary:	A lightweight and secure socks5 proxy

Group:		Applications/Internet
License:	GPLv3+
URL:		https://github.com/shadowsocks/%{name}
Source0:	%{url}/archive/v%{version}.tar.gz

AutoReq:        no
Conflicts:	    python-shadowsocks python3-shadowsocks
BuildRequires:	make gcc openssl-devel
Requires:       openssl

%if 0%{?fedora} >= 15 || 0%{?rhel} >=7
%global use_systemd 1
%else
%global use_systemd 0
%endif

%if 0%{?use_systemd}
%{?systemd_requires}
BuildRequires:   systemd
%endif

%if 0%{?use_system_lib}
BuildRequires:  libev-devel libsodium-devel >= 1.0.4 udns-devel
Requires:       libev libsodium >= 1.0.4 udns
%endif


%description
shadowsocks-libev is a lightweight secured scoks5 proxy for embedded devices and low end boxes.


%prep
%setup -q


%build
%if 0%{?use_system_lib}
%configure --enable-shared --enable-system-shared-lib --disable-documentation
%else
%configure --enable-shared --disable-documentation
%endif
make %{?_smp_mflags}


%install
export DONT_STRIP=1
make install DESTDIR=%{buildroot}
mkdir -p %{buildroot}/etc/shadowsocks-libev
%if ! 0%{?use_systemd}
mkdir -p %{buildroot}%{_initddir}
install -m 755 %{_builddir}/%{buildsubdir}/rpm/SOURCES/etc/init.d/shadowsocks-libev %{buildroot}%{_initddir}/shadowsocks-libev
%else
mkdir -p %{buildroot}%{_sysconfdir}/default
mkdir -p %{buildroot}%{_unitdir}
install -m 644 %{_builddir}/%{buildsubdir}/debian/shadowsocks-libev.default %{buildroot}%{_sysconfdir}/default/shadowsocks-libev
install -m 644 %{_builddir}/%{buildsubdir}/debian/shadowsocks-libev.service %{buildroot}%{_unitdir}/shadowsocks-libev.service
install -m 644 %{_builddir}/%{buildsubdir}/debian/shadowsocks-libev-*.service %{buildroot}%{_unitdir}/
%endif
install -m 644 %{_builddir}/%{buildsubdir}/debian/config.json %{buildroot}%{_sysconfdir}/shadowsocks-libev/config.json

%pre

%post
%if ! 0%{?use_systemd}
/sbin/chkconfig --add shadowsocks-libev > /dev/null 2>&1 || :
%else
%systemd_post shadowsocks-libev.service
%endif

%preun
%if ! 0%{?use_systemd}
if [ $1 -eq 0 ]; then
    /sbin/service shadowsocks-libev stop  > /dev/null 2>&1 || :
    /sbin/chkconfig --del shadowsocks-libev > /dev/null 2>&1 || :
fi
%else
%if 0%{?suse_version}
%service_del_preun shadowsocks-libev.service
%else
%systemd_preun shadowsocks-libev.service
%endif
%endif

%postun
%if 0%{?use_systemd}
%systemd_postun_with_restart shadowsocks-libev.service
%endif

%files
%{_bindir}/*
%{_libdir}/*
%{_includedir}/*
%config(noreplace) %{_sysconfdir}/shadowsocks-libev/config.json
%if ! 0%{?use_systemd}
%{_initddir}/shadowsocks-libev
%else
%{_unitdir}/shadowsocks-libev.service
%{_unitdir}/shadowsocks-libev-*.service
%config(noreplace) %{_sysconfdir}/default/shadowsocks-libev
%endif

%changelog

