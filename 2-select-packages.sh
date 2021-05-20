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

read -p "Add firewalld? [Y/n]: " firewalld_enable
if [[ ! $firewalld_enable =~ ^[Nn]$ ]]; then
  pkglist+=("firewalld")
fi

read -p "Add virtualization tools? [Y/n]: " virt_enable
if [[ ! $virt_enable =~ ^[Nn]$ ]]; then
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

read -p "Add the GNOME desktop? [Y/n]: " gnome_enable
if [[ ! $gnome_enable =~ ^[Nn]$ ]]; then
  pkglist+=(
    "gnome"
    "alsa-utils"
    "gnome-tweaks"
    "firefox"
  )

  read -p "Replace PulseAudio with PipeWire? [Y/n]: " pipewire_enable
  if [[ ! $pipewire_enable =~ ^[Nn]$ ]]; then
    pkglist+=(
      "pipewire"
      "pipewire-alsa"
      "pipewire-jack"
      "pipewire-pulse"
    )
  fi

  read -p "Add Flatpak? [Y/n]: " flatpak_enable
  if [[ ! $flatpak_enable =~ ^[Nn]$ ]]; then
    pkglist+=("flatpak")
  fi
fi

log "Installing selected packages..."
pacstrap /mnt ${pkglist[@]}
