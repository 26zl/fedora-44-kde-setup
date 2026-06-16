#!/bin/bash
# Bus 3 (0000:13:00.0) requires all devices autosuspended before xHCI can enter D3.
# Input devices stay on=on during normal use; we flip them to auto immediately
# before S3 so the root hub can suspend, then restore on after resume.
INPUT_DEVS="373e:001e 048d:5711 046d:c548"

usb_set_power() {
    local mode="$1"
    for vid_pid in $INPUT_DEVS; do
        local vid="${vid_pid%%:*}" pid="${vid_pid##*:}"
        for dev in /sys/bus/usb/devices/*/; do
            if [ "$(cat "$dev/idVendor" 2>/dev/null)" = "$vid" ] && \
               [ "$(cat "$dev/idProduct" 2>/dev/null)" = "$pid" ]; then
                [ "$mode" = "auto" ] && echo 0 > "$dev/power/autosuspend_delay_ms" 2>/dev/null
                echo "$mode" > "$dev/power/control" 2>/dev/null
            fi
        done
    done
}

if [ "$1" = "pre" ]; then
    usb_set_power auto
    sleep 0.5
fi

if [ "$1" = "post" ]; then
    usb_set_power on

    sleep 4
    ACTIVE_USER=$(loginctl list-sessions --no-legend | awk '{print $3}' | head -1)
    USER_ID=$(id -u "$ACTIVE_USER" 2>/dev/null || echo 1000)
    DBUS="unix:path=/run/user/${USER_ID}/bus"

    su -c "DBUS_SESSION_BUS_ADDRESS=${DBUS} /usr/bin/kscreen-doctor \
        output.1.enable output.2.enable" "$ACTIVE_USER" 2>/dev/null || true

    sleep 1
    su -c "DBUS_SESSION_BUS_ADDRESS=${DBUS} dbus-send \
        --session --dest=org.kde.KWin \
        --type=method_call /KWin org.kde.KWin.reconfigure" "$ACTIVE_USER" 2>/dev/null || true
fi
