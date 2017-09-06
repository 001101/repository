#!/bin/bash
CAT="autobuild"
_build() {
    cwd=$PWD
    echo "workingdir: $tmp"
    tmp=$(mktemp -d)
    git clone https://github.com/epiphyte/pkgbuilds $tmp
    cd $tmp
    has=$(git log --after=$(date -d "30 minutes ago" +%Y-%m-%dT%H:%M:%S))
    echo "$has" | systemd-cat -t "$CAT"
    if [ -z "$has" ]; then
        echo "nothing to be done"
    else
        for f in $(find . -type f | grep "PKGBUILD" | grep -v "bin/" | grep -v "containers" | sort | uniq); do
            echo "building: $f" | systemd-cat -t "$CAT"
            cd $(echo $f | sed "s/PKGBUILD//g")
            epiphyte-package
            if [ $? -ne 0 ]; then
                echo "failed" | systemd-cat -t "$CAT"
                echo "failed build: $f" | smirc
            fi
            cd $tmp
        done
    fi
    cd $cwd
    rm -rf $tmp
}

_build > /dev/null 2>&1
