#!/bin/bash
if [ -z "$CHROOT" ]; then
    echo "no CHROOT environment variable set"
    exit 1
fi
arch-nspawn -C /etc/pacman.conf $CHROOT/root pacman -Syyu
