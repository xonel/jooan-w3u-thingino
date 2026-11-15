# Deployment, Safe OTA Upgrades & Recovery

Voir également le guide pas-à-pas en français : [`docs/unbrick-and-flash.md`](unbrick-and-flash.md).

## 1. Initial Unbrick / Full SPI Flash (CH341A)

Use one of the complete **8 MiB (`8 388 608` bytes)** `.bin` images in `firmware/`:
- `firmware/thingino-jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u.bin` — Dual SC2336P / SC2336 (`0x30` + `0x32`)
- `firmware/thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin` — Dual CV2003 (`0x35` + `0x36`, June 2026+ hardware batches)

```bash
flashrom -p ch341a_spi -w firmware/thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin -V
```

## 2. Safe Network Updates & Variant Switching (`sysupgrade`)

Once Thingino is running on the camera (with U-Boot `2013.07` safely in `mtd0`), **never re-flash `mtd0` (bootloader)**. Always perform partial upgrades using `uImage` (magic `27051956`) and `rootfs.squashfs` (magic `68737173`) extracted via `scripts/extract-ota-parts.sh`:

```bash
./scripts/extract-ota-parts.sh firmware/thingino-<profile>.bin /tmp/ota-w3u
scp /tmp/ota-w3u/uImage /tmp/ota-w3u/rootfs.squashfs root@<CAMERA_IP>:/tmp/
ssh root@<CAMERA_IP> "sysupgrade /tmp/uImage && sysupgrade /tmp/rootfs.squashfs"
```

This lets you switch between `sc2336p_dual` and `cv2003_dual` (after checking `sinfo` over SSH) in 30 seconds without opening the camera.

## 3. Preserving Factory MAC Addresses

Restore your camera's factory MAC addresses once over SSH:
```bash
fw_setenv ethaddr XX:XX:XX:XX:XX:XX
fw_setenv wlan_mac XX:XX:XX:XX:XX:YY
```
Do not commit device-unique MAC addresses or factory dumps to Git.
