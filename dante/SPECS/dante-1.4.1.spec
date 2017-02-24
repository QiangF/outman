%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

Name:       dante
Version:    1.4.1
Release:    1%{?dist}
Summary:    Dante is a circuit-level SOCKS client/server that can be used to provide convenient and secure network connectivity.

Group:      Applications/Internet
License:    GPLv3+
URL:        http://www.inet.no/%{name}/
Source0:    %{url}/files/%{name}-%{version}.tar.gz
Source1:    sockd.service
Source2:    sockd.init
## https://gitweb.gentoo.org/repo/gentoo.git/tree/net-proxy/dante/files/dante-1.4.0-HAVE_SENDBUF_IOCTL.patch
## diff -u libscompat.m4.orig libscompat.m4
Patch0:     dante-1.4.1-sendbuf_macro.patch
## https://gitweb.gentoo.org/repo/gentoo.git/tree/net-proxy/dante/files/dante-1.4.0-socksify.patch
Patch1:     dante-1.4.1-socksify.patch

BuildRequires:  autoconf automake bison flex libtool pam-devel

%if 0%{?fedora} >= 15 || 0%{?rhel} >=7
%global use_systemd 1
%else
%global use_systemd 0
%endif

%if 0%{?use_systemd}
%{?systemd_requires}
BuildRequires:   systemd
%endif

%description
Dante is a product developed by Inferno Nettverk A/S. It consists of a SOCKS server and a SOCKS client, implementing RFC 1928 and related standards. It is a flexible product that can be used to provide convenient and secure network connectivity.


%prep
%setup -q
## if do this from the subdirectory of ~/rpmbuild/BUILD then u won't have to specify a `-p` level later.
## ~/rpmbuild/BUILD/dante-1.4.1/libscompat.m4
%patch0 -p1
%patch1

%build

## https://gitweb.gentoo.org/repo/gentoo.git/tree/net-proxy/dante/dante-1.4.1-r1.ebuild
sed -i -e 's:/etc/socks\.conf:/etc/dante/socks.conf:' \
       -e 's:/etc/sockd\.conf:/etc/dante/sockd.conf:' \
       doc/{socksify.1,socks.conf.5,sockd.conf.5,sockd.8}

## find /lib64/ -maxdepth 1 -iname "libc.so.*"
#DANTE_LIBC=$(find /%{_lib}/ -maxdepth 1 -iname "libc.so.*"|awk -F '/' '{print $3}')
DANTE_LIBC=$(find /%{_lib}/ -maxdepth 1 -iname "libc.so.*")

touch acinclude.m4
## https://github.com/pld-linux/dante/blob/master/dante-am.patch
sed -i -e 's:AM_CONFIG_HEADER:AC_CONFIG_HEADERS:' configure.ac
autoreconf --force --install --verbose

## configure 'prototypes' check FAILED with CFLAGS '-grecord-gcc-switches' option
## https://build.opensuse.org/package/view_file/server:proxy/dante/dante.spec
CFLAGS=$(echo "%{optflags}" | sed "s|-grecord-gcc-switches||")

### https://gitweb.gentoo.org/repo/gentoo.git/tree/net-proxy/dante/files/dante-1.4.0-cflags.patch
### NOTE: NOT WORK. configure 'prototypes' check still FAILED
#CFLAGS=$(echo "%{optflags}"|sed -e 's/ -g\>//g')

## https://github.com/pld-linux/dante/blob/master/dante-build.patch

%configure --disable-static --enable-shared --with-pic --with-libc=$DANTE_LIBC \
           --enable-preload --enable-clientdl --enable-serverdl --enable-drt-fallback \
           --without-gssapi --without-libwrap --without-upnp --without-glibc-secure \
           --sysconfdir=/etc/dante --with-socks-conf=/etc/dante/socks.conf --with-sockd-conf=/etc/dante/sockd.conf

make %{?_smp_mflags} V=1


%install
export DONT_STRIP=1
make install DESTDIR=%{buildroot}

## /etc/dante
mkdir -pv %{buildroot}/%{_sysconfdir}/%{name}
install -m 644 example/sock{s,d}.conf %{buildroot}/%{_sysconfdir}/%{name}

mkdir -pv %{buildroot}%{_sysconfdir}/default

%if 0%{?use_systemd}
mkdir -pv %{buildroot}/%{_unitdir}
install -m 644 %{SOURCE1} %{buildroot}/%{_unitdir}/sockd.service
%else
## https://github.com/pld-linux/dante/blob/master/sockd.init
mkdir -pv %{buildroot}/%{_initddir}
install -m 755 %{SOURCE2} %{buildroot}/%{_initddir}/sockd
%endif

%post   -p /sbin/ldconfig

%preun
%if 0%{?use_systemd}
%systemd_preun sockd.service
%else
if [ $1 -eq 0 ]
then
    /sbin/service sockd stop  > /dev/null 2>&1 || :
    /sbin/chkconfig --del sockd > /dev/null 2>&1 || :
fi
%endif

%postun -p /sbin/ldconfig
%if 0%{?use_systemd}
%systemd_postun_with_restart sockd.service
%endif

%files
%{_bindir}/*
%{_libdir}/*
%{_sbindir}/*
%{_includedir}/*
%config(noreplace) %verify(not md5 mtime size) %{_sysconfdir}/%{name}/*.conf
### files beginning with two capital letters are docs: BUGS, README.foo etc.
#%doc [A-Z][A-Z]*
%doc BUGS CREDITS INSTALL LICENSE NEWS README SUPPORT UPGRADE doc/README* doc/*.txt doc/*.protocol
%{_mandir}/man1/socksify.1*
%{_mandir}/man5/sock*.conf.5*
%{_mandir}/man8/sockd.8*
## error: File not found: /root/rpmbuild/BUILDROOT/dante-1.4.1-1.el7.centos.x86_64/etc/dante/sock{s,d}.conf
#%config(noreplace) %{_sysconfdir}/%{name}/sock{s,d}.conf
#%{_mandir}/man1/socksify.1.gz

#%defattr(644,root,root,755)
#%config(noreplace) %verify(not md5 mtime size) %{_sysconfdir}/socks.conf
#%attr(755,root,root) %{_libdir}/libsocks.so.*.*.*
#%attr(755,root,root) %ghost %{_libdir}/libsocks.so.0
#%attr(755,root,root) %{_libdir}/libdsocks.so
#%attr(755,root,root) %{_bindir}/socksify

%if 0%{?use_systemd}
%{_unitdir}/sockd.service
%else
%{_initddir}/sockd
%endif

%changelog

