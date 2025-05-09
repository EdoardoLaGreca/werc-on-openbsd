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

# ---- parts ----

preuninst() {
	if [ $(uname) != "OpenBSD" ]
	then
		echo "$0: operating system is not OpenBSD" >&2
		return 1
	fi

	if [ $(whoami) != "root" ]
	then
		echo "$0: not running as root" >&2
		return 1
	fi

	# check webdir's value
	echo "$webdir" | grep -E '^(/[^[:cntrl:]]+)+$' >/dev/null
	if [ $? -eq 1 ]
	then
		echo "$0: invalid chroot directory" >&2
		return 1
	fi
}

rm9env() {
	# remove hard links, copies, devices
	rm -fR $webdir$p9pdir \
		$webdir/{dev,tmp} \
		$webdir/usr/{lib,libexec,X11R6/lib} \
		$webdir/bin
	rmdir $webdir/usr ; :
}

uninst() {
	ls -1 $webdir/werc/ | grep -v '^sites$' | xargs -I {} rm -R $webdir/werc/{}
}

restore() {
	# restore backups
	test -f /etc/httpd.conf.bk && mv -v /etc/httpd.conf.bk /etc/httpd.conf
	test -f /etc/fstab.bk && mv -v /etc/fstab.bk /etc/fstab
}

# remove packages
rmpkgs() {
	while true
	do
		echo -n "remove the git package? (y/n) "
		read yn
		case $yn in
			[Yy]* )
				pkg_delete git
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
}

# disable services
services() {
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
}

# ---- end parts ----

all() {
	if ! preuninst
	then
		echo "$0: could not complete pre-installation checks" >&2
		exit 1
	fi

	if ! rm9env
	then
		echo "$0: could not remove the contents of $webdir" >&2
	fi

	if ! uninst
	then
		echo "$0: could not uninstall werc" >&2
		exit 1
	fi

	if ! restore
	then
		echo "$0: could not restore backed up files" >&2
		exit 1
	fi

	if ! rmpkgs
	then
		echo "$0: could not remove packages" >&2
		exit 1
	fi

	if ! services
	then
		echo "$0: could not remove services" >&2
		exit 1
	fi

	echo
	echo "$0: the unsetup operation was successful."
	echo "$0: your site's content ($siteroot) has not been removed."
	echo "$0: the werc directory ($webdir/werc) can be safely removed."
	echo "$0: warning: your site's content is in the werc directory."
}

# default values if unset or empty
webdir=${webdir:-"/var/www"}
domain=${domain:-"example.com"}

# other useful variables
p9pdir='/plan9'	# after chroot, full is $webdir$p9pdir
siteroot="$webdir/werc/sites/$domain"


if [ $# -ne 0 ]
then
	for f
	do
		$f
	done
else
	all
fi
