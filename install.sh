#!/usr/bin/env bash
set -e
source utils.sh
source diskutil.sh
source install.conf

function install_base {
  PKG_LIST=(
    "base"
    "base-devel"
    "linux"
    "linux-firmware"
    "linux-headers"
    "bash-completion"
    "vim"
    "btrfs-progs"
    "git"
    "networkmanager"
    "grub"
    "efibootmgr"
    "firewalld"
    "tlp"
    "powertop"
    "ntfs-3g"

    # virtualization tools
    "libvirt"
    "edk2-ovmf"
    "ebtables"
    "dnsmasq"
    "dmidecode"
    "podman"
    "vagrant"
    "nfs-utils"

    # GNOME desktop
    "gnome"
    "alsa-utils"
    "gnome-tweaks"
    "flatpak"
    "firefox"

    # PipeWire audio
    "pipewire"
    "pipewire-alsa"
    "pipewire-jack"
    "pipewire-pulse"
  )

  pacstrap /mnt ${PKG_LIST[@]}
}

proceed="N"
read -p "partition disk \"${TARGET_DISK}\"? (y/N): " proceed
if [[ ${proceed} =~ ^[Yy]$ ]]; then
  # partition disk
  log_info "Partitioning disk \"${TARGET_DISK}\""
  wipe_disk "${TARGET_DISK}"

  partlist=("$TARGET_DISK"*)
  prepare_luks "${partlist[3]}" "${CRYPT_NAME}"
  partition_root "/dev/mapper/${CRYPT_NAME}"
  partition_boot "${partlist[2]}"
  partition_efi "${partlist[1]}"
  create_swapfile "/mnt/swap/swapfile" "${SWAP_FILE_SIZE}"

  # pacstrap
  log_info "Installing base system"
  install_base

  # create fstab
  log_info "Generating fstab"
  genfstab -U /mnt >>/mnt/etc/fstab

  # prepare chroot
  log_info "Preparing chroot"
  cp services/powertop.service /mnt/etc/systemd/system
  cp install.conf chroot.sh utils.sh /mnt
  arch-chroot /mnt ./chroot.sh

  # cleanup
  rm /mnt/chroot.sh /mnt/install.conf /mnt/utils.sh
  log_info "Installation complete."
else
  log_info "disk partitioning aborted"
  exit 1
fi
