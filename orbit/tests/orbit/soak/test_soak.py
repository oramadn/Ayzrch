#!/usr/bin/env python3
"""Safe unattended soak for the current Noctalia/Hyprland session graph."""

from __future__ import annotations

import argparse
import json
import os
import signal
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


HOME = Path.home()
BIN = HOME / ".local/bin"
STOP = False
SERVICES = (
    "orbit-wallpaper-engine.service",
    "workspace-alt-tab-input.service",
    "workspace-alt-tab-release.service",
    "new-workspace-apps.service",
    "window-shader-events.service",
    "hypridle.service",
    "hyprpolkitagent.service",
)


def run(command: list[str], timeout: float = 10) -> tuple[int, str, str]:
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as error:
        return 124, "", str(error)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def service_states() -> dict[str, str]:
    states = {}
    for service in SERVICES:
        code, output, error = run(["systemctl", "--user", "is-active", service])
        states[service] = output if code == 0 else f"failed: {error or output}"
    return states


def process_lines() -> list[str]:
    code, output, _ = run(["ps", "-eo", "pid=,args="])
    return output.splitlines() if code == 0 else []


def live_process_failures() -> list[str]:
    processes = process_lines()
    failures = []
    menu = [line for line in processes if "--config global-menu --no-duplicate" in line]
    noctalia = [line for line in processes if "/usr/bin/noctalia" in line]
    if len(menu) != 1:
        failures.append(f"global-menu process count={len(menu)}")
    if len(noctalia) != 1:
        failures.append(f"Noctalia process count={len(noctalia)}")
    if any("orbit-shell" in line or "hyprshell" in line or "wallpaper-session-effects" in line for line in processes):
        failures.append("retired process family present")
    return failures


def snapshot() -> dict:
    values = {}
    for name, command in {
        "monitors": ["hyprctl", "monitors", "-j"],
        "clients": ["hyprctl", "clients", "-j"],
        "workspaces": ["hyprctl", "workspaces", "-j"],
        "activeworkspace": ["hyprctl", "activeworkspace", "-j"],
    }.items():
        code, output, error = run(command)
        if code != 0:
            raise RuntimeError(f"{name}: {error or output}")
        values[name] = json.loads(output)
    return values


def stop(_signum, _frame):
    global STOP
    STOP = True


def main() -> int:
    parser = argparse.ArgumentParser(prog="orbit-soak")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--hours", type=float, default=None)
    group.add_argument("--minutes", type=float, choices=(1.0, 2.0), default=None)
    parser.add_argument("--interval", type=float, default=30.0)
    args = parser.parse_args()
    duration = args.minutes * 60 if args.minutes is not None else (args.hours if args.hours is not None else 8.0) * 3600
    if duration <= 0 or args.interval <= 0:
        parser.error("duration and interval must be positive")

    state_root = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "orbit/tests"
    run_dir = state_root / f"soak-{datetime.now(timezone.utc).strftime('%Y-%m-%dT%H-%M-%SZ')}-{os.getpid()}"
    run_dir.mkdir(parents=True, exist_ok=True)
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    failures = []
    events = []
    deadline = time.monotonic() + duration
    iteration = 0

    while not STOP and time.monotonic() < deadline:
        iteration += 1
        event = {"iteration": iteration, "time": datetime.now(timezone.utc).isoformat()}
        states = service_states()
        event["services"] = states
        failures_now = [f"{name}: {state}" for name, state in states.items() if state != "active"]
        failures_now.extend(live_process_failures())
        try:
            event["snapshot"] = snapshot()
        except Exception as error:  # noqa: BLE001
            failures_now.append(repr(error))
        event["failures"] = failures_now
        events.append(event)
        failures.extend(f"iteration {iteration}: {failure}" for failure in failures_now)
        remaining = deadline - time.monotonic()
        if remaining > 0 and not STOP:
            time.sleep(min(args.interval, remaining))

    (run_dir / "events.json").write_text(json.dumps(events, indent=2) + "\n")
    summary = {
        "status": "INCOMPLETE" if STOP else ("PASS" if not failures else "FAIL"),
        "iterations": iteration,
        "failures": failures,
        "log_dir": str(run_dir),
    }
    (run_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    return 2 if STOP else (0 if not failures else 1)


if __name__ == "__main__":
    raise SystemExit(main())
