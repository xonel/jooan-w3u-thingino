#!/usr/bin/env bash
# apply-to-thingino.sh — Apply Jooan W3-U dual-sensor patches & profiles
# onto an official checkout of https://github.com/themactep/thingino-firmware
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
THINGINO_DIR="${1:-}"

if [ -z "$THINGINO_DIR" ] || [ ! -f "$THINGINO_DIR/thingino.mk" ]; then
  echo "Usage: $0 /path/to/thingino-firmware" >&2
  exit 1
fi

echo "==> Applying upstream patches to $THINGINO_DIR"
for p in "$REPO_ROOT"/patches/thingino-firmware/*.patch; do
  [ -f "$p" ] || continue
  pname="$(basename "$p")"
  if patch -d "$THINGINO_DIR" -p1 --forward --dry-run < "$p" >/dev/null 2>&1; then
    patch -d "$THINGINO_DIR" -p1 --forward < "$p"
    echo "  [applied] $pname"
  elif patch -d "$THINGINO_DIR" -p1 --reverse --dry-run < "$p" >/dev/null 2>&1; then
    echo "  [already applied] $pname"
  else
    echo "ERROR: patch $pname does not apply cleanly to $THINGINO_DIR" >&2
    exit 1
  fi
done

echo "==> Installing ingenic-sdk patches"
mkdir -p "$THINGINO_DIR/package/all-patches/ingenic-sdk"
cp -f "$REPO_ROOT"/patches/ingenic-sdk/*.patch "$THINGINO_DIR/package/all-patches/ingenic-sdk/"

echo "==> Installing Jooan W3-U camera profiles"
for cam_dir in "$REPO_ROOT"/configs/cameras/*; do
  [ -d "$cam_dir" ] || continue
  cam_name="$(basename "$cam_dir")"
  rm -rf "$THINGINO_DIR/configs/cameras/$cam_name"
  cp -a "$cam_dir" "$THINGINO_DIR/configs/cameras/$cam_name"
  if [ -f "$THINGINO_DIR/scripts/sort_defconfig.py" ]; then
    python3 "$THINGINO_DIR/scripts/sort_defconfig.py" \
      "$THINGINO_DIR/configs/cameras/$cam_name/${cam_name}_defconfig"
  fi
  echo "  [installed] $cam_name"
done

echo "==> Done. Ready to build with:"
echo "    CAMERA=jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u"
echo "    CAMERA=jooan_w3u_t23n_cv2003_dual_eth+atbm6132u"
