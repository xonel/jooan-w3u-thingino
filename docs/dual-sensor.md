# Dual sensor without closed-source drivers

The Jooan W3-U ships two SC2336P lenses. Stock Thingino runs one lenses per
board; OEM firmware uses proprietary kernel modules (`tx_isp_t23_double`,
`sensor_*_t23_double.ko`) that are not acceptable here. This project achieves
both lenses with open-source code only.

## How it works

Ingenic's vendor SDK ships a **double-ISP firmware** for the T23 family:

```
sdk/t23/1.3.0-double/libt23-firmware.a
```

The Thingino build links that double firmware when **`CONFIG_MULTI_SENSOR`** is
defined:

```
isp/t23/Kbuild:9-11  →  link libt23-firmware.a from the -double SDK tree
```

That activates the T23's dual-channel ISP (S1S0 + S1S1 image capture), the same
hardware path the vendor's closed `tx_isp_t23_double.ko` uses — without the blob.

## Sensor map

Two sensor profiles are exposed, one per I2C address:

| Address | Sensor model | Role |
|---------|--------------|------|
| `0x30` | `sc2336ps0` | sensor0 (main lens, RTSP ch0/ch1) |
| `0x32` | `sc2336ps1` | sensor1 (secondary lens, RTSP ch2/ch3) |

Both are variants of the SC2336 driver. **Chip-id caveat**: both lenses report the
classic SC2336 family id `0x10`, which the stock drivers reject
(`"chip found @ 0x30 is not an sc2336p chip"`). The patch in
[`patches/0001-sc2336p-accept-classic-chip-id-0x10.patch`](../patches) makes the
`sc2336p` / `sc2336ps0` / `sc2336ps1` drivers accept `v == 0x10`.

## Memory split

Two ISP instances need two reserved memory areas. The dual profile uses:

- `osmem=30M@0x0` — 30 Mio for the kernel/userspace
- `rmem=34M@0x1e00000` — 34 Mio for the two ISP image pipelines

```text
RAM 64M:  [0x0 .. 30M)   osmem        (linux)
          [30M .. 64M)   rmem @0x1e00000 (dual ISP)
```

## Raptor / streamer setup

The dual profile routes the streamer's S1 output to dedicated RTSP endpoints:

- sensor0 → main (ch0) / sub (ch1)
- sensor1 → **ch2** / **ch3** (via `raptor` S1 main/sub endpoints)
- 15 fps for both sensors and both streams

Selector entries in the profile defconfig:

```
RAPTOR_CONF_SENSOR0_I2C_ADDR="0x30"   RAPTOR_CONF_SENSOR0_NAME="sc2336ps0"
RAPTOR_CONF_SENSOR1_I2C_ADDR="0x32"   RAPTOR_CONF_SENSOR1_NAME="sc2336ps1"
RAPTOR_CONF_S1S0_FPS="15"             RAPTOR_CONF_S1S1_FPS="15"
RAPTOR_CONF_RTSP_ENDPOINT_S1_MAIN="ch2"
RAPTOR_CONF_RTSP_ENDPOINT_S1_SUB="ch3"
```

## Reference

The upstream **W8-U** (T31 or T23 class) profile carries the same dual wiring
(`QTY=2`, `RMEM_MB=34`, PWM + motors, double ISP config); the dual profile here
follows that recipe for the T23N with the SC2336P family.