#!/usr/bin/env bash
# Nox OS - build AUR packages into a local pacman repository.
# Usage: scripts/build-aur.sh <repo_dir> <aur_pkgbase>...
# Must run on Arch Linux as root (makepkg itself runs as an unprivileged user).
set -euo pipefail

repo_dir="$(realpath -m "$1")"; shift
build_user="noxbuild"
build_root="$(mktemp -d /tmp/nox-aur.XXXX)"

mkdir -p "$repo_dir"
pacman -S --needed --noconfirm base-devel git

if ! id "$build_user" >/dev/null 2>&1; then
    useradd -m "$build_user"
    echo "$build_user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/90-noxbuild
fi
chown "$build_user": "$build_root"

for pkgbase in "$@"; do
    echo "==> Building AUR package base: $pkgbase"
    sudo -u "$build_user" git clone --depth 1 "https://aur.archlinux.org/${pkgbase}.git" "$build_root/$pkgbase"
    # Review point: read $build_root/$pkgbase/PKGBUILD if you build locally.
    (cd "$build_root/$pkgbase" && sudo -u "$build_user" makepkg --syncdeps --noconfirm --needed --cleanbuild)
    cp "$build_root/$pkgbase"/*.pkg.tar.zst "$repo_dir/"
done

repo-add --new "$repo_dir/nox-local.db.tar.gz" "$repo_dir"/*.pkg.tar.zst
rm -rf "$build_root"
echo "==> Local repository ready: $repo_dir"
