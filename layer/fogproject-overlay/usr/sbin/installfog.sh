#!/bin/sh

set -e

# TODO create exFAT partition mounted on /images/

temp="$(mktemp --directory)"
readonly temp
mkdir --parents "$temp/tmp/" "$temp/cache/" "$temp/bin/"
trap 'rm --recursive --force -- "$temp"' EXIT

# wget stub
cat << 'EOF' > "$temp/bin/download.tpl"
#!/bin/sh
set -x
readonly cachedir="$DOWNLOAD_CACHE"
for arg in "$@"
do
    filename=$(basename "$arg")
    if [ -f "$cachedir/$filename" ]
    then
        cp "$cachedir/$filename" .
        exit
    fi
done
"$DOWNLOAD_CMD" "$@"
EOF
DOWNLOAD_CACHE="$temp/cache/" DOWNLOAD_CMD=wget envsubst '$DOWNLOAD_CACHE $DOWNLOAD_CMD' < "$temp/bin/download.tpl" > "$temp/bin/wget"
DOWNLOAD_CACHE="$temp/cache/" DOWNLOAD_CMD=curl envsubst '$DOWNLOAD_CACHE $DOWNLOAD_CMD' < "$temp/bin/download.tpl" > "$temp/bin/curl"
chmod +x "$temp/bin/"*

tar --directory="$temp" --strip-components=1 --extract --file /opt/fogproject-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fos-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fog-client-*.tar.gz
PATH="$temp/bin/:$PATH" routeraddress=127.0.0.1 "$temp/bin/installfog.sh" --autoaccept
