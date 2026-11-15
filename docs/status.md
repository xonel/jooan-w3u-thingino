# Status: verified, assumed, unknown

Last updated 2026-11-15. Nothing here has run on a real W3-U yet.

## Verified

| What | How |
|------|-----|
| Both profiles build on `themactep/thingino-firmware` `master+e923f27` | Built in the official builder container |
| Images are 8 MiB with U-Boot 2013.07 SPL, uImage at `0x70000`, squashfs at `0x200000` | Offline inspection (`make validate`) |
| The dual SC2336P image boots under the Ingenic QEMU fork (`ingenic-0.7.17`, machine `ingenic-t23`) with two emulated `sc2336p` sensors at `0x30`/`0x32` and `mipi-switch=7` | `scripts/qemu-dev`, output in [`qemu-sc2336p-dual.txt`](qemu-sc2336p-dual.txt) |
| In that emulation: both sensor drivers probe, `rvd` reports `multi-sensor mode: 2 sensors` and `pipeline ready: 8 streams`, and the `main`, `sub`, `s1_main`, `s1_sub` rings all deliver encoded frames | Same run |
| `Makefile` `head -1` makes `core.fragment` override a camera's U-Boot version choice | Read in the source, fixed by patch 0001 and confirmed by the resulting `.config` |

## Assumed, not confirmed on hardware

| Assumption | Source | Why it may be wrong |
|------------|--------|---------------------|
| Second sensor reset on GPIO 16, MIPI switch on GPIO 7 | Copied from the W8-U profile | The only W3-U hint (old `gpio_default`) mentions 18 and 17, not 16 or 7. QEMU was told the switch is on 7, so it cannot confirm this |
| The W3-U carries two SC2336P at `0x30`/`0x32` | Camera listing and W8-U analogy | #1642 shows `VIDIOC_REGISTER_SENSOR(sc2336p) error` on the tested unit |
| Chip id high byte `0x10` | One reading from an earlier debugging session | Could be an invalid I2C read |
| A CV2003 variant of the W3-U exists | None beyond the presence of `cv2003s0/s1` T23 drivers | Pure hypothesis |
| U-Boot 2026.07 cannot boot this board | One failed flash on a chip later found faulty | Correlation only |
| 30 MiB for Linux is enough | W8-U uses the same split | QEMU showed under 1 MiB free with everything enabled |

## Known placeholders

- The CV2003 profile ships `gc2053.bin` as its ISP tuning file. Even if the sensors start, colours and exposure will be wrong. It has not been run in QEMU.
- `width`/`height` are set explicitly on both sensors in `raptor.config`. In QEMU the registry reported 1920x1080 by itself, so this may be unnecessary.

## Next steps

1. Recover the camera with a single-sensor image and record `sinfo`, `dmesg`, an I2C scan and `thingino-diag -u`.
2. Confirm sensor model, addresses and GPIOs, then correct the profiles.
3. Only then flash a dual image and test `ch0` to `ch3`.
