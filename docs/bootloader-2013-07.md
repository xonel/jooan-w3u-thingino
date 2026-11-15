# U-Boot Version Policy (`2013.07` vs `2026.07`)

## Summary

The Jooan W3-U (Ingenic T23N, 8 MiB SPI NOR) **must use U-Boot `2013.07`** (`u-boot-lzo-with-spl.bin`, load header `0x80370000`, banner `Thingino U-Boot for Ingenic T23N SPL 2013.07`).

Flashing Thingino's default mainline-based `2026.07` (`u-boot-with-tpl-lzma.bin`, load header `0x802a0000`, banner `U-Boot SPL 2026.10-rc1`) **bricks the Jooan W3-U** at SPL boot before serial/MMC/network initialization, requiring external SPI recovery (`CH341A` + SOIC-8 clip).

## Clean Upstream Fix (`patches/thingino-firmware/0001-uboot-allow-camera-defconfig-to-select-2013-07.patch`)

In official `themactep/thingino-firmware`:
1. `configs/fragments/core.fragment` sets `BR2_THINGINO_UBOOT_VERSION_2026_07=y`.
2. `Makefile` previously resolved `THINGINO_UBOOT_VERSION_RAW` with `head -1` across `$(CONFIG_FRAGMENT_FILES) $(CAMERA_CONFIG_REAL)`, so `core.fragment` always won even when a camera defconfig specified `BR2_THINGINO_UBOOT_VERSION_2013_07=y`.
3. Changing `head -1` to `tail -1` in `Makefile` and adding the choice symbols to `configs/fragments/uboot/v2013-07.fragment` allows any camera defconfig to cleanly set `BR2_THINGINO_UBOOT_VERSION_2013_07=y` while keeping standard `# FRAG: soc-xburst1 core` fragment ordering and passing `scripts/sort_defconfig.py` / `make lint`.
