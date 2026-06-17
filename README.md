# Fedora 44 KDE — Full Setup Guide

[![ShellCheck](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/shellcheck.yml)
[![Secret Scan](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/secret-scan.yml/badge.svg)](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/secret-scan.yml)
[![Trivy](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/trivy.yml/badge.svg)](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/trivy.yml)
[![Validate](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/validate.yml/badge.svg)](https://github.com/26zl/fedora-44-kde-setup/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-teal.svg)](LICENSE)
[![Fedora](https://img.shields.io/badge/Fedora-44-blue?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-1d99f3?logo=kde&logoColor=white)](https://kde.org/)
[![Wayland](https://img.shields.io/badge/Wayland-native-orange?logo=wayland&logoColor=white)](https://wayland.freedesktop.org/)

Post-installation guide, config files, and scripts for Fedora 44 KDE Plasma 6 on Wayland. Focused on low-latency gaming and a clean rice.

**Hardware:**

- CPU: AMD Ryzen 9 9900X (Zen 5, 12-core)
- GPU: NVIDIA GeForce RTX 5070 (Blackwell, 12GB VRAM)
- RAM: 32GB DDR5
- Motherboard: Gigabyte X870E AORUS ELITE WIFI7
- Storage: NVMe SSD (KINGSTON SNV3S1000G, 1TB)
- Dual-boot: Windows 11 Pro

---

## Repository Structure

```text
├── configs/
│   ├── conky/conky.conf        # Desktop system stats widget
│   ├── fish/
│   │   ├── config.fish         # Fish shell config (aliases, zoxide, starship)
│   │   └── functions/ya.fish   # Yazi cd-on-exit wrapper
│   ├── kde/
│   │   ├── DarthVader.colors   # KDE color scheme (teal + red on black)
│   │   ├── kvantum/
│   │   │   └── kvantum.kvconfig # Kvantum theme config (LayanDark)
│   │   └── plasma-theme/
│   │       └── darth-vader/    # Custom Plasma desktop theme
│   ├── kitty/kitty.conf        # Terminal config — fish shell, Darth Vader palette
│   ├── starship/starship.toml  # Shell prompt
│   ├── wireplumber/
│   │   └── wireplumber.conf.d/
│   │       └── 50-audio.conf   # Disable unused ALSA nodes, NVIDIA HDMI pro-audio
│   ├── systemd/
│   │   └── conky.service       # ~/.config/systemd/user/ — Conky autostart service
│   └── bashrc                  # ~/.bashrc additions (ble.sh, zoxide, aliases)
├── system/
│   ├── nvidia-wayland.conf     # /etc/environment.d/ — NVIDIA Wayland env vars
│   ├── nvidia-performance.conf # /etc/modprobe.d/ — NVIDIA kernel options
│   ├── 99-tweaks.conf          # /etc/sysctl.d/ — performance tweaks
│   ├── dnf.conf                # /etc/dnf/ — DNF settings
│   ├── zram-generator.conf     # /etc/systemd/ — ZRAM 8GB
│   ├── k10temp.conf            # /etc/modules-load.d/ — CPU temp sensor
│   ├── scx_loader.toml         # /etc/scx_loader/ — scx_lavd Gaming mode
│   ├── resolved-hardening.conf # /etc/systemd/resolved.conf.d/ — Quad9, DNSSEC, DoT
│   ├── tuned-ppd.conf          # /etc/tuned/ppd.conf — PPD → tuned profile map
│   ├── macros.image-language-conf # /etc/rpm/ — limit langpacks to en_US
│   ├── ntsync.conf             # /etc/modules-load.d/ — load ntsync at boot
│   ├── 99-ntsync.rules         # /etc/udev/rules.d/ — ntsync user access
│   ├── 99-lamzu.rules          # /etc/udev/rules.d/ — LAMZU Maya X udev rules
│   ├── 99-disable-wakeup.rules # /etc/udev/rules.d/ — disable USB wakeup
│   ├── libinput-overrides.quirks # /etc/libinput/ — disable mouse debouncing
│   ├── hugepages.conf          # /etc/tmpfiles.d/ — transparent hugepages
│   ├── kwin-display-fix.sh     # /usr/lib/systemd/system-sleep/ — KWin resume hook
│   ├── plasmalogin.conf        # /etc/plasmalogin.conf — login screen wallpaper
│   └── plasmalogin-restart.conf # systemd drop-in — auto-restart plasmalogin on crash
├── scripts/
│   ├── fedora-setup.sh         # Full automated setup from scratch
│   ├── apply-system.sh         # Deploy system/ files to their system paths
│   ├── rice-start.sh           # Restart Conky
│   └── sysinfo.sh              # System health overview in terminal
└── wallpaper/
    └── wallpaper.jpg           # Darth Vader — dark, teal glow, red lightsaber
```

---

## Quick Setup (New Machine)

```bash
git clone https://github.com/26zl/fedora-44-kde-setup.git ~/fedora-setup
cd ~/fedora-setup
bash scripts/fedora-setup.sh
```

> The setup script handles everything except Secure Boot MOK enrollment and BIOS settings, which require manual steps on reboot.

---

## Step-by-Step Guide

### 1. System Update

```bash
sudo dnf upgrade --refresh -y
sudo dnf autoremove && sudo dnf clean all
sudo reboot
```

### 2. DNF Configuration

```bash
sudo cp system/dnf.conf /etc/dnf/dnf.conf
```

Key settings: `installonly_limit=2` (max 2 kernels), `max_parallel_downloads=10`, `fastestmirror=True`

### 3. RPM Fusion

```bash
sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf groupupdate -y core
```

### 4. NVIDIA Drivers + Secure Boot

**Install drivers:**

```bash
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-vaapi-driver
```

Wait ~5 minutes for akmods to build the kernel module, then:

```bash
sudo akmods --force
sudo dracut --force
```

**Apply NVIDIA configs:**

```bash
sudo cp system/nvidia-wayland.conf /etc/environment.d/nvidia-wayland.conf
sudo cp system/nvidia-performance.conf /etc/modprobe.d/nvidia-performance.conf
```

**Enable power management services:**

```bash
sudo systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate
```

**Enroll Secure Boot MOK key:**

```bash
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
sudo reboot
# Select "Enroll MOK" at the blue MOK Manager screen on reboot
```

**Verify after reboot:**

```bash
mokutil --sb-state           # Should show: SecureBoot enabled
lsmod | grep nvidia          # Should list nvidia, nvidia_drm, nvidia_modeset, nvidia_uvm
nvidia-smi                   # Should show your GPU
```

### 5. CPU Performance (AMD Ryzen amd-pstate-epp)

```bash
sudo dnf install -y tuned
sudo systemctl enable --now tuned
sudo cp system/tuned-ppd.conf /etc/tuned/ppd.conf
sudo tuned-adm profile latency-performance
```

The `tuned-ppd.conf` maps KDE's "Performance" power mode to `latency-performance` instead of the default `throughput-performance`, so the profile persists correctly at boot.

> **Note:** AMD Ryzen 9000X uses `amd-pstate-epp`. Only `performance` and `powersave` governors are valid — not `schedutil` or others.

### 6. SCX Scheduler (Gaming)

```bash
sudo dnf install -y scx-scheds
sudo systemctl enable --now scx_loader.service
sudo cp system/scx_loader.toml /etc/scx_loader/config.toml
```

`scx_lavd` in Gaming mode gives significantly better frame pacing and latency for games.

### 7. ZRAM

```bash
sudo dnf install -y zram-generator
sudo cp system/zram-generator.conf /etc/systemd/zram-generator.conf
sudo reboot
```

Verify: `lsblk | grep zram` — should show 8GB swap device.

### 8. sysctl Tweaks

```bash
sudo cp system/99-tweaks.conf /etc/sysctl.d/99-tweaks.conf
sudo sysctl --system
```

| Key | Value | Purpose |
| --- | --- | --- |
| `vm.swappiness` | `150` | Favour ZRAM over disk swap |
| `vm.max_map_count` | `2147483642` | Required for some games (Steam/Proton) |
| `net.core.rmem_max` | `16777216` | Better network throughput |
| `net.core.wmem_max` | `16777216` | Better network throughput |
| `vm.compaction_proactiveness` | `0` | Disable proactive memory compaction — reduces jitter |
| `vm.page_lock_unfairness` | `1` | Lower page lock contention |

Transparent hugepages are configured via `system/hugepages.conf` (deployed to `/etc/tmpfiles.d/`):

```bash
sudo cp system/hugepages.conf /etc/tmpfiles.d/hugepages.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/hugepages.conf
```

| Setting | Value | Purpose |
| --- | --- | --- |
| `transparent_hugepage/enabled` | `always` | Map memory in 2MB pages — fewer TLB misses |
| `transparent_hugepage/shmem_enabled` | `advise` | Hugepages for shared memory (wine/Proton) |
| `transparent_hugepage/khugepaged/defrag` | `0` | Disable background defrag — reduces jitter |

### 9. Kernel Parameters

```bash
sudo grubby --update-kernel=ALL --args="nowatchdog audit=0 skew_tick=1 workqueue.power_efficient=false"
```

| Parameter | Purpose |
| --- | --- |
| `nowatchdog` | Disable watchdog timers — reduces interrupts |
| `audit=0` | Disable audit framework — marginal overhead reduction (RHEL latency guide) |
| `skew_tick=1` | Skew timer ticks across cores — reduces lock contention |
| `workqueue.power_efficient=false` | Disable power-efficient workqueues — prevents cross-core cache misses |

Takes effect on next boot. Verify with `cat /proc/cmdline`.

### 10. CPU Temperature Sensor (k10temp)

```bash
sudo dnf install -y lm_sensors
sudo cp system/k10temp.conf /etc/modules-load.d/k10temp.conf
sudo modprobe k10temp
sensors | grep Tctl  # Verify
```

### 11. Firewall Hardening

Default FedoraWorkstation zone has ports 1025-65535 open. Harden to only what's needed:

```bash
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/udp
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/tcp
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=dhcpv6-client
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect
sudo firewall-cmd --reload
firewall-cmd --list-services  # Verify
```

### 12. Dual-Boot Clock Fix (Windows + Linux)

Make Windows read the hardware clock as UTC (prevents time drift on dual-boot):

Open PowerShell as Administrator on Windows:

```powershell
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f
```

### 13. Backup — Snapper (BTRFS Snapshots)

Fedora installs on BTRFS by default. Snapper integrates natively with Fedora's subvolume layout.

```bash
sudo dnf install -y snapper btrfs-assistant
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo snapper -c root create --description "Initial clean setup" --cleanup-algorithm number
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

> Note: Fedora often pre-configures snapper. If `create-config` returns "subvolume already covered", skip it and go straight to creating a snapshot.

**BTRFS Assistant** (GUI) is available in the app menu — shows all snapshots and allows one-click restore.

To list snapshots:

```bash
sudo snapper -c root list
```

To restore, boot from a live USB, mount the BTRFS partition, and use `btrfs subvolume` to swap snapshots — or use BTRFS Assistant.

### 14. Disable Unnecessary Services

```bash
# System services
sudo systemctl disable --now ModemManager avahi-daemon pcscd

# Baloo file indexer (major CPU offender)
balooctl6 disable
kwriteconfig6 --file baloofilerc --group "Basic Settings" --key "Indexing-Enabled" false

# KDE user services
systemctl --user disable --now \
  app-org.kde.discover.notifier@autostart.service \
  app-org.kde.kalendarac@autostart.service \
  app-sealertauto@autostart.service \
  app-org.freedesktop.problems.applet@autostart.service

# Akonadi (KDE PIM — only needed if using KMail/Kontact)
systemctl --user disable --now akonadi_control.service
```

### 15. libinput Debouncing

libinput adds eager debouncing to all mice by default. The LAMZU Maya X 8K uses Hall Effect sensors — debouncing is unnecessary and can block fast clicks.

```bash
sudo mkdir -p /etc/libinput
sudo cp system/libinput-overrides.quirks /etc/libinput/local-overrides.quirks
```

---

## Terminal Setup

### Kitty Terminal

```bash
sudo dnf install -y kitty
mkdir -p ~/.config/kitty
cp configs/kitty/kitty.conf ~/.config/kitty/kitty.conf
```

**Key bindings:**

| Shortcut | Action |
| --- | --- |
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+Tab` | Next tab |
| `Ctrl+Shift+Enter` | New window (split) |

### JetBrainsMono Nerd Font

```bash
mkdir -p ~/.local/share/fonts/JetBrainsMono
curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
  -o /tmp/JetBrainsMono.tar.xz
tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts/JetBrainsMono/
fc-cache -fv
```

In KDE: **System Settings → Fonts → Fixed width** → `JetBrainsMono Nerd Font`

### Starship Prompt

```bash
curl -sS https://starship.rs/install.sh | sh
cp configs/starship/starship.toml ~/.config/starship.toml
```

### Fish Shell (inside Kitty)

Fish is configured as the shell for Kitty only (`shell /usr/bin/fish` in `kitty.conf`), keeping bash as the login shell for KDE/PAM compatibility.

```bash
sudo dnf install -y fish
cp configs/fish/config.fish ~/.config/fish/config.fish
cp configs/fish/functions/ya.fish ~/.config/fish/functions/ya.fish
```

### Shell Tools

```bash
sudo dnf install -y zoxide lazygit fzf ripgrep fd-find bat eza
```

### ble.sh (bash syntax highlighting)

Adds fish-style syntax coloring and completion in bash. Load order matters — must be sourced before other config:

```bash
git clone --recursive --depth 1 --shallow-submodules \
  https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
make -C /tmp/ble.sh install PREFIX=~/.local
```

`configs/bashrc` is a reference copy of the bashrc additions (aliases, zoxide, mise, starship). `fedora-setup.sh` handles the actual deploy: it prepends the ble.sh `--noattach` loader to line 1, then appends the rest via heredoc — ble.sh requires `--noattach` first and `ble-attach` last.

### mise (Runtime Version Manager)

```bash
curl https://mise.run | sh
eval "$(~/.local/bin/mise activate bash)"
```

### Yazi (Terminal File Manager)

Download prebuilt binary (cargo install often fails on new versions):

```bash
YAZI_VER=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep tag_name | cut -d'"' -f4)
curl -sL "https://github.com/sxyazi/yazi/releases/download/${YAZI_VER}/yazi-x86_64-unknown-linux-gnu.zip" \
  -o /tmp/yazi.zip
unzip -q /tmp/yazi.zip -d /tmp/yazi-bin
sudo install -m755 /tmp/yazi-bin/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi
```

---

## Desktop Rice (Darth Vader Theme)

![Wallpaper](wallpaper/wallpaper.jpg)

**Color palette extracted from wallpaper:**

| Color | Hex | Usage |
| --- | --- | --- |
| Background | `#090909` | Terminal, Conky bg |
| Teal (primary) | `#00c8a8` | Accents, clock, labels |
| Teal (bright) | `#1de9b6` | Directory, highlights |
| Red | `#cc2222` | Errors, speeds, danger |
| Gray | `#b0bec5` | Foreground text |

### Wallpaper

```bash
mkdir -p ~/Pictures
cp wallpaper/wallpaper.jpg ~/Pictures/wallpaper.jpg
```

Set in KDE: right-click desktop → Configure Desktop → Wallpaper

### KDE Color Scheme

```bash
cp configs/kde/DarthVader.colors ~/.local/share/color-schemes/
```

Apply: **System Settings → Colors → Darth Vader → Apply**

### Kvantum Theme (Application Style)

```bash
sudo dnf install -y kvantum
git clone --depth=1 https://github.com/vinceliuice/Layan-kde.git /tmp/layan-kde
```

In **Kvantum Manager:**

1. Install/Update Theme → Select `/tmp/layan-kde/Kvantum/Layan` → Install
2. Change/Delete Theme → Select `LayanDark` → Use this theme

Apply: **System Settings → Application Style → kvantum → Apply**

```bash
mkdir -p ~/.config/Kvantum
cp configs/kde/kvantum/kvantum.kvconfig ~/.config/Kvantum/kvantum.kvconfig
```

Enable blur: **System Settings → Desktop Effects → Blur** (or via terminal):

```bash
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
```

### KDE Panel

Right-click panel → Enter Edit Mode:

- **Position:** Bottom
- **Alignment:** Center
- **Width:** Fit content
- **Floating:** Panel and applets (gives rounded corners)
- **Opacity:** Translucent

### Conky (System Stats Widget)

```bash
sudo dnf install -y conky
mkdir -p ~/.config/conky ~/.config/systemd/user
cp configs/conky/conky.conf ~/.config/conky/conky.conf
cp configs/systemd/conky.service ~/.config/systemd/user/conky.service
systemctl --user daemon-reload
systemctl --user enable --now conky.service
```

---

## Gaming Setup

### Flatpak

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
  com.valvesoftware.Steam \
  net.davidotek.pupgui2 \
  com.heroicgameslauncher.hgl \
  net.lutris.Lutris \
  com.usebottles.bottles \
  org.prismlauncher.PrismLauncher \
  io.github.benjamimgois.goverlay \
  com.github.wwmm.easyeffects
```

### NTSync (Wine/Proton CPU sync)

NTSync is a Linux kernel feature that replaces Wine's user-space synchronization with native kernel primitives — lower CPU overhead and better frame times.

Requires Linux ≥ 6.14 and **GE-Proton ≥ 10-10** (install via ProtonUp-Qt). Standard Steam Proton does not support NTSync yet. Proton uses it automatically once `/dev/ntsync` is available.

```bash
sudo cp system/ntsync.conf /etc/modules-load.d/ntsync.conf
sudo cp system/99-ntsync.rules /etc/udev/rules.d/99-ntsync.rules
sudo udevadm control --reload-rules
sudo modprobe ntsync
```

Verify: `ls /dev/ntsync` — should exist after modprobe.

### Gamescope

```bash
sudo dnf install -y gamescope
sudo setcap cap_sys_nice+ep "$(which gamescope)"
```

`CAP_SYS_NICE` lets Gamescope use `--rt` (real-time scheduling) without root. Steam launch option example: `gamescope -W 2560 -H 1440 -r 165 --hdr-enabled -- %command%`

### GameMode + MangoHud

```bash
sudo dnf install -y gamemode mangohud
```

Steam launch options: `gamemoderun mangohud %command%`

This is the universal baseline — use it on every game, native or Proton. The flags in the table below stack in front of it only for Proton games that need them.

### ProtonUp-Qt (Proton versions)

Installed via Flatpak (`net.davidotek.pupgui2`). Use to install GE-Proton for better game compatibility.

### KDE Direct Scanout

KDE Plasma can bypass the compositor entirely for fullscreen games, reducing latency. Requires:

- No color profile applied to the display
- HDR off
- Night Light off
- No custom KWin effects (default set only)

Compositor bypass happens automatically when conditions are met. Verify with KWin debug console: `qdbus org.kde.KWin /KWin showCompositing`.

### Steam Launch Options

Per-game launch options in Steam (right-click game → Properties → Launch Options):

| Use case | Launch option |
| --- | --- |
| Native Wayland (GE-Proton) | `PROTON_ENABLE_WAYLAND=1 %command%` |
| DLSS / RTX / Reflex | `PROTON_ENABLE_NVAPI=1 DXVK_ENABLE_NVAPI=1 %command%` |
| Ray tracing (VKD3D) | `VKD3D_CONFIG=dxr %command%` |
| GPU not detected in game | add `PROTON_HIDE_NVIDIA_GPU=0` |
| All combined | `PROTON_ENABLE_WAYLAND=1 PROTON_ENABLE_NVAPI=1 DXVK_ENABLE_NVAPI=1 PROTON_HIDE_NVIDIA_GPU=0 VKD3D_CONFIG=dxr %command%` |

Append `gamemoderun mangohud` after the env vars to keep GameMode and the overlay, e.g. `PROTON_ENABLE_NVAPI=1 DXVK_ENABLE_NVAPI=1 gamemoderun mangohud %command%`.

`PROTON_ENABLE_WAYLAND=1` requires GE-Proton — standard Steam Proton ignores it.

---

## Scripts

### `scripts/fedora-setup.sh`

Full automated setup from scratch. Run once on a fresh Fedora 44 KDE install. Handles everything except Secure Boot enrollment.

### `scripts/sysinfo.sh` — alias: `sysinfo`

Quick system health check in terminal. Shows CPU/GPU temps, load, RAM, disk, network, top processes, and warnings if anything exceeds 85%.

### `scripts/rice-start.sh` — alias: `rice`

Restarts Conky.

**Install scripts:**

```bash
mkdir -p ~/scripts
cp scripts/rice-start.sh scripts/sysinfo.sh ~/scripts/
chmod +x ~/scripts/rice-start.sh ~/scripts/sysinfo.sh
```

Aliases (`rice`, `sysinfo`) are already in `configs/fish/config.fish` — deployed by `fedora-setup.sh`.

---

## Verification Checklist

Run after full setup to confirm everything is working:

```bash
# Kernel + Secure Boot
uname -r
mokutil --sb-state

# NVIDIA
nvidia-smi
lsmod | grep nvidia

# CPU
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor  # performance
tuned-adm active                                             # latency-performance

# SCX scheduler
systemctl is-active scx_loader

# ZRAM
lsblk | grep zram
cat /proc/sys/vm/swappiness  # 150

# Firewall
firewall-cmd --list-services  # dhcpv6-client kdeconnect

# Temperature
sensors | grep Tctl

# Rice
pgrep conky && echo "Conky running"
```

---

## Sources & Credits

### Core Tools

| Tool | Source |
| --- | --- |
| Fedora KDE | [fedoraproject.org/spins/kde](https://fedoraproject.org/spins/kde) |
| RPM Fusion | [rpmfusion.org](https://rpmfusion.org/) |
| NVIDIA drivers | [rpmfusion.org/Howto/NVIDIA](https://rpmfusion.org/Howto/NVIDIA) |
| SCX Schedulers | [github.com/sched-ext/scx](https://github.com/sched-ext/scx) |
| Flatpak / Flathub | [flathub.org](https://flathub.org/) |

### Terminal

| Tool | Source |
| --- | --- |
| Kitty | [sw.kovidgoyal.net/kitty](https://sw.kovidgoyal.net/kitty/) |
| Fish | [fishshell.com](https://fishshell.com/) |
| ble.sh | [github.com/akinomyoga/ble.sh](https://github.com/akinomyoga/ble.sh) |
| Starship | [starship.rs](https://starship.rs/) |
| Zoxide | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| Lazygit | [github.com/jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |
| Yazi | [github.com/sxyazi/yazi](https://github.com/sxyazi/yazi) |
| mise | [mise.jdx.dev](https://mise.jdx.dev/) |
| fzf | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| ripgrep | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| bat | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| eza | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| JetBrainsMono NF | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |

### Rice / Desktop

| Tool | Source |
| --- | --- |
| Conky | [github.com/brndnmtthws/conky](https://github.com/brndnmtthws/conky) |
| Kvantum | [github.com/tsujan/Kvantum](https://github.com/tsujan/Kvantum) |
| Layan KDE | [github.com/vinceliuice/Layan-kde](https://github.com/vinceliuice/Layan-kde) |
| Panel Colorizer | [github.com/luisbocanegra/plasma-panel-colorizer](https://github.com/luisbocanegra/plasma-panel-colorizer) |

### Gaming

| Tool | Source |
| --- | --- |
| Steam | [store.steampowered.com](https://store.steampowered.com/) |
| ProtonUp-Qt | [github.com/DavidoTek/ProtonUp-Qt](https://github.com/DavidoTek/ProtonUp-Qt) |
| Heroic Games Launcher | [heroicgameslauncher.com](https://heroicgameslauncher.com/) |
| Lutris | [lutris.net](https://lutris.net/) |
| Bottles | [usebottles.com](https://usebottles.com/) |
| Prism Launcher | [prismlauncher.org](https://prismlauncher.org/) |
| GOverlay | [github.com/benjamimgois/goverlay](https://github.com/benjamimgois/goverlay) |
| EasyEffects | [github.com/wwmm/easyeffects](https://github.com/wwmm/easyeffects) |
| MangoHud | [github.com/flightlessmango/MangoHud](https://github.com/flightlessmango/MangoHud) |
| GameMode | [github.com/FeralInteractive/gamemode](https://github.com/FeralInteractive/gamemode) |
| Gamescope | [github.com/ValveSoftware/gamescope](https://github.com/ValveSoftware/gamescope) |

### Gaming Guides

| Guide | Source |
| --- | --- |
| Linux Gaming Optimization | [github.com/theyareonit/linux-gaming-optimization](https://github.com/theyareonit/linux-gaming-optimization) |
| Linux Gaming Guide (AdelKS) | [github.com/AdelKS/LinuxGamingGuide](https://github.com/AdelKS/LinuxGamingGuide) |
| Linux Gaming Wiki | [linux-gaming.kwindu.eu](https://linux-gaming.kwindu.eu/) |

### References

- [Fedora Documentation](https://docs.fedoraproject.org/)
- [Arch Wiki](https://wiki.archlinux.org/) — good reference even on Fedora
- [r/Fedora](https://www.reddit.com/r/Fedora/)
- [r/unixporn](https://www.reddit.com/r/unixporn/)
- [r/linux_gaming](https://www.reddit.com/r/linux_gaming/)
