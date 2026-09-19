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
| Offline validation of both images | ✅ |
| On-hardware validation | ⏳ waiting — camera flash chip dead, waiting for a replacement (SPI NOR 8 MiB) |

## Hardware

- SoC: **Ingenic T23N** (Pike T23 family), 64 Mio RAM
- Sensors: **2× SmartSight SC2336P** — sensor0 @ `0x30`, sensor1 @ `0x32`
- Interface: **100 Mbit/s Ethernet** (wired)
- Wi-Fi: **ATBM6132U** (setup/companion)
- Flash: 8 MiB (64 Mbit) SPI NOR, 8 partitions (`mtdparts`)
- Extra: motors, button, audio, SD card

## Firmware artifacts

See [`firmware/`](firmware/) — full 8 MiB images plus build reports and checksums:

| Profile | Image | SHA-256 |
|---------|-------|---------|
| Single sensor (`sc2336p`) | `thingino-jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u.bin` | `d20e89c8…` |
| Dual sensor (`sc2336ps0` + `sc2336ps1`) | `thingino-jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u.bin` | `f2ab69e5…` |

Partition layout: `boot`(320K) + `env`(64K) + `backup`(64K) + `kernel`(1600K) +
`rootfs`(squashfs) + `data`(960K, overlayfs upperdir).

## Key points

- **Dual sensor without closed-source drivers**: the two lenses run through the
  Ingenic T23 **double-ISP** firmware, selected by `CONFIG_MULTI_SENSOR` when the
  SDK links `libt23-firmware.a` from `sdk/t23/1.3.0-double`. Sensors are mapped as
  `sc2336ps0` / `sc2336ps1` with a 30M/34M `osmem`/`rmem` split.
  See [`docs/dual-sensor.md`](docs/dual-sensor.md).
- **U-Boot must stay on 2013.07**: the new 2026.07 default bootloader does **not
  boot** this board (proven by a bricked camera). Each profile pins the legacy
  tree via the `v2013-07` fragment. See [`docs/bootloader-2013-07.md`](docs/bootloader-2013-07.md).
- **Deployment policy**: deploy as kernel/rootfs **part** upgrades via `sysupgrade`
  (magics `27051956` / `68737173`). Never write the whole `bootloader` partition
  (`06050403`) unless flashing the recovered golden dump. See
  [`docs/deployment-recovery.md`](docs/deployment-recovery.md).

## Repository layout

```
README.md
docs/                    architecture, bootloader policy, validation, deployment
patches/                 things to apply on the Thingino fork (sensor fix, U-Boot fragment)
profiles/                per-camera defconfig + thingino.json per profile
firmware/                built 8 MiB images + reports + SHA256SUMS.txt
```

## Build

Builds run in a container (the host cannot run the toolchain directly).

```bash
WORKFLOW=1 CAMERA=<profile> \
  make -f Makefile.container container-make MAKECMDGOALS="build_fast pack"
```

The exact images in [`firmware/`](firmware/) were produced from the Thingino fork
commit `master+6e8a0f6` (see the `.md` reports in `firmware/` for full details).

- [Container build notes](docs/deployment-recovery.md#build)
- [Patch application](docs/dual-sensor.md#patch-and-profiles)

## Documentation

- [`docs/dual-sensor.md`](docs/dual-sensor.md) — how the double ISP works, memory split, sensor map, raptor setup
- [`docs/bootloader-2013-07.md`](docs/bootloader-2013-07.md) — why 2013.07, how the fork pins it, the 2026.07 brick history
- [`docs/validation.md`](docs/validation.md) — offline validation performed on both images
- [`docs/deployment-recovery.md`](docs/deployment-recovery.md) — flashing policy, sysupgrade, SPI recovery, MAC preservation

## Roadmap

1. Replace the dead flash chip (CH341A + SOIC-8 clip to restore the golden dump).
2. Flash the dual image head-first, validate both lenses (RTSP ch0/ch1 + ch2/ch3, 15 fps).
3. Submit the profiles + sensor patch + U-Boot pin as **pull requests to
   `themactep/thingino-firmware`**.