#!/usr/bin/env bash
set -e
source "$(dirname $0)/utils.sh"

log "Generating /mnt/etc/fstab..."
genfstab -U /mnt >>/mnt/etc/fstab

# Install /etc/mkinitcpio.conf
log "Copying conf/mkinitcpio.conf to /mnt/etc/mkinitcpio.conf"
cp conf/mkinitcpio.conf /mnt/etc/mkinitcpio.conf

# Install /etc/default/grub
log "Copying conf/grub to /mnt/etc/default/grub"
cp conf/grub /mnt/etc/default/grub

# Install /etc/hosts
log "Copying conf/hosts to /mnt/etc/hosts"
cp conf/hosts /mnt/etc/hosts

# Install /etc/locale.conf
log "Copying conf/locale.conf to /mnt/etc/locale.conf"
cp conf/locale.conf /mnt/etc/locale.conf

# Install /etc/vconsole.conf
log "Copying conf/vconsole.conf to /mnt/etc/vconsole.conf"
cp conf/vconsole.conf /mnt/etc/vconsole.conf

# Install custom services
log "Copying conf/services/powertop.service to /mnt/etc/systemd/system"
cp conf/services/powertop.service /mnt/etc/systemd/system

log "All configuration files have been copied"
