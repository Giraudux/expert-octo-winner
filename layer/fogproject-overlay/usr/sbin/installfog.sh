#!/bin/sh

set -e

# TODO create exFAT partition mounted on /images/
# TODO stub curl

temp="$(mktemp --directory)"
readonly temp
trap 'rm --recursive --force -- "$temp"' EXIT

tar --directory="$temp" --strip-components=1 --extract --file=/opt/fogproject-*.tar.gz
routeraddress=127.0.0.1 "$temp/bin/installfog.sh" --autoaccept
