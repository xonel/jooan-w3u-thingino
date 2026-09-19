#!/bin/bash
# release.sh — Create a new firmware release

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
VERSION_FILE="$REPO_ROOT/VERSION"

usage() {
    cat <<USAGE
Usage: $0 <version>

Creates a GitHub release with firmware artifacts for both profiles.

Example:
  $0 1.0.0
USAGE
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

VERSION="$1"
TAG="v$VERSION"

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be semantic (X.Y.Z)"
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Error: Tag $TAG already exists"
    exit 1
fi

# Ensure clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: Working tree not clean. Commit or stash changes first."
    exit 1
fi

echo "Creating release $TAG..."

# Update VERSION file
echo "$VERSION" > "$VERSION_FILE"

# Update CHANGELOG
sed -i "1s/.*/# Changelog/" CHANGELOG.md
sed -i "2a\\## [$VERSION] - $(date +%Y-%m-%d)\\n\\n### Added\\n\\n### Changed\\n\\n### Fixed\\n\\n### Security\\n" CHANGELOG.md

# Commit version bump
git add VERSION CHANGELOG.md
git commit -m "chore: release v$VERSION" -s

# Create annotated tag
git tag -a "$TAG" -m "Release v$VERSION

Firmware for Jooan W3-U (T23N, SC2336P ×2, ETH, ATBM6132U)

Profiles:
- unique: single SC2336P sensor
- dual: dual SC2336P sensors (auto-detect)

Anti-brick features:
- U-Boot 2013.07 pinned (2026.07 bricks this board)
- Sysupgrade guard blocks bootloader flash
- Env CRC with auto-restore
- Hardware watchdog
- Recovery partition (GPIO button)
- Part-only sysupgrade deployment

Hardware validation:
- S00hw-detect: flash/RAM/MAC/sensor/PHY/motor inventory
- S10sensor-detect: I2C scan + driver load
- S15sensor-iq: IQ auto-select by ISP version
- S09motor-detect: WQ9001 SPI vs GPIO
- S99hw-selftest: first-boot HTTP report
- Kernel fragment: t23-hw-validation

See CHANGELOG.md for full details."

# Push commit and tag
git push origin main
git push origin "$TAG"

echo "Release $TAG created and pushed!"
echo "GitHub Actions will build firmware and create the release with artifacts."
echo "Check: https://github.com/xonel/jooan-w3u-thingino/releases/tag/$TAG"