#!/bin/bash
# version.sh — Semantic version management for firmware releases

set -e

VERSION_FILE="VERSION"
CHANGELOG="CHANGELOG.md"

usage() {
    cat <<USAGE
Usage: $0 {major|minor|patch|show|next}

Commands:
  show          Show current version
  next          Show next versions (major.minor.patch)
  major         Bump major version (X.0.0)
  minor         Bump minor version (X.Y.0)
  patch         Bump patch version (X.Y.Z)

Examples:
  $0 show
  $0 next
  $0 patch
USAGE
}

read_version() {
    cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0"
}

write_version() {
    echo "$1" > "$VERSION_FILE"
}

bump_version() {
    local current=$(read_version)
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current"
    
    case "$1" in
        major) major=$((major + 1)); minor=0; patch=0 ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        patch) patch=$((patch + 1)) ;;
        *) echo "Invalid bump type: $1"; exit 1 ;;
    esac
    
    local new="$major.$minor.$patch"
    write_version "$new"
    echo "$new"
}

show_next() {
    local current=$(read_version)
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current"
    echo "Current: $current"
    echo "Next major: $((major + 1)).0.0"
    echo "Next minor: $major.$((minor + 1)).0"
    echo "Next patch: $major.$minor.$((patch + 1))"
}

cmd="${1:-show}"
case "$cmd" in
    show) read_version ;;
    next) show_next ;;
    major|minor|patch) 
        new=$(bump_version "$cmd")
        echo "Bumped to $new"
        # Update CHANGELOG header
        sed -i "1s/.*/# Changelog/" "$CHANGELOG"
        sed -i "2a\\## [$new] - $(date +%Y-%m-%d)\\n\\n### Added\\n\\n### Changed\\n\\n### Fixed\\n\\n### Security\\n" "$CHANGELOG"
        git add "$VERSION_FILE" "$CHANGELOG"
        git commit -m "chore: release v$new" -s
        git tag -a "v$new" -m "Release v$new"
        echo "Created tag v$new"
        ;;
    *) usage; exit 1 ;;
esac
