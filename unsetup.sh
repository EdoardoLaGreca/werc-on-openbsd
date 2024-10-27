#!/bin/sh

# Run this script to remove the Werc environment on OpenBSD (after setup).

# ---- begin variables ----

# This section contains customizable variables, consider setting their values
# before running the script.

# The domain of your server.
# An invalid domain may result in an unsuccessful or incomplete installation.
domain='example.com'

# The root directory for httpd's chroot environment.
# The default value is usually fine and it should not be changed unless the
# change is backed by a valid reason. If unsure, do not change.
webdir='/var/www'

# ---- end variables ----

# exit on first error
set -o errexit

# check os
test "$(uname)" != "OpenBSD" && { echo "$0: operating system is not OpenBSD" >&2 ; exit 1 ; }

# check root
test "$(whoami)" != "root" && { echo "$0: not running as root" >&2 ; exit 1 ; }

# default values if unset or empty
webdir=${webdir:-"/var/www"}
domain=${domain:-"example.com"}

# check webdir's value
echo "$webdir" | grep -E '^(/[^[:cntrl:]]+)+$' >/dev/null
if [ $? -eq 1 ]
then
	echo "$0: invalid chroot directory" >&2
	exit 1
fi

p9pdir='/usr/local/plan9'

# remove hard links, copies, devices
rm -fr $webdir/dev $webdir/tmp $webdir$p9pdir $webdir/usr $webdir/bin

# restore backups
test -f /etc/httpd.conf.bk && mv -v /etc/httpd.conf.bk /etc/httpd.conf
test -f /etc/fstab.bk && mv -v /etc/fstab.bk /etc/fstab

# remove packages
while true
do
	echo -n "remove bzip2 and plan9port packages? (y/n) "
	read yn
	case $yn in
		[Yy]* )
			pkg_delete bzip2 plan9port
			break
			;;
		[Nn]* )
			break
			;;
		* )
			continue
			;;
	esac
done

# disable services
while true
do
	echo -n "disable the slowcgi and httpd services? (y/n) "
	read yn
	case $yn in
		[Yy]* )
			rcctl disable slowcgi httpd
			break
			;;
		[Nn]* )
			break
			;;
		* )
			continue
			;;
	esac
done

echo
echo "$0: the unsetup operation was successful, now you may want to delete the contents of $webdir by yourself (remember: your website is in $webdir/werc/sites/$domain)"
