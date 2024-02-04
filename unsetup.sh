#!/bin/sh

# run this script to remove the werc environment on openbsd (after setup)

# exit on first error
set -o errexit

# check os
test "$(uname)" != "OpenBSD" && { echo "$0: operating system is not OpenBSD" >&2 ; exit 1 ; }

# check root
test "$(whoami)" != "root" && { echo "$0: not running as root" >&2 ; exit 1 ; }

# ----   begin   ----

# this section contains customizable variables, consider setting their values before running the script

# directory where the httpd chroot environment will be
# this is ok for most cases; change this only if you know what you're doing
webdir='/var/www'

# the domain of your server
# an invalid domain may result in an unsuccessful or even incomplete installation
domain='example.com'

# ----    end    ----

# for security reasons, assign default values if unset or empty
webdir=${webdir:-"/var/www"}
domain=${domain:-"example.com"}

# check webdir value
if [ $(echo "${webdir}" | egrep '^(/|(/[[:alnum:]._][-[:alnum:]._]*)+)$') != "${webdir}" ]
then
	echo "$0: invalid chroot directory" >&2
	exit 1
fi

p9pdir='/usr/local/plan9'

# remove hard links and devices
rm -fr ${webdir}/dev ${webdir}${p9pdir} ${webdir}/usr ${webdir}/bin

# restore backups
test -f /etc/httpd.conf.bk && mv -v /etc/httpd.conf.bk /etc/httpd.conf
test -f /etc/fstab.bk && mv -v /etc/fstab.bk /etc/fstab

while true
do
	echo -n "remove bzip2 and plan9port packages? (y/n) " >&2
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

echo "now you may want to delete the contents of $webdir by yourself (remember that your website is in $webdir/werc)"
