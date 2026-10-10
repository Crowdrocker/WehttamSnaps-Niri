#!/usr/bin/env bash
set -euo pipefail

mode="quick"
if [[ "${1:-}" == "--full" ]]; then
    mode="full"
fi

config_path="${INIR_CONFIG_PATH:-$HOME/.config/inir/config.json}"
output_dir="${ORBIT_AUDIT_DIR:-/tmp/inir-orbit-audit}"
mkdir -p "$output_dir"

for command in jq grim magick python3 systemctl journalctl timeout niri inir; do
    command -v "$command" >/dev/null || {
        printf 'FAIL: missing command: %s\n' "$command" >&2
        exit 1
    }
done

has_usable_systemd_user_manager() {
    [[ -S "${XDG_RUNTIME_DIR:-}/systemd/private" ]] &&
        timeout 3s systemctl --user show-environment >/dev/null 2>&1
}

if ! has_usable_systemd_user_manager; then
    printf 'FAIL: Orbit visual audit requires a usable systemd user manager\n' >&2
    exit 1
fi

[[ -f "$config_path" ]] || {
    printf 'FAIL: config not found: %s\n' "$config_path" >&2
    exit 1
}

original="$(mktemp)"
cp "$config_path" "$original"
last_written=""

restore_config() {
    systemctl --user stop inir.service >/dev/null 2>&1 || true
    if [[ -n "$last_written" ]] && cmp -s "$config_path" "$last_written"; then
        cp "$original" "$config_path"
    else
        python3 - "$original" "$config_path" <<'PY'
import copy
import json
import pathlib
import sys

original_path = pathlib.Path(sys.argv[1])
current_path = pathlib.Path(sys.argv[2])
original = json.loads(original_path.read_text())
current = json.loads(current_path.read_text())

paths = [
    "appearance.globalStyle",
    "orbit.stageMode",
    "orbit.orbital.layout",
    "orbit.orbital.visibleWorkspaces",
    "orbit.orbital.surface.style",
    "orbit.orbital.surface.outline",
    "orbit.orbital.surface.outlineWidth",
    "orbit.orbital.surface.outlineOpacityPercent",
    "orbit.orbital.surface.frameInset",
    "orbit.orbital.surface.shadowMode",
    "orbit.orbital.surface.shadowOpacityPercent",
    "orbit.shelf.layout",
    "orbit.shelf.islandStyle",
]

missing = object()

def read_path(source, path):
    value = source
    for part in path.split("."):
        if not isinstance(value, dict) or part not in value:
            return missing
        value = value[part]
    return copy.deepcopy(value)

def write_path(target, path, value):
    parts = path.split(".")
    parent = target
    for part in parts[:-1]:
        child = parent.get(part)
        if not isinstance(child, dict):
            child = {}
            parent[part] = child
        parent = child
    if value is missing:
        parent.pop(parts[-1], None)
    else:
        parent[parts[-1]] = value

for path in paths:
    write_path(current, path, read_path(original, path))

current_path.write_text(json.dumps(current, indent=4, sort_keys=True) + "\n")
PY
    fi
    systemctl --user reset-failed inir.service >/dev/null 2>&1 || true
    systemctl --user start inir.service >/dev/null 2>&1 || true
}
trap restore_config EXIT INT TERM

wait_shell() {
    local pid=""
    for _ in {1..30}; do
        if [[ "$(systemctl --user is-active inir.service 2>/dev/null || true)" == "active" ]]; then
            pid="$(systemctl --user show -p MainPID --value inir.service)"
            [[ "$pid" != "0" ]] && break
        fi
        sleep 0.1
    done
    [[ -n "$pid" && "$pid" != "0" ]] || return 1
    for _ in {1..40}; do
        if journalctl --user -u inir.service _PID="$pid" --no-pager 2>/dev/null \
                | grep -q 'shellEntryReady'; then
            printf '%s' "$pid"
            return 0
        fi
        sleep 0.1
    done
    return 1
}

socket_for_pid() {
    tr '\0' '\n' < "/proc/$1/environ" | sed -n 's/^NIRI_SOCKET=//p' | head -1
}

