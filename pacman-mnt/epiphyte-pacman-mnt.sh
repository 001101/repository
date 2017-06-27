#!/bin/bash
VARS=/home/$SUDO_USER/.config/epiphyte/env
if [ -e $VARS ]; then
    source $VARS
fi
if [ -z "$LOCAL_REPOS" ]; then
    echo "The LOCAL_REPOS repository is not set, it must point to a directory"
    exit 1
fi

if [ ! -d "$LOCAL_REPOS" ]; then
    echo "$LOCAL_REPOS is not a directory"
    exit 1
fi

_pacman_tmp=""
_first=1
for f in $(find $LOCAL_REPOS -name "*.db.tar.gz" -type f); do
    if [ $_first -eq 1 ]; then
        _pacman_tmp=$(mktemp --suffix "-pacman-mnt.conf")
        cat /etc/pacman.conf > $_pacman_tmp
    fi

    _dir=$(dirname $f)
    _fname=$(basename $f | sed "s/.db.tar.gz//g")
    echo "[$_fname]" >> $_pacman_tmp
    echo "Server = file://$_dir" >> $_pacman_tmp
    _first=0
done

if [ $_first -eq 1 ]; then
    echo "no repositories found"
    exit
fi

pacman --config $_pacman_tmp $@
