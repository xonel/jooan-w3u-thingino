# Unbrick, Flash SPI (CH341A) & Bascule entre variantes SC2336P / CV2003

## 1. Quelle image flasher ?

Jooan a produit **deux révisions matérielles** de la W3-U (même carte T23N + Ethernet GPIO 64 + Wi-Fi ATBM6132U + 8 Mio SPI NOR, mais capteurs différents selon la date d'achat) :

| Révision W3-U | Capteurs I2C | Image complète 8 Mio (pour CH341A) |
|---------------|--------------|------------------------------------|
| **Variante A — Dual SC2336P / SC2336** | `0x30` + `0x32` (chip-id `0x9b3a`, `0xcb3a` ou `0x10`) | `firmware/thingino-jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u.bin` |
| **Variante B — Dual CV2003** *(lots mi-2026)* | `0x35` + `0x36` (chip-id `0x2003`) | `firmware/thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin` |

**Bonne nouvelle : tu n'as besoin d'ouvrir et flasher au CH341A qu'UNE SEULE FOIS !**
Les deux images embarquent le bootloader **U-Boot 2013.07** qui démarre proprement la W3-U, active Ethernet (GPIO 64), le Wi-Fi ATBM6132U, SSH et la WebUI.
Si tu flashes d'abord l'une des deux au programmateur SPI et qu'après remontage tu vois en SSH (`sinfo` ou `dmesg | grep -iE 'sc2336|cv2003|chip'`) que ta carte possède l'autre capteur, tu bascules vers l'autre variante **en 30 secondes par le réseau** sans réouvrir la caméra ni toucher à U-Boot !

---

## 2. Flash initial / Unbrick au programmateur CH341A (8 Mio complet)

1. Vérifie que la puce SPI NOR 8 Mio (64 Mbit, 3.3V, ex. `PY25Q64HA` / `W25Q64JV` / `EN25QX64A`) est détectée hors tension :
   ```bash
   flashrom -p ch341a_spi
   ```
2. Écris l'image complète 8 Mio (**exactement 8 388 608 octets**) et vérifie la relecture :
   ```bash
   # Exemple avec la variante CV2003 (lots juin 2026) ou SC2336P :
   flashrom -p ch341a_spi -w firmware/thingino-jooan_w3u_t23n_cv2003_dual_eth+atbm6132u.bin -V
   ```
3. Branche le câble **RJ45 Ethernet** (le plus simple au premier boot : DHCP actif sur `eth0` grâce au toggle GPIO 64 intégré à `thingino.json`), puis alimente la caméra.
4. Connecte-toi en SSH (`ssh root@<IP_CAMERA>`) ou ouvre `http://<IP_CAMERA>` pour l'assistant initial Thingino.

### Restaurer tes adresses MAC d'origine (recommandé au 1er boot SSH)
Depuis ton backup d'environnement d'origine (`ethaddr` et `wlan_mac`), enregistre-les une fois en SSH pour qu'elles soient conservées en partition `env` :
```bash
fw_setenv ethaddr XX:XX:XX:XX:XX:XX
fw_setenv wlan_mac XX:XX:XX:XX:XX:YY
reboot
```

---

## 3. Diagnostic capteur & bascule réseau SANS réouvrir la caméra

Une fois connecté en SSH sur la caméra :
```bash
# Détecter automatiquement le vrai modèle des capteurs sur le bus I2C :
sinfo
dmesg | grep -iE "isp|sensor|sc2336|cv2003|chip found"
```

- Si les 2 capteurs sont reconnus (`/proc/jz/sensor/sensor0` et `sensor1`), les 4 flux RTSP (`ch0`, `ch1`, `ch2`, `ch3`) sont immédiatement actifs !
- Si c'est l'autre variante de capteur, **ne flashe JAMAIS le `.bin` complet** (inutile de réécrire `mtd0` U-Boot). Extrais et envoie uniquement le `uImage` + `rootfs.squashfs` de l'autre profil via `sysupgrade` partiel :
  ```bash
  # Depuis ton PC :
  ./scripts/extract-ota-parts.sh firmware/thingino-jooan_w3u_t23n_sc2336p_dual_eth+atbm6132u.bin /tmp/ota-w3u
  scp /tmp/ota-w3u/uImage /tmp/ota-w3u/rootfs.squashfs root@<IP>:/tmp/

  # Sur la caméra (flash uniquement kernel + rootfs, ne touche pas à U-Boot mtd0 !) :
  ssh root@<IP> "sysupgrade /tmp/uImage && sysupgrade /tmp/rootfs.squashfs"
  ```
