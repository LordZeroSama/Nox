#!/usr/bin/env bash
# Nox OS - build an ISO for one variant.
# Usage: sudo ./build.sh <perf|generic> [output_dir]
# Requires Arch Linux (or an Arch container) with the "archiso" package.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
variant="${1:-}"
out_dir="$(realpath -m "${2:-$script_dir/out}")"
variant_dir="$script_dir/variants/$variant"

[[ $EUID -eq 0 ]] || { echo "Run as root: sudo $0 $*" >&2; exit 1; }
[[ -n "$variant" && -f "$variant_dir/variant.conf" ]] || {
    echo "Usage: $0 <$(ls "$script_dir/variants" | tr '\n' '|' | sed 's/|$//')> [output_dir]" >&2; exit 1; }
command -v mkarchiso >/dev/null || pacman -S --needed --noconfirm archiso

# shellcheck source=/dev/null
source "$variant_dir/variant.conf"

work_root="$script_dir/work/$variant"
profile_dir="$work_root/profile"
local_repo="$work_root/localrepo"
rm -rf "$work_root/profile" "$work_root/mkarchiso"
mkdir -p "$work_root" "$out_dir"

echo "==> Assembling profile for variant '$variant' (kernel: $NOX_KERNEL)"
cp -a "$script_dir/profile" "$profile_dir"

# Variant overlay (optional extra files)
if [[ -d "$variant_dir/airootfs" ]]; then
    cp -a "$variant_dir/airootfs/." "$profile_dir/airootfs/"
fi

# Package list = common + variant (comments and blank lines removed)
grep -hvE '^\s*(#|$)' "$profile_dir/packages.common" "$variant_dir/packages" \
    | sort -u > "$profile_dir/packages.x86_64"
rm "$profile_dir/packages.common"

# Placeholders in boot menus and profiledef
find "$profile_dir/efiboot" "$profile_dir/syslinux" "$profile_dir/profiledef.sh" -type f -exec sed -i \
    -e "s|%NOX_KERNEL%|${NOX_KERNEL}|g" \
    -e "s|%NOX_VARIANT%|${variant}|g" \
    -e "s|%NOX_KERNEL_PARAMS%|${NOX_KERNEL_PARAMS}|g" {} +

# Local AUR repository (only for variants that need it)
if (( ${#NOX_AUR_PACKAGES[@]} > 0 )); then
    if [[ ! -f "$local_repo/nox-local.db.tar.gz" || "${NOX_REBUILD_AUR:-0}" == "1" ]]; then
        rm -rf "$local_repo"
        "$script_dir/scripts/build-aur.sh" "$local_repo" "${NOX_AUR_PACKAGES[@]}"
    fi
    sed -i "s|^#%NOX_LOCALREPO_BLOCK%|[nox-local]\nSigLevel = Optional TrustAll\nServer = file://${local_repo}|" \
        "$profile_dir/pacman.conf"
else
    sed -i '/%NOX_LOCALREPO_BLOCK%/d' "$profile_dir/pacman.conf"
fi

echo "==> Running mkarchiso"
mkarchiso -v -r -w "$work_root/mkarchiso" -o "$out_dir" "$profile_dir"
echo "==> Done:"
ls -lh "$out_dir"/nox-os-"$variant"-*.iso
