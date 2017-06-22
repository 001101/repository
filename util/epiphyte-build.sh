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

_arch="x86_64"
_vers=""
if [ $(ls -1 *.go 2>/dev/null | wc -l) != 0 ]; then
    _vers=$(cat *.go | grep "const Version" | cut -d "=" -f 2 | sed 's/[[:space:]]*"[[:space:]]*//g')
    echo "_gover=$_vers" >> $BLD
fi 

case $1 in
    "arm7")
        echo "_make_args='arm7'" >> $BLD
        _arch="any"
        ;;
esac

echo "arch=('"$_arch"')" >> $BLD

PREPKG="PKGBUILD.pre"
if [ -e $PREPKG ]; then
    cat $PREPKG >> $BLD
fi

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
tar_xz=$(ls | grep pkg.tar.xz | sort -r | head -n 1)
gpg --detach-sign $tar_xz
if [ $? -ne 0 ]; then
    echo "signing failed"
    exit 1
fi
WORKING=meta.md
tar -xf $tar_xz .PKGINFO --to-stdout | grep -v "^#" > $WORKING
_get_value()
{
    cat $WORKING | grep "^$1 =" | cut -d "=" -f 2 | sed "s/[[:space:]]*//g"
}

ADJUSTED="cleaned.md"
source PKGBUILD

echo "# $pkgname ("$(_get_value "pkgver")")" > $ADJUSTED

echo "
---

$pkgdesc

<a href='$url'>$url</a>

" >> $ADJUSTED

echo "| details | |
| --- | --- |" >> $ADJUSTED

echo "| built | "$(date -d @$(_get_value "builddate") +%Y-%m-%d)" |" >> $ADJUSTED
cat $WORKING | grep -v -E "^(pkgname|pkgver|pkgdesc|url|makedepend|depend|builddate)" | sed "s/^/| /g;s/$/ |/g" | sed "s/=/|/g" >> $ADJUSTED

has_depends=0
for d in $(_get_value "depend"); do
    if [ $has_depends -eq 0 ]; then
    echo "
## dependencies
" >> $ADJUSTED
    fi
    has_depends=1
    echo "* $d" >> $ADJUSTED
done

HTML_START="
<html>
<head>
    <title>$pkgname</title>
<style>

html {
    margin: auto;
}

body {
    margin-top: 20px;
    margin-left: auto;
    margin-right: auto;
    width: 85%; 
}
table {
    border-collapse: collapse;
    width: 100%;
}
th, td {
    padding: 8px;
    text-align: left;
    border-bottom: 1px solid #ddd;
}
</style>
</head>
<body>
"

HTML_END="
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
echo $HTML_START > $OUT_HTML
cat $WORK_HTML >> $OUT_HTML
echo $HTML_END >> $OUT_HTML

cd $cwd
