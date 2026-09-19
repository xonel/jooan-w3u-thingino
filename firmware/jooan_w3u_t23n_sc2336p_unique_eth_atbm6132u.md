# jooan_w3u_t23n_sc2336p_unique_eth_atbm6132u

MTD Partition Details
---------------------
- Generated: mtdparts=jz_sfc:320k(boot),64k(env),64k(backup),1600k(kernel),5184k(rootfs),960k(data),8192k@0(all)
- In U-Boot: mtdparts=jz_sfc:320k(boot),64k(env),64k(backup),1600k(kernel),5184k(rootfs),960k(data),8192k@0(all)

### Bytes
NAME    |   OFFSET |  PT_SIZE |  CONTENT |  ALIGNED |      END |     LOSS |
--------|----------|----------|----------|----------|----------|----------|
U_BOOT  |        0 |   327680 |   188874 |   196608 |   196608 |   131072 |
UB_ENV  |   327680 |    65536 |    65536 |    65536 |   393216 |        0 |
BACKUP  |   393216 |    65536 |        0 |        0 |   393216 |    65536 |
KERNEL  |   458752 |  1638400 |  1450762 |  1638400 |  2097152 |        0 |
ROOTFS  |  2097152 |  5308416 |  5275648 |  5308416 |  7405568 |        0 |
DATA    |  7405568 |   983040 |   983040 |   983040 |  8388608 |        0 |

### Kilobytes
NAME    |   OFFSET |  PT_SIZE |  CONTENT |  ALIGNED |      END |     LOSS |
--------|----------|----------|----------|----------|----------|----------|
U_BOOT  |        0 |      320 |      184 |      192 |      192 |      128 |
UB_ENV  |      320 |       64 |       64 |       64 |      384 |        0 |
BACKUP  |      384 |       64 |        0 |        0 |      384 |       64 |
KERNEL  |      448 |     1600 |     1416 |     1600 |     2048 |        0 |
ROOTFS  |     2048 |     5184 |     5152 |     5184 |     7232 |        0 |
DATA    |     7232 |      960 |      960 |      960 |     8192 |        0 |

### Hexadecimal
NAME    |   OFFSET |  PT_SIZE |  CONTENT |  ALIGNED |      END |     LOSS |
--------|----------|----------|----------|----------|----------|----------|
U_BOOT  |        0 |    50000 |    2E1CA |    30000 |    30000 |    20000 |
UB_ENV  |    50000 |    10000 |    10000 |    10000 |    60000 |        0 |
BACKUP  |    60000 |    10000 |        0 |        0 |    60000 |    10000 |
KERNEL  |    70000 |   190000 |   16230A |   190000 |   200000 |        0 |
ROOTFS  |   200000 |   510000 |   508000 |   510000 |   710000 |        0 |
DATA    |   710000 |    F0000 |    F0000 |    F0000 |   800000 |        0 |

Build: master+6e8a0f6, 2026-09-19 01:43:42 +0000
Build Duration: 0:03:19 (199s)
Disk Writes: 1.7G (1837824000 bytes)
