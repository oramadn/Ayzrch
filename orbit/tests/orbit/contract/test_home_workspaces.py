#!/usr/bin/env python3
"""Synthetic, read-only validation of Orbit Home-workspace topology."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch


REPO = Path(__file__).resolve().parents[3]
HELPER = REPO / "bin/orbit-home-workspaces"
ALT_TAB = REPO / "bin/workspace-alt-tab"


def load_alt_tab():
    loader = importlib.machinery.SourceFileLoader("orbit_alt_tab_topology", str(ALT_TAB))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def mapping(monitors):
    result = subprocess.run(
        [str(HELPER), "--dry-run"],
        input=json.dumps(monitors),
        text=True,
        capture_output=True,
        check=True,
    )
    return [line.split("\t")[:2] for line in result.stdout.splitlines()]


class HomeWorkspaceTopologyTests(unittest.TestCase):
    def test_topologies_and_disconnect_reconnect(self):
        cases = {
            "one": ([{"name": "MONITOR-A", "x": 0, "y": 0}], [("MONITOR-A", "1")]),
            "reference": (
                [{"name": "MONITOR-A", "x": 0, "y": 0}, {"name": "MONITOR-B", "x": 1920, "y": 0}],
                [("MONITOR-A", "1"), ("MONITOR-B", "6")],
            ),
            "reversed_names": (
                [{"name": "Z", "x": 0, "y": 0}, {"name": "A", "x": 1920, "y": 0}],
                [("Z", "1"), ("A", "6")],
            ),
            "reversed_placement": (
                [{"name": "MONITOR-A", "x": 1920, "y": 0}, {"name": "MONITOR-B", "x": 0, "y": 0}],
                [("MONITOR-B", "1"), ("MONITOR-A", "6")],
            ),
            "vertical": (
                [{"name": "TOP", "x": 0, "y": -1080}, {"name": "BOTTOM", "x": 0, "y": 0}],
                [("TOP", "1"), ("BOTTOM", "6")],
            ),
            "three": (
                [{"name": "C", "x": 1920, "y": 0}, {"name": "A", "x": 0, "y": 0}, {"name": "B", "x": 960, "y": 0}],
                [("A", "1"), ("B", "6"), ("C", "11")],
            ),
            "four": (
                [{"name": "D", "x": 0, "y": 1080}, {"name": "B", "x": 0, "y": 0}, {"name": "A", "x": -1920, "y": 0}, {"name": "C", "x": 1920, "y": 0}],
                [("A", "1"), ("B", "6"), ("D", "11"), ("C", "16")],
            ),
            "tie_break": (
                [{"name": "B", "x": 0, "y": 0}, {"name": "A", "x": 0, "y": 0}],
                [("A", "1"), ("B", "6")],
            ),
        }
        for name, (monitors, expected) in cases.items():
            with self.subTest(name=name):
                self.assertEqual(mapping(monitors), [list(item) for item in expected])

        disconnected = [{"name": "MONITOR-A", "x": 0, "y": 0}, {"name": "MONITOR-B", "x": 1920, "y": 0}]
        reconnected = [{"name": "MONITOR-B", "x": 1920, "y": 0}, {"name": "MONITOR-A", "x": 0, "y": 0}]
        self.assertEqual(mapping(disconnected), mapping(reconnected))

    def test_temporary_rules_are_excluded_and_one_blank_stop_remains(self):
        module = load_alt_tab()
        monitor = "MONITOR-A"
        self.assertTrue(module.is_home_rule({"monitor": monitor, "default": True, "persistent": True}, monitor))
        self.assertFalse(module.is_home_rule({"monitor": monitor, "default": True, "persistent": False}, monitor))
        workspaces = [{"name": "1", "monitor": monitor, "windows": 0}]
        rules = [
            {"workspace": "1", "monitor": monitor, "default": True, "persistent": True},
            {"workspace": "99", "monitor": monitor, "default": True, "persistent": False},
        ]
        with patch.object(module, "hypr", side_effect=[workspaces, rules]):
            items = module.workspace_items(monitor)
        self.assertEqual([item["name"] for item in items], ["1"])

    def test_alt_tab_pins_monitor_until_release_then_recaptures(self):
        module = load_alt_tab()
        state = {"open": False, "monitor": "", "selected": "", "mru": []}

        self.assertEqual(module.resolve_cycle_monitor(state, "MONITOR-A", {"MONITOR-A", "MONITOR-B"}), "MONITOR-A")
        self.assertEqual(state["monitor"], "MONITOR-A")
        state["open"] = True
        self.assertEqual(module.resolve_cycle_monitor(state, "MONITOR-B", {"MONITOR-A", "MONITOR-B"}), "MONITOR-A")
        self.assertEqual(state["monitor"], "MONITOR-A")

        state["monitor"] = "MONITOR-A"
        self.assertEqual(module.resolve_cycle_monitor(state, "MONITOR-B", {"MONITOR-B"}), "MONITOR-B")
        self.assertEqual(state["monitor"], "MONITOR-B")

        state.update({"open": False, "monitor": ""})
        self.assertEqual(module.resolve_cycle_monitor(state, "MONITOR-B", {"MONITOR-A", "MONITOR-B"}), "MONITOR-B")
        self.assertEqual(state["monitor"], "MONITOR-B")


if __name__ == "__main__":
    unittest.main()
