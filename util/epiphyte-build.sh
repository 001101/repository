#!/bin/bash
_autobuild() {
    CAT="autobuild"
    LAST_RUN=/tmp/autobuild.report
    IS_FORCE=0
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
        if [ $1 -eq $IS_FORCE ]; then
            has="force"
            _log "forced"
        fi
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
                if [ $1 -eq $IS_FORCE ]; then
                    build=0
                fi
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
    
    force=1
    if [ ! -e $LAST_RUN ]; then
        force=$IS_FORCE
    fi
    
    rm -f $LAST_RUN
    _build $force >> $LAST_RUN 2>&1
}
    
_deploy() {
    source /etc/environment
    if [ -z "$REPO_ROOT" ]; then
        echo "REPO_ROOT must be set in /etc/environment"
        exit 1
    fi
    
    _location=/opt/epiphyte/epiphyte-build/
    _html() {
        REPO_ROOT_INDEX=${REPO_ROOT}/index.html
        echo "<!DOCTYPE html>
            <head>
                <meta charset="utf-8">
                <title>epiphyte community repository</title>
                <link rel="stylesheet" type="text/css" href="/repos/package.css" />
            </head> 
        <body>" > $REPO_ROOT_INDEX
    
        cat ${_location}readme.html >> $REPO_ROOT_INDEX
    
        echo "<table><thead><tr class=\"header\"><th>repositories</th></tr></thead><tbody>" >> $REPO_ROOT_INDEX
        for a in $(find -L $REPO_ROOT -maxdepth 2 | cut -d "/" -f 6 | sort | uniq | grep -v "^$"); do
            echo "<tr><td><a href='epiphyte/$a'>$a</a></td></tr>" >> $REPO_ROOT_INDEX
        done
        echo "</tbody></table><br /><br />" >> $REPO_ROOT_INDEX
    
        echo "
        <table>
        <thead>
        <tr class="header">
        <th>packages</th>
        </tr>
        </thead>
        <tbody>" >> $REPO_ROOT_INDEX
        
        for f in $(find -L $REPO_ROOT -type f -name "*.html" -print | grep -v "index.html" | sort -t/ -k5,6); do
            _use=$(echo $f | sed "s#$REPO_ROOT##g")
            _disp=$(echo $_use | sed "s/\.html//g")
            echo "<tr><td><a href="$_use">$_disp</a></td></tr>" >> $REPO_ROOT_INDEX
        done
        echo "</tbody></table></body></html>" >> $REPO_ROOT_INDEX
    }
    
    if [ -z "$1" ]; then
        echo "input required"
        exit 1
    fi
    
    if [[ "$1" == "index" ]]; then
        _html
        exit 0
    fi
    
    if [ ! -e "$1" ]; then
        echo "location must be a package"
        exit 1
    fi
    echo $1 | grep -q ".html$"
    if [ $? -ne 0 ]; then
        echo "must be the html package"
        exit
    fi
    
    _get_tar() {
        ls -1 $1*.$2 2>/dev/null
    }
    
    _repo=$(_get_tar "" "db.tar.gz")
    if [ -z "$_repo" ]; then
        echo "no repo found..."
        exit
    fi
    if [ $(echo $_repo | wc -l) != 1 ]; then
        echo "must be run from the location of a repo for repo-add"
        exit 1
    fi
    
    _file_path=$(dirname $1)
    _fname=$(basename $1 | sed "s/\.html//g")
    _pkg=$(echo $(_get_tar $_file_path/ "tar.xz") | grep "$_fname")
    _sign=$_pkg.sig
    if [ ! -e $_sign ]; then
        echo "unable to find package and signature files"
        exit
    fi
    
    mv $_file_path/$_fname* .
    _base_pkg=$(basename $_pkg)
    repo-add $_repo $_base_pkg
    _html
    cp ${_location}package.* $REPO_ROOT/
    
    for f in $(find . -type f -name "$_fname-*" -print | grep -v "$_base_pkg"); do
        rm $f
    done
}

_package() {
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
    _arch_build="$1"
    _force_arch=0
    if [ -z "$_arch_build" ]; then
        _overarch=".TARGET"
        if [ -e "$_overarch" ]; then
            _force_arch=1
            _arch_build=$(cat $_overarch)
        fi
    fi
    
    if [ ! -z "$_arch_build" ]; then
        arm7_arch="arm7"
        aarch64_arch="aarch64"
        x86_64_arch="x86_64"
        armany_arch="arm_any"
        any_arch="any"
        SUPPORT_ARCHS="$aarch64_arch $arm7_arch $x86_64_arch $armany_arch $any_arch"
        case $_arch_build in
            $x86_64_arch)
                ;;
            $arm7_arch | $aarch64_arch | $armany_arch)
                echo "_make_args='$_arch_build'" >> $BLD
                _arch="any"
                ;;
            $any_arch)
                _arch="any"
                ;;
            *)
                echo "$_arch_build must be one of: $SUPPORT_ARCHS"
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
        if [ $? -ne 0 ]; then
            echo "configure non-zero exit"
            exit 1
        fi
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
    
    tar_xz=$(ls | grep "pkg.tar.xz$" | sort -r | head -n 1)
    if [ ! -z $IS_USER ]; then
        gpg --detach-sign $tar_xz
        if [ $? -ne 0 ]; then
            echo "signing failed"
            exit 1
        fi
    fi
    
    if [ $_force_arch -eq 0 ]; then
        if namcap $tar_xz | grep -q 'No ELF files and not an "any" package'; then
            echo "architecture must be set to 'any' for this package"
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
}

if [ -z "$1" ]; then
    echo "subcommand required"
    exit 1
fi

cmd="_$1"
$cmd $@
