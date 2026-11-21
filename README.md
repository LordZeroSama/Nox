# Nox OS

OS de jeu portable (Roblox, Minecraft, navigateur), basé sur Arch Linux et `archiso`,
qui démarre depuis un disque externe et **tourne entièrement en RAM**.

Ateliers Nox Aeterna — projet personnel, non affilié à Roblox ni à Arch Linux.

## Principe

```
Disque externe
├── NOXBOOT  (FAT32, ~8 Go)   image du système en lecture seule (squashfs)
└── NOXHOME  (ext4, le reste) /home persistant : jeux, réglages, Wi-Fi
```

1. Au démarrage, l'image (~3 Go) est copiée en RAM (`copytoram=y`). C'est une lecture
   séquentielle, idéale même sur un disque mécanique lent.
2. Le système tourne ensuite depuis la RAM, et un redémarrage le remet à neuf.
3. Seul `/home` est écrit sur le disque, dans la partition `NOXHOME`.

Menu de démarrage :

| Entrée | Usage |
|---|---|
| Nox OS (RAM) | Par défaut, PC avec 8 Go de RAM ou plus |
| Nox OS (lecture disque) | PC avec moins de 8 Go : l'image est lue sur le disque |
| Mode sans échec graphique | Dépannage : console seule, sans pilotes GPU |

## Variantes

| Variante | Noyau | GPU | Cible |
|---|---|---|---|
| `perf` | `linux-zen` | NVIDIA 580xx propriétaire (AUR) + PRIME, Intel/AMD Mesa | ASUS K501LX (GTX 950M) et PC NVIDIA Maxwell/Pascal |
| `generic` | `linux` | Mesa uniquement (Intel, AMD, nouveau) | La plupart des PC x86-64 |

## Contenu

- Session : **labwc** (Wayland, très léger) + `foot` (terminal) + `fuzzel` (lanceur)
- Jeux : **Sober** (Roblox, Flatpak installé au premier démarrage), **Prism Launcher** (Minecraft, Java téléchargé par Prism)
- Navigateur : Firefox
- Perf : GameMode, MangoHud, zram (swap compressé en RAM), gouverneur CPU `performance`, journaux en RAM
- Initramfs **sans `autodetect`** : l'image démarre sur d'autres PC

### Raccourcis

| Touche | Action |
|---|---|
| `Super` | Lanceur d'applications |
| `Super + R` | Roblox |
| `Super + M` | Minecraft (Prism) |
| `Super + B` | Firefox |
| `Super + Entrée` | Terminal |
| `Super + F` / `Super + Q` | Plein écran / fermer |
| Clic droit sur le bureau | Menu Nox (Wi-Fi, infos, persistance, éteindre) |

### Commandes Nox

| Commande | Rôle |
|---|---|
| `nox-wifi` | Se connecter au Wi-Fi |
| `sudo nox-setup-home` | Créer la partition persistante `NOXHOME` dans l'espace libre du disque Nox |
| `nox-firstrun` | (Ré)installer Sober et les extensions Flatpak |
| `nox-run <cmd>` | Lancer un jeu sur le GPU dédié + GameMode (`NOX_HUD=1` affiche les FPS) |
| `nox-info` | État : noyau, RAM, GPU, persistance, santé SMART des disques |

## Construire l'ISO

Deux options : voir [`docs/BUILD.md`](docs/BUILD.md).

- **GitHub Actions** (recommandé depuis Windows) : onglet *Actions*, puis *Build Nox OS ISO*, puis *Run workflow*.
- **Localement sous Arch Linux** : `sudo ./build.sh perf`

## Installer sur le disque externe

Depuis Windows : voir [`docs/INSTALL-WINDOWS.md`](docs/INSTALL-WINDOWS.md).

## Structure du dépôt

```
build.sh                  assemble le profil d'une variante puis lance mkarchiso
profile/                  profil archiso commun (dérivé de "baseline")
  profiledef.sh           nom, modes de boot, compression
  packages.common         paquets communs
  symlinks.txt            liens (services systemd activés…), recréés au build
  efiboot/ syslinux/      menus de démarrage UEFI / BIOS
  airootfs/               fichiers copiés dans le système
variants/<nom>/           variant.conf (noyau, paramètres) + packages
scripts/build-aur.sh      compile les paquets AUR dans un dépôt local
ci/ .github/workflows/    build automatique sur GitHub
docs/                     guides
```

## Limites connues

- **Sober** est non officiel et expérimental. Roblox peut le casser à tout moment.
- **Roblox Studio** n'est pas pris en charge (passer par Windows ou Vinegar).
- Le pilote NVIDIA 580xx vient de l'AUR (paquet communautaire) : relis le `PKGBUILD`.
- Le boot BIOS (syslinux) ne fonctionne qu'avec l'ISO gravée telle quelle, pas avec la
  méthode « fichiers extraits sur FAT32 » (UEFI uniquement).
- L'utilisateur `nox` a `sudo` sans mot de passe (machine personnelle). Supprimer
  `/etc/sudoers.d/10-nox` si le PC est partagé.
