epiphyte repository
===

An epiphyte-hosted repository of pre-built packages for software systems developed for/by the epiphyte community

# browse

You can browse the repository packages and information [here](https://mirror.epiphyte.network/repos/index.html). The repository tooling is available on [github](https://github.com/epiphyte/repository)

# setup

enable the repository
```
vim /etc/pacman.conf
---
#uncomment the following line and the corresponding server for arch/system type
#[epiphyte]
# for x86_64
#Server = https://mirror.epiphyte.network/repos/$repo/community
# for armv7h,aarch64, or generally similar arm devices (e.g. pi2, pi3, odroid c2)
#Server = https://mirror.epiphyte.network/repos/$repo/$arch
```

update pacman
```
pacman -Syy
```

required keys for package signing from [enckse](https://github.com/enckse) and on [pool.sks-keyservers.net](http://pool.sks-keyservers.net/pks/lookup?op=vindex&fingerprint=on&search=0xF08D2E576641A175)
```
pacman-key -r A7D812B7A501CEBB2AA30289F08D2E576641A175
```

or download and locally add

```
curl https://mirror.epiphyte.network/repos/enckse.gpg > ~/enckse.gpg
pacman-key -a ~/enckse.gpg
```

then locally sign
```
pacman-key --lsign A7D812B7A501CEBB2AA30289F08D2E576641A175
```

# archive

Archived/old versions of packages are stored [here](https://mirror.epiphyte.network/repos/archive)

# auriphyte

The [auriphyte](https://mirror.epiphyte/network/repos/auriphyte) contains pre-built aur packages (rebuilt daily).

To enable the auriphyte repository
```
[auriphyte]
SigLevel = PackageOptional
Server = http://mirror.epiphyte.network/repos/$repo/
```

**Packages in auriphyte are automatically built and not signed**