write_case_config() {
    local filter="$1"
    local target="$(mktemp)"
    jq "$filter" "$original" > "$target"
    cp "$target" "$config_path"
    rm -f "$last_written"
    last_written="$(mktemp)"
    cp "$config_path" "$last_written"
}

capture_case() {
    local name="$1"
    local entry="$2"
    local expected_layout="$3"
    local filter="$4"

    systemctl --user stop inir.service
    sleep 0.15
    write_case_config "$filter"
    systemctl --user reset-failed inir.service >/dev/null 2>&1 || true
    systemctl --user start inir.service

    local pid
    pid="$(wait_shell)" || {
        printf 'FAIL: shell did not become ready for %s\n' "$name" >&2
        return 1
    }
    local socket
    socket="$(socket_for_pid "$pid")"
    [[ -n "$socket" ]] || {
        printf 'FAIL: NIRI_SOCKET missing for %s\n' "$name" >&2
        return 1
    }

    case "$entry" in
        stage) inir orbit stage >/dev/null ;;
        orbital) inir orbit orbital >/dev/null ;;
        studio) inir orbit studio >/dev/null ;;
        *) printf 'FAIL: unknown entry %s\n' "$entry" >&2; return 1 ;;
    esac

    local layer_ready=false
    for _ in {1..20}; do
        if NIRI_SOCKET="$socket" niri msg layers 2>/dev/null | grep -q 'quickshell:orbit'; then
            layer_ready=true
            break
        fi
        sleep 0.1
    done
    $layer_ready || {
        printf 'FAIL: Orbit layer not visible for %s\n' "$name" >&2
        return 1
    }

    local status_json=""
    local state_ready=false
    for _ in {1..30}; do
        status_json="$(inir orbit status 2>/dev/null || true)"
        local settled=false
        if [[ -n "$status_json" ]] && python3 -c \
                'import sys; raise SystemExit(0 if float(sys.argv[1]) >= .995 and float(sys.argv[2]) >= .95 else 1)' \
                "$(jq -r '.entryProgress // 0' <<<"$status_json" 2>/dev/null)" \
                "$(jq -r '.stageOpacity // 0' <<<"$status_json" 2>/dev/null)"; then
            settled=true
        fi
        if [[ -n "$status_json" ]] \
                && [[ "$(jq -r '.loaderReady // false' <<<"$status_json" 2>/dev/null)" == "true" ]] \
                && [[ "$(jq -r '.layout // ""' <<<"$status_json" 2>/dev/null)" == "$expected_layout" ]] \
                && $settled \
                && { [[ "$expected_layout" == "stage" ]] \
                    || (( $(jq -r '.cardCount // 0' <<<"$status_json") > 0 )); }; then
            if [[ "$entry" != "studio" ]] \
                    || [[ "$(jq -r '.studio // false' <<<"$status_json")" == "true" ]]; then
                state_ready=true
                break
            fi
        fi
        sleep 0.1
    done
    $state_ready || {
        printf 'FAIL: Orbit runtime state not ready for %s: %s\n' "$name" "$status_json" >&2
        return 1
    }

    sleep 0.3
    local output
    output="$(NIRI_SOCKET="$socket" niri msg -j focused-output | jq -r '.name')"
    NIRI_SOCKET="$socket" grim -o "$output" "$output_dir/$name.png"
    printf '%s\n' "$status_json" | jq . > "$output_dir/$name.json"

    local issues
    issues="$(journalctl --user -u inir.service _PID="$pid" --no-pager \
        | grep -Ei 'ReferenceError|TypeError|Binding loop|Unable to assign|Required property|QQmlComponent: Component is not ready' \
        || true)"
    if [[ -n "$issues" ]]; then
        printf 'FAIL: QML/runtime issue in %s\n%s\n' "$name" "$issues" >&2
        return 1
    fi

    printf '%-24s pid=%s output=%s cards=%s\n' "$name" "$pid" "$output" \
        "$(jq -r '.cardCount // 0' <<<"$status_json")"
}

