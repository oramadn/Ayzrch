#!/usr/bin/env bash
# Claude Code status line — directory + git branch + model, in Orbit's palette.
#
# Decorative colours are read from the semantic palette orbit-theme regenerates
# on every wallpaper change, so this line follows the desktop the way the prompt
# and the terminal do. The rate-limit and context thresholds deliberately do not:
# they are a traffic light, and under a wallpaper scheme that tints every slot
# toward one hue the palette's own success and warning collapse to within a few
# RGB units of each other. A warning that cannot be seen is worse than one that
# clashes, so those three stay fixed.

input=$(cat)

# Parse all needed fields in a single python3 pass (jq is not installed on this machine)
fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(printf '%s' "$input" | python3 -c '
import json, sys

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}

workspace = d.get("workspace") or {}
model = d.get("model") or {}
context_window = d.get("context_window") or {}
rate_limits = d.get("rate_limits") or {}
five_hour = rate_limits.get("five_hour") or {}
cost = d.get("cost") or {}

cwd = workspace.get("current_dir") or d.get("cwd") or ""
model_name = model.get("display_name") or ""
used_pct = context_window.get("used_percentage")
worktree_name = workspace.get("git_worktree") or ""
five_hour_pct = five_hour.get("used_percentage")
total_cost = cost.get("total_cost_usd")

total_input_tokens = context_window.get("total_input_tokens")
total_output_tokens = context_window.get("total_output_tokens")
context_window_size = context_window.get("context_window_size")

abs_tokens = None
if isinstance(total_input_tokens, (int, float)) and isinstance(total_output_tokens, (int, float)):
    abs_tokens = total_input_tokens + total_output_tokens

print(cwd)
print(model_name)
print("" if used_pct is None else used_pct)
print(worktree_name)
print("" if five_hour_pct is None else five_hour_pct)
print("" if total_cost is None else total_cost)
print("" if abs_tokens is None else abs_tokens)
print("" if context_window_size is None else context_window_size)

# Orbit palette, read in this same pass rather than a second interpreter
# start: this runs on every status line render. Any failure prints blanks and
# the shell falls back to its built-in colours.
def _rgb(value):
    try:
        text = str(value).lstrip("#")
        return "%d;%d;%d" % tuple(int(text[i:i + 2], 16) for i in (0, 2, 4))
    except Exception:
        return ""

palette = {}
try:
    import os
    config_home = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    with open(config_home + "/orbit/generated/noctalia/semantic.json") as handle:
        palette = json.load(handle).get("semantic") or {}
except Exception:
    palette = {}

print(_rgb(palette.get("accent")))
print(_rgb(palette.get("text_muted")))
print(_rgb(palette.get("accent_secondary")))
')

cwd="${fields[0]}"
model="${fields[1]}"
used_pct="${fields[2]}"
worktree_name="${fields[3]}"
five_hour_pct="${fields[4]}"
total_cost="${fields[5]}"
abs_tokens="${fields[6]}"
context_window_size="${fields[7]}"
palette_accent="${fields[8]:-}"
palette_muted="${fields[9]:-}"
palette_accent_secondary="${fields[10]:-}"

home="$HOME"
display_dir="$cwd"
worktree_label=""

# Git branch (skip optional locks)
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

  # A linked worktree's path is the whole checkout location (often nested under
  # the main repo), which the branch then repeats. Show the main repo's path and
  # the worktree's name instead. git-dir differs from git-common-dir only in a
  # linked worktree -- a submodule has the two equal.
  { read -r top; read -r git_dir; read -r common_dir; } < <(
    git -C "$cwd" --no-optional-locks rev-parse --path-format=absolute \
      --show-toplevel --git-dir --git-common-dir 2>/dev/null)
  if [ -n "$common_dir" ] && [ "$git_dir" != "$common_dir" ]; then
    display_dir=$(dirname "$common_dir")
    worktree_label="${worktree_name:-$(basename "$top")}${cwd#"$top"}"
    # Claude Code's own worktrees name the branch worktree-<name>.
    case "$branch" in
      "$worktree_name"|"worktree-$worktree_name"|"$(basename "$top")"|"worktree-$(basename "$top")") branch="" ;;
    esac
  fi
fi

short_cwd="${display_dir/#$home/\~}"

