#!/usr/bin/env python3
"""Read-only checks against the current Hyprland user session."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import time
from pathlib import Path


RESULTS = []
TIMEOUT = 15


class SkipTest(Exception):
    pass


def check(name, function):
    try:
        function()
    except SkipTest as error:
        RESULTS.append({"id": name, "status": "SKIP", "reason": str(error)})
    except Exception as error:  # noqa: BLE001
        RESULTS.append({"id": name, "status": "FAIL", "error": repr(error)})
    else:
        RESULTS.append({"id": name, "status": "PASS"})


def command(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True, timeout=TIMEOUT).stdout.strip()


def require_session():
    if os.geteuid() == 0:
        raise SkipTest("run as the desktop user, not root")
    if not os.environ.get("XDG_RUNTIME_DIR") or not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        raise SkipTest("Hyprland user-session environment is unavailable")
    if not Path("/usr/bin/hyprctl").exists():
        raise SkipTest("hyprctl is unavailable")


def current_processes():
    return subprocess.run(["ps", "-eo", "pid=,args="], check=True, capture_output=True, text=True).stdout.splitlines()


def check_session_json():
    require_session()
    for args in (
        ("monitors", "-j"),
        ("clients", "-j"),
        ("workspaces", "-j"),
        ("activeworkspace", "-j"),
    ):
        json.loads(command("hyprctl", *args))


def check_noctalia_and_global_menu():
    require_session()
    processes = current_processes()
    noctalia_name = Path(shutil.which("noctalia") or "noctalia").name

    def argv(line):
        return line.split(None, 1)[1].split()

    noctalia = [line for line in processes if argv(line) and Path(argv(line)[0]).name == noctalia_name]
    menu = [
        line for line in processes
        if len(argv(line)) >= 4
        and Path(argv(line)[0]).name == "quickshell"
        and argv(line)[1:4] == ["--config", "global-menu", "--no-duplicate"]
    ]
    assert len(noctalia) == 1, noctalia
    assert len(menu) == 1, menu
    assert not any("orbit-shell" in line or "hyprshell" in line for line in processes)


def check_plugins():
    require_session()
    output = command("hyprctl", "plugins", "list").lower()
    for name in ("hyprglass", "hyprwindowshade", "scrolloverview"):
        assert name in output, output


def check_services():
    require_session()
    services = (
        "orbit-wallpaper-engine.service",
        "workspace-alt-tab-input.service",
        "workspace-alt-tab-release.service",
        "new-workspace-apps.service",
        "window-shader-events.service",
        "hypridle.service",
        "hyprpolkitagent.service",
    )
    result = subprocess.run(["systemctl", "--user", "is-active", *services], check=False, capture_output=True, text=True, timeout=TIMEOUT)
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.splitlines() == ["active"] * len(services), result.stdout


def check_input_idle_cpu():
    require_session()
    helper = str(Path.home() / ".local/bin/orbit-input-state")
    matches = [line.split(None, 1)[0] for line in current_processes() if line.rstrip().endswith(f"python3 {helper}")]
    assert len(matches) == 1, matches
    pid = matches[0]
    ticks = lambda: int(Path(f"/proc/{pid}/stat").read_text().split()[13]) + int(Path(f"/proc/{pid}/stat").read_text().split()[14])
    hz = os.sysconf(os.sysconf_names["SC_CLK_TCK"])
    before = ticks()
    time.sleep(10)
    after = ticks()
    cpu_percent = (after - before) / hz / 10 * 100
    assert cpu_percent < 5.0, cpu_percent
    assert Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid}") + "/orbit/alt-held").read_text() in {"0\n", "1\n"}


def check_no_stale_references():
    require_session()
    hyprland = (Path.home() / ".config/hypr/hyprland.lua").read_text()
    assert "quickshell/orbit" not in hyprland
    processes = current_processes()
    assert not any("orbit-shell" in line or "hyprshell" in line or "wallpaper-session-effects" in line for line in processes)


def main() -> int:
    check("LIVE-001", check_session_json)
    check("LIVE-002", check_noctalia_and_global_menu)
    check("LIVE-003", check_plugins)
    check("LIVE-004", check_services)
    check("LIVE-005", check_input_idle_cpu)
    check("LIVE-006", check_no_stale_references)
    print(json.dumps({"tests": RESULTS}, indent=2))
    return 1 if any(item["status"] != "PASS" for item in RESULTS) else 0


if __name__ == "__main__":
    raise SystemExit(main())
