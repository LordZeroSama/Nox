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

# Recreate symlinks (systemd units, timezone, resolv.conf) from the manifest
while read -r link_target link_path; do
    [[ -z "$link_target" || "$link_target" == \#* ]] && continue
    mkdir -p "$(dirname "$profile_dir/$link_path")"
    ln -sfn "$link_target" "$profile_dir/$link_path"
done < "$profile_dir/symlinks.txt"
rm "$profile_dir/symlinks.txt"

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

# Local repository: packages from this repo (packages/*) + AUR packages of the variant
repo_entries=("$script_dir"/packages/*/)
for aur_name in "${NOX_AUR_PACKAGES[@]}"; do
    repo_entries+=("aur:$aur_name")
done
rm -rf "$local_repo"
bash "$script_dir/scripts/build-repo.sh" "$local_repo" "${repo_entries[@]}"
sed -i "s|^#%NOX_LOCALREPO_BLOCK%|[nox-local]\nSigLevel = Optional TrustAll\nServer = file://${local_repo}|" \
    "$profile_dir/pacman.conf"

echo "==> Running mkarchiso"
mkarchiso -v -r -w "$work_root/mkarchiso" -o "$out_dir" "$profile_dir"
echo "==> Done:"
ls -lh "$out_dir"/nox-os-"$variant"-*.iso
