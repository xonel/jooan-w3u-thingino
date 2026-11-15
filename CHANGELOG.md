# Changelog

All notable changes to this project are documented in this file.

## [0.2.0] - 2026-11-15

### Added
- Rebased cleanly onto official upstream `themactep/thingino-firmware` (`master` Nov 2026) with `thingino-raptor-config` (`raptor.config`).
- Added **Dual CV2003** profile (`jooan_w3u_t23n_cv2003_dual_eth+atbm6132u`, `cv2003s0` @ `0x35` + `cv2003s1` @ `0x36`, SRGGB10 IQ fallback) alongside **Dual SC2336P** (`jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u`, `0x30` + `0x32`).
- Extended SC2336P patch to accept `0x9b3a` (SC2336P), `0xcb3a` (SC2336), and `0x10` (classic SC2336).
- Explicit `RAPTOR_SENSOR0_WIDTH/HEIGHT=1920x1080` and `RAPTOR_SENSOR1_WIDTH/HEIGHT=1920x1080` in `raptor.config` so `rvd` multi-sensor crop & sub-stream scaler initialize cleanly.
- Explicit `reset_gpio=18` (`sensor_1`), `reset_gpio=16` (`sensor_2`), and `mipi_switch_gpio=7`.
- Added `scripts/apply-to-thingino.sh` to apply patches & profiles onto any clean `themactep/thingino-firmware` checkout.
- Added ready-to-use **Frigate NVR + go2rtc** configuration (`frigate/config.example.yml`, `docs/frigate.md`) and CH341A unbrick/OTA switch guide (`docs/unbrick-and-flash.md`).
- Fixed GitHub Actions workflows (`build-validate.yml`, `release.yml`) to clone `themactep/thingino-firmware`, apply patches, build in `thingino-builder-image`, and validate SPL/uImage/SquashFS magics.

### Removed
- Removed broken custom `gen-raptor-conf` / `S10sensor-detect` overlay scripts and invalid Buildroot Kconfig symbols that conflicted with upstream Thingino & Raptor INI configuration.

## [0.1.0] - 2026-09-19

### Added
- Initial Jooan W3-U T23N dual-sensor SC2336P exploration, U-Boot 2013.07 pin, and chip-id `0x10` patch.
