#!/bin/bash
PKGBUILD=/etc/epiphyte.d/pkgbuilds
CACHE=/var/cache/aur/
WORK_DIR=/tmp/
REPO="auriphyte.db.tar.gz"
REPO_NAME=$CACHE/$REPO

_build() {
    cwd=$PWD
    pkgs=""
    fail=0
    for b in $(cat $PKGBUILD); do
        _file=$b.tar.gz
        rm -f $_file
        _tmp=$(mktemp -d)
        echo "building $b in $_tmp"
        cd $_tmp
        curl https://aur.archlinux.org/cgit/aur.git/snapshot/$b.tar.gz > $_file
        tar xf $_file
        cd $b
        makechrootpkg -c -r $CHROOT
        if [ $? -ne 0 ]; then
            echo "failed aur build: $b" | smirc
            fail=1
        fi
        for f in $(ls *.pkg.tar.xz); do
            pkgs=$pkgs" $f"
            rsync -avc $f $CACHE
        done
    done
    cd $CACHE
    if [ ! -z "$pkgs" ]; then
        repo-add -n $REPO $pkgs
        if [ $? -ne 0 ]; then
            echo "unable to update: $b" | smirc
            fail=1
        fi
    fi
    if [ $fail -eq 0 ]; then
        echo "aurbuilds completed" | smirc
    fi
    cd $cwd
}

if [ ! -d $CACHE ]; then
    echo "$CACHE does not exist"
    exit 1
fi
if [ ! -e $REPO_NAME ]; then
    echo "$REPO_NAME does not exist"
    exit 1
fi
if [ ! -e $PKGBUILD ]; then
    echo "$PKGBUILD does not exist"
    exit 1
fi

_build
