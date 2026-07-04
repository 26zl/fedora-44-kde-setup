#!/bin/bash
# Fedora 44 KDE — Ryzen 9 9900X, RTX 5070, dual-boot Windows 11 Pro
# Run as regular user — sudo is called where needed

set -e
cd "$(dirname "$0")/.."

TEAL='\033[38;2;0;200;168m'
RED='\033[38;2;170;28;28m'
RESET='\033[0m'

ok()   { echo -e "  ${TEAL}✓${RESET} $1"; }
info() { echo -e "  ${TEAL}→${RESET} $1"; }
warn() { echo -e "  ${RED}!${RESET} $1"; }
section() { echo -e "\n${TEAL}━━━ $1 ━━━${RESET}"; }

section "DNF configuration"
sudo cp system/dnf.conf /etc/dnf/dnf.conf
ok "DNF configured (max 2 kernels, parallel downloads)"

section "Locale debloat"
if rpm -q glibc-all-langpacks &>/dev/null; then
    sudo dnf swap -y glibc-all-langpacks glibc-langpack-en
    ok "glibc-all-langpacks replaced with glibc-langpack-en"
else
    ok "glibc-langpack-en already in place"
fi
sudo cp system/macros.image-language-conf /etc/rpm/macros.image-language-conf
sudo find /usr/share/locale -maxdepth 1 -mindepth 1 -type d ! -name 'en*' ! -name 'C' ! -name 'POSIX' -exec rm -rf {} +
ok "Non-English locales removed, langpack macro set"

section "RPM Fusion"
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf group upgrade -y core
ok "RPM Fusion free + nonfree installed"

section "NVIDIA drivers"
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-vaapi-driver
ok "NVIDIA akmod drivers installed"

section "System tools"
sudo dnf install -y \
    steam \
    gamemode \
    mangohud \
    gamescope \
    htop \
    btop \
    wl-clipboard \
    kvantum \
    conky \
    tuned \
    scx-scheds \
    zram-generator \
    lm_sensors \
    snapper \
    btrfs-assistant
ok "System tools installed"

section "Terminal tools"
sudo dnf install -y \
    kitty \
    fish \
    zoxide \
    lazygit \
    fzf \
    ripgrep \
    fd-find \
    bat \
    eza \
    git-delta

# fish runs inside kitty (not as login shell — keeps KDE session stable)
ok "fish installed (used as kitty shell, not login shell)"

# Starship — not packaged in Fedora, use the official installer
if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ok "Starship installed"
else
    ok "Starship already installed"
fi

# mise
if ! command -v mise &>/dev/null; then
    curl https://mise.run | sh
    ok "mise installed"
else
    ok "mise already installed"
fi

# Yazi — prebuilt binary; latest/download URL needs no GitHub API call
if ! command -v yazi &>/dev/null; then
    curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip" \
        -o /tmp/yazi.zip
    unzip -qo /tmp/yazi.zip -d /tmp/yazi-bin
    sudo install -m755 /tmp/yazi-bin/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi
    rm -rf /tmp/yazi.zip /tmp/yazi-bin
    ok "Yazi installed"
else
    ok "Yazi already installed"
fi

# ble.sh — bash syntax highlighting
if [[ ! -f ~/.local/share/blesh/ble.sh ]]; then
    git clone --recursive --depth 1 --shallow-submodules \
        https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
    make -C /tmp/ble.sh install PREFIX=~/.local
    rm -rf /tmp/ble.sh
    ok "ble.sh installed"
else
    ok "ble.sh already installed"
fi

# JetBrainsMono Nerd Font
mkdir -p ~/.local/share/fonts/JetBrainsMono
curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
    -o /tmp/JetBrainsMono.tar.xz
tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts/JetBrainsMono/
fc-cache -fv -q
ok "JetBrainsMono Nerd Font installed"

