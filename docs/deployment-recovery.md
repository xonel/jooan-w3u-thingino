# Deployment & recovery

## Flashing policy

- **Deploy as kernel/rootfs "part" upgrades** via `sysupgrade`. The camera's
  `sysupgrade` dispatches on the leading 4 bytes of the uploaded file:
  - `27051956` → kernel partition only
  - `68737173` → rootfs partition only
- **Never** do a whole-disk ("bootloader" `06050403`) flash that replaces the
  bootloader or the env **unless** the goal is to restore the recovered golden
  dump (see below).
- Keep the **bricking risk** in mind: the new 2026.07 default U-Boot does not run
  on this board. See [`bootloader-2013-07.md`](bootloader-2013-07.md).

## Preserve factory identity

Any rewritten environment must keep the factory values from the original dump:

- `ethaddr` and `wlan_mac` (retrieve from the camera's original U-Boot env, not
  published here on purpose).

These are device-private and must not be committed to the repository.

## Recovery plan (bricked camera)

The board is currently bricked until the flash chip is replaced:

1. The SPI NOR (64 Mbit / 8 MiB, e.g. PY25Q64) is **dead**.
2. Recovery is done with an **SPI programmer** (`CH341A` + SOIC-8 clip) and needs
   **no CPU**: write the original 8 MiB dump
   (`flash-all-mtd7.bin`, sha256 `5126921b…aadf`) directly to the chip.
3. SD-card USBoot autoupdate is a dead end on this camera (the new U-Boot never
   runs far enough to read the SD).

Recovery assets are kept out of this repository (they belong to the physical
camera owner's backup, not to a public dev repo).

## Build

Builds run in a container from a fork of
`github.com/themactep/thingino-firmware` patched with:

1. the sensor fix — `patches/0001-sc2336p-…patch` in `package/all-patches/ingenic-sdk/`
2. the U-Boot pin — `patches/uboot-v2013-07.fragment` in
   `configs/fragments/uboot/v2013-07.fragment`
3. the camera profiles — `profiles/` defconfigs under `configs/cameras/`

```bash
WORKFLOW=1 CAMERA=jooan_w3u_t23n_sc2336p_<unique|dual>_eth_atbm6132u \
  make -f Makefile.container container-make MAKECMDGOALS="build_fast pack"
```

After building the dual profile, the U-Boot env must be regenerated (delete
`images/u-boot-env.bin` + `uenv.txt` and re-run `build_fast pack`) so the
2013.07 `bootcmd` (no `run autoupdate`) is baked into the image.

Artifacts land in
`output/master/<profile>-3.10.14-uclibc/images/`:
`thingino-<profile>.bin` (final), `u-boot-lzo-with-spl.bin`, `u-boot-env.bin`,
`uImage`, `rootfs.squashfs`, `data.jffs2`.