#! /bin/sh

# Generate checksums (SHA-256) for the files specified as arguments and output
# them in the respective files.

# get command for calculating checksum.
# sumcmd has the command (potentially with arguments) for calculating the file's
# checksum while regxp has a regular expression to remove output in excess.
os=$(uname -s)
case $os in
	Linux ) sumcmd='sha256sum'
		regxp='[[:space:]].*$'
		;;
	*BSD ) sumcmd='sha256 -q'
		regxp=''
		;;
	* ) sumcmd=error
		;;
esac

if [ "$sumcmd" = "error" ]
then
	echo "$0: error: unsupported operating system."
	echo "$0: edit the script to add this operating system."
	exit 1
fi

for f
do
	$sumcmd $f | sed "s/$regxp//" >$f.sum
done

