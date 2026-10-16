#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    printf 'Usage: %s <shell> <script>\n' "$0" >&2
    exit 2
fi

shell="$1"
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="$repo_root/$2"

"$shell" -n "$script_path"

temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/periodblocker-validation.XXXXXX")"

cleanup() {
    rm -f "$temporary_dir/logger"
    rmdir "$temporary_dir"
}
trap cleanup EXIT

cat > "$temporary_dir/logger" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$temporary_dir/logger"

script_output="$(PATH="$temporary_dir:$PATH" "$shell" "$script_path")"

assert_output_contains() {
    local expected="$1"
    case "$script_output" in
        *"$expected"*) ;;
        *)
            printf 'Expected sample output not found: %s\n' "$expected" >&2
            printf '%s\n' "$script_output" >&2
            return 1
            ;;
    esac
}

assert_output_contains '[EXPLODED] Sliced 4'
assert_output_contains '[BLOCKED] doubleclick.net'
assert_output_contains '[ALLOWED] analytics.google.com'
assert_output_contains '[ALLOWED] example.com'
assert_output_contains '[BLOCKED] s0.2mdn.net'

printf '%s syntax check and isolated sample checks passed.\n' "$2"
