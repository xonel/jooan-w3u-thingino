# Validation (offline)

Both firmwares were validated **offline** (images inspected without hardware).
The camera cannot be used for on-device testing until its flash chip is replaced.

## Checks performed

On the final 8 MiB `.bin` (both profiles):

| Offset   | Expected | Meaning | Result |
|----------|----------|---------|--------|
| `0x0`    | `06050403`   | U-Boot magic | ✅ both |
| `0x50000` | env         | decoded with `strings` | ✅ both |
| `0x60000` | `ffffffff`  | backup env (unprogrammed) | ✅ both |
| `0x70000` | `27051956`  | uImage magic (kernel) | ✅ both |
| `0x200000`| `68737173`  | `hsqs` squashfs magic (rootfs) | ✅ both |
| `0x710000`| `85190320`  | jffs2 magic (data/overlay) | ✅ both |

On the U-Boot tree and env:

- Built tree reports `U_BOOT_VERSION "Thingino U-Boot for Ingenic 2013.07"`
  (`PLAIN_VERSION "2013.07"`) — i.e. the legacy bootloader, not the 2026.07 that
  bricks this board.
- `bootcmd` has **no** `run autoupdate; run loaduenv;` prefix (2013.07 flow) and
  uses `sf probe` with the correct 8-partition `mtdparts`.
- `mtdparts=jz_sfc:320k(boot),64k(env),64k(backup),1600k(kernel),5184k(rootfs),960k(data),8192k@0(all)`

## Environment (per profile)

| Variable | Unique | Dual |
|----------|--------|------|
| `osmem`  | `41M@0x0`             | `30M@0x0`            |
| `rmem`   | `23M@0x2900000`       | `34M@0x1e00000`      |
| sensor modules | `sensor_sc2336p_t23.ko` | `sensor_sc2336ps0_t23.ko` + `sensor_sc2336ps1_t23.ko` |
| sensor blob | `sc2336p-t23.bin`   | — |

## Rootfs / overlay

- Kernel sensor modules for the profile are present inside `rootfs.squashfs`
  (`unsquashfs`).
- The per-camera overlay (`usr/sbin/sinfo` + `etc/init.d/S99sensor-diag`) is
  packed into the `data` partition (overlayfs upperdir at runtime), not into the
  squashfs.
- `thingino-sensor-info` binary is available at `/usr/sbin/sinfo`; the custom
  cross-compiled `sinfo` shadows it at runtime via the data overlay.

## Artifacts / hashes

`firmware/SHA256SUMS.txt` + Buildroot reports in `firmware/*.md` (exact partition
sizes, build commit `master+6e8a0f6`, duration, image names).

## Not yet validated on hardware

- Both lenses actually probing (`sinfo`/dmesg on the camera)
- RTSP ch0/ch1 + ch2/ch3 streaming at 15 fps
- WiFi (ATBM6132U) and wired Ethernet bring-up
- Motors / button / SD