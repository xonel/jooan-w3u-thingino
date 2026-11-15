# Jooan W3-U — Dual-Sensor Thingino Firmware (Frigate Ready)

Custom [Thingino](https://github.com/themactep/thingino-firmware) profiles, upstream-ready patches, and prebuilt **8 MiB** SPI NOR firmware images for the **Jooan W3-U** dual-lens IP camera (**Ingenic T23N**, wired Ethernet + AltoBeam ATBM6132U Wi-Fi + PTZ + two-way audio + MicroSD), exposing **both cameras simultaneously** (`ch0`/`ch1` + `ch2`/`ch3`) to **Frigate NVR** without proprietary OEM `*_double.ko` kernel blobs.

## Prebuilt Firmware Images (`firmware/`)

Jooan shipped two hardware sensor revisions of the W3-U on the same T23N PCB. **Both 8 MiB images are built and validated** from official `themactep/thingino-firmware` (`master+e923f27`, 2026-11-15) with **U-Boot `2013.07` pinned** (`0x80370000`, avoiding the `2026.07` SPL brick):

| Hardware Revision | Sensors (I2C0) | 8 MiB SPI Image (`firmware/`) | SHA-256 |
|-------------------|----------------|-------------------------------|---------|
| **Dual SC2336P / SC2336** | `0x30` + `0x32` (`0x9b3a` / `0xcb3a` / `0x10`) | `thingino-jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u.bin` | `d2edff20…` |
| **Dual CV2003** *(mid-2026+ batches)* | `0x35` + `0x36` (`0x2003`) | `thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin` | `127478ae…` |

> **Tip if unsure which sensor batch your W3-U has:** You only need to flash with your `CH341A` programmer **once**! Both images boot Linux, Ethernet (GPIO 64), Wi-Fi, WebUI, and SSH. Once booted, run `sinfo` over SSH to check the exact sensor ID — if your board uses the other variant, switch in 30 seconds over SSH with `scripts/extract-ota-parts.sh` + `sysupgrade` (never touching `mtd0` U-Boot, never reopening the camera). See [`docs/unbrick-and-flash.md`](docs/unbrick-and-flash.md).

## RTSP Streams for Frigate NVR

| Camera / Lens | Stream | RTSP Endpoint | Resolution / FPS | Audio |
|---------------|--------|---------------|------------------|-------|
| **Lens 1 (`sensor0`)** | Main (`record`) | `rtsp://thingino:thingino@<IP>:554/ch0` | `1920×1080 @ 15 fps` H.264 | AAC + 2-way Backchannel |
| **Lens 1 (`sensor0`)** | Sub (`detect`) | `rtsp://thingino:thingino@<IP>:554/ch1` | `640×360 @ 15 fps` H.264 | — |
| **Lens 2 (`sensor1`)** | Main (`record`) | `rtsp://thingino:thingino@<IP>:554/ch2` | `1920×1080 @ 15 fps` H.264 | — |
| **Lens 2 (`sensor1`)** | Sub (`detect`) | `rtsp://thingino:thingino@<IP>:554/ch3` | `640×360 @ 15 fps` H.264 | — |

Ready-to-paste Frigate + `go2rtc` + ONVIF PTZ configuration: [`frigate/config.example.yml`](frigate/config.example.yml) and [`docs/frigate.md`](docs/frigate.md).

## Hardware Mapping (`thingino.json`)

- **SoC / RAM / Flash**: Ingenic T23N, 64 MiB RAM (`osmem=30M@0x0`, `rmem=34M@0x1e00000`), 8 MiB SPI NOR
- **Ethernet**: 100 Mbit/s wired (`eth` enable GPIO `64`, `toggle: true`)
- **Wi-Fi**: AltoBeam ATBM6132U USB (`wlan` power GPIO `6`, `toggle: true`)
- **Dual Sensors**: `sensor_1` reset GPIO `18`, `sensor_2` reset GPIO `16`, MIPI switch GPIO `7`
- **Lighting & IR-Cut**: IR 850nm GPIO `59`, White LED GPIO `60`, IR-Cut coil GPIOs `"50 49"`
- **Audio / SD / Reset**: Speaker amp GPIO `63` (`active_low: true`), MMC CD GPIO `61`, Reset button GPIO `62`
- **PTZ Motors**: Pan `"53 52 54 51"`, Tilt `"51 54 52 53"`, switch GPIO `17` (`4000×750` steps)

## Build from Official `themactep/thingino-firmware`

Works out of the box with either **Podman** or **Docker**:

```bash
# Clone/update official themactep/thingino-firmware, apply patches/profiles, build both images & validate:
make build

# Or apply patches/profiles onto an existing thingino-firmware checkout:
./scripts/apply-to-thingino.sh /path/to/thingino-firmware
```

## Repository Structure

```text
configs/cameras/         Official Thingino camera profiles (defconfig, raptor.config, thingino.json)
patches/
  ingenic-sdk/           SC2336P family chip-id patch (0x9b3a / 0xcb3a / 0x10)
  thingino-firmware/     U-Boot 2013.07 camera-override fix + T23 CV2003 IQ fallback
scripts/
  apply-to-thingino.sh   Applies patches & profiles onto official themactep/thingino-firmware
  extract-ota-parts.sh   Extracts uImage + rootfs.squashfs from .bin for safe partial sysupgrade
frigate/
  config.example.yml     Ready-to-use Frigate 0.14+ / go2rtc / ONVIF PTZ config for both lenses
firmware/                Validated 8 MiB SPI NOR images + partition reports + SHA256SUMS.txt
docs/                    Unbrick & flash guide, Frigate setup, dual-sensor architecture, U-Boot policy
```

## Documentation

- [`docs/unbrick-and-flash.md`](docs/unbrick-and-flash.md) — Unbrick CH341A, sauvegarde MAC, et bascule réseau `SC2336P` ↔ `CV2003`
- [`docs/frigate.md`](docs/frigate.md) — Intégration des 2 objectifs + audio + PTZ ONVIF dans Frigate
- [`docs/dual-sensor.md`](docs/dual-sensor.md) — Architecture ISP multi-capteur T23N & Raptor
- [`docs/bootloader-2013-07.md`](docs/bootloader-2013-07.md) — Pourquoi U-Boot `2013.07` est indispensable sur la W3-U
- [`docs/validation.md`](docs/validation.md) — Rapport de validation binaire des images 8 Mio
