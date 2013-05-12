#!/bin/bash

repo=$wok_repo/ssl
index_domain=$repo/.index/domain

test ! -d $repo \
|| test ! -d $index_domain \
	&& echo "Invalid repository" \
	&& exit 1

# Parameters
#============

usage() {
	test -n "$1" && echo -e "$1\n"
	echo "Usage: wok ssl <action>"
	echo
	echo "    add <domain>           Create the domain"
	echo "    rm <domain> [options]  Remove the domain"
	echo "        -f, --force        ... without confirmation"
	echo "    ls [pattern]           List domains (by pattern if specified)"
	echo
	exit 1
}

# Processing
force=
action=
#domain=
argv=
while [ -n "$1" ]; do
	arg=$1;shift
	case $arg in
		-f|--force) force=1;;
		*)
			if test -z "$action"; then action="$arg"
			#elif test -z "$domain"; then domain="$arg"
			else argv="$argv $arg"
			fi
			;;
	esac
done
set -- $argv # Restitute the rest...

# Validation
test -z "$action" && usage
test $action != 'add' \
&& test $action != 'rm' \
&& test $action != 'ls' \
	&& usage "Invalid action."

# Add, rm, user validation
if [ $action != 'ls' ]; then
	domain="$1";shift
	test -z "$domain" && usage "Give a domain (e.g. example.org)."
	test ! $(preg_match ':^[a-z0-9\-.]{1,255}$:' $domain) \
		&& echo "Invalid domain name" \
		&& exit 1
fi

if [ $action = 'ls' ]; then
	pattern="$1";shift
	test -z "$pattern" && pattern='*'
fi

# Run
#=====

case $action in
	ls)
		silent cd $repo
		find . -maxdepth 1 -type f -name "$pattern" \
			| sed -r 's/^.{2}//' \
			| sort
		silent cd -
		;;
	add)
		test -e $index_domain/$domain \
			&& echo "This domain has already its certificate and key" \
			&& exit 1
		test -z "$($wok_path/wok-www ls $domain)" \
			&& error "This domain does not exist"

		uid="$($wok_path/wok-www uid $domain)"
		ssl_path="$wok_www_path/$domain/.ssl"
		test ! -d $ssl_path && mkdir $ssl_path
		openssl req -x509 -nodes -days 7300 -newkey rsa:2048 \
			-keyout $ssl_path/snakeoil.key \
			-out $ssl_path/snakeoil.pem
		chown -R $uid:$wok_www_uid_group $ssl_path
		chmod -R g=,o= $ssl_path

		touch $repo/$domain
		ln -s "../../$domain" $index_domain/$domain
		echo "_domain=$domain" >> $repo/$domain
		;;
	rm)
		test ! -e $index_domain/$domain \
			&& echo "This domain has no certificate" \
			&& exit 1
		if test ! $force; then
			confirm "Remove certificate (users will be warned)?" || exit 0
		fi
		source $repo/$domain
		uid="$($wok_path/wok-www uid $_domain)"
		ssl_path="$wok_www_path/$_domain/.ssl"
		rm $ssl_path/snakeoil.pem
		rm $ssl_path/snakeoil.key
		;;
esac