#!/bin/bash
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
    exit 1
fi

_filecnt=$(ls $(dirname $1) | grep "html$" | wc -l)
if [ $_filecnt -ne 1 ]; then
    echo "directory must contain a unique html file"
    exit 1
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
cp $_base_pkg ${REPO_ROOT}/archive/
repo-add -R $_repo $_base_pkg
_html
cp ${_location}package.* $REPO_ROOT/
