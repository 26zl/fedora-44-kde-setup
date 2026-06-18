#!/bin/bash
# Fedora 44 KDE — Ryzen 9 9900X, RTX 5070, dual-boot Windows 11 Pro
# Run as regular user — sudo is called where needed

set -e
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
sudo dnf swap -y glibc-all-langpacks glibc-langpack-en
sudo cp system/macros.image-language-conf /etc/rpm/macros.image-language-conf
sudo find /usr/share/locale -maxdepth 1 -mindepth 1 -type d ! -name 'en*' ! -name 'C' ! -name 'POSIX' -exec rm -rf {} +
ok "glibc-all-langpacks replaced with glibc-langpack-en, non-English locales removed"

section "RPM Fusion"
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf groupupdate -y core
ok "RPM Fusion free + nonfree installed"

section "NVIDIA drivers"
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-vaapi-driver
ok "NVIDIA akmod drivers installed"

sudo cp system/nvidia-wayland.conf /etc/environment.d/nvidia-wayland.conf
sudo cp system/nvidia-performance.conf /etc/modprobe.d/nvidia-performance.conf
sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume.service
ok "NVIDIA Wayland environment configured, suspend/resume services enabled"

section "Kernel / sysctl tweaks"
sudo cp system/99-tweaks.conf /etc/sysctl.d/99-tweaks.conf
sudo sysctl --system -q
sudo cp system/hugepages.conf /etc/tmpfiles.d/hugepages.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/hugepages.conf
ok "sysctl tweaks applied, transparent hugepages configured"

section "Kernel parameters"
sudo grubby --update-kernel=ALL --args="nowatchdog audit=0 skew_tick=1 workqueue.power_efficient=false"
ok "Kernel parameters added (nowatchdog, audit=0, skew_tick=1, workqueue.power_efficient=false) — takes effect on next boot"

section "ZRAM"
sudo dnf install -y zram-generator
sudo cp system/zram-generator.conf /etc/systemd/zram-generator.conf
ok "ZRAM 8GB configured"

section "CPU temperature sensor"
sudo dnf install -y lm_sensors
sudo cp system/k10temp.conf /etc/modules-load.d/k10temp.conf
sudo modprobe k10temp
ok "k10temp loaded and persistent"

section "Firewall hardening"
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=mdns 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/udp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/tcp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=dhcpv6-client
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect
sudo firewall-cmd --reload
ok "Firewall hardened (dhcpv6-client, kdeconnect only)"

section "DNS hardening (Quad9 + DNSSEC + DoT)"
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo cp system/resolved-hardening.conf /etc/systemd/resolved.conf.d/hardening.conf
sudo systemctl restart systemd-resolved
ok "Quad9 DNS, DNSSEC=allow-downgrade, DNSOverTLS=opportunistic"

section "Dual-boot RTC fix"
sudo timedatectl set-local-rtc 0
ok "RTC set to UTC (Windows must use UTC too)"

section "System tools"
sudo dnf install -y \
    steam \
    gamemode \
    mangohud \
    htop \
    btop \
    wl-clipboard \
    kvantum \
    conky \
    tuned \
    scx-scheds
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
    eza

# fish runs inside kitty (not as login shell — keeps KDE session stable)
ok "fish installed (used as kitty shell, not login shell)"

# Starship
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

# Yazi (prebuilt binary)
YAZI_VER=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep tag_name | cut -d'"' -f4)
curl -sL "https://github.com/sxyazi/yazi/releases/download/${YAZI_VER}/yazi-x86_64-unknown-linux-gnu.zip" -o /tmp/yazi.zip
unzip -q /tmp/yazi.zip -d /tmp/yazi-bin
sudo install -m755 /tmp/yazi-bin/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi
ok "Yazi installed"

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
curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
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

section "NTSync (Wine/Proton CPU optimization)"
sudo cp system/ntsync.conf /etc/modules-load.d/ntsync.conf
sudo cp system/99-ntsync.rules /etc/udev/rules.d/99-ntsync.rules
sudo udevadm control --reload-rules
sudo modprobe ntsync
ok "NTSync enabled — Proton uses it automatically"

section "Gamescope"
sudo dnf install -y gamescope
sudo setcap cap_sys_nice+ep "$(which gamescope)"
ok "Gamescope installed, CAP_SYS_NICE granted (--rt works)"

section "SCX scheduler (gaming)"
sudo systemctl enable --now scx_loader.service
sudo cp system/scx_loader.toml /etc/scx_loader/config.toml
ok "scx_lavd Gaming mode enabled"

section "tuned performance profile"
sudo systemctl enable --now tuned
sudo cp system/tuned-ppd.conf /etc/tuned/ppd.conf
sudo tuned-adm profile latency-performance
ok "tuned: latency-performance (PPD performance mapped to latency-performance)"

section "Disable ABRT crash reporters"
sudo systemctl disable --now abrtd abrt-oops abrt-xorg abrt-journal-core 2>/dev/null || true
ok "ABRT disabled (reduces background CPU/RAM usage)"

section "KWin latency"
kwriteconfig6 --file kwinrc --group Compositing --key LatencyPolicy ExtremelyLow
kwriteconfig6 --file kwinrc --group Compositing --key MaxFPS 165
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
ok "KWin: ExtremelyLow latency, 165Hz max, blur enabled"

