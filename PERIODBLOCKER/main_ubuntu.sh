#!/usr/bin/env bash
# ====================================================================
# LU ZU MONOLITH ENGINE :: 4D STRING EXPLODER & UBUNTU ARCHIVIST
# Platform: Native Ubuntu Linux Bourne/Bash Shell (x86_64 & ARM64)
# ====================================================================

set -euo pipefail

# ANSI Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;30m'
NC='\033[0m'

# Native Ubuntu Journald / Syslog Logger Function
write_luzu_log() {
    local msg="$1"
    local color="${2:-$CYAN}"

    # 1. Console Output
    echo -e "${color}${msg}${NC}"

    # 2. Write directly to systemd journald / syslog
    logger -t "LuZuMonolith" "$msg" 2>/dev/null || true
}

write_luzu_log ""
write_luzu_log "============================================================" "$CYAN"
write_luzu_log " LU ZU MONOLITH :: 4D STRING EXPLODER & UBUNTU ARCHIVIST" "$CYAN"
write_luzu_log "============================================================" "$CYAN"
write_luzu_log " Runtime: Native Ubuntu Bourne Shell ($(uname -m) - $(lsb_release -ds 2>/dev/null || echo 'Ubuntu'))" "$GREEN"
write_luzu_log "============================================================" "$CYAN"
write_luzu_log ""

write_luzu_log "[九眼] Initializing Native Linux Cryptographic & Span Engines..." "$CYAN"

# Native ROT13 Engine via tr
luzu_rot13() {
    echo "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}

# Self-Test 1: Cryptographic Rotation Loop
TEST_PAYLOAD="LuZu-Archivist-Trace"
ENCODED=$(luzu_rot13 "$TEST_PAYLOAD")
DECODED=$(luzu_rot13 "$ENCODED")

if [[ "$DECODED" != "$TEST_PAYLOAD" ]]; then
    write_luzu_log "[FAIL] LuZuRot Verification Error!" "\033[0;31m"
    exit 1
fi
write_luzu_log "[PASS] [六 :: 旋] Cryptographic Loop: $TEST_PAYLOAD -> $ENCODED -> $DECODED" "$GREEN"

# Self-Test 2: Safe String Explosion (Native Bash Array Slicing)
COMPLEX_STREAM="doubleclick.net;analytics.google.com;example.com;s0.2mdn.net"
write_luzu_log "\n--- [四 :: 裂] Executing 4D Safe String Explosion ---" "$YELLOW"

IFS=';' read -r -a EXPLODED_DOMAINS <<< "$COMPLEX_STREAM"

write_luzu_log "[EXPLODED] Sliced ${#EXPLODED_DOMAINS[@]} dynamic memory fragments safely." "$GREEN"

for domain in "${EXPLODED_DOMAINS[@]}"; do
    write_luzu_log "  |---> Spatial Segment Captured: $domain" "$GRAY"
done

# Filter Engine Verification
write_luzu_log "\n--- [八 :: 濾] Performing Domain Analysis ---" "$YELLOW"

BLOCKED_LIST=("doubleclick.net" "s0.2mdn.net")

for domain in "${EXPLODED_DOMAINS[@]}"; do
    IS_BLOCKED=0
    for b in "${BLOCKED_LIST[@]}"; do
        if [[ "$domain" == "$b" ]]; then
            IS_BLOCKED=1
            break
        fi
    done

    if [[ $IS_BLOCKED -eq 1 ]]; then
        write_luzu_log "  [BLOCKED] $domain" "\033[0;31m"
    else
        write_luzu_log "  [ALLOWED] $domain" "$GREEN"
    fi
done

write_luzu_log "\n[九 :: 歸] All traces written to Ubuntu journalctl (view with: journalctl -t LuZuMonolith -f)." "$CYAN"