repository
===

An epiphyte-hosted repository of pre-built packages for software systems developed for/by the epiphyte community

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

# package

please see the corresponding repositories for more information

| project | architectures |
| --- | --- |
| [mbot-receiver](https://github.com/epiphyte/synapse-tools) | x86_64, armv7h |
| [phab-http](https://github.com/epiphyte/synapse-tools) | x86_64 |
| [matrix-bot](https://github.com/epiphyte/matrix-bot) | x86_64 |
