# Firmware artifacts

Validated (offline) 8 MiB Thingino images for the Jooan W3-U.

| Profile | File | SHA-256 | Notes |
|---------|------|---------|-------|
| Single SC2336P | `thingino-jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u.bin` | `d20e89c8fe6f110404016a48e0a2dd9c1d25c31e497f479e7c2228d0835234c0` | sensor0 only, env `41M/23M` |
| Dual SC2336P | `thingino-jooan_w3u_t23n_sc2336p_dual_eth_atbm6132u.bin` | `f2ab69e59dbed7d78e55794564567d4cb3d2553e1abad1428d234a3ff9b873ca` | two lenses (`sc2336ps0`+`sc2336ps1`), env `30M/34M` |

Both images contain U-Boot **2013.07** (`u-boot-lzo-with-spl.bin`), the patched
sensor drivers, and the diagnostic overlay (`sinfo` + `S99sensor-diag`) in the
data partition.

Full partition-by-partition reports: `.md` files next to each image.

Verify:

```sh
sha256sum -c SHA256SUMS.txt
```