#!/bin/bash
cwd=$PWD
echo "workingdir: $tmp"
tmp=$(mktemp -d)
git clone https://github.com/epiphyte/pkgbuilds $tmp
cd $tmp
has=$(git log --after=$(date -d "10 minutes ago" +%Y-%m-%dT%H:%M:%S))
if [ -z "$has" ]; then
    echo "nothing to be done"
else
    for f in $(find . -type f | grep "PKGBUILD" | grep -v "bin/" | grep -v "containers"); do
        echo "building: $f"
        cd $(echo $f | sed "s/PKGBUILD//g")
        epiphyte-package
        if [ $? -ne 0 ]; then
            echo "failed build: $f" | smirc
        fi
        cd $tmp
    done
fi
cd $cwd
rm -rf $tmp
