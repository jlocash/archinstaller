#!/usr/bin/env bash
set -e
source "$(dirname $0)/utils.sh"

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
  "tlp"
  "powertop"
)

log "Selecting packages for system installation"

FIREWALLD_ENABLE="Y"
read -p "Add firewalld? [Y/n]: " FIREWALLD_ENABLE
[[ $FIREWALLD_ENABLE =~ ^[Yy]$ ]] && PKG_LIST+=("firewalld")

VIRTUALIZATION_ENABLE="Y"
read -p "Add virtualization tools? [Y/n]: " VIRTUALIZATION_ENABLE
[[ $VIRTUALIZATION_ENABLE =~ ^[Yy]$ ]] && PKG_LIST+=(
  "libvirt"
  "edk2-ovmf"
  "ebtables"
  "dnsmasq"
  "dmidecode"
  "podman"
  "vagrant"
  "nfs-utils"
)

GNOME_ENABLE="Y"
read -p "Add the GNOME desktop? [Y/n]: " GNOME_ENABLE
if [[ $GNOME_ENABLE =~ ^[Yy]$ ]]; then
  PKG_LIST+=(
    "gnome"
    "alsa-utils"
    "gnome-tweaks"
    "flatpak"
    "firefox"
  )

  PIPEWIRE_ENABLE="Y"
  read -p "Replace pulseaudio with PipeWire? [Y/n]: " PIPEWIRE_ENABLE
  [[ $PIPEWIRE_ENABLE =~ ^[Yy]$ ]] && PKG_LIST+=(
    "pipewire"
    "pipewire-alsa"
    "pipewire-jack"
    "pipewire-pulse"
  )

  FLATPAK_ENABLE="Y"
  read -p "Add Flatpak? [Y/n]: " FLATPAK_ENABLE
  [[ $FLATPAK_ENABLE =~ ^[Yy]$ ]] && PKG_LIST+=(
    "pipewire"
    "pipewire-alsa"
    "pipewire-jack"
    "pipewire-pulse"
  )
fi

log "Installing selected packages..."
pacstrap /mnt ${PKG_LIST[@]}
