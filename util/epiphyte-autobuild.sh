#!/bin/bash
cwd=$PWD
for f in $(find . -type f | grep "PKGBUILD" | grep -v "bin/" | grep -v "containers"); do
    cd $(echo $f | sed "s/PKGBUILD//g")
    epiphyte-package
    if [ $? -ne 0 ]; then
        echo "failed build: $f" | smirc
    fi
    cd $cwd
done
