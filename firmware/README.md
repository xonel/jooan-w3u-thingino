# Firmware Artifacts — Jooan W3-U Dual-Sensor (T23N, 8 MiB)

> Experimental and untested on hardware. The `.bin` files are GitHub Release assets; this directory keeps only the partition reports and checksums.

Built from official [`themactep/thingino-firmware`](https://github.com/themactep/thingino-firmware) (`master+e923f27`, 2026-11-15) with U-Boot `2013.07` (`0x80370000`) and Raptor Streaming System (`ch0`/`ch1` + `ch2`/`ch3` @ 15 fps).

| Hardware Variant | Image (`8 388 608` B / 8 MiB) | SHA-256 |
|------------------|-------------------------------|---------|
| **Dual SC2336P / SC2336** (`0x30` + `0x32`, IDs `0x9b3a`/`0xcb3a`/`0x10`) | `thingino-jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u.bin` | `d2edff20e2ebaa0d663b575294186bc856fe9fd0a9108ecc53f6c7da4683d77d` |
| **Dual CV2003** (`0x35` + `0x36`, ID `0x2003`, speculative, placeholder IQ) | `thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin` | `127478ae171b330e649d973544b5fb8a8416dbba3772759c9aa779b86972b422` |

Verify checksums:
```bash
sha256sum -c SHA256SUMS.txt
```

Extract partial OTA parts (`uImage` + `rootfs.squashfs`) for safe network switching (`sysupgrade`) without touching `mtd0` (U-Boot):
```bash
../scripts/extract-ota-parts.sh thingino-jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u.bin /tmp/ota-sc2336p
../scripts/extract-ota-parts.sh thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin /tmp/ota-cv2003
```
