#!/bin/sh

set -e

# TODO create exFAT partition
if [ ! -d /images/ ]
then
  mkdir /images/
fi

temp="$(mktemp --directory)"
readonly temp
trap 'rm --recursive --force -- "$temp"' EXIT

tar --directory="$temp" --strip-components=1 --extract --file=/opt/fogproject-*.tar.gz
"$temp/bin/installfog.sh" --autoaccept
