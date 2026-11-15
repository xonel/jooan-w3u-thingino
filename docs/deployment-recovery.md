# Deployment, Safe OTA Upgrades & Recovery

Voir également le guide pas-à-pas en français : [`docs/unbrick-and-flash.md`](unbrick-and-flash.md).

## 1. Initial Unbrick / Full SPI Flash (CH341A)

Use one of the complete **8 MiB (`8 388 608` bytes)** `.bin` images from the GitHub Release:
- `firmware/thingino-jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u.bin` — Dual SC2336P / SC2336 (`0x30` + `0x32`)
- `firmware/thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin` — Dual CV2003 (`0x35` + `0x36`, speculative, placeholder IQ)

```bash
flashrom -p ch341a_spi -w firmware/thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin -V
```

## 2. Network updates

`sysupgrade <file>` detects kernel (`27051956`), rootfs (`68737173`) or full images by magic and reboots after flashing. Switching between profiles over the network is untested; prefer the SPI programmer while the camera is open. See [`unbrick-and-flash.md`](unbrick-and-flash.md).

## 3. Preserving Factory MAC Addresses

Restore your camera's factory MAC addresses once over SSH:
```bash
fw_setenv ethaddr XX:XX:XX:XX:XX:XX
fw_setenv wlan_mac XX:XX:XX:XX:XX:YY
```
Do not commit device-unique MAC addresses or factory dumps to Git.
