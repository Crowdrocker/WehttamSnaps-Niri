#!/bin/bash
#===============================================================================
# Layout Module — Detect layout activation/deactivation events
#===============================================================================
# Description:
#   Subscribes to `mmsg watch all-tags` and emits JSON when any tag's layout
#   becomes active or inactive on any monitor.
#
# Output format (JSON lines):
#   {"layout":"M","state":"active","monitor":"DP-1","tag":1}
#   {"layout":"M","state":"inactive","monitor":"DP-1","tag":1}
#
# Dependencies:
#   - jq
#   - mmsg
#===============================================================================

declare -A MONITOR_LAYOUT

process_tags_update() {
    local json="$1"
    local monitors monitor tag layout is_active

    monitors=$(jq -c '.all_tags[]' <<< "$json" 2>/dev/null)

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        monitor=$(jq -r '.monitor' <<< "$entry" 2>/dev/null)
        [[ -z "$monitor" ]] && continue

        while IFS= read -r tag_entry; do
            [[ -z "$tag_entry" ]] && continue
            tag=$(jq -r '.index' <<< "$tag_entry" 2>/dev/null)
            layout=$(jq -r '.layout' <<< "$tag_entry" 2>/dev/null)
            is_active=$(jq -r '.is_active' <<< "$tag_entry" 2>/dev/null)

            if [[ "$is_active" == "true" ]]; then
                local prev="${MONITOR_LAYOUT[$monitor]}"
                if [[ "$prev" != "$layout" ]]; then
                    if [[ -n "$prev" ]]; then
                        echo "{\"layout\":\"$prev\",\"state\":\"inactive\",\"monitor\":\"$monitor\",\"tag\":$tag}"
                    fi
                    echo "{\"layout\":\"$layout\",\"state\":\"active\",\"monitor\":\"$monitor\",\"tag\":$tag}"
                    MONITOR_LAYOUT["$monitor"]="$layout"
                fi
            fi
        done < <(jq -c '.tags[]' <<< "$entry" 2>/dev/null)
    done <<< "$monitors"
}

if ! command -v mmsg &>/dev/null || ! command -v jq &>/dev/null; then
    echo "layout.sh: mmsg and jq are required" >&2
    exit 1
fi

while read -r line; do
    process_tags_update "$line"
done < <(mmsg watch all-tags 2>/dev/null)
