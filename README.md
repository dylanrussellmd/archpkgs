# archpkgs

A small, signed pacman repository for AUR packages that take hours to build
(for example `webkit2gtk`), so a fresh install downloads them instead.

Packages and the repository database are assets of the GitHub release
[`x86_64`](https://github.com/dylanrussellmd/archpkgs/releases/tag/x86_64).
Everything is signed with the archpkgs key (`archpkgs.asc` in this repo).
Only redistributable software belongs here: no proprietary binaries such as Citrix
Workspace.

## Current release contents

The `x86_64` release currently contains these packages (release asset versions):

| Package | Version | Reason |
|---|---|---|
| `webkit2gtk` | `2.50.6-8` | Long AUR build; Citrix dependency |
| `libsoup` | `2.74.3-4` | Citrix dependency; AUR `check()` needs Apache |
| `libjxl-0.11` | `0.11.2-1` | Pinned `icaclient` build dependency |
| `qml-language-server-git` | `r62.767f2d0-1` | AUR build fails on a Go proxy 403 |

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

Build packages with `makepkg` (or recreate an installed one with `fakepkg`), then
publish. `publish.sh` creates the `x86_64` release if needed, downloads its
existing database/index assets, signs each new package, and updates the
database with `repo-add --sign` (replacing an existing package of the same
name). It replaces `repo-add`'s database symlinks with regular copies, then
uploads each package and signature plus signed `archpkgs.db`/`archpkgs.files`
indexes in both pacman-requested flat names and `.tar.gz` archive names. Existing
release packages remain listed in the updated database.

## Repackaging an installed package (no rebuild)

`bacman` is no longer shipped by `pacman-contrib`. Its successor,
[fakepkg](https://github.com/Edenhofer/fakepkg) 1.42.2, reassembles a package from
an installed one, but writes the package base as `base`, which pacman reports as
an unknown key. Map it to `pkgbase` before use:

```sh
curl -fsSL https://github.com/Edenhofer/fakepkg/archive/v1.42.2.tar.gz | tar xz
sed -i 's/^\t\t\t\t"conflicts")    PKG_VAR=conflict;;/&\n\t\t\t\t"base")         PKG_VAR=pkgbase;;/' fakepkg-1.42.2/fakepkg
bash fakepkg-1.42.2/fakepkg -o out <package>
# rename to name-ver-rel-x86_64.pkg.tar.zst, then verify:
pacman -Qip out/*.pkg.tar.zst      # no warnings
```

The `webkit2gtk` 2.50.6-8 and `libjxl-0.11` 0.11.2-1 uploads were made
this way from the copies installed on `home` (both built from their AUR
PKGBUILDs). Each was checked by installing it into an empty root
(`pacman --root … -Udd`) and running `pacman -Qkk`.
