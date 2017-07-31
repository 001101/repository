util
===

epiphyte-build utilities for package maintenance/deployment.

# epiphyte-package

handles/supports building, signing, versioning, html generation, and uploading of packages

from a folder with an epiphyte `PKGBUILD`
```
epiphyte-package
```

to build for arm (any)
```
epiphyte-package arm_any
```

# epiphyte-deploy

deploy a new package, from within repo directory
```
epiphyte-deploy /path/to/generated/html/file.html
```
* requires `file.html`, `file-<vers>.tar.xz`, and `file-<vers>.tar.xz.sig` to all exist and be in the same location

to rebuild the index/public html page
```
epiphyte-deploy index
```
