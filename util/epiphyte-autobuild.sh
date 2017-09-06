#!/bin/bash
cwd=$PWD
echo "workingdir: $tmp"
tmp=$(mktemp -d)
git clone https://github.com/epiphyte/pkgbuilds $tmp
cd $tmp
for f in $(find . -type f | grep "PKGBUILD" | grep -v "bin/" | grep -v "containers"); do
    echo "building: $f"
    cd $(echo $f | sed "s/PKGBUILD//g")
    epiphyte-package
    if [ $? -ne 0 ]; then
        echo "failed build: $f" | smirc
    fi
    cd $cwd
done