section "Lock screen wallpaper"
kwriteconfig6 --file kscreenlockerrc \
  --group "Greeter" --group "Wallpaper" --group "org.kde.image" --group "General" \
  --key "Image" "file://${HOME}/Pictures/wallpaper.jpg"
ok "Lock screen wallpaper set"

section "Snapper (BTRFS snapshots)"
sudo dnf install -y snapper btrfs-assistant
if ! snapper list-configs | grep -q "^root"; then
    sudo snapper -c root create-config /
fi
if ! snapper list-configs | grep -q "^home"; then
    sudo snapper -c home create-config /home
fi
sudo snapper -c root create --description "Initial clean setup" --cleanup-algorithm number
sudo snapper -c home create --description "Initial home snapshot" --cleanup-algorithm number
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
ok "Snapper installed — root + home snapshots taken, timeline enabled"

section "Audio (WirePlumber)"
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cp configs/wireplumber/wireplumber.conf.d/50-audio.conf \
    ~/.config/wireplumber/wireplumber.conf.d/50-audio.conf
systemctl --user restart wireplumber
ok "WirePlumber: unused audio devices disabled, NVIDIA HDMI pro-audio configured"

section "LAMZU mouse udev rules"
sudo cp system/99-lamzu.rules /etc/udev/rules.d/99-lamzu.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
ok "LAMZU Maya X 8K: udev rules installed — configure via lamzu.net in Chrome"

section "libinput debounce"
sudo mkdir -p /etc/libinput
sudo cp system/libinput-overrides.quirks /etc/libinput/local-overrides.quirks
ok "libinput eager debouncing disabled (Hall Effect sensor — no debounce needed)"

section "Suspend / resume fixes"
sudo cp system/99-disable-wakeup.rules /etc/udev/rules.d/99-disable-wakeup.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo cp system/kwin-display-fix.sh /usr/lib/systemd/system-sleep/kwin-display-fix.sh
sudo chmod +x /usr/lib/systemd/system-sleep/kwin-display-fix.sh
sudo cp system/usb-autosuspend.service /etc/systemd/system/usb-autosuspend.service
sudo systemctl daemon-reload
sudo systemctl enable --now usb-autosuspend.service
ok "USB wakeup disabled, USB autosuspend service enabled, KWin display resume hook installed"

section "plasmalogin restart on failure (NVIDIA logout fix)"
sudo mkdir -p /etc/systemd/system/plasmalogin.service.d
sudo cp system/plasmalogin-restart.conf /etc/systemd/system/plasmalogin.service.d/restart.conf
sudo systemctl daemon-reload
ok "plasmalogin restarts automatically on NVIDIA Wayland logout crash"

section "Login screen wallpaper"
sudo mkdir -p /usr/share/wallpapers/custom
sudo cp wallpaper/wallpaper.jpg /usr/share/wallpapers/custom/wallpaper.jpg
sudo cp system/plasmalogin.conf /etc/plasmalogin.conf
ok "Login screen wallpaper set"


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
cp -r configs/kde/plasma-theme/darth-vader ~/.local/share/plasma/desktoptheme/
cp configs/fish/config.fish ~/.config/fish/config.fish
cp configs/fish/functions/ya.fish ~/.config/fish/functions/ya.fish
cp wallpaper/wallpaper.jpg ~/Pictures/wallpaper.jpg
ok "User configs written"

cp scripts/rice-start.sh scripts/sysinfo.sh ~/scripts/
chmod +x ~/scripts/rice-start.sh ~/scripts/sysinfo.sh
ok "Scripts installed to ~/scripts/"


# bashrc — ble.sh must load at the very top (before other config)
if ! grep -q 'blesh/ble.sh' ~/.bashrc; then
    sed -i '1s|^|[[ $- == *i* ]] \&\& source ~/.local/share/blesh/ble.sh --noattach\n\n|' ~/.bashrc
    ok "$HOME/.bashrc: ble.sh --noattach added at top"
fi

# bashrc additions
if ! grep -q 'zoxide init' ~/.bashrc; then
cat >> ~/.bashrc <<'EOF'

eval "$(zoxide init bash)"

# lazygit
alias lg='lazygit'

# yazi — cd into directory on exit
ya() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# mise — runtime version manager
eval "$(~/.local/bin/mise activate bash 2>/dev/null)" || true

# Starship prompt
eval "$(starship init bash)"

[[ ${BLE_VERSION-} ]] && ble-attach
EOF
    ok "$HOME/.bashrc updated"
fi

cp configs/systemd/conky.service ~/.config/systemd/user/conky.service
systemctl --user daemon-reload
systemctl --user enable --now conky.service
ok "Conky systemd user service installed and enabled"

section "Setup complete"
warn "Manual steps required after reboot:"
echo "  1. Enroll Secure Boot MOK key: sudo mokutil --import /etc/pki/akmods/certs/public_key.der"
echo "     → Select 'Enroll MOK' at the blue MOK Manager screen on reboot"
echo "  2. Wait ~5 min for NVIDIA kernel module to build, then: sudo akmods --force && sudo dracut --force"
echo "  3. KDE Settings → Colors → DarthVader → Apply"
echo "  4. KDE Settings → Application Style → kvantum → Apply"
echo "  5. KDE Settings → Fonts → Fixed width → JetBrainsMono Nerd Font"
echo "  6. KDE Settings → Wallpaper → ~/Pictures/wallpaper.jpg"
echo "  7. Start Conky: conky --daemonize --pause=3 --config=~/.config/conky/conky.conf"
echo ""
ok "Reboot recommended."
