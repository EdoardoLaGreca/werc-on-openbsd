#!/bin/sh

# run this script to set up the werc environment on openbsd
# http://werc.cat-v.org/

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
# an invalid domain may result in an unsuccessful or incomplete installation
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
test "${webdir}" = "/" && echo "$0: careful, webdir is root" >&2

# ----   functions   ----

# check if a directory (or one of the parents of that directory) is an fstab entry marked as "nodev"
# directories marked as "nodev" cannot contain special devices (e.g. /dev/null)
is_nodev() {
	dir="$1"

	# get directories with "nodev"
	fstab_dirs="$(egrep ',?nodev,?' /etc/fstab | awk '{ print $2 }')"

	# check for each $fstab_dir if it is a parent directory of $dir
	for fstab_dir in ${fstab_dirs}
	do
		test "$(echo "${dir}" | grep -E "^${fstab_dir}/?")" && return 0
	done

	return 1
}

# ---- end functions ----

pkg_add bzip2 plan9port
p9pdir='/usr/local/plan9'

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
if [ -f /etc/httpd.conf ]
then
	cp /etc/httpd.conf /etc/httpd.conf.bk
	echo "$0: /etc/httpd.conf already exists, it has been copied to /etc/httpd.conf.bk" >&2
fi

# write new httpd.conf
# for some reason, httpd waits until timeout ("connection request timeout") for some files
echo \
'server "'${domain}'" {

	# see https://man.openbsd.org/httpd.conf to enable ssl/tls

	listen on * port 80
	connection request timeout 4

	location "/pub/*" {
		root "/werc"
	}

	location found "/*" {
		root "/werc/sites/'${domain}'"
	}

	location not found "/*" {
		root "/"
		fastcgi {
			param DOCUMENT_ROOT "/werc/bin"
			param SCRIPT_FILENAME "/werc/bin/werc.rc"
			socket "/run/slowcgi.sock"
		}
	}
}

types {
	include "/usr/share/misc/mime.types"
}
' >/etc/httpd.conf

if is_nodev "${webdir}"
then
	# back up fstab
	cp /etc/fstab /etc/fstab.bk

	# remove "nodev" from /var in /etc/fstab so that we can create /dev/null
	# this requires a reboot to be effective
	oldline=$(grep ' /var ' /etc/fstab)
	newline=$(echo "${oldline}" | sed 's/nodev//' | sed 's/,,/,/')
	oldfile=$(cat /etc/fstab)
	echo "${oldfile}" | sed "s#${oldline}#${newline}#" >/etc/fstab # this assumes that the line doesn't have a comment after (who puts comments at the end of fstab lines anyway?)
	echo "$0: /etc/fstab changed, a reboot is required at the end of the setup process" >&2
fi

# create devices in $webdir
mkdir -p "${webdir}/dev"
p=$(pwd)
cd ${webdir}/dev
/dev/MAKEDEV std
cd $p

# create /tmp in $webdir
mkdir -p "${webdir}/tmp"
chmod 1777 "${webdir}/tmp"

# hard-link required things into the chroot environment
mkdir -p ${webdir}${p9pdir} ${webdir}/usr/libexec ${webdir}/usr/lib ${webdir}/bin ${webdir}${p9pdir}/lib
ln ${p9pdir}/rcmain ${webdir}${p9pdir}
ln /usr/libexec/ld.so ${webdir}/usr/libexec
ln /usr/lib/lib{m,util,pthread,c,z,expat}.so* ${webdir}/usr/lib
ln /bin/{pwd,mv} ${webdir}/bin
ln ${p9pdir}/lib/fortunes ${webdir}${p9pdir}/lib

# recursively hard-link everyting (including sub-dirs) under ${p9pdir}/bin into the chroot environment
allbins="$(find ${p9pdir}/bin -not -type d | sed "s|^${p9pdir}/bin/||")"
for bin in $allbins
do
	dir=$(dirname $bin)
	mkdir -p ${webdir}/bin/${dir}
	ln ${p9pdir}/bin/${bin} ${webdir}/bin/${bin}
done

# enable slowcgi and httpd
rcctl enable slowcgi
rcctl enable httpd

echo "$0: setup completed!" >&2
echo "$0: check prior messages to see if you need to reboot; otherwise, you can start the httpd and slowcgi services" >&2

exit 0
