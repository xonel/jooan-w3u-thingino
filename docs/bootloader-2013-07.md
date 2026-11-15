# U-Boot Version Policy (`2013.07` vs `2026.07`)

## Summary

The Jooan W3-U (Ingenic T23N, 8 MiB SPI NOR) is built here with **U-Boot `2013.07`** (`u-boot-lzo-with-spl.bin`, load header `0x80370000`, banner `Thingino U-Boot for Ingenic T23N SPL 2013.07`).

One full flash of an image carrying the default `2026.07` bootloader (`u-boot-with-tpl-lzma.bin`, load header `0x802a0000`, banner `U-Boot SPL 2026.10-rc1`) was followed by a camera that no longer started. This is a single observation: the flash chip was later found faulty, so it does not prove that `2026.07` cannot boot this board. `2013.07` is pinned because it is the only bootloader seen booting this camera (#1642).

## Clean Upstream Fix (`patches/thingino-firmware/0001-uboot-allow-camera-defconfig-to-select-2013-07.patch`)

In official `themactep/thingino-firmware`:
1. `configs/fragments/core.fragment` sets `BR2_THINGINO_UBOOT_VERSION_2026_07=y`.
2. `Makefile` previously resolved `THINGINO_UBOOT_VERSION_RAW` with `head -1` across `$(CONFIG_FRAGMENT_FILES) $(CAMERA_CONFIG_REAL)`, so `core.fragment` always won even when a camera defconfig specified `BR2_THINGINO_UBOOT_VERSION_2013_07=y`.
3. Changing `head -1` to `tail -1` in `Makefile` and adding the choice symbols to `configs/fragments/uboot/v2013-07.fragment` allows any camera defconfig to cleanly set `BR2_THINGINO_UBOOT_VERSION_2013_07=y` while keeping standard `# FRAG: soc-xburst1 core` fragment ordering and passing `scripts/sort_defconfig.py` / `make lint`.
