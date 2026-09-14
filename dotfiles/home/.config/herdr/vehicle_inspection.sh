#!/usr/bin/env bash
#
# vehicle_inspection.sh — herdr launcher (port of ~/.config/tmuxinator/vehicle_inspection.yml)
#
# Run it from inside a running herdr session:
#     ~/.config/herdr/vehicle_inspection.sh
# (Optionally add a shell alias, e.g.  alias vi-herdr='~/.config/herdr/vehicle_inspection.sh')
#
# Lives under ~/.config/herdr so it syncs via chezmoi. Only this file is tracked by
# chezmoi — herdr's sockets/logs/session.json are intentionally left unmanaged.
#
# Mapping from tmuxinator -> herdr:
#   tmuxinator session  -> herdr workspace
#   tmuxinator window   -> herdr tab
#   tmuxinator pane     -> herdr pane
#
# NOTE: the tmuxinator on_project_start hook (prefix+C -> spawn a `cc:<label>` Claude
# window) is NOT ported. It was a tmux-only keybinding. herdr has native agent support;
# if you want a key for it, add a [[keys.command]] entry to config.toml instead.

set -euo pipefail

HERDR="${HERDR:-herdr}"
ROOT="/home/omar/Workspace/connectedmotion/vehicle-inspection"
BACKEND="$ROOT/backend"
MOBILE="$ROOT/mobile"

# --- helpers ---------------------------------------------------------------
# Extract a dotted path from JSON on stdin, e.g.  jget result.workspace.workspace_id
jget() {
  python3 -c 'import sys,json
d=json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d=d[k]
print(d)' "$1"
}

# Type a command into a pane'\''s interactive shell (+Enter). Keeps the shell alive,
# matching tmuxinator'\''s send-keys behaviour.
run() { "$HERDR" pane run "$1" "${@:2}" >/dev/null; }

# --- preflight -------------------------------------------------------------
if ! "$HERDR" workspace list >/dev/null 2>&1; then
  echo "herdr server not reachable. Start herdr first, then run this script." >&2
  exit 1
fi

# Idempotent: if a vehicle_inspection workspace already exists, just focus it.
EXISTING=$("$HERDR" workspace list | python3 -c 'import sys,json
for w in json.load(sys.stdin)["result"]["workspaces"]:
    if w["label"] == "vehicle_inspection":
        print(w["workspace_id"]); break')
if [ -n "$EXISTING" ]; then
  echo "vehicle_inspection already open ($EXISTING); focusing it."
  "$HERDR" workspace focus "$EXISTING" >/dev/null
  exit 0
fi

# --- workspace + tab 1: editor (nvim) --------------------------------------
CREATE=$("$HERDR" workspace create --cwd "$ROOT" --label vehicle_inspection --focus)
WS=$(echo "$CREATE"       | jget result.workspace.workspace_id)
EDITOR_TAB=$(echo "$CREATE" | jget result.tab.tab_id)
EDITOR_PANE=$(echo "$CREATE" | jget result.root_pane.pane_id)
"$HERDR" tab rename "$EDITOR_TAB" editor >/dev/null
run "$EDITOR_PANE" nvim

# --- tab 2: server (stacked: server + ngrok) -------------------------------
S=$("$HERDR" tab create --workspace "$WS" --cwd "$BACKEND" --label server)
SERVER_PANE=$(echo "$S" | jget result.root_pane.pane_id)
NGROK_PANE=$("$HERDR" pane split --pane "$SERVER_PANE" --direction down | jget result.pane.pane_id)
run "$SERVER_PANE" source .venv/bin/activate
run "$SERVER_PANE" uv run run-local
run "$NGROK_PANE"  ngrok http 8087

# --- tab 3: mobile (stacked: editor + devices) -----------------------------
M=$("$HERDR" tab create --workspace "$WS" --cwd "$MOBILE" --label mobile)
MOBILE_EDIT_PANE=$(echo "$M" | jget result.root_pane.pane_id)
MOBILE_DEV_PANE=$("$HERDR" pane split --pane "$MOBILE_EDIT_PANE" --direction down | jget result.pane.pane_id)
run "$MOBILE_EDIT_PANE" nvim
run "$MOBILE_DEV_PANE"  flutter devices

# --- tab 4: docker (lazydocker) --------------------------------------------
D=$("$HERDR" tab create --workspace "$WS" --cwd "$ROOT" --label docker)
DOCKER_PANE=$(echo "$D" | jget result.root_pane.pane_id)
run "$DOCKER_PANE" lazydocker

# Land on the editor tab, like tmuxinator opens on the first window.
"$HERDR" tab focus "$EDITOR_TAB" >/dev/null 2>&1 || true

echo "vehicle_inspection ready ($WS)."
