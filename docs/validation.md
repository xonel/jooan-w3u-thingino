# Validation Report (Offline Binary & RootFS Inspection)

Both 8 MiB dual-sensor images (`jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u` and `jooan_w3u_t23n_cv2003_dual_eth+atbm6132u`) built from official `themactep/thingino-firmware` (`master+e923f27`, 2026-11-15) passed all structural, bootloader, kernel, module, and Raptor configuration checks:

## 1. Flash Partition Layout (`8 388 608` bytes exact)

`mtdparts=jz_sfc:320k(boot),64k(env),64k(backup),1600k(kernel),5248k(rootfs),896k(data),8192k@0(all)`

| Offset | Partition | Magic / Expected | SC2336P Dual | CV2003 Dual |
|--------|-----------|------------------|--------------|-------------|
| `0x000000` | `boot` (320K) | `06050403` + load `0x80370000` + `SPL 2013.07` | ✅ | ✅ |
| `0x050000` | `env` (64K) | `osmem=30M@0x0`, `rmem=34M@0x1e00000`, pure `sf probe` `bootcmd` | ✅ | ✅ |
| `0x060000` | `backup` (64K) | `0xffffffff` | ✅ | ✅ |
| `0x070000` | `kernel` (1600K) | `27051956` (LZMA uImage 3.10.14) | ✅ | ✅ |
| `0x200000` | `rootfs` (5248K) | `68737173` (`hsqs` SquashFS XZ) | ✅ | ✅ |
| `0x720000` | `data` (896K) | `8519` (JFFS2 overlayfs upperdir) | ✅ | ✅ |

## 2. RootFS, Kernel Modules & Raptor Configuration

- `/etc/modules.d/20-isp`: `tx_isp_t23 isp_clk=200000000 direct_mode=0 isp_memopt=0 print_level=1 mipi_switch_gpio=7`
- `/etc/modules.d/30-sensor_1`: `sensor_sc2336ps0_t23 reset_gpio=18` / `sensor_cv2003s0_t23 reset_gpio=18`
- `/etc/modules.d/30-sensor_2`: `sensor_sc2336ps1_t23 reset_gpio=16` / `sensor_cv2003s1_t23 reset_gpio=16`
- `/etc/modules.d/40-audio`: `audio spk_gpio=63 spk_level=0`
- Wi-Fi & SD: `atbm6132u.ko`, `jzmmc_v12.ko`, `exfat.ko`, `vfat.ko` present
- Sensor IQ blobs in `/usr/share/sensor/`: `sc2336p-t23.bin` (`176 288` B) and `cv2003-t23.bin` (`176 288` B) + `s0`/`s1` symlinks
- `/etc/raptor.conf`:
  - `[sensor0]` & `[sensor1]` both carry `width = 1920`, `height = 1080`, `fps = 15`
  - `[rtsp]` exposes `ch0` (S0 1080p + AAC + backchannel), `ch1` (S0 360p), `ch2` (S1 1080p), `ch3` (S1 360p)
  - `[osd]` sets `isp_osd = true`
