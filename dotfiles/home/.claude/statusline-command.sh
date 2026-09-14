#!/usr/bin/env bash
# Claude Code status line — mirrors Starship config (directory + git branch + model)

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
')

cwd="${fields[0]}"
model="${fields[1]}"
used_pct="${fields[2]}"
worktree_name="${fields[3]}"
five_hour_pct="${fields[4]}"
total_cost="${fields[5]}"
abs_tokens="${fields[6]}"
context_window_size="${fields[7]}"

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Git branch (skip optional locks)
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

# ANSI colors matching Starship theme (dimmed-friendly)
BLUE='\033[38;2;173;198;255m'     # #adc6ff — directory color
GRAY='\033[38;2;191;198;220m'     # #bfc6dc — git branch color
PURPLE='\033[38;2;208;188;255m'   # #d0bcff — worktree color (distinct from git branch)
GREEN='\033[38;2;166;218;149m'    # rate-limit under 70%
YELLOW='\033[38;2;245;224;108m'   # rate-limit 70-89%
RED='\033[38;2;255;180;171m'      # #ffb4ab — rate-limit 90%+ (matches starship error_symbol)
DIM='\033[2m'
RESET='\033[0m'

parts=()

# Directory
[ -n "$short_cwd" ] && parts+=("$(printf '%b%s%b' "$BLUE" "$short_cwd" "$RESET")")

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
