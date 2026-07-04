#!/bin/bash
# Rice starter — restarts the Conky user service

systemctl --user restart conky.service
echo "Rice is live."
