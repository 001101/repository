#!/bin/bash
source /etc/environment
if [ -z "$REPO_ROOT" ]; then
    echo "REPO_ROOT must be set in /etc/environment"
    exit 1
fi
if [ -z "$1" ]; then
    echo "input package html required"
    exit 1
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

repo-add $_repo $_pkg
REPO_ROOT_INDEX=${REPO_ROOT}/index.html
echo "<!DOCTYPE html>
    <head>
        <meta charset="utf-8">
        <title>epiphyte-build</title>
        <link rel="stylesheet" type="text/css" href="/repos/package.css" />
    </head> 
<body>
    <h1>epiphyte repository</h1>
    <hr />
    <table>
    <thead>
    <tr class="header">
    <th>packages</th>
    </tr>
    </thead>
    <tbody>" > $REPO_ROOT_INDEX

for f in $(find $REPO_ROOT -type f -name "*.html" -print | grep -v "index.html"); do
    _use=$(realpath $f | sed "s#$REPO_ROOT##g")
    echo "<tr><td><a href="$_use">$_use</a></td></tr>" >> $REPO_ROOT_INDEX
done
echo "</tbody></table></body></html>" >> $REPO_ROOT_INDEX
cp /opt/epiphyte/epiphyte-build/package.css $REPO_ROOT/package.css
