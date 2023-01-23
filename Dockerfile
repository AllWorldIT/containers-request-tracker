FROM registry.conarx.tech/containers/nginx/3.17


ARG VERSION_INFO=
LABEL org.opencontainers.image.authors   = "Nigel Kukard <nkukard@conarx.tech>"
LABEL org.opencontainers.image.version   = "3.17"
LABEL org.opencontainers.image.base.name = "registry.conarx.tech/containers/nginx/3.17"


ENV RTHOME=/opt/rt5
ENV RT_VERSION=5.0.3
ENV RT_EXTENSION_JSGANTT=1.07
ENV RT_EXTENSION_REPEATTICKET=2.00
ENV RT_EXTENSION_RESETPASSWORD=1.12


# Copy in patches so we can patch below...
COPY patches/ /root/patches/

RUN set -eux; \
	true "Spawn-FCGI"; \
	apk add --no-cache \
		spawn-fcgi; \
	true "MariaDB"; \
	apk add --no-cache \
		mariadb-client; \
	true "Perl"; \
	apk add --no-cache perl; \
	true "Users"; \
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
		# DO NOT ADD, CRASHES DUE TO USE AFTER DISCONNECT - CAN BE USED WHEN HITS 1.68
		perl-dbix-searchbuilder \
		# DBIx::SearchBuilder deps
		perl-class-returnvalue perl-cache-simple-timedexpiry perl-class-accessor perl-clone perl-want perl-dbix-dbschema \
		perl-time-parsedate \
		perl-encode-hanextra \
		perl-moose \
		perl-moosex \
		perl-json-xs \
		perl-test-failwarnings \
		perl-cookie-baker \
		perl-http-entity-parser \
		perl-parallel-forkmanager \
		html2text \
	; \
	true "RT requirements: from CPAN"; \
	apk add --no-cache --virtual .build-deps \
		make perl-dev perl-module-install \
		alpine-sdk perl-dbd-sqlite perl-want \
		perl-app-cpanminus \
	; \
	\
	# Modules not in alpine
	cpanm --verbose install \
		Encode::Detect::Detector \
		HTML::FormatExternal \
		HTML::Gumbo \
		Module::Path \
		MooseX::NonMoose \
		MooseX::Role::Parameterized \
		Path::Dispatcher \
		HTTP::Headers::ActionPack \
		HTTP::Headers::Fast \
		IO::Handle::Util \
		Web::Machine \
		Text::WordDiff \
	; \
	# Make build directory
	mkdir /root/build; \
	# DO NOT REMOVE, FIXES SEGFAULT CRASH
	#true "Build DBIx::SearchBuilder"; \
	#cd /root/build; \
	#wget "https://cpan.metacpan.org/authors/id/B/BP/BPS/DBIx-SearchBuilder-1.68.tar.gz"; \
	#tar zxvf "DBIx-SearchBuilder-1.68.tar.gz"; \
	#cd "DBIx-SearchBuilder-1.68"; \
	#perl Makefile.PL; \
	#make; make install; \
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
	rm -f "rt-${RT_VERSION}.tar.gz"; \
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
	true "Cleanup"; \
	apk del .build-deps; \
	rm -rf \
		/root/.cpan \
		/root/.cpanm \
		/root/patches \
		/root/build; \
	rm -f /var/cache/apk/*


## Nginx configuration
COPY etc/nginx/http.d/50_vhost_default.conf /etc/nginx/http.d/50_vhost_default.conf
COPY etc/nginx/rt.conf.fastcgi /etc/nginx/rt.conf.fastcgi
RUN set -eux; \
	chown root:root \
		/etc/nginx/http.d/50_vhost_default.conf \
		/etc/nginx/rt.conf.fastcgi; \
	chmod 0644 \
		/etc/nginx/http.d/50_vhost_default.conf \
		/etc/nginx/rt.conf.fastcgi


# spawn-fcgi
COPY etc/supervisor/conf.d/spawn-fcgi.conf /etc/supervisor/conf.d/spawn-fcgi.conf
RUN set -eux; \
	chown root:root /etc/supervisor/conf.d/spawn-fcgi.conf; \
	chmod 0644 /etc/supervisor/conf.d/spawn-fcgi.conf


# RT
COPY sbin/rt-ldap-importer /usr/local/sbin/
COPY usr/local/share/flexible-docker-containers/init.d/46-rt.sh /usr/local/share/flexible-docker-containers/init.d
COPY usr/local/share/flexible-docker-containers/pre-init-tests.d/46-rt.sh /usr/local/share/flexible-docker-containers/pre-init-tests.d
COPY usr/local/share/flexible-docker-containers/tests.d/44-nginx.sh /usr/local/share/flexible-docker-containers/tests.d
RUN set -eux; \
	true "Setup FCGI cache"; \
	mkdir -p /var/lib/fcgicache; \
	chown nginx:root /var/lib/fcgicache; \
	chmod 700 /var/lib/fcgicache; \
	true "Versioning"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	true "Permissions"; \
	chown root:root \
		/usr/local/sbin/rt-ldap-importer; \
	chmod 0755 \
		/usr/local/sbin/rt-ldap-importer; \
	fdc set-perms


VOLUME ["/opt/rt"]
