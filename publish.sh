#!/usr/bin/env bash
# Sign packages and publish them to the archpkgs pacman repository, which is
# hosted as assets of the GitHub release "x86_64".
#
#   ARCHPKGS_KEY=<fingerprint> ./publish.sh path/to/pkg.pkg.tar.zst...
#
# gpg asks for the signing key's passphrase. Existing database and packages in
# the release are kept; packages with the same name are replaced by repo-add.
set -euo pipefail

REPO=archpkgs
TAG=x86_64
GH=dylanrussellmd/archpkgs
KEY=${ARCHPKGS_KEY:?set ARCHPKGS_KEY to the signing key fingerprint}
WORK=${ARCHPKGS_WORK:-$HOME/.cache/archpkgs}

(($# > 0)) || { echo "usage: ARCHPKGS_KEY=<fpr> $0 pkg.pkg.tar.zst..." >&2; exit 2; }
mkdir -p "$WORK"

gh release view "$TAG" -R "$GH" >/dev/null 2>&1 ||
	gh release create "$TAG" -R "$GH" --title "archpkgs x86_64" \
		--notes "Signed pacman repository. See README.md for pacman.conf and key setup."

# Start from the published database so earlier packages stay listed.
for f in "$REPO.db.tar.gz" "$REPO.db.tar.gz.sig" "$REPO.files.tar.gz" "$REPO.files.tar.gz.sig"; do
	gh release download "$TAG" -R "$GH" -p "$f" -D "$WORK" --clobber 2>/dev/null || true
done

upload=()
for p in "$@"; do
	b=$(basename "$p")
	[[ $b == *:* ]] && { echo "GitHub assets cannot contain ':' ($b)" >&2; exit 1; }
	cp -f "$p" "$WORK/$b"
	gpg --local-user "$KEY" --detach-sign --no-armor --yes -o "$WORK/$b.sig" "$WORK/$b"
	upload+=("$WORK/$b" "$WORK/$b.sig")
done

(cd "$WORK" && repo-add --sign --key "$KEY" "$REPO.db.tar.gz" "${@##*/}")

# pacman requests archpkgs.db / archpkgs.files; release assets cannot be symlinks.
for kind in db files; do
	cp -f "$WORK/$REPO.$kind.tar.gz" "$WORK/$REPO.$kind"
	cp -f "$WORK/$REPO.$kind.tar.gz.sig" "$WORK/$REPO.$kind.sig"
	upload+=("$WORK/$REPO.$kind" "$WORK/$REPO.$kind.sig" "$WORK/$REPO.$kind.tar.gz" "$WORK/$REPO.$kind.tar.gz.sig")
done

gh release upload "$TAG" -R "$GH" --clobber "${upload[@]}"
echo "Published: ${*##*/}"