section "Flatpak (gaming)"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    net.davidotek.pupgui2 \
    com.heroicgameslauncher.hgl \
    net.lutris.Lutris \
    com.usebottles.bottles \
    org.prismlauncher.PrismLauncher \
    io.github.benjamimgois.goverlay \
    com.github.wwmm.easyeffects
ok "ProtonUp-Qt, Heroic, Lutris, Bottles, Prism, GOverlay, EasyEffects installed"

section "tuned"
sudo systemctl enable --now tuned
ok "tuned enabled (profile is set by apply-system.sh)"

section "System configs (scripts/apply-system.sh)"
bash scripts/apply-system.sh
ok "System files deployed via apply-system.sh"

section "SCX scheduler (gaming)"
sudo systemctl enable --now scx_loader.service
ok "scx_lavd Gaming mode enabled (config deployed by apply-system.sh)"

section "Gamescope capabilities"
sudo setcap cap_sys_nice+ep "$(command -v gamescope)"
ok "Gamescope granted CAP_SYS_NICE (--rt works)"

section "Firewall hardening"
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=mdns 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=ssh 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=samba-client 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/udp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/tcp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=dhcpv6-client
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect
sudo firewall-cmd --reload
ok "Firewall hardened (dhcpv6-client + kdeconnect only; ssh, samba-client, mdns removed)"

section "Dual-boot (RTC + GRUB default)"
sudo timedatectl set-local-rtc 0
# GRUB re-picks the last-booted OS after a Windows hibernate wake; GRUB_SAVEDEFAULT requires GRUB_DEFAULT=saved
grub_changed=0
if ! grep -q '^GRUB_DEFAULT=saved' /etc/default/grub; then
    if grep -q '^GRUB_DEFAULT=' /etc/default/grub; then
        sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
    else
        echo 'GRUB_DEFAULT=saved' | sudo tee -a /etc/default/grub >/dev/null
    fi
    grub_changed=1
fi
if ! grep -q '^GRUB_SAVEDEFAULT=true' /etc/default/grub; then
    echo 'GRUB_SAVEDEFAULT=true' | sudo tee -a /etc/default/grub >/dev/null
    grub_changed=1
fi
if [[ $grub_changed -eq 1 ]]; then
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
fi
ok "RTC set to UTC (Windows must use UTC too); GRUB remembers last-booted OS"

section "Disable ABRT crash reporters"
sudo systemctl disable --now abrtd abrt-oops abrt-xorg abrt-journal-core 2>/dev/null || true
ok "ABRT disabled (reduces background CPU/RAM usage)"

section "KWin latency"
kwriteconfig6 --file kwinrc --group Compositing --key LatencyPolicy ExtremelyLow
kwriteconfig6 --file kwinrc --group Compositing --key MaxFPS 165
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
# KWin's gamepad->keyboard desktop navigation hijacks controllers in games/emulators
kwriteconfig6 --file kwinrc --group Plugins --key gamecontrollerEnabled false
ok "KWin: ExtremelyLow latency, 165Hz max, blur enabled, gamepad-nav disabled"

section "Lock screen wallpaper"
kwriteconfig6 --file kscreenlockerrc \
  --group "Greeter" --group "Wallpaper" --group "org.kde.image" --group "General" \
  --key "Image" "file://${HOME}/Pictures/wallpaper.jpg"
ok "Lock screen wallpaper set"

section "Snapper (BTRFS snapshots)"
# guards need sudo — a plain user can't see root's snapper configs
if ! sudo snapper list-configs | grep -q "^root"; then
    sudo snapper -c root create-config / || warn "root config not created (subvolume already covered?)"
fi
if ! sudo snapper list-configs | grep -q "^home"; then
    sudo snapper -c home create-config /home || warn "home config not created (subvolume already covered?)"
fi
if ! sudo snapper -c root list 2>/dev/null | grep -q "Initial clean setup"; then
    sudo snapper -c root create --description "Initial clean setup" --cleanup-algorithm number || warn "root snapshot failed"
