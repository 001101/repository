#!/bin/bash
if [ ! -e PKGBUILD ]; then
    echo "PKGBUILD must be present"
    exit 1
fi

if [ -z "$CHROOT" ]; then
    echo
    echo "no chroot defined, make sure to run"
    echo "==="
    echo
    echo "CHROOT=/path/to/chroot"
    echo "export CHROOT"
    echo "mkarchroot \$CHROOT/root base-devel"
    echo "arch-nspawn \$CHROOT/root pacman -Syu"
    echo
    exit 1
fi


BIN=bin
BLD=$BIN/PKGBUILD
rm -rf $BIN
mkdir -p $BIN

PREPKG="PKGBUILD.pre"
if [ -e $PREPKG ]; then
    cat $PREPKG >> $BLD
fi

_arch="x86_64"
_vers=""
if [ $(ls -1 *.go 2>/dev/null | wc -l) != 0 ]; then 
    _vers=$(cat *.go | grep "const Version" | cut -d "=" -f 2 | sed 's/[[:space:]]*"[[:space:]]*//g')
    echo "pkgver=0.$vers" >> $BLD
fi 

case $1 in
    "arm7")
        echo "_make_args='arm7'" >> $BLD
        _arch="any"
        ;;
esac

echo "arch=('"$_arch"')" >> $BLD

cat PKGBUILD >> $BLD

PSTPKG="PKGBUILD.post"
if [ -e $PSTPKG ]; then
    cat $PSTPKG >> $BLD
fi

cwd=$PWD
cd $BIN
makechrootpkg -c -r $CHROOT
if [ $? -ne 0 ]; then
    echo "package build failed"
    exit 1
fi
gpg --detach-sign $(ls | grep pkg.tar.xz | sort -r | head -n 1)
if [ $? -ne 0 ]; then
    echo "signing failed"
    exit 1
fi
cd $cwd
