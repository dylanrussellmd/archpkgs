# archpkgs

A small, signed pacman repository for AUR packages that take hours to build
(for example `webkit2gtk`), so a fresh install downloads them instead.

Packages and the repository database are assets of the GitHub release
[`x86_64`](https://github.com/dylanrussellmd/archpkgs/releases/tag/x86_64).
Everything is signed with the archpkgs key (`archpkgs.asc` in this repo).
Only redistributable software belongs here: no proprietary binaries such as Citrix
Workspace.

## Use it

```sh
# 1. Trust the signing key (once per machine).
#    Fingerprint: E8C3E50D7ADC0639B86AD5AB9F5B63EC5E895468
curl -fsSL https://raw.githubusercontent.com/dylanrussellmd/archpkgs/main/archpkgs.asc -o /tmp/archpkgs.asc
sudo pacman-key --add /tmp/archpkgs.asc
sudo pacman-key --lsign-key E8C3E50D7ADC0639B86AD5AB9F5B63EC5E895468
```

```ini
# 2. /etc/pacman.conf, after the official repositories
[archpkgs]
SigLevel = Required DatabaseRequired
Server = https://github.com/dylanrussellmd/archpkgs/releases/download/x86_64
```

## Publish a package

```sh
ARCHPKGS_KEY=E8C3E50D7ADC0639B86AD5AB9F5B63EC5E895468 ./publish.sh /path/to/name-ver-rel-x86_64.pkg.tar.zst
```

Build packages with `makepkg` (or recreate an installed one with `bacman`), then
publish. `publish.sh` signs each package, updates `archpkgs.db` with `repo-add
--sign`, and uploads both to the release.
