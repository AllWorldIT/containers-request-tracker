FROM registry.gitlab.iitsp.com/allworldit/docker/alpine:latest

ARG VERSION_INFO
LABEL maintainer="Nigel Kukard <nkukard@LBSD.net>"

ENV RT_VERSION=4.4.4
ENV RT_EXTENSION_JSGANTT=1.04
ENV RT_EXTENSION_REPEATTICKET=1.11
ENV RT_EXTENSION_RESETPASSWORD=1.05

# Copy in patches so we can patch below...
COPY patches/ /root/patches/

RUN set -eux; \
	true "Nginx"; \
	apk add --no-cache nginx; \
	ln -sf /dev/stdout /var/log/nginx/access.log; \
	ln -sf /dev/stderr /var/log/nginx/error.log; \
	true "Spawn-FCGI"; \
	apk add --no-cache spawn-fcgi; \
	true "MariaDB"; \
	apk add --no-cache mariadb mariadb-client mariadb-server-utils pwgen; \
	true "Perl"; \
	apk add --no-cache perl; \
#	true "Groups"; \
#	addgroup -g 82 -S www-data; \
	true "Users"; \
	adduser -u 82 -D -S -H -h /var/www/html -G www-data www-data; \
	adduser -u 500 -D -H -h /opt/rt -G www-data -g 'RT user' rt; \
	true "RT requirements"; \
	apk add --no-cache \
		perl \
		perl-libwww \
		perl-term-readkey \
		perl-html-scrubber \
		perl-css-squish \
		perl-devel-globaldestruction \
		perl-xml-rss \
		perl-data-page \
		perl-html-mason \
		perl-html-mason-psgihandler \
		perl-symbol-global-name \
		perl-datetime-format-natural \
		perl-business-hours \
		perl-plack \
		perl-text-template \
		perl-html-parser \
		perl-module-refresh \
		perl-net-ip \
		perl-html-rewriteattributes \
		perl-convert-color \
		perl-locale-maketext-fuzzy \
		perl-data-guid \
		perl-regexp-common \
		perl-scope-upper \
		perl-mime-tools \
		perl-regexp-common-net-cidr \
		perl-text-password-pronounceable \
		perl-html-formattext-withlinks-andtables \
		perl-json \
		perl-email-address \
		perl-locale-maketext-lexicon \
		perl-module-versions-report \
		perl-tree-simple \
		perl-date-extract \
		perl-mime-types \
		perl-universal-require \
		perl-log-dispatch \
		perl-date-manip \
		perl-net-cidr \
		perl-text-wrapper \
		perl-text-quoted \
		perl-html-quoted \
		perl-email-address-list \
		perl-regexp-ipv6 \
		perl-css-minifier-xs \
		perl-apache-session \
		perl-role-basic \
		perl-data-page-pageset \
		perl-crypt-eksblowfish \
		perl-javascript-minifier-xs \
		perl-data-ical \
		perl-text-wikiformat \
		perl-cgi-emulate-psgi \
		perl-starlet \
		perl-fcgi \
		perl-lwp-protocol-https \
		perl-mozilla-ca \
		perl-fcgi-procmanager \
		perl-net-ldap \
		perl-gd \
		perl-graphviz \
		perl-string-shellquote \
		perl-crypt-x509 \
		mariadb-connector-c \
		perl-dbi \
		perl-dbd-mysql \
		# DO NOT ADD, CRASHES DUE TO USE AFTER DISCONNECT
