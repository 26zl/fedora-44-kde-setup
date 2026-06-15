#!/bin/bash
# Post-resume hook: re-enables displays after amdgpu LTTPR DP link re-init
# on the USB-C output (DP-1) drops the connector briefly on every resume.
if [ "$1" = "post" ]; then
    sleep 4
    ACTIVE_USER=$(loginctl list-sessions --no-legend | awk '{print $3}' | head -1)
    USER_ID=$(id -u "$ACTIVE_USER" 2>/dev/null || echo 1000)
    DBUS="unix:path=/run/user/${USER_ID}/bus"

    # Re-enable all outputs — kscreen-doctor handles outputs that briefly
    # disappeared during LTTPR re-training without affecting already-active ones
    su -c "DBUS_SESSION_BUS_ADDRESS=${DBUS} /usr/bin/kscreen-doctor \
        output.1.enable output.2.enable" "$ACTIVE_USER" 2>/dev/null || true

    sleep 1
    su -c "DBUS_SESSION_BUS_ADDRESS=${DBUS} dbus-send \
        --session --dest=org.kde.KWin \
        --type=method_call /KWin org.kde.KWin.reconfigure" "$ACTIVE_USER" 2>/dev/null || true
fi
