# shellcheck shell=sh
# Nox OS - start the graphical session automatically on tty1.
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(id -u)" -eq 1000 ]; then
    if grep -q nomodeset /proc/cmdline; then
        echo "Mode sans echec : pas de session graphique. Outils : nox-info, nox-wifi, nox-setup-home"
    else
        # Wayland compositors need the per-user runtime dir created by systemd-logind
        export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        export XDG_SESSION_TYPE=wayland
        # Hybrid laptops: draw the desktop on the GPU wired to the screen (usually Intel),
        # the NVIDIA GPU is used for games through nox-run (PRIME offload).
        for connector_status in /sys/class/drm/card*-*/status; do
            if [ "$(cat "$connector_status" 2>/dev/null)" = "connected" ]; then
                display_card="$(basename "$(dirname "$connector_status")")"
                export WLR_DRM_DEVICES="/dev/dri/${display_card%%-*}"
                break
            fi
        done
        echo "Demarrage de la session graphique (GPU ecran : ${WLR_DRM_DEVICES:-auto})..."
        labwc > /tmp/labwc.log 2>&1
        labwc_status=$?
        if [ "$labwc_status" -ne 0 ]; then
            echo
            echo "=== La session graphique a echoue (code $labwc_status). Fin du journal : ==="
            tail -n 25 /tmp/labwc.log
            echo "=== Journal complet : /tmp/labwc.log | relancer : labwc ==="
        fi
    fi
fi
