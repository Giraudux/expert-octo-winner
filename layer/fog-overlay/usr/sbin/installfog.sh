#!/bin/sh

set -xe

# Grow root partition and filesystem
root_filesystem_source=$(findmnt --noheadings --output source /)
readonly root_filesystem_source
root_blockdevice_pkname=$(lsblk --noheadings --output pkname --paths "$root_filesystem_source")
readonly root_blockdevice_pkname
root_blockdevice_partn=$(lsblk --noheadings --output partn "$root_filesystem_source")
readonly root_blockdevice_partn
growpart "$root_blockdevice_pkname" "$root_blockdevice_partn"
resize2fs "$root_filesystem_source"

temp="$(mktemp --directory)"
readonly temp
mkdir --parents "$temp/tmp/" "$temp/cache/" "$temp/bin/"
trap 'rm --recursive --force -- "$temp"' EXIT

# Stub
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

# Extract assets
tar --directory="$temp" --strip-components=1 --extract --file /opt/fogproject-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fos-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fog-client-*.tar.gz

# Install FOG
PATH="$temp/bin/:$PATH" routeraddress=127.0.0.1 "$temp/bin/installfog.sh" --autoaccept

# Create /images/ exFAT partition
# device=$(lsblk --noheadings --paths --output pkname "$(findmnt --noheadings --output source /)")
# readonly device
# free_space=$(parted --json --script "$device" unit s print free | jq ".disk.partitions[-1]")
# readonly free_space
# [ "$(echo "$free_space" | jq --raw-output ".type")" = free ]
# last_partition_ori=$(parted --json --script "$device" unit s print | jq ".disk.partitions[-1]")
# readonly last_partition_ori
# start=$(echo "$free_space" | jq --raw-output ".start")
# readonly start
# end=$(echo "$free_space" | jq --raw-output ".end")
# readonly end
# parted --script "$device" mkpart primary "$start" "$end"
# # TODO sleep ?
# last_partition_new=$(parted --json --script "$device" unit s print | jq ".disk.partitions[-1]")
# readonly last_partition_new
# [ "$(echo "$last_partition_ori" | jq --raw-output ".number")" != "$(echo "$last_partition_new" | jq --raw-output ".number")" ]
# part_path=$(lsblk --json --output "path,partn" "$device" | jq --raw-output ".blockdevices[] | select(.partn==$(echo "$last_partition_new" | jq ".number")) | .path")
# readonly part_path
# mkfs.exfat --volume-label=images "$part_path"
# uuid=$(lsblk --json --output "uuid" "$part_path" | jq --raw-output ".blockdevices[0].uuid")
# echo "UUID=$uuid /images  exfat defaults,rw,noatime,errors=remount-ro 0 2" | tee --append /etc/fstab
