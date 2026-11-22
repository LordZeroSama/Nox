# Installer Nox OS sur le disque externe (depuis Windows)

> ⚠️ Cette procédure **efface tout le disque choisi**. Vérifie deux fois le numéro du
> disque à l'étape 2.

## 1. Prérequis

- L'ISO `nox-os-perf-AAAA.MM.JJ-x86_64.iso` (voir `BUILD.md`)
- [7-Zip](https://www.7-zip.org/) (gratuit)
- Le disque externe branché

## 2. Partitionner avec diskpart

Invite de commandes **en administrateur** :

```
diskpart
list disk
```

Repère le disque externe à sa taille (465 Go), par exemple `Disque 2`. Puis :

```
select disk 2
clean
convert gpt
create partition primary size=8192
format fs=fat32 quick label=NOXBOOT
assign letter=N
exit
```

- La partition **NOXBOOT** fait 8 Go : de quoi garder deux versions de l'OS.
- Le reste du disque reste **non alloué**. Nox OS y créera la partition `NOXHOME`.

## 3. Copier l'OS

Ouvre l'ISO avec 7-Zip (clic droit, puis **7-Zip**, puis **Extraire vers…**) et extrais
**tout le contenu** à la racine de `N:\`. On doit obtenir, entre autres, `N:\EFI\`,
`N:\loader\`, `N:\nox\` et `N:\boot\`.

## 4. Démarrer dessus

1. Redémarre le PC en appuyant sur **Échap** pour ouvrir le menu de démarrage
   (sur la plupart des portables ASUS ; sinon F2 pour le BIOS, puis l'onglet Boot).
2. Choisis l'entrée **UEFI** du disque externe.
3. Dans le menu Nox, laisse **Nox OS (RAM)**. La copie en RAM affiche une barre de
   progression (30 à 60 s sur un disque mécanique).

Si le PC ne voit pas le disque : vérifie que le mode **UEFI** est actif et que
**Secure Boot** est désactivé (c'est déjà le cas sur le K501LX).

## 5. Premier démarrage

1. Clic droit sur le bureau, puis **Wi-Fi** (ou `nox-wifi` dans un terminal).
2. Clic droit, puis **Configurer la persistance** : crée `NOXHOME` dans l'espace libre (tape `OUI`).
3. Redémarre. Au démarrage suivant, Sober (Roblox) s'installe automatiquement dans `NOXHOME`.
4. Lance Roblox avec `Super + R` et connecte-toi.

## Mettre à jour l'OS (automatique)

1. Télécharge [`windows/Mettre-a-jour-Nox.bat`](../windows/Mettre-a-jour-Nox.bat)
   (bouton « Download raw file ») et place-le où tu veux, par exemple sur le Bureau ou à la racine de `N:\`.
2. Branche le disque Nox et double-clique sur le fichier (accepte la demande administrateur).
3. Le script compare ta version à la dernière publiée sur GitHub, télécharge l'ISO
   (reprise possible si la connexion coupe), vérifie son intégrité et remplace le contenu
   de `NOXBOOT`. `NOXHOME` (jeux, réglages) n'est pas touché.

La version installée est notée dans `N:\nox-release.txt`.
