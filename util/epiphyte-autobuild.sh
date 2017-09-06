#!/bin/bash
CAT="autobuild"
LAST_RUN=/tmp/autobuild.report

_log() {
    echo "$@" | tee -a $LAST_RUN | systemd-cat -t "$CAT"
}

_git() {
    git log --after=$(date -d "30 minutes ago" +%Y-%m-%dT%H:%M:%S) $@
}

_build() {
    cwd=$PWD
    tmp=$(mktemp -d)
    _log "workingdir: $tmp"
    git clone https://github.com/epiphyte/pkgbuilds $tmp
    cd $tmp
    has=$(_git)
    _log "$has"
    if [ -z "$has" ]; then
        _log "noop"
    else
        files=$(_git "--pretty=format: --name-only" | sed "/^$/d" | grep "PKGBUILD" | sort | uniq)
        for f in $(find . -type f | grep "PKGBUILD" | grep -v "bin/" | grep -v "containers" | sort | uniq); do
            build=1
            for m in $(echo "$files"); do
                use_name="./$m"
                if [ "$use_name" == "$f" ]; then
                    build=0
                fi
            done
            if [ $build -eq 1 ]; then
                continue
            fi
            _log "building: $f" 
            cd $(echo $f | sed "s/PKGBUILD//g")
            epiphyte-package
            if [ $? -ne 0 ]; then
                _log "failed"
                echo "failed build: $f" | smirc
            fi
            cd $tmp
        done
        _log "done"
        echo "autobuild completed" | smirc
    fi
    cd $cwd
    rm -rf $tmp
}

rm -f $LAST_RUN
_build >> $LAST_RUN 2>&1
