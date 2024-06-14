#!/bin/bash


wait_for_db() {
	while true; do
		fdc_notice "RequestTracker waiting for MySQL server '$MYSQL_HOST'..."
		export MYSQL_PWD="$MYSQL_PASSWORD"
		if mariadb-admin ping --skip-ssl --host "$MYSQL_HOST" --user "$MYSQL_USER" --silent --connect-timeout=2; then
			break
		fi
		unset MYSQL_PWD
		sleep 1
	done
}


# Setup database credentials
cat <<EOF > /root/.my.cnf
[client]
host=$MYSQL_HOST
user=$MYSQL_USER
password=$MYSQL_PASSWORD
EOF


# Save root password for RT access
cat <<EOF > /root/.rt_dba_password
$MYSQL_ROOT_PASSWORD
EOF


# Create new configuration file
cat <<EOF > /opt/rt5/etc/RT_SiteConfig.d/00-default.pm
use utf8;

Set(\$DatabaseType, "mysql");
Set(\$DatabaseRTHost, "$MYSQL_HOST");
Set(\$DatabaseHost, "$MYSQL_HOST");
Set(\$DatabaseUser, "$MYSQL_USER");
Set(\$DatabasePassword, "$MYSQL_PASSWORD");
Set(\$DatabaseName, "$MYSQL_DATABASE");

Set(\$ExternalStorageCutoffSize, 10_000);
Set(%ExternalStorage,
	Type => 'Disk',
	Path => '/opt/rt5/var/attachments',
);

EOF


# Link in our own config file...
if [ ! -e /opt/rt/RT_SiteConfig.pm ]; then
	touch /opt/rt/RT_SiteConfig.pm
	chown rt:www-data /opt/rt/RT_SiteConfig.pm
	chmod 640 /opt/rt/RT_SiteConfig.pm
fi
ln -s /opt/rt/RT_SiteConfig.pm /opt/rt5/etc/RT_SiteConfig.d/50-custom.pm


# Make sure we have an attachments directory setup
if [ ! -d /opt/rt/var/attachments ]; then
	mkdir -p /opt/rt/var/attachments
	chown rt:www-data /opt/rt/var/attachments
	chmod 750 /opt/rt/var/attachments
fi
# Link attachments directory in
ln -s /opt/rt/var/attachments /opt/rt5/var/


# Make sure we have a shredder directory setup
if [ ! -d /opt/rt/var/data/RT-Shredder ]; then
	mkdir -p /opt/rt/var/data/RT-Shredder
	chown rt:www-data /opt/rt/var/data/RT-Shredder
	chmod 750 /opt/rt/var/data/RT-Shredder
fi
# Make sure the dir exists
if [ ! -d /opt/rt5/var/data ]; then
	mkdir -p /opt/rt5/var/data
fi
# Link it in
ln -s /opt/rt/var/data/RT-Shredder /opt/rt5/var/data/


# Reset permissions on local/html directory which could be mapped in
chown rt:www-data /opt/rt5/local/html
find /opt/rt5/local/html -type d -print0 | xargs -0 -r chmod 0755
find /opt/rt5/local/html -type f -print0 | xargs -0 -r chmod 0644


# Wait for database to become available
wait_for_db


# Check if we need to initialize the database
if [ ! -e /opt/rt/.RT_VERSION ]; then
	fdc_notice "Initialize RequestTracker database"

	# shellcheck disable=SC2164
	cd /opt/rt

	/usr/bin/perl /opt/rt5/sbin/rt-setup-database --action init --skip-create

	echo "$RT_VERSION" > /opt/rt/.RT_VERSION
	fdc_notice "Done initializing RequestTracker database"
fi


RT_VERSION_OLD=$(cat /opt/rt/.RT_VERSION)
if [ "$RT_VERSION" != "$RT_VERSION_OLD" ]; then
	fdc_notice "Upgrade RequestTracker database"

	# shellcheck disable=SC2164
	cd /opt/rt

	/usr/bin/perl /opt/rt5/sbin/rt-setup-database --action upgrade \
		--root-password-file /root/.rt_dba_password \
		--upgrade-from "$RT_VERSION_OLD"

	# Update RT version
	echo "$RT_VERSION" > /opt/rt/.RT_VERSION
	fdc_notice "Done upgrade RequestTracker database"
fi


if [ ! -e /opt/rt/.RT_EXTENSION_REPEATTICKET ]; then
	fdc_notice "Initialize RequestTracker extension RT::Extension::RepeatTicket"

	# shellcheck disable=SC2164
	cd /opt/rt

	# Repeat ticket
	/usr/bin/perl /opt/rt5/sbin/rt-setup-database --action insert --skip-create \
		--datadir "/opt/rt5/local/plugins/RT-Extension-RepeatTicket/etc" \
		--datafile "/opt/rt5/local/plugins/RT-Extension-RepeatTicket/etc/initialdata" \
		--package "q[RT::Extension::RepeatTicket]" --ext-version "q[${RT_EXTENSION_REPEATTICKET}]"
	echo "$RT_EXTENSION_REPEATTICKET" > /opt/rt/.RT_EXTENSION_REPEATTICKET
	fdc_notice "Initialized RequestTracker extension RT::Extension::RepeatTicket"
fi


if [ ! -e /opt/rt/.RT_EXTENSION_RESETPASSWORD ]; then
	fdc_notice "Initialize RequestTracker extension RT::Extension::ResetPassword"

	# shellcheck disable=SC2164
	cd /opt/rt

	# Reset password
	/usr/bin/perl /opt/rt5/sbin/rt-setup-database --action insert --skip-create \
			--datadir "/opt/rt5/local/plugins/RT-Extension-ResetPassword/etc" \
			--datafile "/opt/rt5/local/plugins/RT-Extension-ResetPassword/etc/initialdata" \
			--package "q[RT::Extension::ResetPassword]" --ext-version "q[${RT_EXTENSION_RESETPASSWORD}]"
	echo "$RT_EXTENSION_RESETPASSWORD" > /opt/rt/.RT_EXTENSION_RESETPASSWORD
	fdc_notice "Initialized RequestTracker extension RT::Extension::ResetPassword"
fi


# Create nginx cache directory
if [ ! -d /var/lib/fcgicache ]; then
	mkdir -p /var/lib/fcgicache
fi
chown nginx:root /var/lib/fcgicache
chmod 700 /var/lib/fcgicache


# Setup Postfix transport for rt5
# shellcheck disable=SC2016
echo 'rt unix - n n - - pipe flags=DORhu user=rt argv=/opt/rt5/bin/rt-mailgate --queue $nexthop --action correspond --url http://localhost/' >> /etc/postfix/master.cf


# Setup crontab if we have LDAP configuration
# shellcheck disable=SC2016
if grep -q -E '^\s*Set\(\s*\$LDAPUpdateUsers' /opt/rt5/etc/RT_SiteConfig.d/*; then
	cat <<EOF > /etc/cron.d/request-tracker
@reboot rt /usr/local/sbin/rt-ldap-importer --verbose
*/15 * * * * rt /usr/local/sbin/rt-ldap-importer
EOF
fi
