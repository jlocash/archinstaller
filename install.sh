#!/usr/bin/env bash
set -e
source utils.sh
source diskutil.sh
source install.conf

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

proceed="N"
read -p "partition disk \"$TARGET_DISK\"? (y/N): " proceed
if [[ $proceed =~ ^[Yy]$ ]]; then
  # partition disk
  log_info "Partitioning disk \"$TARGET_DISK\""
  wipe_disk "$TARGET_DISK"

  efi_partname="$(get_efi_partname $TARGET_DISK)"
  boot_partname="$(get_boot_partname $TARGET_DISK)"
  root_partname="$(get_root_partname $TARGET_DISK)"

  prepare_luks "$root_partname"
  partition_root "/dev/mapper/$(get_crypt_name $TARGET_DISK)"
  partition_boot "$boot_partname"
  partition_efi "$efi_partname"

  create_swapfile "/mnt/swap/swapfile" "$SWAP_FILE_SIZE"

  # Install
  log_info "Installing system packages"
  pacstrap /mnt ${PKG_LIST[@]}

  # Create fstab
  log_info "Generating fstab"
  genfstab -U /mnt >>/mnt/etc/fstab

  log_info "Preparing chroot"

  # Install /etc/mkinitcpio.conf
  cp conf/mkinitcpio.conf /mnt/etc/mkinitcpio.conf

  # Install /etc/default/grub
  cp conf/grub /mnt/etc/default/grub

  # Install /etc/hosts
  cp conf/hosts /mnt/etc/hosts

  # Install /etc/locale.conf
  cp conf/locale.conf /mnt/etc/locale.conf

  # Install /etc/vconsole.conf
  cp conf/vconsole.conf /mnt/etc/vconsole.conf

  # Install custom services  
  cp conf/services/powertop.service /mnt/etc/systemd/system

  # Apply chroot config
  cp chroot.conf /mnt/chroot.conf
  sed -i "s|__TARGET_ROOT_PARTITION__|$root_partname|" /mnt/chroot.conf
  sed -i "s|__TARGET_CRYPT_NAME__|$(get_crypt_name $TARGET_DISK)|" /mnt/chroot.conf

  # Execute chroot
  cp install.conf chroot.sh utils.sh /mnt
  arch-chroot /mnt ./chroot.sh
  rm /mnt/chroot.sh /mnt/install.conf /mnt/utils.sh
  log_info "Installation complete."
else
  log_info "disk partitioning aborted"
  exit 1
fi
