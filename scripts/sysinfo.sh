#!/bin/bash
# System status — quick health overview

TEAL='\033[38;2;0;200;168m'
RED='\033[38;2;170;28;28m'
GRAY='\033[38;2;144;168;160m'
WHITE='\033[38;2;200;216;208m'
RESET='\033[0m'

line() { echo -e "${TEAL}────────────────────────────────────${RESET}"; }

echo ""
line
echo -e "  ${TEAL}SYSTEM STATUS${RESET}  $(date '+%A, %d %B %Y  %H:%M')"
line

# System
KERNEL=$(uname -r)
UPTIME=$(uptime -p | sed 's/up //')
echo -e "  ${GRAY}kernel ${RESET}${WHITE}${KERNEL}${RESET}"
echo -e "  ${GRAY}uptime ${RESET}${WHITE}${UPTIME}${RESET}"

line

# CPU
CPU_LOAD=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {printf "%.1f", usage}')
CPU_FREQ=$(grep 'cpu MHz' /proc/cpuinfo | awk '{sum+=$4; count++} END {printf "%.2f", sum/count/1000}')
CPU_TEMP=$(sensors 2>/dev/null | grep 'Tctl:' | awk '{print $2}' | tr -d '+')
echo -e "  ${TEAL}CPU  ${GRAY}Ryzen 9 9900X${RESET}"
echo -e "  ${GRAY}load   ${WHITE}${CPU_LOAD}%  ${GRAY}freq  ${WHITE}${CPU_FREQ}GHz  ${GRAY}temp  ${WHITE}${CPU_TEMP:-N/A}${RESET}"

line

# GPU
if command -v nvidia-smi &>/dev/null; then
    GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
    GPU_LOAD=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader | tr -d ' ')
    GPU_VRAM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader | tr -d ' ')
    GPU_VRAM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | tr -d ' ')
    echo -e "  ${TEAL}GPU  ${GRAY}RTX 5070${RESET}"
    echo -e "  ${GRAY}temp   ${WHITE}${GPU_TEMP}°C  ${GRAY}load  ${WHITE}${GPU_LOAD}  ${GRAY}vram  ${WHITE}${GPU_VRAM_USED} / ${GPU_VRAM_TOTAL}${RESET}"
fi

line

# Memory
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_PCT=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
SWAP_USED=$(free -h | awk '/^Swap:/ {print $3}')
SWAP_TOTAL=$(free -h | awk '/^Swap:/ {print $2}')
echo -e "  ${TEAL}MEMORY${RESET}"
echo -e "  ${GRAY}ram    ${WHITE}${MEM_USED} / ${MEM_TOTAL} ${GRAY}(${MEM_PCT}%)${RESET}"
echo -e "  ${GRAY}zram   ${WHITE}${SWAP_USED} / ${SWAP_TOTAL}${RESET}"

line

# Disk
ROOT_USED=$(df -h / | awk 'NR==2 {print $3}')
ROOT_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
ROOT_PCT=$(df / | awk 'NR==2 {print $5}')
DATA_USED=$(df -h /mnt/data 2>/dev/null | awk 'NR==2 {print $3}')
DATA_TOTAL=$(df -h /mnt/data 2>/dev/null | awk 'NR==2 {print $2}')
echo -e "  ${TEAL}DISK${RESET}"
echo -e "  ${GRAY}root   ${WHITE}${ROOT_USED} / ${ROOT_TOTAL} ${GRAY}(${ROOT_PCT})${RESET}"
[ -n "$DATA_USED" ] && echo -e "  ${GRAY}data   ${WHITE}${DATA_USED} / ${DATA_TOTAL}${RESET}"

line

# Network — adjust interface name to match your system (check with: ip link show)
IP=$(ip -4 addr show enp14s0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo -e "  ${TEAL}NETWORK${RESET}"
echo -e "  ${GRAY}ip     ${WHITE}${IP:-No address}${RESET}"

line

# Top processes
echo -e "  ${TEAL}TOP PROCESSES${RESET}"
ps -eo comm,pcpu --sort=-pcpu | head -4 | tail -3 | \
    awk -v teal="$TEAL" -v gray="$GRAY" -v white="$WHITE" -v reset="$RESET" \
    '{printf "  %s%-20s%s %s%s%%%s\n", gray, $1, reset, white, $2, reset}'

line
echo ""

# Warnings
WARN=0
[ "$MEM_PCT" -gt 85 ] && echo -e "  ${RED}WARNING: RAM usage above 85%${RESET}" && WARN=1
[ "${GPU_TEMP:-0}" -gt 85 ] && echo -e "  ${RED}WARNING: GPU temp above 85°C${RESET}" && WARN=1
[ "${ROOT_PCT/\%/}" -gt 85 ] && echo -e "  ${RED}WARNING: Root disk above 85% full${RESET}" && WARN=1
[ "$WARN" -eq 0 ] && echo -e "  ${TEAL}All systems healthy.${RESET}"
echo ""