# Decorative colours: Orbit's palette when it is readable, otherwise the values
# the palette was generated from, so the line still renders on a bare machine.
fg_or() { # $1 = "r;g;b" from the palette, $2 = fallback escape
    if [ -n "$1" ]; then printf '\033[38;2;%sm' "$1"; else printf '%b' "$2"; fi
}
BLUE=$(fg_or "$palette_accent"            '\033[38;2;173;198;255m')  # directory
GRAY=$(fg_or "$palette_muted"             '\033[38;2;191;198;220m')  # git branch
PURPLE=$(fg_or "$palette_accent_secondary" '\033[38;2;208;188;255m') # worktree

# Thresholds: fixed on purpose. See the note at the top of this file.
GREEN='\033[38;2;166;218;149m'    # rate-limit under 70%
YELLOW='\033[38;2;245;224;108m'   # rate-limit 70-89%
RED='\033[38;2;255;180;171m'      # rate-limit 90%+
DIM='\033[2m'
RESET='\033[0m'

parts=()

# Directory
if [ -n "$worktree_label" ]; then
  parts+=("$(printf '%b%s%b %b⎇ %s%b' "$BLUE" "$short_cwd" "$RESET" "$PURPLE" "$worktree_label" "$RESET")")
elif [ -n "$short_cwd" ]; then
  parts+=("$(printf '%b%s%b' "$BLUE" "$short_cwd" "$RESET")")
fi

# Git branch
[ -n "$branch" ] && parts+=("$(printf '%b %s%b' "$GRAY" "$branch" "$RESET")")

# 5-hour rate limit usage, colored by threshold
if [ -n "$five_hour_pct" ]; then
  five_hour_rounded=$(printf '%.0f' "$five_hour_pct")
  if [ "$five_hour_rounded" -ge 90 ]; then
    RL_COLOR="$RED"
  elif [ "$five_hour_rounded" -ge 70 ]; then
    RL_COLOR="$YELLOW"
  else
    RL_COLOR="$GREEN"
  fi
  parts+=("$(printf '%b5h:%s%%%b' "$RL_COLOR" "$five_hour_rounded" "$RESET")")
fi

# Model
[ -n "$model" ] && parts+=("$(printf '%b%s%b' "$DIM" "$model" "$RESET")")

# Context usage: absolute tokens (if available) + used percentage, colored by threshold
format_tokens() {
  # Compact k/M formatting of a raw token count
  local n
  n=$(printf '%.0f' "$1")
  if [ "$n" -ge 1000000 ]; then
    awk -v v="$n" 'BEGIN { printf "%.0fM", v / 1000000 }'
  elif [ "$n" -ge 1000 ]; then
    awk -v v="$n" 'BEGIN { printf "%.0fk", v / 1000 }'
  else
    printf '%s' "$n"
  fi
}

if [ -n "$abs_tokens" ] || [ -n "$used_pct" ]; then
  ctx_used_rounded=""
  [ -n "$used_pct" ] && ctx_used_rounded=$(printf '%.0f' "$used_pct")

  CTX_COLOR="$DIM"
  if [ -n "$ctx_used_rounded" ]; then
    if [ "$ctx_used_rounded" -ge 90 ]; then
      CTX_COLOR="$RED"
    elif [ "$ctx_used_rounded" -ge 70 ]; then
      CTX_COLOR="$YELLOW"
    else
      CTX_COLOR="$GREEN"
    fi
  fi

  if [ -n "$abs_tokens" ] && [ -n "$context_window_size" ]; then
    ctx_text="ctx:$(format_tokens "$abs_tokens")/$(format_tokens "$context_window_size")"
    [ -n "$ctx_used_rounded" ] && ctx_text="${ctx_text} (${ctx_used_rounded}%)"
  elif [ -n "$ctx_used_rounded" ]; then
    ctx_text="ctx:${ctx_used_rounded}%"
  else
    ctx_text=""
  fi

  [ -n "$ctx_text" ] && parts+=("$(printf '%b%s%b' "$CTX_COLOR" "$ctx_text" "$RESET")")
fi

# Total session cost (omit when absent or zero)
if [ -n "$total_cost" ]; then
  is_zero=$(awk -v v="$total_cost" 'BEGIN { print (v == 0) ? 1 : 0 }')
  if [ "$is_zero" != "1" ]; then
    cost_text="\$$(printf '%.2f' "$total_cost")"
    parts+=("$(printf '%b%s%b' "$DIM" "$cost_text" "$RESET")")
  fi
fi

# Join with an explicit " | " separator
joined=""
for p in "${parts[@]}"; do
  if [ -z "$joined" ]; then
    joined="$p"
  else
    joined="${joined} | ${p}"
  fi
done

printf '%s' "$joined"