#		perl-dbix-searchbuilder \
		# DBIx::SearchBuilder deps
		perl-class-returnvalue perl-cache-simple-timedexpiry perl-class-accessor perl-clone perl-want perl-dbix-dbschema \
		perl-time-parsedate \
	; \
	true "RT requirements: from CPAN"; \
	apk add --no-cache --virtual .build-deps \
		make perl-dev perl-module-install \
		# DBIx::SearchBuilder
		alpine-sdk perl-dbd-sqlite perl-want; \
	\
	# Make build directory
	mkdir /root/build; \
	# DO NOT REMOVE, FIXES SEGFAULT CRASH
	true "Build DBIx::SearchBuilder"; \
	cd /root/build; \
	wget "https://cpan.metacpan.org/authors/id/B/BP/BPS/DBIx-SearchBuilder-1.67.tar.gz"; \
	tar zxvf "DBIx-SearchBuilder-1.67.tar.gz"; \
	cd "DBIx-SearchBuilder-1.67"; \
	patch -p1 < /root/patches/DBIx-SearchBuilder/DBIx-SearchBuilder-1.67_mariadb-fix.patch; \
	perl Makefile.PL; \
	make; make install; \
	\
	true "RT download"; \
	cd /root/build; \
	wget "https://download.bestpractical.com/pub/rt/release/rt-${RT_VERSION}.tar.gz"; \
	tar -zxvf "rt-${RT_VERSION}.tar.gz"; \
	cd "rt-${RT_VERSION}"; \
	true "RT patching"; \
	for i in /root/patches/*.patch; do patch -p1 < $i; done; \
	true "RT configuration"; \
	./configure --enable-externalauth; \
	true "RT dependency test"; \
	make testdeps; \
	true "RT install"; \
	make install; \
	\
	true "RT extension RT::Extension::RepeatTicket"; \
	cd /root/build; \
	wget "https://cpan.metacpan.org/authors/id/B/BP/BPS/RT-Extension-RepeatTicket-${RT_EXTENSION_REPEATTICKET}.tar.gz"; \
	tar -zxvf "RT-Extension-RepeatTicket-${RT_EXTENSION_REPEATTICKET}.tar.gz"; \
	cd "RT-Extension-RepeatTicket-${RT_EXTENSION_REPEATTICKET}"; \
	perl Makefile.PL; \
	make; make install; \
	\
	true "RT extension RT::Extension::JSGantt"; \
	cd /root/build; \
	wget "https://cpan.metacpan.org/authors/id/B/BP/BPS/RT-Extension-JSGantt-${RT_EXTENSION_JSGANTT}.tar.gz"; \
	tar -zxvf "RT-Extension-JSGantt-${RT_EXTENSION_JSGANTT}.tar.gz"; \
	cd "RT-Extension-JSGantt-${RT_EXTENSION_JSGANTT}"; \
	perl Makefile.PL; \
	make; make install; \
	\
	true "RT extension RT::Extension::ResetPassword"; \
	cd /root/build; \
	wget "https://cpan.metacpan.org/authors/id/B/BP/BPS/RT-Extension-ResetPassword-${RT_EXTENSION_RESETPASSWORD}.tar.gz"; \
	tar -zxvf "RT-Extension-ResetPassword-${RT_EXTENSION_RESETPASSWORD}.tar.gz"; \
	cd "RT-Extension-ResetPassword-${RT_EXTENSION_RESETPASSWORD}"; \
	perl Makefile.PL; \
	make; make install; \
	\
	true "Versioning"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	true "Cleanup"; \
	apk del .build-deps; \
	rm -rf /root/.cpan /root/patches /root/build; \
	rm -f /var/cache/apk/*

## Nginx configuration
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d/rt.conf /etc/nginx/conf.d/default.conf
COPY etc/nginx/rt.conf.fastcgi /etc/nginx/rt.conf.fastcgi
COPY etc/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
COPY init.d/50-nginx.sh /docker-entrypoint-init.d/50-nginx.sh
RUN set -eux \
		chown root:root \
			/etc/nginx/nginx.conf \
			/etc/nginx/conf.d/default.conf \
			/etc/nginx/rt.conf.fastcgi \
			/etc/supervisor/conf.d/nginx.conf \
			/docker-entrypoint-init.d/50-nginx.sh; \
		chmod 0644 \
			/etc/nginx/nginx.conf \
			/etc/nginx/conf.d/default.conf \
			/etc/nginx/rt.conf.fastcgi \
			/etc/supervisor/conf.d/nginx.conf; \
		chmod 0755 \
			/docker-entrypoint-init.d/50-nginx.sh
EXPOSE 80

# spawn-fcgi
COPY etc/supervisor/conf.d/spawn-fcgi.conf /etc/supervisor/conf.d/spawn-fcgi.conf
RUN set -eux \
		chown root:root /etc/supervisor/conf.d/spawn-fcgi.conf; \
		chmod 0644 /etc/supervisor/conf.d/spawn-fcgi.conf

# MariaDB
COPY etc/my.cnf.d/docker.cnf /etc/my.cnf.d/docker.cnf
COPY etc/supervisor/conf.d/mariadb.conf /etc/supervisor/conf.d/mariadb.conf
COPY init.d/50-mariadb.sh /docker-entrypoint-init.d/50-mariadb.sh
COPY pre-init-tests.d/50-mariadb.sh /docker-entrypoint-pre-init-tests.d/50-mariadb.sh
RUN set -eux \
		chown root:root \
			/etc/my.cnf.d/docker.cnf \
			/etc/supervisor/conf.d/mariadb.conf \
			/docker-entrypoint-init.d/50-mariadb.sh \
			/docker-entrypoint-pre-init-tests.d/50-mariadb.sh; \
		chmod 0644 \
			/etc/my.cnf.d/docker.cnf \
			/etc/supervisor/conf.d/mariadb.conf; \
		chmod 0755 \
			/docker-entrypoint-init.d/50-mariadb.sh \
			/docker-entrypoint-pre-init-tests.d/50-mariadb.sh
VOLUME ["/var/lib/mysql"]

# RT
COPY sbin/rt-ldap-importer /usr/local/sbin/
COPY init.d/70-rt.sh /docker-entrypoint-init.d/70-rt.sh
COPY pre-init-tests.d/50-rt.sh /docker-entrypoint-pre-init-tests.d/50-rt.sh
RUN set -eux \
		chown root:root \
			/usr/local/sbin/rt-ldap-importer \
			/docker-entrypoint-init.d/70-rt.sh \
			/docker-entrypoint-pre-init-tests.d/50-rt.sh; \
		chmod 0755 \
			/usr/local/sbin/rt-ldap-importer \
			/docker-entrypoint-init.d/70-rt.sh \
			/docker-entrypoint-pre-init-tests.d/50-rt.sh
#COPY backup /root/

