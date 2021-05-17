#!/usr/bin/env bash
set -e
source utils.sh

CRYPT_PATH="$(findmnt -n -o SOURCE --target=/ | cut -d '[' -f 1)"
CRYPT_NAME="$(echo $CRYPT_PATH | cut -d '/' -f 4)"
ROOT_PART="$(cryptsetup status $CRYPT_NAME | grep device: | cut -d ':' -f 2 | xargs)"
GRUB_CRYPT_ENTRY="rd.luks.name=$(blkid -s UUID -o value $ROOT_PART)=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME"

hwclock --systohc

# locale
log "Configuring system locale"
TARGET_LOCALE="en_US.UTF-8"
read -p "enter desired locale [en_US.UTF-8]: " TARGET_LOCALE
echo "$TARGET_LOCALE $(echo $TARGET_LOCALE | cut -d '.' -f 2)" >>/etc/locale.gen
locale-gen
sed -i "s/__TARGET_LOCALE__/$TARGET_LOCALE/" /etc/locale.conf

# keymap
log "Configuring system keymap"
TARGET_KEYMAP="us"
read -p "enter desired keymap [us]: " TARGET_KEYMAP
sed -i "s/__TARGET_KEYMAP__/$TARGET_KEYMAP/" /etc/vconsole.conf

# hostname
log "Configuring system hostname"
TARGET_HOSTNAME="archlinux"
read -p "enter desired hostname [archlinux]: " TARGET_HOSTNAME
echo "$TARGET_HOSTNAME" >/etc/hostname
sed -i "s/__TARGET_HOSTNAME__/$TARGET_HOSTNAME/g" /etc/hosts

# enable systemd services
log "Enabling systemd services"
systemctl enable \
  NetworkManager \
  fstrim.timer \
  dnsmasq \
  ebtables \
  libvirtd \
  firewalld \
  tlp \
  powertop \
  gdm

# install and configure GRUB
log "Installing the GRUB bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=archlinux
sed -i "s|__GRUB_CRYPT_ENTRY__|$GRUB_CRYPT_ENTRY|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Regenerate initramfs
log "Regenerating initramfs"
mkinitcpio -p linux

# create administrator user
log "Creating local administrator account"
username=""
while [[ "$username" == "" ]]; do
  read -p "Enter username: " username
done

useradd -m -G wheel "$username"
passwd "$username"

# tweak /etc/sudoers
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

# Lock root account
log "Locking root account"
passwd -l root