compare_cases() {
    python3 - "$output_dir/$1.png" "$output_dir/$2.png" "$3" "$4" <<'PY'
from PIL import Image, ImageChops, ImageStat
import sys

a = Image.open(sys.argv[1]).convert("RGB")
b = Image.open(sys.argv[2]).convert("RGB")
label = sys.argv[3]
minimum = float(sys.argv[4])
d = ImageChops.difference(a, b)
h = d.histogram()
total = a.width * a.height * 3
changed = sum(h[256*c+i] for c in range(3) for i in range(5, 256)) / total * 100
mean = sum(ImageStat.Stat(d).mean) / 3
print(f"{label}: changed>4={changed:.4f}% mean={mean:.4f} bbox={d.getbbox()}")
if changed < minimum:
    raise SystemExit(f"FAIL: {label} did not produce the expected rendered difference")
PY
}

assert_workspace_motion_edge_guard() {
    local pid socket output current_idx target_idx
    pid="$(systemctl --user show -p MainPID --value inir.service)"
    socket="$(socket_for_pid "$pid")"
    [[ -n "$socket" ]] || {
        printf 'FAIL: NIRI_SOCKET missing for workspace edge guard\n' >&2
        return 1
    }
    output="$(NIRI_SOCKET="$socket" niri msg -j focused-output | jq -r '.name')"
    current_idx="$(NIRI_SOCKET="$socket" niri msg -j workspaces | jq -r \
        --arg output "$output" '.[] | select(.output == $output and .is_active) | .idx' | head -1)"
    target_idx="$(NIRI_SOCKET="$socket" niri msg -j workspaces | jq -r \
        --arg output "$output" --argjson current "${current_idx:-0}" \
        '[.[] | select(.output == $output and .idx != $current) | .idx] | first // empty')"
    [[ -n "$current_idx" && -n "$target_idx" ]] || {
        printf 'SKIP: workspace edge guard needs two workspaces on %s\n' "$output"
        return 0
    }

    NIRI_SOCKET="$socket" grim -o "$output" "$output_dir/workspace-motion-before.png"
    NIRI_SOCKET="$socket" niri msg action focus-workspace "$target_idx" >/dev/null
    sleep 0.05
    NIRI_SOCKET="$socket" grim -o "$output" "$output_dir/workspace-motion-mid.png"
    NIRI_SOCKET="$socket" niri msg action focus-workspace "$current_idx" >/dev/null || true
    sleep 0.35

    python3 - "$output_dir/workspace-motion-before.png" "$output_dir/workspace-motion-mid.png" <<'PY'
from PIL import Image, ImageChops, ImageStat
import sys

a = Image.open(sys.argv[1]).convert("RGB")
b = Image.open(sys.argv[2]).convert("RGB")
regions = {
    "left32": (0, 0, 32, a.height),
    "bottom32": (0, a.height - 32, a.width, a.height),
}
for label, box in regions.items():
    d = ImageChops.difference(a.crop(box), b.crop(box))
    mean = sum(ImageStat.Stat(d).mean) / 3
    histogram = d.histogram()
    total = d.width * d.height * 3
    changed = sum(histogram[256*c+i] for c in range(3) for i in range(5, 256)) / total * 100
    print(f"Workspace motion {label}: changed>4={changed:.4f}% mean={mean:.4f}")
    if changed > 1.0 or mean > 0.75:
        raise SystemExit(f"FAIL: workspace motion leaks through Orbit backdrop at {label}")
PY
}

base='.orbit.stageMode="orbital" | .orbit.orbital.surface.style="current" | .orbit.shelf.layout="islands" | .orbit.shelf.islandStyle="material"'

capture_case stage-current stage stage "$base | .orbit.stageMode=\"stage\""
capture_case orbit-current orbital orbit "$base | .orbit.orbital.layout=\"orbit\""
capture_case horizon-current orbital horizon "$base | .orbit.orbital.layout=\"horizon\""
capture_case gallery-current orbital gallery "$base | .orbit.orbital.layout=\"gallery\""
capture_case deck-current orbital deck "$base | .orbit.orbital.layout=\"deck\""
capture_case atlas-current orbital atlas "$base | .orbit.orbital.layout=\"atlas\""
capture_case orbit-ricelin orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.orbital.surface.style=\"ricelin\" | .orbit.shelf.islandStyle=\"ricelin\""
capture_case studio studio orbit "$base | .orbit.orbital.layout=\"orbit\""

