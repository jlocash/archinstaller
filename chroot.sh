#!/usr/bin/env bash
set -e
source utils.sh

hwclock --systohc

# locale
log "Configuring system locale"
read -p "enter desired locale [en_US.UTF-8]: " TARGET_LOCALE
if [[ -z $TARGET_LOCALE ]]; then
  TARGET_LOCALE="en_US.UTF-8"
fi

echo "$TARGET_LOCALE $(echo $TARGET_LOCALE | cut -d '.' -f 2)" >>/etc/locale.gen
locale-gen
sed -i "s/__TARGET_LOCALE__/$TARGET_LOCALE/" /etc/locale.conf

# keymap
log "Configuring system keymap"
read -p "enter desired keymap [us]: " TARGET_KEYMAP
if [[ -z $TARGET_KEYMAP ]]; then
  TARGET_KEYMAP="us"
fi
sed -i "s/__TARGET_KEYMAP__/$TARGET_KEYMAP/" /etc/vconsole.conf

# hostname
log "Configuring system hostname"
read -p "enter desired hostname [archlinux]: " TARGET_HOSTNAME
if [[ -z $TARGET_HOSTNAME ]]; then
  TARGET_HOSTNAME="archlinux"
fi
echo "$TARGET_HOSTNAME" >/etc/hostname
sed -i "s/__TARGET_HOSTNAME__/$TARGET_HOSTNAME/g" /etc/hosts

# enable systemd services
log "Enabling systemd services"
svc_list=(
  "NetworkManager"
  "fstrim.timer"
  "dnsmasq"
  "ebtables"
  "libvirtd"
  "firewalld"
  "tlp"
  "powertop"
  "gdm"
)

for svc in ${svc_list[@]}; do
  systemctl enable $svc || true
done

# install and configure GRUB
log "Installing the GRUB bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=archlinux
CRYPT_NAME="$(basename $(findmnt -nvo SOURCE --target=/))"
GRUB_CRYPT_ENTRY="rd.luks.uuid=$CRYPT_NAME"
sed -i "s|__GRUB_CRYPT_ENTRY__|$GRUB_CRYPT_ENTRY|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Regenerate initramfs
log "Regenerating initramfs"
mkinitcpio -p linux

# create administrator user
log "Creating local administrator account"
username=""
while [[ -z $username ]]; do
  read -p "Enter username: " username
done

useradd -m -G wheel "$username"
passwd "$username"

# tweak /etc/sudoers
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

# Lock root account
log "Locking root account"
passwd -l root
