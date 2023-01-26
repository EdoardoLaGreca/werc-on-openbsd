#!/bin/sh

# run this script to remove the werc environment on openbsd (after setup)

# exit on first error
set -o errexit

# check os
[ "$(uname)" != "OpenBSD" ] && { echo "$0: operating system is not OpenBSD" >&2 ; exit 1 ; }

# check root
[ "$(whoami)" != "root" ] && { echo "$0: not running as root" >&2 ; exit 1 ; }

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
[ $(echo "${webdir}" | egrep '^(/|(/[[:alnum:]._][-[:alnum:]._]*)+)$') = "${webdir}" ] || {
	echo "$0: invalid chroot directory" >&2
	exit 1
}

mv /etc/httpd.conf.bk /etc/httpd.conf
mv /etc/fstab.bk /etc/fstab
rm -r ${webdir}/werc

while true
do
	read -p "remove bzip2 and plan9port packages? (y/n) " yn >&2
	case $yp in
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
