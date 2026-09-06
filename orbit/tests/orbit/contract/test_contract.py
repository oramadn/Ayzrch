#!/usr/bin/env python3
"""Deterministic contracts for the surviving Orbit/Hyprland architecture."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import os
import subprocess
import tomllib
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
BIN = REPO / "bin"
UNIT_DIR = REPO / "systemd/user"
HYPR = REPO / "config/hypr"
GLOBAL_MENU = REPO / "config/quickshell/global-menu"


def load(name: str, path: Path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class CurrentArchitectureTests(unittest.TestCase):
    def test_current_files_and_syntax(self):
        required = (
            BIN / "orbit-app-launch",
            BIN / "orbit-appmenu",
            BIN / "orbit-appmenu-atspi",
            BIN / "orbit-input-state",
            BIN / "orbit-home-workspaces",
            BIN / "orbit-monitor",
            BIN / "orbit-session-transition",
            BIN / "orbit-home-workspaces",
            BIN / "orbit-theme",
            BIN / "orbit-wallpaper-control",
            BIN / "install-hyprglass",
            BIN / "install-scrolloverview",
            BIN / "workspace-alt-tab",
            BIN / "workspace-alt-tab-release",
            HYPR / "scripts/new-workspace-apps",
            HYPR / "scripts/window-shader-events",
            HYPR / "hyprland.lua",
            HYPR / "appearance.toml",
            GLOBAL_MENU / "shell.qml",
        )
        self.assertFalse([str(path) for path in required if not path.is_file()])

        shell_scripts = (
            BIN / "orbit-session-transition",
            BIN / "orbit-home-workspaces",
            BIN / "workspace-alt-tab-release",
            HYPR / "scripts/new-workspace-apps",
            HYPR / "scripts/window-shader-events",
        )
        for path in shell_scripts:
            self.assertTrue(os.access(path, os.X_OK), path)
            subprocess.run(["bash", "-n", str(path)], check=True, capture_output=True, text=True)
        for path in (BIN / "orbit-input-state", BIN / "orbit-monitor", BIN / "orbit-theme", BIN / "workspace-alt-tab"):
            compile(path.read_text(), str(path), "exec")

        for path in (REPO / "config").rglob("*.toml"):
            tomllib.loads(path.read_text())
        for path in (REPO / "config").rglob("*.json"):
            if path.name != "settings.json" or path.parent.name != "zed":
                json.loads(path.read_text())

    def test_current_startup_graph(self):
        hyprland = (HYPR / "hyprland.lua").read_text()
        self.assertIn('hl.exec_cmd("/usr/bin/noctalia &")', hyprland)
        self.assertIn(
            'quickshell .. " --config global-menu --no-duplicate &"',
            hyprland,
        )
        self.assertNotIn("orbit-shell", hyprland)
        self.assertNotIn("wallpaper-session-effects", hyprland)
        self.assertNotIn("quickshell/orbit", hyprland)

    def test_global_menu_config_is_current(self):
        source = "\n".join(path.read_text() for path in GLOBAL_MENU.glob("*.qml"))
        self.assertIn("ApplicationActionsSurface", source)
        self.assertIn("MenuSurface", source)
        self.assertIn("noctalia-global-menu-anchor", source)
        self.assertNotIn("quickshell/orbit", source)

    def test_removed_architecture_is_not_required(self):
        removed = (
            REPO / "config/quickshell/orbit",
            BIN / "orbit-shell",
            BIN / "orbit-shell-ui",
            REPO / "config/hyprshell",
            REPO / "config/hypr/scripts/hyprshell-start",
            UNIT_DIR / "orbit-shell.service",
            UNIT_DIR / "wallpaper-session-effects.service",
            REPO / "config/hypr/scripts/wallpaper-session-effects",
            BIN / "orbit-colors-extract.retired",
            BIN / "orbit-wallpaper-engine.pre-recovery-fix",
        )
        self.assertFalse([str(path) for path in removed if path.exists()])

    def test_current_units_and_session_target(self):
        target = (UNIT_DIR / "hyprland-session.target").read_text()
        for service in (
            "workspace-alt-tab-input.service",
            "workspace-alt-tab-release.service",
            "new-workspace-apps.service",
        ):
            self.assertIn(f"Wants={service}", target)

        expected_exec = {
            "orbit-wallpaper-engine.service": "%h/.local/bin/orbit-wallpaper-engine",
            # Arch has no `sg` (shadow ships newgrp only); `input` group
            # membership is granted at install instead.
            "workspace-alt-tab-input.service": "%h/.local/bin/orbit-input-state",
            "workspace-alt-tab-release.service": "%h/.local/bin/workspace-alt-tab-release",
            "new-workspace-apps.service": "%h/.config/hypr/scripts/new-workspace-apps",
            "window-shader-events.service": "%h/.config/hypr/scripts/window-shader-events",
        }
        for unit, command in expected_exec.items():
            self.assertIn(f"ExecStart={command}", (UNIT_DIR / unit).read_text())

    def test_new_workspace_canonical_service_ownership_contract(self):
        service = (UNIT_DIR / "new-workspace-apps.service").read_text()
        script = (HYPR / "scripts/new-workspace-apps").read_text()
        self.assertIn("ExecStart=%h/.config/hypr/scripts/new-workspace-apps", service)
        self.assertIn("WantedBy=hyprland-session.target", service)
        self.assertIn("is_allowlisted", script)
        self.assertIn("openwindow>>", script)
        self.assertIn("flock -x 9", script)
        self.assertNotIn('hl.exec_cmd(scripts .. "/new-workspace-apps &")', (HYPR / "hyprland.lua").read_text())

    def test_plugins_are_configured_and_referenced(self):
        hyprland = (HYPR / "hyprland.lua").read_text()
        for name in (
            "hyprGlassPlugin",
            "hyprWindowShadePlugin",
            "scrollOverviewPlugin",
        ):
            self.assertIn(name, hyprland)

    def test_input_state_and_alt_tab_contract(self):
        unit = (UNIT_DIR / "workspace-alt-tab-input.service").read_text()
        helper = (BIN / "orbit-input-state").read_text()
        release = (BIN / "workspace-alt-tab-release").read_text()
        self.assertIn("orbit-input-state", unit)
        self.assertIn("RuntimeDirectory=orbit", unit)
        self.assertIn("pyudev", helper)
        self.assertIn("selectors", helper)
        self.assertIn("EAGAIN", helper)
        self.assertIn("ALT_CODES", helper)
        self.assertNotIn("ID_INPUT_KEYBOARD", helper)
        self.assertIn("alt-held", release)
        self.assertIn('workspace-alt-tab" close', release)

    def test_home_workspace_contract(self):
        helper = (BIN / "orbit-home-workspaces").read_text()
        alt_tab = (BIN / "workspace-alt-tab").read_text()
        self.assertIn("1 + index * 5", helper)
        self.assertIn("sort_by([(.x // 0), (.y // 0), (.name // \"\")])", helper)
        self.assertIn('rule.get("persistent") is True', alt_tab)
        self.assertIn('rule.get("default") is True', alt_tab)

    def test_input_module_contract(self):
        module = load("orbit_input_state_contract", BIN / "orbit-input-state")
        if module.ecodes is None:
            self.skipTest("python-evdev is not installed")
        self.assertFalse(module.has_alt_capability({module.ecodes.EV_KEY: [30, 272]}))
        self.assertTrue(module.has_alt_capability({module.ecodes.EV_KEY: [56]}))
        self.assertTrue(module.has_alt_capability({module.ecodes.EV_KEY: [100]}))

    def test_wallpaper_and_transition_contract(self):
        # The renderer is built from the pinned external checkout rather than
        # tracked here, so its contract is checked where it is installed.
        installed = Path.home() / ".local/bin/orbit-wallpaper-engine"
        transition = (BIN / "orbit-session-transition").read_text()
        if installed.is_file():
            wallpaper = installed.read_bytes()
            self.assertIn(b"ORBIT_WALLPAPER_CONTROL_FILE", wallpaper)
            self.assertNotIn(b"ps3-wave-wallpaper", wallpaper)
        self.assertIn("orbit-wallpaper-engine.service", transition)
        self.assertIn("orbit-session-transition", transition)
        self.assertNotIn("wallpaper-session-effects", transition)

    def test_wallpaper_external_integration_install_contract(self):
        installer = (BIN / "dotfiles-install-wallpaper").read_text()
        self.assertIn("integrations/noctalia", installer)
        self.assertIn("orbit-wallpaper-settings", installer)
        self.assertIn("install_noctalia_integration", installer)
        self.assertIn('ORBIT_WALLPAPER_REF:-v0.2.0', installer)

    def test_pinned_core_plugin_installers_contract(self):
        installers = {
            "install-hyprglass": (
                "https://github.com/hyprnux/hyprglass.git",
                "5bc835dcc909cef6980291688143048cf16942b5",
                "make",
                "hyprglass.so",
            ),
            "install-scrolloverview": (
                "https://github.com/yayuuu/hyprland-scroll-overview.git",
                "f9248ab6bee770e9d68813b48cc6ca12b3271254",
                "make all",
                "libscrolloverview.so",
            ),
        }
        tracked = subprocess.run(
            ["git", "-C", str(REPO), "ls-files", "*.so"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        self.assertEqual(tracked, "")
        for name, (url, revision, build, output) in installers.items():
            path = BIN / name
            source = path.read_text()
            self.assertTrue(os.access(path, os.X_OK), path)
            self.assertIn(url, source)
            self.assertIn(revision, source)
            self.assertIn(build, source)
            self.assertIn(output, source)
            self.assertNotIn("origin/main", source)
            self.assertNotIn("refs/heads/main", source)
            self.assertIn("source_dir=", source)
            self.assertIn("plugin_dir=", source)
            self.assertNotIn('source_dir="$REPO', source)

    def test_wallpaper_launcher_routes_through_hyprland_placement(self):
        launcher = (BIN / "orbit-wallpaper-launcher").read_text()
        desktop = (REPO / "desktop/orbit-wallpaper-engine-settings.desktop").read_text()
        self.assertIn("hl.dsp.exec_cmd", launcher)
        self.assertIn('size = { 560, 760 }', launcher)
        self.assertIn('monitor_w-560-20', launcher)
        self.assertIn('45 }', launcher)
        self.assertIn("Exec=orbit-wallpaper-launcher", desktop)
        self.assertNotIn("Exec=orbit-wallpaper-settings", desktop)


if __name__ == "__main__":
    unittest.main()
