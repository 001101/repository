#!/bin/bash
PKGBUILD=/etc/epiphyte.d/pkgbuilds
CACHE=/var/cache/aur/
WORK_DIR=/tmp/

_build() {
    cwd=$PWD
    pkgs=""
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
        for f in $(ls *.pkg.tar.xz); do
            pkgs=$pkgs" $f"
            rsync -avc $f $CACHE
        done
    done
    cd $CACHE
    if [ ! -z "$pkgs" ]; then
        repo-add -n auriphyte.db.tar.gz $pkgs
    fi
    cd $cwd
}

_build
