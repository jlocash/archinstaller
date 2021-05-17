#!/usr/bin/env bash
set -e
source "$(dirname $0)/utils.sh"

BTRFS_MOUNT_OPTS="ssd,noatime,space_cache,commit=120,compress=zstd"

log "DISK PARTITIONING"

SELECTED_DISK=""
while [[ "$SELECTED_DISK" == "" ]]; do
  read -p "enter disk to partition (eg: /dev/sda): " SELECTED_DISK
done

disk_continue="N"
log "disk '$SELECTED_DISK' selected for partitioning"
read -p "continue? (y/N): " disk_continue

if [[ $disk_continue =~ ^[Yy]$ ]]; then
  log "wiping disk '$SELECTED_DISK'"
  # Format the disk as GPT with the following paritition scheme:
  # - 1 - 512M        - /boot/efi
  # - 2 - 1GB         - /boot
  # - 3 - remaining   - /
  sgdisk --zap-all $SELECTED_DISK
  log "Creating new parition table "
  sgdisk --clear \
    --new=1:0:+512MiB --typecode=1:ef00 \
    --new=2:0:+1GiB --typecode=2:8300 \
    --new=3:0:0 --typecode=3:8300 \
    $SELECTED_DISK

  partlist=("$SELECTED_DISK"*)
  root=${partlist[3]}
  boot=${partlist[2]}
  efi=${partlist[1]}

  # create luks
  log "Creating luks on $root"
  cryptsetup -y -v luksFormat "$root"
  luksUUID=$(cryptsetup luksUUID $root)
  crypt_name="/dev/mapper/luks-$luksUUID"
  cryptsetup open "$root" "$crypt_name"
  
  # create btrfs root
  log "Creating BTRFS on $crypt_name"

  mkfs.btrfs "$crypt_name"
  mount -t btrfs "$crypt_name" /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@swap
  umount -R /mnt

  # Mount subvolumes
  log "Mounting BTRFS subvolumes"
  mount -t btrfs -o "subvol=@,$BTRFS_MOUNT_OPTS" "$crypt_name" /mnt
  mkdir /mnt/{home,swap}
  mount -t btrfs -o "subvol=@home,$BTRFS_MOUNT_OPTS" "$crypt_name" /mnt/home
  mount -t btrfs -o "subvol=@swap,$BTRFS_MOUNT_OPTS" "$crypt_name" /mnt/swap

  # create /boot
  log "Creating ext4 filesystem on $boot"
  mkfs.ext4 "$boot"
  mkdir -p /mnt/boot
  mount "$boot" /mnt/boot

  # create /boot/efi
  log "Creating FAT32 filesystem on $efi"
  mkfs.vfat -F32 "$efi"
  mkdir -p /mnt/boot/efi
  mount "$efi" /mnt/boot/efi

  # create swapfile
  swap_size=""
  while [[ "$swap_size" == "" ]]; do
    read -p "Enter swap file size (eg: 2G): " swap_size
  done

  log "Creating swapfile at /swap/swapfile"
  truncate -s 0 /mnt/swap/swapfile
  chattr +C /mnt/swap/swapfile
  btrfs property set /mnt/swap/swapfile compression none
  fallocate -l "$swap_size" /mnt/swap/swapfile
  chmod 600 /mnt/swap/swapfile
  mkswap /mnt/swap/swapfile
  swapon /mnt/swap/swapfile

  log "Partitioning completed on $SELECTED_DISK"  
else
  log "partitioning aborted by user"
  exit 1
fi
