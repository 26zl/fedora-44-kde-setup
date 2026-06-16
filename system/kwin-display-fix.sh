#!/bin/bash
# Bus 3 (0000:13:00.0) requires all devices autosuspended before xHCI can enter D3.
# LAMZU dongle (373e:001e) fails autosuspend with -110 (RF receiver must stay active),
# so we deauthorize it before sleep and re-authorize after. Other input devices get
# power/control=auto. All restored on post-resume.
AUTOSUSPEND_DEVS="048d:5711 046d:c548"
DEAUTH_DEVS="373e:001e"

find_dev() {
    local vid="${1%%:*}" pid="${1##*:}"
    for dev in /sys/bus/usb/devices/*/; do
        [ "$(cat "$dev/idVendor" 2>/dev/null)" = "$vid" ] && \
        [ "$(cat "$dev/idProduct" 2>/dev/null)" = "$pid" ] && \
        echo "$dev" && return
    done
}

if [ "$1" = "pre" ]; then
    for vid_pid in $AUTOSUSPEND_DEVS; do
        dev=$(find_dev "$vid_pid")
        [ -n "$dev" ] && echo 0 > "$dev/power/autosuspend_delay_ms" 2>/dev/null
        [ -n "$dev" ] && echo auto > "$dev/power/control" 2>/dev/null
    done
    for vid_pid in $DEAUTH_DEVS; do
        dev=$(find_dev "$vid_pid")
        [ -n "$dev" ] && echo 0 > "${dev}authorized" 2>/dev/null
    done
    sleep 0.5
fi

if [ "$1" = "post" ]; then
    for vid_pid in $AUTOSUSPEND_DEVS; do
        dev=$(find_dev "$vid_pid")
        [ -n "$dev" ] && echo on > "$dev/power/control" 2>/dev/null
    done
    for vid_pid in $DEAUTH_DEVS; do
        dev=$(find_dev "$vid_pid")
        [ -n "$dev" ] && echo 1 > "${dev}authorized" 2>/dev/null
    done

    sleep 4
    ACTIVE_USER=$(loginctl list-sessions --no-legend | awk '{print $3}' | head -1)
    USER_ID=$(id -u "$ACTIVE_USER" 2>/dev/null || echo 1000)
    DBUS="unix:path=/run/user/${USER_ID}/bus"
    WAYLAND="wayland-0"

    su -c "DBUS_SESSION_BUS_ADDRESS=${DBUS} WAYLAND_DISPLAY=${WAYLAND} /usr/bin/kscreen-doctor \
        output.1.enable output.2.enable" "$ACTIVE_USER" 2>/dev/null || true

    sleep 1
    su -c "DBUS_SESSION_BUS_ADDRESS=${DBUS} dbus-send \
        --session --dest=org.kde.KWin \
        --type=method_call /KWin org.kde.KWin.reconfigure" "$ACTIVE_USER" 2>/dev/null || true
fi
