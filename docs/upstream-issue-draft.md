# Upstream GitHub Issue (`themactep/thingino-firmware#2022`)

- **Live Issue URL:** https://github.com/themactep/thingino-firmware/issues/2022
- **Related Issue:** https://github.com/themactep/thingino-firmware/issues/1642
- **Title:** `[RFC / Camera Support] Jooan W3-U (T23N, #111 / #1642): Dual-sensor Raptor profiles (SC2336P & CV2003), U-Boot 2013.07 pin & upstream findings`

---

## Context & Goal

This is a follow-up to **#1642** (*Jooan W3U Purchased June 2026 — Streamer crash, blank image*, with PCB photos) regarding the **Jooan W3-U** ([thingino.com/cameras/111](https://thingino.com/cameras/111), currently `jooan_w3u_t23n_sc2336p_eth+atbm6132u` with description *"8MB. Only one sensor is supported at a time"*).

Our goal is to help bring **full open-source dual-sensor support** (both lenses streaming concurrently via `ingenic-sdk` `CONFIG_MULTI_SENSOR=1` + Raptor `ch0`/`ch1` + `ch2`/`ch3`, without any closed OEM `*_double.ko` modules) to the Jooan W3-U so it works out of the box with NVRs like Frigate, and to share several upstream issues/questions we ran into while building and validating the profiles against current `master` (`e923f27`).

