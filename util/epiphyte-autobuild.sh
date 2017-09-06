#!/bin/bash
cwd=$PWD
for f in $(find . -type f | grep "PKGBUILD" | grep -v "bin/" | grep -v "containers"); do
    cd $(echo $f | sed "s/PKGBUILD//g")
    epiphyte-package
    cd $cwd
done
