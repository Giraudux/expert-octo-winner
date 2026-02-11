#!/bin/sh

set -xe

temp="$(mktemp --directory)"
readonly temp
mkdir --parents "$temp/tmp/" "$temp/cache/" "$temp/bin/"
trap 'rm --recursive --force -- "$temp"' EXIT

# wget stub
cat << 'EOF' > "$temp/bin/download.tpl"
#!/bin/sh
readonly cachedir="$DOWNLOAD_CACHE"
for arg in "$@"
do
    filename=$(basename -- "$arg")
    if [ -f "$cachedir/$filename" ]
    then
        cp "$cachedir/$filename" .
        exit
    fi
done
"$DOWNLOAD_CMD" "$@"
EOF
DOWNLOAD_CACHE="$temp/cache/" DOWNLOAD_CMD="$(command -v wget)" envsubst '$DOWNLOAD_CACHE $DOWNLOAD_CMD' < "$temp/bin/download.tpl" > "$temp/bin/wget"
DOWNLOAD_CACHE="$temp/cache/" DOWNLOAD_CMD="$(command -v curl)" envsubst '$DOWNLOAD_CACHE $DOWNLOAD_CMD' < "$temp/bin/download.tpl" > "$temp/bin/curl"
chmod +x "$temp/bin/"*

tar --directory="$temp" --strip-components=1 --extract --file /opt/fogproject-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fos-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fog-client-*.tar.gz
PATH="$temp/bin/:$PATH" routeraddress=127.0.0.1 "$temp/bin/installfog.sh" --autoaccept

# device=$(lsblk --noheadings --paths --output name "$(findmnt --noheadings --output source /)")
# readonly device
# free_space=$(parted --json --script "$device" unit s print free | jq ".disk.partitions[-1]")
# readonly free_space
# if [ "$(echo "$free_space" | jq --raw-output ".type")" = free ]
# then
#     last_partition_ori=$(parted --json --script "$device" unit s print | jq ".disk.partitions[-1]")
#     readonly last_partition_ori
#     start=$(echo "$free_space" | jq --raw-output ".start")
#     readonly start
#     end=$(echo "$free_space" | jq --raw-output ".end")
#     readonly end
#     parted --script "$device" mkpart primary "$start" "$end"
#     # TODO sleep ?
#     last_partition_new=$(parted --json --script "$device" unit s print | jq ".disk.partitions[-1]")
#     readonly last_partition_new
#     if [ "$last_partition_ori" != "$last_partition_new" ]
#     then
#         part_path=$(lsblk --json --output "path,partn" "$device" | jq --raw-output ".blockdevices[] | select(.partn==$(echo "$last_partition_new" | jq ".number")) | .path")
#         readonly part_path
#         sudo mkfs.exfat "$part_path"
#     fi
#     # TODO update fstab
# fi
