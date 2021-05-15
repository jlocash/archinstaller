#!/usr/bin/env bash
set -e
source utils.sh

function get_efi_partname {
  local partlist=("$1"*)
  echo "${partlist[1]}"
}

function get_boot_partname {
  local partlist=("$1"*)
  echo "${partlist[2]}"
}

function get_root_partname {
  local partlist=("$1"*)
  echo "${partlist[3]}"
}

function get_crypt_name {
  local root_partname="$(get_root_partname "$1")"
  echo "luks-$(cryptsetup luksUUID ${root_partname})"
}

function wipe_disk {
  local target="${1}" # eg: /dev/sda

  # Format the disk as GPT with the following paritition scheme:
  # - 1 - 512M        - /boot/efi
  # - 2 - 1GB         - /boot
  # - 3 - remaining   - /
  sgdisk --zap-all "${TARGET_DISK}"
  sgdisk --clear \
    --new=1:0:+512MiB --typecode=1:ef00 \
    --new=2:0:+1GiB --typecode=2:8300 \
    --new=3:0:0 --typecode=3:8300 \
    "${TARGET_DISK}"
}

function prepare_luks {
  local target="${1}" # eg: /dev/sda3
  # local crypt_name="${2}"
  log_info "Creating luks on ${target}"
  cryptsetup -y -v luksFormat "${target}"

  local crypt_name="luks-$(cryptsetup luksUUID ${target})"
  log_info "Opening luks on ${target}"
  cryptsetup open "${target}" "${crypt_name}"
}

function partition_root {
  local target="${1}" # /dev/mapper/luks-<luksUUID>
  local mount_opts="${2}"

  log_info "Creating BTRFS filesystem on ${target}"

  mkfs.btrfs "${target}"
  mount -t btrfs "${target}" /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@swap
  umount -R /mnt

  # Mount subvolumes
  log_info "Mounting btrfs subvolumes"
  mount -t btrfs -o "subvol=@,${mount_opts}" "${target}" /mnt
  mkdir /mnt/{home,swap}
  mount -t btrfs -o "subvol=@home,${mount_opts}" "${target}" /mnt/home
  mount -t btrfs -o "subvol=@swap,${mount_opts}" "${target}" /mnt/swap
}s

function partition_boot {
  local target="${1}" # eg: /dev/sda2

  log_info "Creating /boot on ${target}"
  mkfs.ext4 "${target}"
  mkdir -p /mnt/boot
  mount "${target}" /mnt/boot
}

function partition_efi {
  local target="${1}" # eg: /dev/sda1

  log_info "Creating efi on ${PARTLIST[1]}"
  mkfs.vfat -F32 "${PARTLIST[1]}"
  mkdir -p /mnt/boot/efi
  mount "${PARTLIST[1]}" /mnt/boot/efi
}

function create_swapfile {
  local target="${1}" # eg: /mnt/swap/swapfile
  local size="${2}" # eg: 2G

  log_info "Creating swapfile at /swap/swapfile"
  truncate -s 0 "${target}"
  chattr +C "${target}"
  btrfs property set "${target}" compression none
  fallocate -l "${size}" "${target}"
  chmod 600 "${target}"
  mkswap "${target}"
  swapon "${target}"
}
