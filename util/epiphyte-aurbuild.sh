#!/bin/bash
PKGBUILD=/etc/epiphyte.d/pkgbuilds
CACHE=/var/cache/aur/
WORK_DIR=/tmp/

_build() {
    cwd=$PWD
    pkgs=""
    for b in $(cat $PKGBUILD); do
        _file=$b.tar.gz
        rm -f $_file
        _tmp=$(mktemp -d)
        echo "building $b in $_tmp"
        cd $_tmp
        curl https://aur.archlinux.org/cgit/aur.git/snapshot/$b.tar.gz > $_file
        tar xf $_file
        cd $b
        epiphyte-package x86_64
        if [ $? -ne 0 ]; then
            echo "failed aur build: $b" | smirc
        fi
        for f in $(ls *.pkg.tar.xz); do
            pkgs=$pkgs" $f"
            rsync -avc $f $CACHE
        done
    done
    cd $CACHE
    if [ ! -z "$pkgs" ]; then
        repo-add -n auriphyte.db.tar.gz $pkgs
        if [ $? -ne 0 ]; then
            echo "unable to update: $b" | smirc
        fi
    fi
    cd $cwd
}

_build
