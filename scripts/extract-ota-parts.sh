#!/usr/bin/env bash
# extract-ota-parts.sh — Extract exact uImage + rootfs.squashfs from an 8 MiB Thingino .bin
# for safe partial network sysupgrade (never touches mtd0 U-Boot!)
set -euo pipefail

BIN="${1:-}"
OUT_DIR="${2:-./ota-out}"

if [ -z "$BIN" ] || [ ! -f "$BIN" ]; then
  echo "Usage: $0 <firmware/thingino-*.bin> [output-dir]" >&2
  exit 1
fi

python3 - "$BIN" "$OUT_DIR" << 'PY'
import os, struct, sys

bin_path, out_dir = sys.argv[1], sys.argv[2]
data = open(bin_path, "rb").read()
assert len(data) == 8388608, f"Expected 8388608 bytes, got {len(data)}"

# uImage @ 0x70000 (big-endian magic 0x27051956, size at +12, 64B header)
k_off = 0x70000
magic, _, _, k_size = struct.unpack(">IIII", data[k_off:k_off+16])
assert magic == 0x27051956, f"Invalid uImage magic at 0x70000: {hex(magic)}"
uimage = data[k_off : k_off + 64 + k_size]

# SquashFS @ 0x200000 (little-endian magic b'hsqs', bytes_used uint64 at +40, 4K padded)
r_off = 0x200000
assert data[r_off:r_off+4] == b"hsqs", "Invalid SquashFS magic at 0x200000"
bytes_used = struct.unpack("<Q", data[r_off+40:r_off+48])[0]
r_padded = (bytes_used + 4095) & ~4095
squashfs = data[r_off : r_off + r_padded]

os.makedirs(out_dir, exist_ok=True)
open(os.path.join(out_dir, "uImage"), "wb").write(uimage)
open(os.path.join(out_dir, "rootfs.squashfs"), "wb").write(squashfs)
print(f"Extracted to {out_dir}:")
print(f"  uImage          ({len(uimage)} bytes)")
print(f"  rootfs.squashfs ({len(squashfs)} bytes)")
PY
