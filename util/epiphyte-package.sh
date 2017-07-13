#!/bin/bash
EPIPHYTE_ENV=$HOME/.config/epiphyte/env
if [ -e $EPIPHYTE_ENV ]; then
    IS_USER=1
    source $EPIPHYTE_ENV
fi

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

_arch="x86_64"
_vers=""
if [ $(ls -1 *.go 2>/dev/null | wc -l) != 0 ]; then
    _vers=$(cat *.go | grep "const Version" | cut -d "=" -f 2 | sed 's/[[:space:]]*"[[:space:]]*//g')
    echo "_gover=$_vers" >> $BLD
fi 

if [ ! -z "$1" ]; then
    arm7_arch="arm7"
    aarch64="aarch64"
    x86_64_arch="x86_64"
    SUPPORT_ARCHS="$arm7_arch $x86_64_arch"
    case $1 in
        $x86_64_arch)
            ;;
        $arm7_arch | $aarch64)
            echo "_make_args='$1'" >> $BLD
            _arch="any"
            ;;
        *)
            echo "$1 must be one of: $SUPPORT_ARCHS"
            exit
    esac
fi

echo "arch=('"$_arch"')" >> $BLD

PREPKG="PKGBUILD.pre"
if [ -e $PREPKG ]; then
    cat $PREPKG >> $BLD
fi

if [ -e "INSTALL" ]; then
    _install_sh="install.sh"
    _install=$BIN/$_install_sh
    cp INSTALL $_install
    chmod 777 $_install
    echo "install='"$_install_sh"'" >> $BLD
fi

cat PKGBUILD | grep -q "^pkgver="
_nopkgver=$?
_pkgdate=$(date -u +%Y%m%d)
_gitrev_originmaster=""
if [ $_nopkgver -ne 0 ]; then
    echo "pkgver=$_pkgdate" >> $BLD
    _gitrev_originmaster=$(git rev-parse origin/master)
fi

cat PKGBUILD >> $BLD

PSTPKG="PKGBUILD.post"
if [ -e $PSTPKG ]; then
    cat $PSTPKG >> $BLD
fi

if [ -e "configure" ]; then
    ./configure $BLD $BIN
fi

cwd=$PWD
cd $BIN
makechrootpkg -c -r $CHROOT
if [ $? -ne 0 ]; then
    echo "package build failed"
    exit 1
fi

# we have a package, locally delivered packages are NOT signed or html generated
if [ -e "$cwd/.LOCAL" ]; then
    echo "local package build completed."
    cd $cwd
    exit 0
fi

tar_xz=$(ls | grep pkg.tar.xz | sort -r | head -n 1)
if [ ! -z $IS_USER ]; then
    gpg --detach-sign $tar_xz
    if [ $? -ne 0 ]; then
        echo "signing failed"
        exit 1
    fi
fi

WORKING=meta.md
tar -xf $tar_xz .PKGINFO --to-stdout | grep -v "^#" > $WORKING
_get_value()
{
    cat $WORKING | grep "^$1 =" | cut -d "=" -f 2 | sed "s/[[:space:]]*//g"
}

ADJUSTED="cleaned.md"
source PKGBUILD

_pkgversion=$(_get_value "pkgver")

if [ ! -z $IS_USER ]; then
    sudo pacman -Syy
    cur=$(pacman -Sl epiphyte | cut -d " " -f 2,3 | sed "s/ /:/g" | grep "$pkgname:")
    if [ $_nopkgver -ne 0 ] && [ ! -z "$cur" ]; then
        echo $cur | grep -q "$_pkgdate"
        if [ $? -ne 0 ]; then
            if [ $pkgrel -ne 1 ]; then
                echo "pkgrel should be reset ($_pkgdate -> $pkgrel)"
                exit 1
            fi
        fi
    fi
    echo $cur | grep -q "$pkgname:$_pkgversion"
    if [ $? -eq 0 ]; then
        echo "package version and/or release need to be updated"
        read -p "force (y/n)? " forcey
        if [[ $forcey != "y" ]]; then
            exit 1
        fi
    fi

fi

echo "# $pkgname ($_pkgversion)" > $ADJUSTED

echo "
---

$pkgdesc

<a href='$url'>$url</a>

" >> $ADJUSTED

echo "| details | |
| --- | --- |" >> $ADJUSTED

echo "| built | "$(date -d @$(_get_value "builddate") +%Y-%m-%d)" |" >> $ADJUSTED
echo "| size | "$(_get_value "size" | awk '{$1/=1024;printf "%.2fKB\n",$1}')" |" >> $ADJUSTED
if [ $_nopkgver -ne 0 ]; then
    echo "| commit | $_gitrev_originmaster |" >> $ADJUSTED
fi
cat $WORKING | grep -v -E "^(pkgname|pkgver|pkgdesc|url|makedepend|depend|builddate|size|backup)" | sed "s/optdepend/optional/g" | sed "s/^/| /g;s/$/ |/g" | sed "s/=/|/g" >> $ADJUSTED

has_depends=0
for d in $(_get_value "depend"); do
    if [ $has_depends -eq 0 ]; then
    echo "
## dependencies

| packages |
| --- |" >> $ADJUSTED
    fi
    has_depends=1
    echo "| $d |" >> $ADJUSTED
done

echo "
## contents

| file/directory |
| --- |" >> $ADJUSTED
tar -tf $tar_xz  | grep -v "^\." | sed "s/^/| /g;s/$/ |/g" >> $ADJUSTED

HTML_START="<!DOCTYPE html>
    <head>
        <meta charset=\"utf-8\">
        <title>$pkgname</title>
        <link rel=\"stylesheet\" type=\"text/css\" href=\"/repos/package.css\" />
        <script src=\"/repos/package.js\"></script>
    </head>
<body>
"

HTML_END="
<br />
<hr />
<a href=\"/repos/index.html\">index</a>
</body>
</html>
"

mv $ADJUSTED $WORKING
WORK_HTML=$WORKING.html
pandoc $WORKING --out $WORK_HTML
if [ $? -ne 0 ]; then
    echo "unable to build html page"
    exit 1
fi

OUT_HTML=$pkgname.html
echo "$HTML_START" > $OUT_HTML
cat $WORK_HTML | sed "s/>contents/>contents [+]/g" >> $OUT_HTML
echo "$HTML_END" >> $OUT_HTML
if [ ! -z "$MIRROR_EPIPHYTE" ] && [ ! -z $IS_USER ]; then
    yn="n"
    read -p "upload (y/n)? " yn
    if [[ $yn == "y" ]]; then
        scp $tar_xz $OUT_HTML $tar_xz.sig $MIRROR_EPIPHYTE:~/
    fi
fi
cd $cwd
