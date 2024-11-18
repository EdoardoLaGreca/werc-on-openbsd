#! /bin/sh

# Test setup.sh and unsetup.sh.

# make a snapshot of all existing file paths
# $1 = directory of which to take the snapshot
# $2 = name of the output file
snapfs() {
	du -a "$1" | awk '{ print $2 }' | sort >"$2"
}

files="{,un}setup.sh"
ftp https://raw.githubusercontent.com/EdoardoLaGreca/werc-on-openbsd/main/$files
sha256 $files
sed -i "s/^domain='.*'$/domain='mysite.lol'/" $files
grep 'mysite\.lol' $files
chmod 744 $files
snapfs /etc etc.bef
snapfs /var/www www.bef

setup() {
	doas ./setup.sh
	snapfs /etc etc.aft1
	snapfs /var/www www.aft1
}

unsetup() {
	doas ./unsetup.sh
	snapfs /etc etc.aft2
	snapfs /var/www www.aft2
}

"$@"
