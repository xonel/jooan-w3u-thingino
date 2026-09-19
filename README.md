# Jooan W3-U — Dual-Sensor Thingino Firmware

Custom [Thingino](https://github.com/themactep/thingino-firmware) firmware for the
**Jooan W3-U** IP camera, built entirely from open-source components so that
**both SC2336P lenses work** — no OEM `tx_isp_t23_double` or
`sensor_*_t23_double.ko` closed-source drivers.

> This repository tracks the development of these firmwares (profiles, patches,
> build documentation and validated artifacts). Once validated on hardware, the
> changes are meant to be submitted upstream to the Thingino project as pull
> requests for the whole community.

## Status

| Step | State |
|------|-------|
| Profiles (unique / dual) | ✅ committed & built |
| U-Boot pinned to bootable 2013.07 | ✅ |
| Sensor fix (chip-id `0x10`) | ✅ |
| `sinfo` + boot diagnostics embedded | ✅ |
| **Anti-brick hardening** (sysupgrade guard, env CRC, watchdog) | ✅ implemented |
| **Multi-sensor auto-detection** (I2C scan + dynamic raptor.conf) | ✅ implemented |
| **Recovery partition + hardware watchdog** | ✅ implemented |
| **CI: QEMU boot test + magic validation** | ✅ GitHub Actions |
| Offline validation of both images | ✅ |
| On-hardware validation | ⏳ waiting — camera flash chip dead, waiting for replacement (SPI NOR 8 MiB) |

## Hardware

- SoC: **Ingenic T23N** (Pike T23 family), 64 Mio RAM
- Sensors: **2× SmartSight SC2336P** — sensor0 @ `0x30`, sensor1 @ `0x32`
- Interface: **100 Mbit/s Ethernet** (wired)
- Wi-Fi: **ATBM6132U** (setup/companion)
- Flash: 8 MiB (64 Mbit) SPI NOR, 8 partitions (`mtdparts`)
- Extra: motors, button, audio, SD card

## Firmware artifacts

See [`firmware/`](firmware/) — full 8 MiB images plus build reports and checksums:

| Profile | Image | SHA-256 | osmem / rmem |
|---------|-------|---------|--------------|
| Single sensor (`sc2336p`) | `thingino-jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u.bin` | `d20e89c8…` | 38M / 26M |
| Dual sensor (`sc2336ps0` + `sc2336ps1`) | `thingino-jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u.bin` | `f2ab69e5…` | 28M / 36M |

**Optimized partition layout** (8 MiB total):
- `boot` 320K (U-Boot 2013.07 `u-boot-lzo-with-spl.bin`)
- `env` 64K + `backup` 64K (CRC-protected, auto-restore)
- `kernel` 1500K (LZ4 compressed)
- `rootfs` ~4.9M (squashfs, minimal busybox)
- `recovery` 512K (minimal kernel + recovery-shell)
- `data` 512K (overlayfs upperdir, contains `sinfo` + `S99sensor-diag`)

## Key features

### 🔒 Anti-brick hardening
- **Sysupgrade guard** (`S99sysupgrade-guard`): refuses any image with U-Boot magic (`06050403`) unless `FORCE_BOOTLOADER=1` + interactive confirmation — prevents the `sysupgrade -b -p` brick vector (issue #386).
- **Env CRC + auto-restore** (`S01env-crc`): CRC32 of env partition checked at boot; auto-restores from backup partition if corrupted; minimal default fallback if both dead.
- **Hardware watchdog** (`S05watchdog`): Ingenic T23 WDT kicked every 30s; clean reboot on userspace hang.
- **Recovery partition** (512K): minimal kernel + `recovery-shell` (flashcp, fw_setenv, sf tools) triggered by GPIO button hold (10s) at boot via `bootcmd_recovery`.

### 🔍 Multi-sensor auto-detection
- **`S10sensor-detect`**: scans I2C buses 0/1 at addresses 0x30/0x32/0x36/0x40/0x37 at boot, reads chip ID, matches against `sensor.map` + built-in table, loads correct kernel modules (`sc2336p`, `gc2053`, `gc4653`, `imx307`, …).
- **`sensor.map`**: per-device override file for non-standard sensors.
- **`gen-raptor-conf`**: generates `raptor.conf` dynamically from detected sensors (RTSP ch0/ch1 for sensor0, ch2/ch3 for sensor1, fps, etc.).
- **Single firmware image works with SC2336P, GC2053, GC4653, IMX307, etc.** — no rebuild needed for sensor swap.

### 🛡️ Safe deployment policy
- **Sysupgrade guard** blocks accidental bootloader flashes.
- **Part-only upgrades** via `sysupgrade` (kernel magic `27051956`, rootfs magic `68737173`).
- **Env CRC** preserves `ethaddr`/`wlan_mac` across flashes.
- **RUBICON timestamp** (2026-01-13) enforced by sysupgrade for partial upgrades.

## Repository layout

```
README.md
.github/workflows/       CI: QEMU boot test + magic verification
docs/                    architecture, bootloader policy, validation, deployment
overlay/                 rootfs overlay (init.d, usr/sbin, etc/)
patches/                 sensor fix, U-Boot fragments (v2013-07 pin, recovery)
profiles/                per-camera defconfig + thingino.json per profile
firmware/                built 8 MiB images + reports + SHA256SUMS.txt
```

## Build

Builds run in a container (the host cannot run the toolchain directly).

```bash
WORKFLOW=1 CAMERA=<profile> \
  make -f Makefile.container container-make MAKECMDGOALS="build_fast pack"
```

Profiles:
- `jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u` (single sensor)
- `jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u` (dual sensor, auto-detect)

The exact images in [`firmware/`](firmware/) were produced from the Thingino fork
commit `master+6e8a0f6` (see the `.md` reports in `firmware/` for full details).

## CI / Testing

GitHub Actions workflow (`.github/workflows/qemu-test.yml`) runs on every push:
1. Builds both profiles in container (`build_fast pack`)
2. Verifies all 4 magic numbers in each `.bin` (U-Boot, kernel, rootfs, data)
3. QEMU smoke boot (MIPS, 64M RAM, v4l2loopback for sensor simulation)
4. Validates `SHA256SUMS.txt`
5. Uploads artifacts for download

## Documentation

- [`docs/dual-sensor.md`](docs/dual-sensor.md) — double ISP, memory split, sensor map, raptor setup
- [`docs/bootloader-2013-07.md`](docs/bootloader-2013-07.md) — why 2013.07, fork pin mechanism, 2026.07 brick history
- [`docs/validation.md`](docs/validation.md) — offline validation performed on both images
- [`docs/deployment-recovery.md`](docs/deployment-recovery.md) — flashing policy, sysupgrade, SPI recovery, MAC preservation

## Roadmap

1. Replace the dead flash chip (CH341A + SOIC-8 clip to restore `flash-all-mtd7.bin`).
2. Flash the dual image, validate both lenses (RTSP ch0–ch3, 15 fps).
3. Test sensor swap (GC2053, IMX307) via `sensor.map` without rebuild.
4. Submit profiles + sensor patch + U-Boot pin + anti-brick patches as **PRs to
   `themactep/thingino-firmware`**.

## Upstream contribution plan

| PR | Scope | Thingino issue ref |
|----|-------|-------------------|
| 1 | `ingenic-sdk: accept classic SC2336P chip-id 0x10` | #966, #1128 |
| 2 | `uboot: pin 2013.07 for Ingenic T23N boards` | #386, wiki |
| 3 | `cameras: add Jooan W3-U T23N profiles (unique + dual)` | — |
| 4 | `sysupgrade: guard bootloader flash (-b -p)` | #386 |
| 5 | `init: env CRC + watchdog + recovery partition` | wiki unbricking |