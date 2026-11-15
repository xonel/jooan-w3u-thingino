#!/usr/bin/env bash
# release.sh — Create and tag a new Jooan W3-U firmware release
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
VERSION_FILE="$REPO_ROOT/VERSION"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>   (e.g. 0.2.0)" >&2
  exit 1
fi

VERSION="$1"
TAG="v$VERSION"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be semantic (X.Y.Z)" >&2
  exit 1
fi

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: Tag $TAG already exists" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: Working tree not clean. Commit or stash changes first." >&2
  exit 1
fi

echo "$VERSION" > "$VERSION_FILE"
git add VERSION
git commit -m "chore: release v$VERSION" -s || true

git tag -a "$TAG" -m "Release v$VERSION — Jooan W3-U Dual-Sensor Thingino Firmware (SC2336P + CV2003)"
git push origin main
git push origin "$TAG"
echo "Release $TAG pushed! GitHub Actions will publish release binaries."
