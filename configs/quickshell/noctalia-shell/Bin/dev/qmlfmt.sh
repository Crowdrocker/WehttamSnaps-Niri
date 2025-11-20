#!/usr/bin/env -S bash
set -euo pipefail

# QML Formatter Script
# Uses: https://github.com/jesperhh/qmlfmt
# Install: AUR package "qmlfmt-git" (requires qt6-5compat)

command -v qmlfmt &>/dev/null || { echo "qmlfmt not found" >&2; exit 1; }

format_file() { qmlfmt -e -b 360 -t 2 -i 2 -w "$1" || { echo "Failed: $1" >&2; return 1; }; }
export -f format_file

# Find all .qml files
mapfile -t all_files < <(find "${1:-.}" -name "*.qml" -type f)
[ ${#all_files[@]} -eq 0 ] && { echo "No QML files found"; exit 0; }

echo "Scanning ${#all_files[@]} files for array destructuring..."
safe_files=()
for file in "${all_files[@]}"; do
    # Checks for a comma inside brackets followed by an equals sign aka "array destructuring"
    # as this ES6 syntax is not supported by qmlfmt and will result in breakage.
    if grep -qE '\[.*,.*\]\s*=' "$file"; then
        echo "-> Skipping (Array destructuring detected): $file" >&2
    else
        safe_files+=("$file")
    fi
done

[ ${#safe_files[@]} -eq 0 ] && { echo "No safe files to format after filtering."; exit 0; }

echo "Formatting ${#safe_files[@]} files..."
printf '%s\0' "${safe_files[@]}" | \
    xargs -0 -P "${QMLFMT_JOBS:-$(nproc)}" -I {} bash -c 'format_file "$@"' _ {} \
    && echo "Done" || { echo "Errors occurred" >&2; exit 1; }