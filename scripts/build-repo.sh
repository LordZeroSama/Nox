#!/usr/bin/env bash
# Nox OS - build packages into a local pacman repository.
# Usage: scripts/build-repo.sh <repo_dir> <entry>...
#   entry = path to a directory with a PKGBUILD (packages of this repo)
#        or aur:<pkgbase> (cloned from the AUR)
# Must run on Arch Linux as root (makepkg itself runs as an unprivileged user).
set -euo pipefail

repo_dir="$(realpath -m "$1")"; shift
build_user="noxbuild"
build_root="$(mktemp -d /tmp/nox-pkg.XXXX)"

mkdir -p "$repo_dir"
pacman -S --needed --noconfirm base-devel git

if ! id "$build_user" >/dev/null 2>&1; then
    useradd -m "$build_user"
    echo "$build_user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/90-noxbuild
fi
chown "$build_user": "$build_root"

for entry in "$@"; do
    if [[ "$entry" == aur:* ]]; then
        name="${entry#aur:}"
        echo "==> Cloning AUR package base: $name"
        sudo -u "$build_user" git clone --depth 1 "https://aur.archlinux.org/${name}.git" "$build_root/$name"
        # Review point: read $build_root/$name/PKGBUILD if you build locally.
    else
        name="$(basename "$entry")"
        echo "==> Using local package: $name"
        cp -r "$entry" "$build_root/$name"
        chown -R "$build_user": "$build_root/$name"
    fi
    (cd "$build_root/$name" && sudo -u "$build_user" makepkg --syncdeps --noconfirm --needed --cleanbuild)
    cp "$build_root/$name"/*.pkg.tar.zst "$repo_dir/"
done

repo-add --new "$repo_dir/nox-local.db.tar.gz" "$repo_dir"/*.pkg.tar.zst
rm -rf "$build_root"
echo "==> Local repository ready: $repo_dir"