compare_cases orbit-current horizon-current 'Orbit → Horizon layout' 0.10
compare_cases orbit-current gallery-current 'Orbit → Gallery layout' 0.10
compare_cases orbit-current deck-current 'Orbit → Deck layout' 0.10
compare_cases orbit-current atlas-current 'Orbit → Atlas layout' 0.10
compare_cases orbit-current orbit-ricelin 'Current → Ricelin surface' 0.01

if [[ "$mode" == "full" ]]; then
    capture_case stage-ricelin stage stage "$base | .orbit.stageMode=\"stage\" | .orbit.orbital.surface.style=\"ricelin\""
    capture_case stage-frame-zero stage stage "$base | .orbit.stageMode=\"stage\" | .orbit.orbital.surface.frameInset=0"
    capture_case stage-frame-max stage stage "$base | .orbit.stageMode=\"stage\" | .orbit.orbital.surface.frameInset=18"
    capture_case stage-shadow-off stage stage "$base | .orbit.stageMode=\"stage\" | .orbit.orbital.surface.shadowMode=\"off\""
    capture_case stage-shadow-all stage stage "$base | .orbit.stageMode=\"stage\" | .orbit.orbital.surface.shadowMode=\"all\" | .orbit.orbital.surface.shadowOpacityPercent=100"
    capture_case outline-off orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.orbital.surface.outline=false"
    capture_case outline-max orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.orbital.surface.outline=true | .orbit.orbital.surface.outlineWidth=4 | .orbit.orbital.surface.outlineOpacityPercent=100"
    capture_case frame-zero orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.orbital.surface.frameInset=0"
    capture_case frame-max orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.orbital.surface.frameInset=18"
    capture_case shadow-off orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.orbital.surface.shadowMode=\"off\""
    capture_case shadow-all orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.orbital.surface.shadowMode=\"all\" | .orbit.orbital.surface.shadowOpacityPercent=100"
    capture_case atlas-three orbital atlas "$base | .orbit.orbital.layout=\"atlas\" | .orbit.orbital.visibleWorkspaces=3"
    capture_case atlas-seven orbital atlas "$base | .orbit.orbital.layout=\"atlas\" | .orbit.orbital.visibleWorkspaces=7"
    capture_case shelf-bar-current orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.shelf.layout=\"bar\" | .orbit.shelf.islandStyle=\"material\""
    capture_case shelf-bar-ricelin orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.shelf.layout=\"bar\" | .orbit.shelf.islandStyle=\"ricelin\""
    capture_case shelf-minimal-current orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.shelf.layout=\"minimal\" | .orbit.shelf.islandStyle=\"material\""
    capture_case shelf-minimal-ricelin orbital orbit "$base | .orbit.orbital.layout=\"orbit\" | .orbit.shelf.layout=\"minimal\" | .orbit.shelf.islandStyle=\"ricelin\""
    compare_cases stage-current stage-ricelin 'Stage Current → Ricelin surface' 0.01
    compare_cases stage-frame-zero stage-frame-max 'Stage frame inset 0 → 18' 0.005
    compare_cases stage-shadow-off stage-shadow-all 'Stage shadow off → all' 0.002
    compare_cases outline-off outline-max 'Outline off → max' 0.005
    compare_cases frame-zero frame-max 'Frame inset 0 → 18' 0.005
    compare_cases shadow-off shadow-all 'Shadow off → all' 0.002
    compare_cases atlas-current atlas-three 'Atlas 5 → 3 workspaces' 0.10
    compare_cases atlas-current atlas-seven 'Atlas 5 → 7 workspaces' 0.10
    compare_cases gallery-current deck-current 'Gallery → Deck identity' 0.10
    compare_cases shelf-bar-current shelf-bar-ricelin 'Bar Current → Ricelin surface' 0.002
    compare_cases shelf-minimal-current shelf-minimal-ricelin 'Minimal Current → Ricelin surface' 0.002

    for style in inir regalia zzz; do
        capture_case "style-$style" orbital orbit "$base | .appearance.globalStyle=\"$style\" | .orbit.orbital.layout=\"orbit\""
        compare_cases orbit-current "style-$style" "Material → $style" 0.05
    done

    assert_workspace_motion_edge_guard
fi

printf 'Orbit visual audit complete: %s\n' "$output_dir"
