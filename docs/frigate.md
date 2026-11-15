# Intégration Frigate NVR (les 2 caméras de la Jooan W3-U)

> Configuration cible, non testée : elle suppose que le profil dual fonctionne sur la caméra. Voir [`status.md`](status.md).

Avec le firmware Thingino Dual-Sensor (Raptor Streaming System), le SoC Ingenic T23N expose **4 flux RTSP indépendants** (2 flux par capteur : 1 flux principal 1080p pour l'enregistrement et 1 sous-flux 360p léger pour la détection d'objets Frigate) :

| Objectif / Capteur | Rôle | URL RTSP | Résolution / FPS | Audio |
|--------------------|------|----------|------------------|-------|
| **Capteur 0** (`s0`) | Flux principal (`record`) | `rtsp://thingino:thingino@<IP>:554/ch0` | 1920×1080 @ 15 fps (H.264) | AAC + Backchannel 2 voies |
| **Capteur 0** (`s0`) | Sous-flux (`detect`) | `rtsp://thingino:thingino@<IP>:554/ch1` | 640×360 @ 15 fps (H.264) | — |
| **Capteur 1** (`s1`) | Flux principal (`record`) | `rtsp://thingino:thingino@<IP>:554/ch2` | 1920×1080 @ 15 fps (H.264) | — |
| **Capteur 1** (`s1`) | Sous-flux (`detect`) | `rtsp://thingino:thingino@<IP>:554/ch3` | 640×360 @ 15 fps (H.264) | — |

> **Identifiants RTSP par défaut** : utilisateur `thingino`, mot de passe `thingino` (modifiables dans la WebUI Thingino → *Streamer / RTSP* ou dans `/etc/raptor.conf` section `[rtsp]`).

## Configuration Frigate (`config.yml`)

Voir le fichier prêt à l'emploi [`frigate/config.example.yml`](../frigate/config.example.yml).

Points importants :
1. **Passe toujours par `go2rtc`** (intégré à Frigate) pour ne maintenir qu'une seule connexion RTSP active par flux sur le T23N (`max_clients = 4` par défaut).
2. **PTZ ONVIF** : Thingino expose le serveur ONVIF sur le port HTTP `80` avec les identifiants WebUI (`root` / ton mot de passe). Attache le bloc `onvif:` uniquement à la caméra correspondant à la tête motorisée (Pan/Tilt).
3. **Orientation d'image (Flip/Mirror)** : si l'une des deux lentilles est inversée verticalement/horizontalement selon le montage mural ou plafond :
   - Capteur 0 : réglable dans la WebUI ou dans `/etc/raptor.conf` sous `[image]` (`hflip = 1`, `vflip = 1`)
   - Capteur 1 : réglable dans `/etc/raptor.conf` sous `[sensor1_image]` (`hflip = 1`, `vflip = 1`), puis `service raptor restart`.
4. **Test rapide avant Frigate** (depuis ton PC) :
   ```bash
   ffplay rtsp://thingino:thingino@<IP>:554/ch0
   ffplay rtsp://thingino:thingino@<IP>:554/ch2
   ```
