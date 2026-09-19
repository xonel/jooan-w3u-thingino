# U-Boot version policy (2013.07 that boots vs 2026.07 that bricks)

## TL;DR

**This board only boots with U-Boot 2013.07.** The modern 2026.07 default
bootloader produced by the Thingino fork does **not** boot on the Jooan W3-U —
its SPL/`sf probe` never works.

This was proven the expensive way: early in the project a whole-disk upgrade with
a 2026.07-era image (`u-boot-with-tpl-lzma.bin`, banner `U-Boot SPL 2026.10-rc1`)
bricked the camera into silence (no network, no SD autoupdate, nothing). The
camera only recovered thanks to a full 8 MiB dump (`flash-all-mtd7.bin`) of the
original vendor firmware taken before the experiment.

## How the fork selects the U-Boot version

The Thingino fork pins the U-Boot version with a Kconfig choice
(`package/thingino-uboot/Config.in`):

```
BR2_THINGINO_UBOOT_VERSION_2026_07    # default
BR2_THINGINO_UBOOT_VERSION_2013_07
BR2_THINGINO_UBOOT_VERSION_CUSTOM_FORK
```

The selection propagates through several layers:

1. `Makefile:209` greps the first `BR2_THINGINO_UBOOT_VERSION_*=y` in the
   effective config stack (`fragments → camera defconfig → user fragments`) and
   builds a tag (`2013-07`, `2026-07`, …).
2. That tag selects the config fragment `configs/fragments/uboot/v<tag>.fragment`
   which is appended to the config stack and drives Buildroot:
   - `v2013-07.fragment` → legacy build system, custom version `2013.07`,
     output `u-boot-lzo-with-spl.bin`
   - `v2026-07.fragment` → `BR2_TARGET_UBOOT_LATEST_VERSION` → version `2026.07`,
     output `u-boot-with-spl-lzma.bin`
3. It also drives the final image rules (`UBOOT_BIN_NAME`, whether the U-Boot env
   prepends `run autoupdate; run loaduenv;` to `bootcmd`, etc.).

## The pinned-build trap

`configs/fragments/core.fragment` sets `BR2_THINGINO_UBOOT_VERSION_2026_07=y`.
Because the grep is order-sensitive (`head -1` over the config stack), a camera
defconfig that only mentions `uboot/v2013-07` in its `# FRAG:` line *does not*
switch the selected version — `core.fragment` (earlier in the stack) wins, the
`v2026-07.fragment` is auto-appended and Buildroot builds 2026.07. The result
bricks the board.

## The fix used in this project

1. Add the choice symbols **into** the `v2013-07.fragment` itself:

   ```kconfig
   BR2_THINGINO_UBOOT_VERSION_2013_07=y
   # BR2_THINGINO_UBOOT_VERSION_2026_07 is not set
   ```

2. Reference that fragment **first** in each profile's `# FRAG:` line so it
   appears before `core.fragment` in the version-resolution stack:

   ```text
   # FRAG: uboot/v2013-07 soc-xburst1 core
   ```

After `distclean` + `defconfig`, the generated Buildroot `.config` must show:

```
BR2_TARGET_UBOOT_VERSION="2013.07"
BR2_TARGET_UBOOT_BUILD_SYSTEM_LEGACY=y
BR2_TARGET_UBOOT_BOARDNAME="isvp_t23n_sfcnor"
BR2_TARGET_UBOOT_FORMAT_CUSTOM_NAME="u-boot-lzo-with-spl.bin"
BR2_THINGINO_UBOOT_VERSION_2013_07=y
```

And the built tree reports: `U_BOOT_VERSION "Thingino U-Boot for Ingenic 2013.07"`.

## Verification

- `firmware/*.md` reports include the exact partition sizes used to rebuild
  U-Boot (`U_BOOT 320K @0x0`, env/backup/kernel/rootfs/data layout).
- `docs/validation.md` lists the boot-area checks performed on both images.