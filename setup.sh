#!/bin/sh

# Run this script to set up the Werc environment on OpenBSD.
# Werc's website: http://werc.cat-v.org/

# ---- variables ----

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

# ---- functions ----

# check whether the drive that holds a given directory is marked as "nodev"
# directories marked as "nodev" cannot contain special devices (e.g. /dev/null)
is_nodev() {
	dir="$1"

	# fstab dir that contains (or is) $dir
	fsdir=$(drivepath $dir)

	if grep "[[:space:]]$fsdir[[:space:]]" </etc/fstab | grep -E '(,|[[:space:]])nodev(,|[[:space:]])' >/dev/null
	then
		return 0
	fi

	return 1
}

# find the innermost path which contains the given directory from /etc/fstab entries
drivepath() {
	dir="$1"

	fspaths=$(awk '{ print $2 }' </etc/fstab)
	while :
	do
		echo $fspaths | grep "^$dir$" >/dev/null
		test $? -eq 0 && break
		test $dir = '/' && return 1	# avoid infinite loop
		dir=$(dirname $dir)
	done

	echo $dir
}

# acts like ln if possible, otherwise cp
lncp() {
	ln "$@" 2>/dev/null || cp "$@"
}

# ---- end functions ----

# ---- parts ----

# pre-installation checks
preinst() {
	if [ $(uname) != "OpenBSD" ]
	then
		echo "$0: operating system is not OpenBSD" >&2
		return 1
	fi

	if [ $(whoami) != "root" ]
	then
		echo "$0: not running as root user" >&2
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

# configure httpd
httpdconf() {
	# backup current httpd.conf
	if [ -r /etc/httpd.conf ]
	then
		cp /etc/httpd.conf /etc/httpd.conf.bk
		echo "$0: /etc/httpd.conf exists, backed up to /etc/httpd.conf.bk" >&2
	fi

	# new httpd.conf
	# for some reason, httpd waits until timeout ("connection request timeout") for some files
	echo "$httpdconffile" >/etc/httpd.conf
}

# configure fstab
fstabconf() {
	if is_nodev $webdir
	then
		cp /etc/fstab /etc/fstab.bk

		# remove "nodev" from $webdir in /etc/fstab so that we can create /dev/null
		# this requires a reboot to be effective
		oldline=$(grep `fstab_parent $webdir` </etc/fstab)
		newline=$(echo "$oldline" | sed 's/nodev//' | sed 's/,,/,/')
		oldfile=$(cat /etc/fstab)
		echo "$oldfile" | sed "s!$oldline!$newline!" >/etc/fstab
		echo "$0: /etc/fstab has been changed, a reboot is required at the end of the setup process"
	fi
}

# werc installation
inst() {
	pkg_add bzip2 plan9port || return 1

	ftp -S dont http://code.9front.org/hg/werc/archive/tip.tar.bz2 || return 1
	tar xjf tip.tar.bz2 -C $webdir
	rm tip.tar.bz2
	mv $webdir/werc-* $webdir/werc

	# default siteroot contents
	mkdir $siteroot
	mkdir $siteroot/_werc
	cp -R $webdir/werc/lib $siteroot/_werc
	printf "# congratulations\n\nit works! :)\n" >$siteroot/index.md
}

# pour files and directories into $webdir
mkweb() {
	# create devices
	mkdir -p "$webdir/dev"
	p=$(pwd)
	cd $webdir/dev
	/dev/MAKEDEV std
	cd $p

	# create /tmp in $webdir
	mkdir -p "$webdir/tmp"
	chmod 1777 "$webdir/tmp"

	# lncp required things into the chroot environment
	mkdir -p $webdir$p9pdir $webdir/usr/libexec $webdir/usr/lib $webdir/bin $webdir$p9pdir/lib
	lncp $p9pdir/rcmain $webdir$p9pdir
	lncp /usr/libexec/ld.so $webdir/usr/libexec
	lncp /usr/lib/lib{m,util,pthread,c,z,expat}.so* $webdir/usr/lib
	lncp /bin/{pwd,mv} $webdir/bin
	lncp $p9pdir/lib/fortunes $webdir$p9pdir/lib

	# recursively lncp everyting (including sub-dirs) under $p9pdir/bin into the chroot environment
	allbins="$(find $p9pdir/bin -not -type d | sed "s|^$p9pdir/bin/||")"
	for bin in $allbins
	do
		dir=$(dirname $bin)
		mkdir -p $webdir/bin/$dir
		lncp $p9pdir/bin/$bin $webdir/bin/$bin
	done
}

services() {
	# enable slowcgi and httpd
	rcctl enable slowcgi httpd
}

# ---- end parts ----

all() {
	if ! preinst
	then
		echo "$0: could not complete pre-installation checks" >&2
		exit 1
	fi

	if ! httpdconf
	then
		echo "$0: could not configure httpd" >&2
		exit 1
	fi

	if ! fstabconf
	then
		echo "$0: could not configure /etc/fstab" >&2
		exit 1
	fi

	if ! inst
	then
		echo "$0: could not install werc" >&2
		exit 1
	fi

	if ! mkweb
	then
		echo "$0: could not add files and directories to $webdir" >&2
		exit 1
	fi

	if ! services
	then
		echo "$0: could not enable required services" >&2
		exit 1
	fi

	echo
	echo "$0: setup completed!"
	echo "$0: check prior messages to see if you need to reboot; otherwise, you can start the httpd and slowcgi services"
}

# default values if unset or empty
domain=${domain:-"example.com"}
webdir=${webdir:-"/var/www"}

# other useful variables
p9pdir='/usr/local/plan9'
siteroot="$webdir/werc/sites/$domain"
httpdconffile='server "'$domain'" {

	# see httpd.conf(5) to enable ssl/tls

	listen on * port 80
	connection request timeout 4

	location "/pub/*" {
		root "/werc"
	}

	location found "/*" {
		root "/werc/sites/'$domain'"
	}

	location not found "/*" {
		root "/"
		fastcgi {
			param PLAN9 "'$p9pdir'"
			param DOCUMENT_ROOT "/werc/bin"
			param SCRIPT_FILENAME "/werc/bin/werc.rc"
			socket "/run/slowcgi.sock"
		}
	}
}

types {
	include "/usr/share/misc/mime.types"
}'

if [ $# -ne 0 ]
then
	for f
	do
		f
	done
else
	all
fi
