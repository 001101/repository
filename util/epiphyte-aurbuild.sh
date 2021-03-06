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
        echo "building $b"
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
            if [ ! -e $CACHE/$f ]; then
                echo "updating $f"
                pkgs=$pkgs" $f"
                rsync -avc $f $CACHE
            fi
        done
        rm -rf $_tmp
        _prev_vers=$(ls $CACHE | grep ^${b}-[0-9] | sort -r | tail -n +30)
        for p in $(echo $_prev_vers); do
            rm $CACHE/$p
            _removing=$CACHE/$p
            echo "removing archived version: $_removing"
            rm $_removing
        done
    done
    cd $CACHE
    if [ -z "$pkgs" ]; then
        echo "nothing to be done"
    else
        for p in $(echo "$pkgs"); do
            echo "repository update: $p ($b)"
            repo-add -n $REPO $p
            if [ $? -ne 0 ]; then
                echo "unable to update: $p ($b)" | smirc
                fail=1
            fi
        done
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
if [ $UID -eq 0 ]; then
    echo "can not run as root"
    exit 1
fi

_build
