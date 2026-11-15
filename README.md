# Jooan W3-U — Experimental Dual-Sensor Thingino Firmware

Experimental [Thingino](https://github.com/themactep/thingino-firmware) profiles and patches aiming to stream **both lenses** of the **Jooan W3-U** (Ingenic T23N, wired Ethernet, ATBM6132U Wi-Fi, PTZ) at once (`ch0`/`ch1` + `ch2`/`ch3`), for use with Frigate, without OEM `*_double.ko` modules.

> **Status: not yet tested on a real camera.** The images build and pass offline inspection only. Read [`docs/status.md`](docs/status.md) before flashing: it lists what is verified, what is assumed, and what is known to be a placeholder.

## Prebuilt images

Images are attached to the [GitHub Releases](https://github.com/xonel/jooan-w3u-thingino/releases), not stored in git. Built from `themactep/thingino-firmware` `master+e923f27` with U-Boot `2013.07`.

| Profile | Sensors expected (I2C0) | Maturity |
|---------|-------------------------|----------|
| `jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u` | `sc2336ps0` @ `0x30` + `sc2336ps1` @ `0x32` | Experimental, untested on hardware |
| `jooan_w3u_t23n_cv2003_dual_eth+atbm6132u` | `cv2003s0` @ `0x35` + `cv2003s1` @ `0x36` | Speculative: no evidence yet that any W3-U carries CV2003; uses a placeholder IQ file (untuned image) |

Which sensors a given W3-U carries must be read from the running camera (`sinfo`, `dmesg`) before choosing a dual profile. See [`docs/unbrick-and-flash.md`](docs/unbrick-and-flash.md).

## Intended RTSP streams (once validated)

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
- **Dual Sensors (unverified, copied from the W8-U profile)**: `sensor_1` reset GPIO `18`, `sensor_2` reset GPIO `16`, MIPI switch GPIO `7`
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
  thingino-firmware/     U-Boot 2013.07 camera-override fix + CV2003 placeholder IQ (applied by apply-to-thingino.sh)
  upstream-series/       Same changes as a 4-commit git format-patch series on themactep master
scripts/
  apply-to-thingino.sh   Applies patches & profiles onto official themactep/thingino-firmware
  extract-ota-parts.sh   Extracts uImage + rootfs.squashfs from .bin for safe partial sysupgrade
frigate/
  config.example.yml     Ready-to-use Frigate 0.14+ / go2rtc / ONVIF PTZ config for both lenses
firmware/                Partition reports + SHA256SUMS.txt (images are Release assets)
.github/workflows/      CI: build both profiles on upstream master and check the image layout
docs/                    Unbrick & flash guide, Frigate setup, dual-sensor architecture, U-Boot policy
```

## Documentation

- [`docs/unbrick-and-flash.md`](docs/unbrick-and-flash.md) — Unbrick CH341A, sauvegarde MAC, et bascule réseau `SC2336P` ↔ `CV2003`
- [`docs/frigate.md`](docs/frigate.md) — Intégration des 2 objectifs + audio + PTZ ONVIF dans Frigate
- [`docs/dual-sensor.md`](docs/dual-sensor.md) — Architecture ISP multi-capteur T23N & Raptor
- [`docs/bootloader-2013-07.md`](docs/bootloader-2013-07.md) — Pourquoi U-Boot `2013.07` est indispensable sur la W3-U
- [`docs/status.md`](docs/status.md) — Verified vs assumed, QEMU result, open questions
- [`docs/validation.md`](docs/validation.md) — Rapport de validation binaire des images 8 Mio
- [`docs/upstream-issue-draft.md`](docs/upstream-issue-draft.md) — Suivi upstream [`themactep/thingino-firmware#2022`](https://github.com/themactep/thingino-firmware/issues/2022) & [`#1642`](https://github.com/themactep/thingino-firmware/issues/1642)
