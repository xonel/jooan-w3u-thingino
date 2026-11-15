# Remise en service et flash (procédure prudente)

> Rien de ce dépôt n'a encore été testé sur une vraie W3-U. Voir [`status.md`](status.md).

## 1. Récupérer la caméra d'abord, en mono-capteur

Avant tout essai dual, remets la caméra dans un état connu :

1. Avec le programmateur CH341A, vérifie que la puce SPI NOR 8 Mio est détectée : `flashrom -p ch341a_spi`.
2. Écris une image **mono-capteur connue pour démarrer** : ta sauvegarde complète d'origine, ou l'image officielle `thingino-jooan_w3u_t23n_sc2336p_eth+atbm6132u.bin` qui avait démarré (réseau, WebUI, PTZ) dans l'issue #1642.
3. Branche le RJ45, démarre, connecte-toi en SSH.

## 2. Relever le matériel réel

Sur la caméra en fonctionnement :

```bash
sinfo
dmesg | grep -iE "isp|sensor|chip|sc2336|cv2003"
for a in 0x30 0x32 0x35 0x36 0x37; do i2cdetect -y 0 $a $a; done
fw_printenv ethaddr wlan_mac
thingino-diag -u
```

Ce relevé tranche trois points aujourd'hui supposés : le modèle des capteurs, leurs adresses I2C, et (avec le firmware d'origine si tu l'as encore) les GPIO de reset et du switch MIPI. Note aussi les adresses MAC.

## 3. Essayer un profil dual

Seulement si le relevé confirme deux capteurs d'un modèle supporté :

- Programmateur encore branché : écris l'image dual complète de la Release (`flashrom -p ch341a_spi -w thingino-<profil>.bin`). C'est la voie la plus sûre, car tu peux revenir en arrière.
- Par le réseau : les profils mono et dual ont le même découpage de partitions seulement si la taille du rootfs aligné est identique, ce qui n'est pas garanti. Une mise à jour partielle (`sysupgrade <fichier>`) redémarre la caméra après chaque fichier ; cette voie n'a pas été testée ici et n'est pas recommandée tant que le programmateur est disponible.

Après démarrage, vérifie `dmesg`, `logread | grep rvd`, puis les flux `rtsp://<IP>:554/ch0` et `/ch2`.

## 4. Adresses MAC

Si l'environnement U-Boot a été réécrit, restaure tes adresses d'origine une fois en SSH :

```bash
fw_setenv ethaddr XX:XX:XX:XX:XX:XX
fw_setenv wlan_mac XX:XX:XX:XX:XX:YY
```
