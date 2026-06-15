#!/bin/bash
# Deploy all system/ files from repo to live system.
# Run from the repo root: bash scripts/apply-system.sh

set -e
TEAL='\033[38;2;0;200;168m'
RED='\033[38;2;170;28;28m'
RESET='\033[0m'

ok()      { echo -e "  ${TEAL}✓${RESET} $1"; }
warn()    { echo -e "  ${RED}!${RESET} $1"; }
section() { echo -e "\n${TEAL}━━━ $1 ━━━${RESET}"; }

section "NVIDIA"
sudo cp system/nvidia-performance.conf /etc/modprobe.d/nvidia-performance.conf
sudo cp system/nvidia-wayland.conf /etc/environment.d/nvidia-wayland.conf
sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume.service
ok "nvidia-performance.conf, nvidia-wayland.conf, suspend/resume services enabled"

section "sysctl / DNF / ZRAM"
sudo cp system/99-tweaks.conf /etc/sysctl.d/99-tweaks.conf
sudo sysctl --system -q
sudo cp system/dnf.conf /etc/dnf/dnf.conf
sudo cp system/macros.image-language-conf /etc/rpm/macros.image-language-conf
sudo cp system/zram-generator.conf /etc/systemd/zram-generator.conf
sudo cp system/k10temp.conf /etc/modules-load.d/k10temp.conf
sudo cp system/hugepages.conf /etc/tmpfiles.d/hugepages.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/hugepages.conf
ok "99-tweaks.conf, dnf.conf, macros.image-language-conf, zram-generator.conf, k10temp.conf, hugepages.conf"

section "Kernel parameters"
sudo grubby --update-kernel=ALL --remove-args="nowatchdog audit=0 skew_tick=1 workqueue.power_efficient=false" 2>/dev/null || true
sudo grubby --update-kernel=ALL --args="nowatchdog audit=0 skew_tick=1 workqueue.power_efficient=false"
ok "Kernel parameters set (takes effect on next boot)"

section "SCX scheduler"
sudo cp system/scx_loader.toml /etc/scx_loader/config.toml
ok "scx_loader.toml"

section "tuned"
sudo cp system/tuned-ppd.conf /etc/tuned/ppd.conf
sudo tuned-adm profile latency-performance
ok "tuned: PPD performance mapped to latency-performance"

section "udev rules"
sudo cp system/99-lamzu.rules /etc/udev/rules.d/99-lamzu.rules
sudo cp system/99-disable-wakeup.rules /etc/udev/rules.d/99-disable-wakeup.rules
sudo cp system/99-usb-autosuspend.rules /etc/udev/rules.d/99-usb-autosuspend.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
ok "99-lamzu.rules, 99-disable-wakeup.rules, 99-usb-autosuspend.rules"

section "Suspend / resume"
sudo cp system/kwin-display-fix.sh /usr/lib/systemd/system-sleep/kwin-display-fix.sh
sudo chmod +x /usr/lib/systemd/system-sleep/kwin-display-fix.sh
ok "kwin-display-fix.sh"

section "DNS hardening"
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo cp system/resolved-hardening.conf /etc/systemd/resolved.conf.d/hardening.conf
sudo systemctl restart systemd-resolved
ok "resolved-hardening.conf (Quad9, DNSSEC, DoT)"

section "plasmalogin restart fix"
sudo mkdir -p /etc/systemd/system/plasmalogin.service.d
sudo cp system/plasmalogin-restart.conf /etc/systemd/system/plasmalogin.service.d/restart.conf
sudo systemctl daemon-reload
ok "plasmalogin-restart.conf"

section "plasmalogin wallpaper"
sudo mkdir -p /usr/share/wallpapers/custom
sudo cp wallpaper/wallpaper.jpg /usr/share/wallpapers/custom/wallpaper.jpg
sudo cp system/plasmalogin.conf /etc/plasmalogin.conf
ok "Login screen wallpaper set"

section "libinput debounce"
sudo mkdir -p /etc/libinput
sudo cp system/libinput-overrides.quirks /etc/libinput/local-overrides.quirks
ok "libinput-overrides.quirks"

section "NTSync"
sudo cp system/ntsync.conf /etc/modules-load.d/ntsync.conf
sudo cp system/99-ntsync.rules /etc/udev/rules.d/99-ntsync.rules
sudo udevadm control --reload-rules
sudo modprobe ntsync 2>/dev/null || true
ok "99-ntsync.rules, ntsync.conf"

section "Done"
ok "All system files deployed. Reboot recommended if modprobe/zram configs changed."
