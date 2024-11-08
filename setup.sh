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
	mntp=$(mountp $dir)

	if grep "[[:space:]]$mntp[[:space:]]" </etc/fstab | grep -E '(,|[[:space:]])nodev(,|[[:space:]])' >/dev/null
	then
		return 0
	fi

	return 1
}

# find the innermost mount point which contains the given directory from /etc/fstab entries
mountp() {
	dir="$1"

	mntps=$(awk '{ print $2 }' </etc/fstab)
	while :
	do
		echo "$mntps" | grep "^$dir$" >/dev/null
		test $? -eq 0 && break
		test $dir = '/' && return 1	# avoid infinite loop
		dir=$(dirname $dir)
	done

	echo $dir
}

# acts like ln if possible, otherwise cp
# do NOT pass options like '-R'
lncp() {
	last=$(eval echo $"$#")
	for f
	do
		ln "$f" "$last" 2>/dev/null || cp "$f" "$last"
	done
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
		echo "$0: root user required" >&2
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

		# remove "nodev" from $webdir in /etc/fstab to make /dev/null
		# this requires a reboot to be effective
		mntp=$(mountp $webdir)
		oldline=$(grep "[[:space:]]$mntp[[:space:]]" /etc/fstab)
		newline=$(echo "$oldline" | sed 's/nodev//;s/,,/,/')
		oldfile=$(cat /etc/fstab)
		echo "$oldfile" | sed "s!$oldline!$newline!" >/etc/fstab
		echo "$0: /etc/fstab has been changed, reboot when script terminates to apply"
	fi
}

# werc installation
inst() {
	pkg_add bzip2 || return 1

	if [ -d $siteroot ]
	then
		# werc has been uninstalled and it is being re-installed again
		mv $siteroot .
		reinst=yes
		echo "$0: existing site root detected ($siteroot), will not overwrite"
	fi

	ftp -S dont http://code.9front.org/hg/werc/archive/tip.tar.bz2 || return 1
	tar xjf tip.tar.bz2 -C $webdir
	rm tip.tar.bz2
	mv $webdir/werc-* $webdir/werc

	if [ "$reinst" = yes ]
	then
		mv $(basename $siteroot) $(dirname $siteroot)
	else
		# default siteroot contents
		mkdir $siteroot
		mkdir -p $siteroot/_werc/{lib,pub,pub/style}
		printf "masterSite=$domain\nsiteTitle='title'\nsiteSubTitle='subtitle'\n" >$siteroot/_werc/config
		cp $webdir/werc/lib/{default_master.tpl,footer.inc,top_bar.inc} $siteroot/_werc/lib
		cp $webdir/werc/pub/style/style.css $siteroot/_werc/pub/style
		printf "# congratulations\n\nit works! :)\n" >$siteroot/index.md
	fi
}

# make the plan 9 environment in the new root
mk9env() {
	# install plan9port in $webdir
	pkg_add git || return 1
	git clone https://github.com/9fans/plan9port $webdir$p9pdir || return 1
	( cd $webdir$p9pdir ; ./INSTALL -r $p9pdir ) || return 1

	# all programs need to be in $webdir/bin and some are missing
	rm -f $webdir/bin
	lncp $webdir$p9pdir/bin $webdir/bin
	lncp /bin/{pwd,mv} $webdir/bin

	# create devices
	mkdir $webdir/dev
	( cd $webdir/dev ; /dev/MAKEDEV std )

	# create /tmp with permissions accepted by werc
	mkdir $webdir/tmp
	chmod 1777 $webdir/tmp

	# lncp required things into the chroot environment
	mkdir -p $webdir/usr/{lib,libexec}
	lncp /usr/lib/lib{m,util,pthread,c,z,expat}.so* $webdir/usr/lib
	lncp /usr/libexec/ld.so $webdir/usr/libexec
}

services() {
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

	if ! mk9env
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
	echo "$0: you may need to reboot (see prior messages); otherwise, you can start httpd and slowcgi"
}

# default values if unset or empty
domain=${domain:-"example.com"}
webdir=${webdir:-"/var/www"}

# other useful variables
p9pdir='/plan9'	# after chroot, full is $webdir$p9pdir
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
			param PATH "/bin"
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
		$f
	done
else
	all
fi