Before opening PRs (and while finishing SPI flash recovery/reassembly on the physical unit from #1642), we would really appreciate maintainer feedback (`@themactep` / `@gtxaspec`) on whether our design and fixes look sound and idiomatic for Thingino `master`.

---

## Hardware Summary (Jooan W3-U)

- **SoC / RAM / Flash**: Ingenic T23N (`xburst1`), 64 MiB RAM (`osmem=30M@0x0`, `rmem=34M@0x1e00000` for dual ISP), 8 MiB SPI NOR
- **Wired Ethernet**: 100M (`gpio.eth`: pin `64`, `toggle: true` — PR #1026)
- **Wi-Fi**: AltoBeam ATBM6132U USB (`gpio.wlan`: pin `6`, `toggle: true`)
- **SD Card**: MMC0 PB 4-bit (`gpio.mmc_cd`: `61` — PR #1034)
- **Dual-sensor wiring** (matches `jooan_w8u_t23n_sc2336_atbm6132u` topology + wired Ethernet):
  - `sensor_1` reset GPIO: `18`
  - `sensor_2` reset GPIO: `16`
  - MIPI switch GPIO: `7`
- **Peripherals**: PTZ motors (`gpio_pan: "53 52 54 51"`, `gpio_tilt: "51 54 52 53"`, `gpio_switch: 17`), speaker amp GPIO `63` (`active_low: true`), IR 850nm GPIO `59`, white LED GPIO `60`, IR-cut `"50 49"`, reset button GPIO `62`

### Two Sensor Revisions Across W3-U Batches

While investigating #1642 (`VIDIOC_REGISTER_SENSOR(sc2336p) error!` on a June 2026 W3-U unit), we found two sensor configurations relevant to W3-U hardware:
1. **Dual SC2336P / SC2336** (`sc2336ps0` @ `0x30` + `sc2336ps1` @ `0x32` on I2C0) — note that some SC2336-family sensors report `0xcb3a` (plain SC2336) or classic `0x10` high byte instead of `0x9b3a`.
2. **Dual CVSens CV2003** (`cv2003s0` @ `0x35` + `cv2003s1` @ `0x36` on I2C0, chip ID `0x2003`) — drivers `3.10.14/sensor-src/t23/cv2003s0.c` and `cv2003s1.c` already exist in `thingino/ingenic-sdk`!

---

## Prepared Profiles & Repositories

We rebased everything cleanly onto `themactep/thingino-firmware` (`master+e923f27`) using the new `thingino-raptor-config` (`raptor.config`) infrastructure:

- **Fork branch (`themactep/thingino-firmware` base)**: https://github.com/xonel/thingino-firmware/tree/jooan-w3u-dual
- **Standalone repo, patches, docs & prebuilt 8 MiB images (`v0.2.0`)**: https://github.com/xonel/jooan-w3u-thingino ([Release v0.2.0](https://github.com/xonel/jooan-w3u-thingino/releases/tag/v0.2.0))

Two dual-sensor profiles were built and inspected offline:
1. `jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u`
2. `jooan_w3u_t23n_cv2003_dual_eth+atbm6132u`

---

## Technical Findings & Questions for Maintainers

While building and auditing the generated rootfs / U-Boot / Raptor pipeline on `master`, we noticed 5 specific items we'd like your eyes on:

### 1. U-Boot `2026.07` SPL bricks this T23N board vs `2013.07` boots + `Makefile` override bug
- On the physical W3-U from #1642, images built with **U-Boot `2013.07`** (`u-boot-lzo-with-spl.bin`, header load `0x80370000`, `Thingino U-Boot for Ingenic T23N SPL 2013.07`) booted reliably (Ethernet, Wi-Fi, PTZ, WebUI all worked).
- Flashing a full image built from `master` with default **U-Boot `2026.07`** (`u-boot-with-tpl-lzma.bin`, header load `0x802a0000`, `U-Boot SPL 2026.10-rc1`) bricked the camera before console/SD/network init (verified via SPI dump).
- **Build system bug found when pinning `2013.07` in a camera defconfig**:
  In `Makefile` (~line 212):
  ```makefile
  THINGINO_UBOOT_VERSION_RAW := $(if $(CAMERA_CONFIG_REAL),$(strip $(shell grep -h '^BR2_THINGINO_UBOOT_VERSION_' $(EARLY_TOOLCHAIN_INPUT_FILES) 2>/dev/null | grep '=y$$' | head -1 | sed 's/.*UBOOT_VERSION_\(.*\)=y/\1/')))
  ```
  Because `EARLY_TOOLCHAIN_INPUT_FILES` orders `$(CONFIG_FRAGMENT_FILES)` (`core.fragment`, which sets `BR2_THINGINO_UBOOT_VERSION_2026_07=y`) **before** `$(CAMERA_CONFIG_REAL)`, `head -1` always picks `2026_07` even if a camera defconfig sets `BR2_THINGINO_UBOOT_VERSION_2013_07=y`. In addition, `configs/fragments/uboot/v2013-07.fragment` did not set `BR2_THINGINO_UBOOT_VERSION_2013_07=y` / `# BR2_THINGINO_UBOOT_VERSION_2026_07 is not set` when appended last.
  - **Question**: Should we submit a small PR changing `head -1` → `tail -1` in `Makefile` + adding the choice symbols to `v2013-07.fragment`? Also, is there a known reason `isvp_t23n_sfcnor` `u-boot-with-tpl-lzma.bin` (`2026.07`) fails on this T23N NOR board?

### 2. Multi-sensor `width` / `height` in `raptor.config` (`rvd_pipeline.c` crop & scaler gate)
- In `gtxaspec/raptor` (`rvd/rvd_pipeline.c` lines 784–804 & 974–987), `s0`/`s1` drivers do not populate `/proc/jz/sensor/sensor0/{width,height}` (`0x0`). `rvd` falls back to `[stream0] width/height` or `[sensor0] width/height`, and **only enables `fs->crop` (required on main streams in multi-sensor mode) and `fs->scaler` (for `640x360` sub-streams) if `sensor_w > 0 && sensor_h > 0`**.
- We noticed upstream `jooan_w8u_t23n_sc2336_atbm6132u/raptor.config` does not set `RAPTOR_SENSOR0_WIDTH` / `RAPTOR_SENSOR0_HEIGHT`, so we explicitly set `1920`×`1080` on `SENSOR0` and `SENSOR1` in our W3-U `raptor.config`:
  ```ini
  RAPTOR_SENSOR0_NAME="cv2003"       # or "sc2336p" (matches .name in s0 driver)
  RAPTOR_SENSOR0_I2C_ADDR="0x35"     # or "0x30"
  RAPTOR_SENSOR0_WIDTH="1920"
  RAPTOR_SENSOR0_HEIGHT="1080"
  RAPTOR_SENSOR0_FPS="15"
  RAPTOR_SENSOR1_NAME="cv2003s1"     # or "sc2336ps1"
  RAPTOR_SENSOR1_I2C_ADDR="0x36"     # or "0x32"
  RAPTOR_SENSOR1_WIDTH="1920"
  RAPTOR_SENSOR1_HEIGHT="1080"
  RAPTOR_SENSOR1_FPS="15"
  RAPTOR_STREAM0_FPS="15"
  RAPTOR_STREAM1_FPS="15"
  RAPTOR_S1S0_FPS="15"
  RAPTOR_S1S1_FPS="15"
  RAPTOR_RTSP_ENDPOINT_S1_MAIN="ch2"
  RAPTOR_RTSP_ENDPOINT_S1_SUB="ch3"
  RAPTOR_OSD_ISP_OSD_TRUE=y
  ```
  - **Question**: Does T23 dual-sensor Raptor work best with `BR2_ISP_DIRECT_MODE_0=y` (as in `jooan_w8u_t23n_sc2336_atbm6132u_defconfig`) and `BR2_THINGINO_RMEM_MB=34`, or should IVDC (`BR2_ISP_DIRECT_MODE_2=y` + `ivdc = true`) be enabled for 2×1080p@15fps + 2×360p@15fps?

### 3. `BR2_ISP_MIPI_SWITCH_GPIO` Kconfig/Makefile mismatch + `s1` `reset_gpio`
- In `Config.soc.in:523`, `BR2_ISP_MIPI_SWITCH_GPIO` is an `int` (`default 7`), whereas `thingino.mk:373` uses `$(call isp_param,ISP_MIPI_SWITCH_GPIO,mipi_switch_gpio)` which expects a `bool` (`=y`) + `_VALUE`, so `$(ISP_MIPI_SWITCH_GPIO)` currently expands to empty (`tx-isp-t23.ko` happens to default `mipi_switch_gpio` to `7` in `.data`, and we also passed `BR2_ISP_PARAMS="mipi_switch_gpio=7"`).
- Also, both `sc2336ps1.c` and `cv2003s1.c` default `reset_gpio = -1` (while `s0` defaults to `GPIO_PA(18)`), and `gpio.sensor_1` / `gpio.sensor_2` in `thingino.json` are not injected into `/etc/modules.d/30-sensor_{1,2}` by `ingenic-sdk.mk`, so we passed `BR2_SENSOR_1_PARAMS="reset_gpio=18"` and `BR2_SENSOR_2_PARAMS="reset_gpio=16"` explicitly. Is that the preferred pattern, or should `ingenic-sdk.mk` read `gpio.sensor_1` / `gpio.sensor_2` via `jct` like it does for `gpio.speaker` and `gpio.button_reset`?

### 4. Missing `sensor-iq/t23/cv2003.bin` in `thingino/ingenic-sdk`
- `thingino/ingenic-sdk` has `3.10.14/sensor-src/t23/cv2003s0.c` and `cv2003s1.c`, but no `sensor-iq/t23/cv2003.bin` (only `sensor-iq/t32/cv2003-PRJ007-day.bin`), which breaks `INSTALL_SENSOR_BIN` when building `cv2003s0`/`cv2003s1` on T23.
- As a temporary build fallback, we pointed missing T23 `cv2003.bin` to `gc2053.bin` (same `V4L2_MBUS_FMT_SRGGB10_1X10` 1080p RAW10 linear 2-lane MIPI format, matching how `sensor-iq/t23/os02g10.bin -> gc2053.bin` is set up). Does anyone have a proper `cv2003` T23 1.3.0 IQ tuning `.bin` we could add to `thingino/ingenic-sdk`?

### 5. SC2336P family chip-ID variants (`0x9b3a` / `0xcb3a` / `0x10`)
- We included a small patch (`0001-sc2336p-accept-classic-chip-id-0x10.patch`) allowing `sc2336p`, `sc2336ps0`, and `sc2336ps1` on T23 to accept `0xcb` (`0xcb3a`) and `0x10` in addition to `0x9b` (`0x9b3a`).

---

## Current Testing Status & Next Steps

- **Offline / QEMU**: Both 8 MiB `.bin` images build cleanly on `master+e923f27`; SPL `2013.07` header (`0x80370000`), `uenv` (`osmem=30M`, `rmem=34M`), `/etc/modules.d/*`, IQ symlinks, and generated `/etc/raptor.conf` have been verified. (If `qemu-dev` already models `cv2003` or if testing `jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u` with `-device image-sensor,model=sc2336p` + `-global ingenic-t31.mipi-switch=7` is recommended, we are happy to run that too!)
- **Hardware**: The W3-U board from #1642 is currently disassembled awaiting SPI flash recovery (`CH341A`) after the earlier `2026.07` U-Boot brick. As soon as it is flashed and reassembled, we will post `sinfo`, `dmesg`, `thingino-diag -u`, and live RTSP `ch0`–`ch3` results here, and then submit clean PRs so [camera #111](https://thingino.com/cameras/111) can support both sensors.

Any guidance, corrections, or suggestions from the team would be greatly appreciated!
