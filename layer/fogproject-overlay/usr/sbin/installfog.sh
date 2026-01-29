#!/bin/sh

set -e

# TODO create exFAT partition mounted on /images/
# TODO stub curl

temp="$(mktemp --directory)"
readonly temp
trap 'rm --recursive --force -- "$temp"' EXIT

# curl stub
# mkdir -p "$temp/bin/"
# touch "$temp/bin/curl"
# chmod +x "$temp/bin/curl"

# wget stub
mkdir -p "$temp/bin/"
cat << 'EOF' > "$temp/bin/wget"
set -x
if [ -f "../$2" ]
then
  cp "../$2" "$2"
else
  wget "$@"
fi
EOF
chmod +x "$temp/bin/wget"

tar --directory="$temp" --strip-components=1 --extract --file=/opt/fogproject-*.tar.gz
mkdir "$temp/tmp/"
tar --directory="$temp/tmp/" --strip-components=1 --extract --file=/opt/fos-*.tar.gz
tar --directory="$temp/tmp/" --strip-components=1 --extract --file=/opt/fog-client-*.tar.gz
PATH="$temp/bin/:$PATH" routeraddress=127.0.0.1 "$temp/bin/installfog.sh" --autoaccept
