#!/usr/bin/env bash
# Runs inside an archlinux:latest container (privileged). Used by GitHub Actions.
set -euo pipefail
variant="$1"
pacman -Syu --noconfirm --needed archiso git base-devel
cd /build
bash ./build.sh "$variant" /build/out
