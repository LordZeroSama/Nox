# Construire l'ISO

## Option A : GitHub Actions (depuis Windows, rien à installer)

1. Crée un dépôt GitHub (privé ou public) et pousse ce dossier :
   ```
   git remote add origin https://github.com/<ton-compte>/nox-os.git
   git push -u origin main
   ```
2. Sur GitHub, ouvre **Actions**, puis **Build Nox OS ISO**, puis **Run workflow**, et choisis `perf`.
3. Attends la fin (30 à 60 min : la compilation du pilote NVIDIA prend du temps).
4. Télécharge l'artefact `nox-os-perf` (un .zip qui contient l'ISO).

Remarques :
- Dépôt privé : le build consomme des minutes du quota gratuit d'Actions. Un dépôt public
  n'a pas de quota.
- L'artefact est conservé 7 jours.

## Option B : localement sous Arch Linux

```
sudo pacman -S --needed archiso git base-devel
sudo ./build.sh perf          # ou: generic
# ISO dans ./out/
```

- Le dépôt AUR local est mis en cache dans `work/perf/localrepo`.
  Pour forcer la recompilation : `sudo NOX_REBUILD_AUR=1 ./build.sh perf`
- Espace disque nécessaire : ~10 Go dans `work/`.

## Tester sans disque externe

Sous Arch : `run_archiso -u -i out/nox-os-*.iso` (paquet `qemu-desktop`).
Le GPU NVIDIA ne sera pas utilisé dans la VM : c'est normal.