fi
if ! sudo snapper -c home list 2>/dev/null | grep -q "Initial home snapshot"; then
    sudo snapper -c home create --description "Initial home snapshot" --cleanup-algorithm number || warn "home snapshot failed"
fi
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
ok "Snapper: root + home snapshots, timeline enabled"

section "Audio (WirePlumber)"
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cp configs/wireplumber/wireplumber.conf.d/50-audio.conf \
    ~/.config/wireplumber/wireplumber.conf.d/50-audio.conf
systemctl --user restart wireplumber
ok "WirePlumber: unused audio devices disabled, NVIDIA HDMI pro-audio configured"

section "Writing user configs"
mkdir -p ~/.config/kitty ~/.config/conky \
         ~/.config/Kvantum ~/.local/share/color-schemes \
         ~/scripts ~/Pictures ~/.config/fish/functions \
         ~/.local/share/plasma/desktoptheme \
         ~/.config/systemd/user

cp configs/kitty/kitty.conf ~/.config/kitty/kitty.conf
cp configs/starship/starship.toml ~/.config/starship.toml
cp configs/conky/conky.conf ~/.config/conky/conky.conf
cp configs/kde/DarthVader.colors ~/.local/share/color-schemes/DarthVader.colors
cp configs/kde/kvantum/kvantum.kvconfig ~/.config/Kvantum/kvantum.kvconfig
cp -rT configs/kde/plasma-theme ~/.local/share/plasma/desktoptheme/darth-vader
cp configs/fish/config.fish ~/.config/fish/config.fish
cp configs/fish/functions/ya.fish ~/.config/fish/functions/ya.fish
cp wallpaper/wallpaper.jpg ~/Pictures/wallpaper.jpg
ok "User configs written"

cp scripts/rice-start.sh scripts/sysinfo.sh ~/scripts/
chmod +x ~/scripts/rice-start.sh ~/scripts/sysinfo.sh
ok "Scripts installed to ~/scripts/"

# ble.sh requires --noattach first and ble-attach last; configs/bashrc goes in between
if ! grep -q 'blesh/ble.sh' ~/.bashrc; then
    sed -i '1s|^|[[ $- == *i* ]] \&\& source ~/.local/share/blesh/ble.sh --noattach\n\n|' ~/.bashrc
    ok "$HOME/.bashrc: ble.sh --noattach added at top"
fi
if ! grep -q 'zoxide init' ~/.bashrc; then
    # the ble-attach line must land in .bashrc unexpanded
    # shellcheck disable=SC2016
    { echo ""; cat configs/bashrc; echo ""; echo '[[ ${BLE_VERSION-} ]] && ble-attach'; } >> ~/.bashrc
    ok "$HOME/.bashrc: configs/bashrc appended, ble-attach added last"
fi

cp configs/systemd/conky.service ~/.config/systemd/user/conky.service
systemctl --user daemon-reload
systemctl --user enable --now conky.service
ok "Conky systemd user service installed and enabled"

section "Setup complete"
warn "Before rebooting (Secure Boot):"
echo "  1. Wait ~5 min for the NVIDIA kernel module to build, then:"
echo "       sudo akmods --force && sudo dracut --force"
echo "  2. Queue the MOK key: sudo mokutil --import /etc/pki/akmods/certs/public_key.der"
echo "     → reboot and pick 'Enroll MOK' at the blue MOK Manager screen"
echo ""
warn "After reboot:"
echo "  3. KDE Settings → Colors → DarthVader → Apply"
echo "  4. KDE Settings → Application Style → kvantum → Apply"
echo "  5. KDE Settings → Fonts → Fixed width → JetBrainsMono Nerd Font"
echo "  6. KDE Settings → Wallpaper → ~/Pictures/wallpaper.jpg"
echo ""
info "Conky runs as a systemd user service (systemctl --user status conky)"
info "For retro emulation (ES-DE + PS1/PS2/PS3/Wii): bash scripts/emulation-setup.sh"
ok "Reboot recommended."
