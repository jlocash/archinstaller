#!/usr/bin/env bash
set -e
source utils.sh
source install.conf

# constants
ROOTPART="$(get_root_partname $TARGET_DISK)" # eg: /dev/sda3
CRYPT_NAME="$(get_crypt_name $TARGET_DISK)"  # eg: /dev/mapper/luks-<luksUUID>
GRUB_CRYPT_ENTRY="rd.luks.name=$(blkid -s UUID -o value $ROOTPART)=$CRYPT_NAME root=/dev/mapper$CRYPT_NAME"

# configure timezone
log_info "Configuring timezone, date and locale"
timedatectl set-ntp true
timedatectl set-timezone "$TARGET_TIMEZONE"

# apply locale
echo "$TARGET_LOCALE $(echo $TARGET_LOCALE | cut -d '.' -f 2)" >>/etc/locale.gen
locale-gen
sed -i "s/__TARGET_LOCALE__/$TARGET_LOCALE/" /etc/locale.conf

# apply keymap
sed -i "s/__TARGET_KEYMAP__/$TARGET_KEYMAP/" /etc/vconsole.conf

# configure hostname
log_info "Configuring system hostname"
echo "$TARGET_HOSTNAME" >/etc/hostname
sed -i "s/__TARGET_HOSTNAME__/$TARGET_HOSTNAME/g" /etc/hosts

# enable systemd services
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
log_info "Installing the GRUB bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=archlinux
sed -i "s|__GRUB_CRYPT_ENTRY__|$grub_crypt_entry|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Regenerate initramfs
mkinitcpio -p linux

# create administrator user
log_info "Creating local administrator account"
read -p "Enter username: " username

while [[ "$username" == "" ]]; do
  log_info "Invalid username: \"$username\""
  read -p "Enter username: " username
done

useradd -m -G wheel "$username"
passwd "$username"

# tweak /etc/sudoers
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

# Lock root account
log_info "Locking root account"
passwd -l root
