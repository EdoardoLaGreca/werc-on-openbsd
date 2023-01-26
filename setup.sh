#!/bin/sh

# run this script to set up the werc environment on openbsd
# http://werc.cat-v.org/

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
[ "${webdir}" = "/" ] && echo "$0: careful, webdir is root" >&2

# ----   functions   ----

# check if directory is in (or is child of a directory in) fstab and it is marked as "nodev"
check_fstab() {
	dir="$1"

	# get directories with "nodev"
	fstab_dirs="$(egrep ',?nodev,?' /etc/fstab | cut -d ' ' -f 2)"

	# check for each $fstab_dir if it is a parent directory of $dir
	for fstab_dir in ${fstab_dirs}
	do
		[ "$(echo "${dir}" | egrep "^${fstab_dir}/?")" ] return 0
	done

	return 1
}

# ---- end functions ----

pkg_add bzip2 plan9port

# download werc into the environment and set it up
ftp -S dont http://code.9front.org/hg/werc/archive/tip.tar.bz2
tar xjf tip.tar.bz2 -C ${webdir}
rm tip.tar.bz2
mv ${webdir}/werc-* ${webdir}/werc
siteroot="${webdir}/werc/sites/${domain}"
mkdir ${siteroot}
cp -r ${siteroot}/../werc.cat-v.org/_werc ${siteroot}
printf "# congratulations\n\nit works! :)\n" >${siteroot}/index.md

# backup current httpd.conf
[ -f /etc/httpd.conf ] && {
	cp /etc/httpd.conf /etc/httpd.conf.bk
	echo "$0: /etc/httpd.conf already exists, it has been copied to /etc/httpd.conf.bk" >&2
}

# write new httpd.conf
# for some reason, httpd waits until timeout ("connection request timeout") for some files
echo \
"server \"${domain}\" {
	listen on * port 80
	#listen on * tls port 443
	connection request timeout 1

	root \"/\"
	fastcgi {
		param DOCUMENT_ROOT \"/werc/bin\"
		param SCRIPT_FILENAME \"/werc/bin/werc.rc\"
		socket \"/run/slowcgi.sock\"
	}
}

types {
	include \"/usr/share/misc/mime.types\"
}
" >/etc/httpd.conf

# if $webdir is (or is inside of) an entry in /etc/fstab that is marked as "nodev"
if [ ( check_fstab "${webdir}" ) ]
then
	# remove "nodev" from /var in /etc/fstab so that we can create /dev/null
	# this requires a reboot to be effective
	oldline=$(grep ' /var ' /etc/fstab)
	newline=$(echo "${oldline}" | sed 's/nodev//' | sed 's/,,/,/')
	oldfile=$(cat /etc/fstab)
	echo "${oldfile}" | sed "s#${oldline}#${newline}#" >/etc/fstab # this assumes that the line doesn't have a comment after (who puts comments at the end of fstab lines anyway?)
	echo "$0: /etc/fstab changed, a reboot is required at the end of the setup process" >&2
fi

# create /dev/null in $webdir
mkdir -p "${webdir}/dev"
mknod -m 666 "${webdir}/dev/null" c 2 2 # "2 2" is OS-dependent

# copy required things into the chroot environment
mkdir -p ${webdir}/usr/local/plan9 ${webdir}/usr/libexec ${webdir}/usr/lib ${webdir}/bin
cp /usr/local/plan9/rcmain ${webdir}/usr/local/plan9
cp /usr/local/plan9/bin/* ${webdir}/bin
cp /usr/libexec/ld.so ${webdir}/usr/libexec
cp /usr/lib/lib{m,util,pthread,c,z,expat}.so* ${webdir}/usr/lib
cp /bin/{sh,pwd} ${webdir}/bin

# enable slowcgi and httpd
rcctl enable slowcgi
rcctl enable httpd

echo "$0: setup completed!" >&2
echo "$0: check prior messages to see if you need to reboot; otherwise, you can start the httpd and slowcgi services" >&2

exit 0
