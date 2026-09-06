#!/usr/bin/env bash
# Shared physical monitor adjacency for Orbit directional actions.
# Reads monitor JSON on stdin and prints destination name and active workspace.
orbit_adjacent_monitor() {
    local current_id="$1"
    local direction="$2"
    jq -r --argjson current "$current_id" --arg direction "$direction" '
        first(.[] | select(.id == $current)) as $current_monitor |
        def overlap($a1; $a2; $b1; $b2):
            (if $a1 > $b1 then $a1 else $b1 end) < (if $a2 < $b2 then $a2 else $b2 end);
        def destination:
            [ .[] | select(.id != $current) |
              if $direction == "l" then
                  select($current_monitor.x - (.x + .width) >= 0 and $current_monitor.x - (.x + .width) <= 8)
                  | select(overlap($current_monitor.y; $current_monitor.y + $current_monitor.height; .y; .y + .height))
                  | . + {gap: ($current_monitor.x - (.x + .width))}
              elif $direction == "r" then
                  select(.x - ($current_monitor.x + $current_monitor.width) >= 0 and .x - ($current_monitor.x + $current_monitor.width) <= 8)
                  | select(overlap($current_monitor.y; $current_monitor.y + $current_monitor.height; .y; .y + .height))
                  | . + {gap: (.x - ($current_monitor.x + $current_monitor.width))}
              elif $direction == "u" then
                  select($current_monitor.y - (.y + .height) >= 0 and $current_monitor.y - (.y + .height) <= 8)
                  | select(overlap($current_monitor.x; $current_monitor.x + $current_monitor.width; .x; .x + .width))
                  | . + {gap: ($current_monitor.y - (.y + .height))}
              else
                  select(.y - ($current_monitor.y + .height) >= 0 and .y - ($current_monitor.y + .height) <= 8)
                  | select(overlap($current_monitor.x; $current_monitor.x + $current_monitor.width; .x; .x + .width))
                  | . + {gap: (.y - ($current_monitor.y + $current_monitor.height))}
              end
            ] | sort_by(.gap) | first;
        [$current_monitor.name, (destination.name // ""), (destination.activeWorkspace.name // "")] | @tsv
    '
}
