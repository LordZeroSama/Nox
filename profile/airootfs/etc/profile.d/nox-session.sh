# shellcheck shell=sh
# Nox OS - start the graphical session automatically on tty1.
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(id -u)" -eq 1000 ]; then
    if grep -q nomodeset /proc/cmdline; then
        echo "Mode sans echec : pas de session graphique. Outils : nox-info, nox-wifi, nox-setup-home"
    else
        exec labwc > /tmp/labwc.log 2>&1
    fi
fi
