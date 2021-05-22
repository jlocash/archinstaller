#!/usr/bin/env bash
set -e
source "$(dirname $0)/utils.sh"

log "Copying chroot scripts to /mnt"
cp $(dirname $0)/{chroot,utils}.sh /mnt
log "Executing chroot"
arch-chroot /mnt ./chroot.sh
rm /mnt/{chroot,utils}.sh
