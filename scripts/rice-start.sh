#!/bin/bash
# Rice starter — restarts Conky

pkill conky 2>/dev/null
sleep 1

conky --daemonize --pause=3 --config="$HOME/.config/conky/conky.conf"
echo "Rice is live."
