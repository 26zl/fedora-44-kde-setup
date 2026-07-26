#!/bin/bash
# Re-enroll the akmods signing key after a BIOS flash.
#
# Flashing the BIOS clears UEFI NVRAM, and the MOK list goes with it. The locally
# signed NVIDIA modules then fail signature verification under Secure Boot, nouveau
# claims the card instead, and Plasma comes up to a black screen. Everything still
# boots — you land in a TTY — so run this from there.

set -e

TEAL='\033[38;2;0;200;168m'
RED='\033[38;2;170;28;28m'
RESET='\033[0m'

ok()      { echo -e "  ${TEAL}✓${RESET} $1"; }
warn()    { echo -e "  ${RED}!${RESET} $1"; }
section() { echo -e "\n${TEAL}━━━ $1 ━━━${RESET}"; }

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

section "State"
if ! mokutil --sb-state 2>/dev/null | grep -qi enabled; then
    ok "Secure Boot is off — unsigned modules load fine, nothing to enroll"
    exit 0
fi
ok "Secure Boot enabled"

if lsmod | grep -q '^nvidia'; then
    ok "nvidia module already loaded"
else
    warn "nvidia module not loaded"
fi
lspci -k | grep -A3 -i 'VGA' | grep 'Kernel driver' | sed 's/^\s*/  /' || true

KEY=""
for candidate in /etc/pki/akmods/certs/public_key.der /etc/pki/akmods/certs/*.der; do
    [ -f "$candidate" ] && { KEY="$candidate"; break; }
done
[ -n "$KEY" ] || { warn "no signing key under /etc/pki/akmods/certs"; exit 1; }
echo "  key: $KEY"

if mokutil --test-key "$KEY" 2>/dev/null | grep -q "already enrolled"; then
    ok "key is already enrolled — nothing to do"
    if ! lsmod | grep -q '^nvidia'; then
        warn "but nvidia is not loaded, so the problem is elsewhere: check 'dmesg | grep -i nvidia'"
    fi
    exit 0
fi
warn "key is NOT enrolled — this is why the modules will not load"

section "Enrollment"
[ -t 0 ] || { warn "needs an interactive terminal for the password prompt"; exit 1; }
cat <<'INFO'
  You will now set a ONE-TIME password, entered twice. It is used once at the
  next boot and then discarded. Use digits only, e.g. 12345678 — the MOK screen
  is US layout, so Norwegian keys land in the wrong place.

  After this finishes, reboot. A blue "Shim UEFI key management" screen appears
  and waits about 10 seconds:

      Enroll MOK  ->  Continue  ->  Yes  ->  password  ->  Reboot

  Miss the window and nothing breaks — just run this script again.
INFO
read -rp "  Enter to continue, Ctrl+C to abort: " _

mokutil --import "$KEY"

if mokutil --list-new 2>/dev/null | grep -q .; then
    ok "enrollment queued — reboot and follow the blue screen"
else
    warn "nothing queued, the import may have failed"
    exit 1
fi
