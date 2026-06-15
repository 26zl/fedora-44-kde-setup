#!/bin/bash
# Run after resume — gives KWin time to reconfigure display outputs
if [ "$1" = "post" ]; then
    sleep 3
    ACTIVE_USER=$(loginctl list-sessions --no-legend | awk '{print $3}' | head -1)
    USER_ID=$(id -u "$ACTIVE_USER" 2>/dev/null || echo 1000)
    DBUS="unix:path=/run/user/${USER_ID}/bus"
    su -c "DBUS_SESSION_BUS_ADDRESS=${DBUS} dbus-send \
        --session --dest=org.kde.KWin \
        --type=method_call /KWin org.kde.KWin.reconfigure" "$ACTIVE_USER" 2>/dev/null || true
fi
