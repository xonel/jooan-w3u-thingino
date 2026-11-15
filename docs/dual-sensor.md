# Dual-Sensor Architecture on Jooan W3-U (T23N)

The Jooan W3-U is a dual-lens IP camera (fixed wide-angle lens + Pan/Tilt lens) powered by an **Ingenic T23N** (64 MiB DDR2, 8 MiB SPI NOR, wired 100M Ethernet via GPIO 64 toggle, AltoBeam ATBM6132U USB Wi-Fi).

Depending on manufacturing batch, Jooan shipped **two sensor variants** on the same board:
1. **Dual SmartSens SC2336P / SC2336** (`0x30` + `0x32` on I2C0; chip ID `0x9b3a`, `0xcb3a`, or classic `0x10`)
2. **Dual CVSens CV2003** (`0x35` + `0x36` on I2C0; chip ID `0x2003`, mid-2026 batches)

## How Dual-Sensor Works on Official Thingino

When `BR2_THINGINO_IMAGE_SENSOR_QTY=2` is set in the camera defconfig:
1. **`ingenic-sdk`** compiles with `CONFIG_MULTI_SENSOR=1`, linking Ingenic's dual-sensor T23 ISP library (`libt23-firmware.a` multi-sensor build) into `tx-isp-t23.ko` (`mipi_switch_gpio=7`, `direct_mode=0`, `isp_memopt=0`, `isp_clk=200000000`) and building both synchronized (`s0`/`s1`) sensor modules:
   - SC2336P profile: `sensor_sc2336ps0_t23.ko` (`reset_gpio=18`) + `sensor_sc2336ps1_t23.ko` (`reset_gpio=16`)
   - CV2003 profile: `sensor_cv2003s0_t23.ko` (`reset_gpio=18`) + `sensor_cv2003s1_t23.ko` (`reset_gpio=16`)
2. **Memory split (`64 MiB` total)**:
   - `osmem=30M@0x0` (Linux kernel + userspace)
   - `rmem=34M@0x1e00000` (Dual ISP + H.264 encoder ring buffers)
3. **Raptor Streaming System (`raptor.config` → `/etc/raptor.conf`)**:
   - Explicitly declares `width = 1920` and `height = 1080` on `[sensor0]` and `[sensor1]` (required because `s0`/`s1` drivers report `0x0` in `/proc/jz/sensor` prior to stream crop/scaler setup in `rvd_pipeline.c`).
   - Uses hardware ISP OSD (`isp_osd = true`) for zero extra DDR bandwidth.
   - Exposes **4 concurrent H.264 RTSP streams** on port `554` for Frigate NVR:
     - `/ch0` — Sensor 0 Main (`1920x1080 @ 15 fps` + AAC audio + 2-way backchannel)
     - `/ch1` — Sensor 0 Sub (`640x360 @ 15 fps` for Frigate object detection)
     - `/ch2` — Sensor 1 Main (`1920x1080 @ 15 fps`)
     - `/ch3` — Sensor 1 Sub (`640x360 @ 15 fps` for Frigate object detection)
