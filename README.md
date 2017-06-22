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
#Server = http://mirror.epiphyte.network/repos/$repo/community
# for armv7h/pi2/pi3
#Server = http://mirror.epiphyte.network/repos/$repo/$arch
```

update pacman
```
pacman -Syy
```

required keys for package signing from [enckse](https://github.com/enckse) and on [pool.sks-keyservers.net](http://pool.sks-keyservers.net/pks/lookup?op=vindex&fingerprint=on&search=0xF08D2E576641A175)
```
pacman-key -r A7D812B7A501CEBB2AA30289F08D2E576641A175
pacman-key --lsign A7D812B7A501CEBB2AA30289F08D2E576641A175
```

