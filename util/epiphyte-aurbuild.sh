#!/bin/bash
PKGBUILD=/etc/epiphyte.d/pkgbuilds
CACHE=/var/cache/aur/
WORK_DIR=/tmp/

_build() {
    cwd=$PWD
    for b in $(cat $PKGBUILD); do
        rm -f $_file
        _tmp=$(mktemp -d)
        echo "building $b in $_tmp"
        cd $_tmp
        _file=$b.tar.gz
        curl https://aur.archlinux.org/cgit/aur.git/snapshot/$b.tar.gz > $_file
        tar xf $_file
        cd $b
        makepkg -sr --noconfirm
        rsync -avc $b $CACHE
    done
    cd $cwd
}

_build
