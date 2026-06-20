#!/bin/bash
# Retro emulation: ES-DE frontend + standalone emulators (PS1/PS2/PS3, Wii).
# Run from the repo root: bash scripts/emulation-setup.sh
# BIOS, firmware and ROMs are user-provided — see the manual steps at the end.

set -e
TEAL='\033[38;2;0;200;168m'
RED='\033[38;2;170;28;28m'
RESET='\033[0m'

ok()      { echo -e "  ${TEAL}✓${RESET} $1"; }
warn()    { echo -e "  ${RED}!${RESET} $1"; }
section() { echo -e "\n${TEAL}━━━ $1 ━━━${RESET}"; }

section "ES-DE frontend (Terra repo)"
sudo dnf install -y \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
    --setopt='terra.gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc' \
    terra-release
sudo dnf install -y emulationstation-de
ok "ES-DE installed"

section "Emulators (Flatpak)"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    net.pcsx2.PCSX2 \
    org.duckstation.DuckStation \
    net.rpcs3.RPCS3 \
    org.DolphinEmu.dolphin-emu \
    org.libretro.RetroArch
ok "PCSX2 (PS2), DuckStation (PS1), RPCS3 (PS3), Dolphin (Wii), RetroArch (SNES/N64)"
warn "DuckStation's Flathub build is end-of-life. It still works; for the"
warn "maintained version use the official AppImage in ~/Applications/ instead."

section "Flatpak ROM access"
# Default ROM root is ~/Emulation. If ROMs live on another disk, also grant
# that path, e.g. flatpak override --user --filesystem=/mnt/data <app>
for app in net.pcsx2.PCSX2 org.duckstation.DuckStation net.rpcs3.RPCS3 \
           org.libretro.RetroArch org.DolphinEmu.dolphin-emu; do
    flatpak override --user --filesystem="$HOME/Emulation" "$app"
done
ok "Emulators granted access to ~/Emulation"

section "ES-DE default emulators (standalone, not libretro)"
mkdir -p "$HOME/ES-DE/custom_systems"
cp configs/es-de/es_systems.xml "$HOME/ES-DE/custom_systems/es_systems.xml"
ok "custom_systems/es_systems.xml: psx/ps2/ps3/wii default to standalone"

section "Emulation setup complete"
warn "Manual steps (BIOS/firmware/ROMs are user-provided, not shipped):"
echo "  1. ROMs   → ~/Emulation/roms/<system>/  (psx, ps2, ps3, snes, n64, wii)"
echo "  2. PS1/PS2 BIOS → each emulator's bios folder under ~/.var/app/<id>/"
echo "  3. PS3 firmware → RPCS3 → File → Install Firmware (PS3UPDAT.PUP from Sony)"
echo "  4. SNES/N64 cores → RetroArch → Online Updater → Update Installed Cores"
echo "                      (snes9x, Mupen64Plus-Next)"
echo "  5. Controller → each emulator has its OWN mapping (PCSX2/DuckStation:"
echo "     Settings → Controllers → Automatic Mapping; Dolphin: Wii Remote 1"
echo "     → Emulated Wii Remote → Configure)"
echo ""
ok "Launch ES-DE and set the ROM directory to ~/Emulation/roms"
