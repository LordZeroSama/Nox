#!/usr/bin/env bash
# shellcheck disable=SC2034
# Nox OS - archiso profile definition.
# Values marked %NOX_*% are filled in by build.sh for each variant (perf / generic).

iso_name="nox-os-%NOX_VARIANT%"
iso_label="NOX_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Ateliers Nox Aeterna"
iso_application="Nox OS - portable gaming system"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="nox"
# BIOS boot kept for older PCs; UEFI uses systemd-boot (works from extracted files on FAT32).
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
# zstd: slightly bigger than xz but much faster to decompress -> faster boot on weak CPUs.
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
kernel_params_x86_64="%NOX_KERNEL_PARAMS%"
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/sudoers.d/10-nox"]="0:0:440"
  ["/usr/local/bin/nox-run"]="0:0:755"
  ["/usr/local/bin/nox-firstrun"]="0:0:755"
  ["/usr/local/bin/nox-setup-home"]="0:0:755"
  ["/usr/local/bin/nox-wifi"]="0:0:755"
  ["/usr/local/bin/nox-tune"]="0:0:755"
  ["/usr/local/bin/nox-info"]="0:0:755"
  ["/usr/local/bin/nox-displays"]="0:0:755"
)
