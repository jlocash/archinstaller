#!/usr/bin/env bash
set -e
source utils.sh
source install.conf

function configure_time_date_locale() {
  log_info "Configuring timezone, date and locale"
  timedatectl set-ntp true
  timedatectl set-timezone "${TARGET_TIMEZONE}"
  # ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  echo "${TARGET_LOCALE} $(echo ${TARGET_LOCALE} | cut -d '.' -f 2)" >>/etc/locale.gen
  locale-gen
  echo "LANG=\"${TARGET_LOCALE}\"" >>/etc/locale.conf
  echo "KEYMAP=\"${TARGET_KEYMAP}\"" >/etc/vconsole.conf
}

function configure_hosts() {
  log_info "Configuring system hostname"
  echo "$1" >/etc/hostname
  echo "
  127.0.0.1     localhost.localdomain localhost
  ::1           localhost.localdomain localhost
  127.0.1.1     $1.localdomain $1
  " >>/etc/hosts
}

function enable_services() {
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
}

function configure_bootloader() {
  local crypt_part="${1}"                       # eg: /dev/sda3
  local crypt_name="${2}"                       # eg: luks-<uuid>
  local crypt_path="/dev/mapper/${crypt_name}"  # eg: /dev/mapper/luks-<uuid>

  local grub_crypt_entry="rd.luks.name=$(blkid -s UUID -o value $crypt_part)=${crypt_name} root=${crypt_path}"
  local grub_cmdline_entries="apparmor=1 security=apparmor loglevel=3 quiet $grub_crypt_entry"

  log_info "Installing the GRUB bootloader"
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=archlinux
  sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT/#GRUB_CMDLINE_LINUX_DEFAULT/" /etc/default/grub
  echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${grub_cmdline_entries}\"" >>/etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
}

function configure_initramfs() {
  log_info "Configuring initramfs"
  mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
  echo 'MODULES=""' >>/etc/mkinitcpio.conf
  echo 'BINARIES=""' >>/etc/mkinitcpio.conf
  echo 'FILES=""' >>/etc/mkinitcpio.conf
  echo 'HOOKS="base systemd autodetect keyboard sd-vconsole modconf block btrfs sd-encrypt filesystems fsck"' >>/etc/mkinitcpio.conf

  mkinitcpio -p linux
}

function add_user() {
  log_info "Creating local administrator account"
  read -p "Enter username: " username

  while [[ "${username}" == "" ]]; do
    log_info "Invalid username: \"${username}\""
    read -p "Enter username: " username
  done

  useradd -m -G wheel "${username}"
  passwd "${username}"
}

partlist=("$TARGET_DISK"*)
configure_time_date_locale
configure_hosts "${TARGET_HOSTNAME}"
enable_services
configure_bootloader "${partlist[3]}" "${CRYPT_NAME}"
configure_initramfs
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
add_user
log_info "Locking root account"
passwd -l root
