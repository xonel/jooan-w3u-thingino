# Changelog

All notable changes to this firmware will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Hardware validation suite (flash/RAM/MAC/sensor/PHY/motor detection)
- Sensor IQ auto-selection based on ISP firmware version
- First-boot self-test with HTTP report server
- Motor driver auto-detection (WQ9001 SPI vs GPIO)
- Kernel config fragment for hardware validation
- Sensor auto-detection (S10sensor-detect + sensor.map)
- Dynamic raptor.conf generation from detected sensors
- Sysupgrade guard blocking bootloader flashes
- Env CRC verification with auto-restore from backup
- Hardware watchdog (Ingenic T23 WDT)
- Recovery partition with minimal shell
- U-Boot 2013.07 pin for T23N (prevents 2026.07 brick)
- Dual-sensor support via Ingenic double-ISP firmware
- Sensor chip-id 0x10 acceptance patch for SC2336P family

### Security
- Sysupgrade guard prevents accidental bootloader flash (issue #386)
- Env CRC with auto-restore from backup partition
- Hardware watchdog prevents freeze-induced bricks
- Recovery partition accessible via GPIO button hold

## [0.1.0] - 2026-09-19

### Added
- Initial Jooan W3-U T23N dual-sensor firmware
- Single-sensor (unique) and dual-sensor profiles
- SC2336P sensor chip-id 0x10 acceptance
- U-Boot 2013.07 pin for T23N (bootable)
- Multi-sensor auto-detection via I2C scan
- Dynamic raptor.conf generation
- Sensor diagnostics (sinfo + S99sensor-diag) in data overlay
- GitHub Actions CI with QEMU boot test

### Fixed
- U-Boot 2026.07 brick on T23N (pinned to 2013.07)

### Security
- Part-only sysupgrade deployment policy
- Environment CRC with backup auto-restore
