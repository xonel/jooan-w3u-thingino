# jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u

MTD Partition Details
---------------------
- Generated: mtdparts=jz_sfc:320k(boot),64k(env),64k(backup),1600k(kernel),5248k(rootfs),896k(data),8192k@0(all)
- In U-Boot: mtdparts=jz_sfc:320k(boot),64k(env),64k(backup),1600k(kernel),5248k(rootfs),896k(data),8192k@0(all)

### Bytes
NAME    |   OFFSET |  PT_SIZE |  CONTENT |  ALIGNED |      END |     LOSS |
--------|----------|----------|----------|----------|----------|----------|
U_BOOT  |        0 |   327680 |   188926 |   196608 |   196608 |   131072 |
UB_ENV  |   327680 |    65536 |    65536 |    65536 |   393216 |        0 |
BACKUP  |   393216 |    65536 |        0 |        0 |   393216 |    65536 |
KERNEL  |   458752 |  1638400 |  1371467 |  1638400 |  2097152 |        0 |
ROOTFS  |  2097152 |  5373952 |  5365760 |  5373952 |  7471104 |        0 |
DATA    |  7471104 |   917504 |   917504 |   917504 |  8388608 |        0 |

### Kilobytes
NAME    |   OFFSET |  PT_SIZE |  CONTENT |  ALIGNED |      END |     LOSS |
--------|----------|----------|----------|----------|----------|----------|
U_BOOT  |        0 |      320 |      184 |      192 |      192 |      128 |
UB_ENV  |      320 |       64 |       64 |       64 |      384 |        0 |
BACKUP  |      384 |       64 |        0 |        0 |      384 |       64 |
KERNEL  |      448 |     1600 |     1339 |     1600 |     2048 |        0 |
ROOTFS  |     2048 |     5248 |     5240 |     5248 |     7296 |        0 |
DATA    |     7296 |      896 |      896 |      896 |     8192 |        0 |

### Hexadecimal
NAME    |   OFFSET |  PT_SIZE |  CONTENT |  ALIGNED |      END |     LOSS |
--------|----------|----------|----------|----------|----------|----------|
U_BOOT  |        0 |    50000 |    2E1FE |    30000 |    30000 |    20000 |
UB_ENV  |    50000 |    10000 |    10000 |    10000 |    60000 |        0 |
BACKUP  |    60000 |    10000 |        0 |        0 |    60000 |    10000 |
KERNEL  |    70000 |   190000 |   14ED4B |   190000 |   200000 |        0 |
ROOTFS  |   200000 |   520000 |   51E000 |   520000 |   720000 |        0 |
DATA    |   720000 |    E0000 |    E0000 |    E0000 |   800000 |        0 |

Build: master+e923f27, 2026-11-15 00:13:56 +0000
Build Duration: 0:22:05 (1325s)
Disk Writes: 16.2G (17426167808 bytes)
