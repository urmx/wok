#!/bin/bash

# Parameters
#============

usage() {
	test -n "$1" && echo -e "$1\n"
	echo "Usage: wok rm [-f] <domain>"
	echo
	echo "    -f, --force  Do not ask confirmation"
	echo
	exit 1
}

# Processing
domain=
force=
argv=
while [ -n "$1" ]; do
	arg=$1;shift
	case $arg in
		-f|--force) force=1;;
		*)
			if test -z "$domain"; then domain="$arg"
			else argv="$argv $arg"
			fi
			;;
	esac
done

# Validation
test -z "$domain" && usage "Give a domain (e.g. example.org)."

# Run
#=====

if test ! $force; then
	confirm "This will destroy everything. Are you ure?" || exit 0
fi

args=
test $force && args="$args --force"

#$wok_path/wok-mail rm $domain $args
$wok_path/wok-mongo rm $domain $args
$wok_path/wok-mysql rm $domain $args
$wok_path/wok-pgsql rm $domain $args
#$wok_path/wok-ftp rm $domain $args
$wok_path/wok-ssl rm $domain $args
$wok_path/wok-nginx rm $domain $args
$wok_path/wok-php rm $domain $args
$wok_path/wok-www rm $domain $args

echo