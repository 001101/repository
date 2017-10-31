#!/bin/bash
if [ -z "$CHROOT" ]; then
    echo "no CHROOT environment variable set"
    exit 1
fi
UPDATE="update"
BUILD="build"

case $1 in
    $UPDATE)
        echo "updating chroot at $CHROOT"
        arch-nspawn -C /etc/pacman.conf $CHROOT/root pacman -Syyu
        ;;
    $BUILD)
        echo "building chroot at $CHROOT"
        mkarchroot -C /etc/pacman.conf $CHROOT/root base-devel
        ;;
    *)
        echo "must run with $BUILD or $UPDATE"
        ;;
esac
