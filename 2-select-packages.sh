#!/usr/bin/env bash
set -e
source "$(dirname $0)/utils.sh"

pkglist=(
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

firewalld_enable="Y"
read -p "Add firewalld? [Y/n]: " firewalld_enable
if [[ $firewalld_enable =~ ^[Yy]$ ]]; then
  pkglist+=("firewalld")
fi

virt_enable="Y"
read -p "Add virtualization tools? [Y/n]: " virt_enable
if [[ $virt_enable =~ ^[Yy]$ ]]; then
  pkglist+=(
    "libvirt"
    "edk2-ovmf"
    "ebtables"
    "dnsmasq"
    "dmidecode"
    "podman"
    "vagrant"
    "nfs-utils"
  )
fi

gnome_enable="Y"
read -p "Add the GNOME desktop? [Y/n]: " gnome_enable
if [[ $gnome_enable =~ ^[Yy]$ ]]; then
  pkglist+=(
    "gnome"
    "alsa-utils"
    "gnome-tweaks"
    "flatpak"
    "firefox"
  )

  pipewire_enable="Y"
  read -p "Replace pulseaudio with PipeWire? [Y/n]: " pipewire_enable
  if [[ $pipewire_enable =~ ^[Yy]$ ]]; then
    pkglist+=(
      "pipewire"
      "pipewire-alsa"
      "pipewire-jack"
      "pipewire-pulse"
    )
  fi

  flatpak_enable="Y"
  read -p "Add Flatpak? [Y/n]: " flatpak_enable
  if [[ $flatpak_enable =~ ^[Yy]$ ]]; then
    pkglist+=(
      "pipewire"
      "pipewire-alsa"
      "pipewire-jack"
      "pipewire-pulse"
    )
  fi
fi

log "Installing selected packages..."
pacstrap /mnt ${pkglist[@]}
