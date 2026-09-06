#!/usr/bin/env python3

import importlib.machinery
import importlib.util
import errno
import os
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "bin/orbit-input-state"
LOADER = importlib.machinery.SourceFileLoader("orbit_input_state", str(SOURCE))
SPEC = importlib.util.spec_from_loader("orbit_input_state", LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def payload(event_type, code, value):
    return MODULE.EVENT.pack(0, 0, event_type, code, value)


class FakeReader:
    def __init__(self, values):
        self.values = iter(values)

    def __call__(self, _fd, _size):
        value = next(self.values)
        if isinstance(value, BaseException):
            raise value
        return value


class InputStateTests(unittest.TestCase):
    def test_device_capability_selection(self):
        key = MODULE.ecodes.EV_KEY
        self.assertFalse(MODULE.has_alt_capability({key: [30, 272]}))
        self.assertTrue(MODULE.has_alt_capability({key: [30, 56]}))
        self.assertTrue(MODULE.has_alt_capability({key: [100]}))

    def test_mixed_pointer_without_alt_is_rejected(self):
        key = MODULE.ecodes.EV_KEY
        self.assertFalse(MODULE.has_alt_capability({key: [272, 273]}))

    def test_event_queue_is_drained_until_eagain(self):
        state = MODULE.AltState(writer=lambda _held: None)
        reader = FakeReader([
            payload(MODULE.EV_KEY, 56, 1),
            payload(MODULE.EV_KEY, 56, 0),
            BlockingIOError(errno.EAGAIN, "would block"),
        ])
        self.assertTrue(MODULE.drain_device(3, "/dev/input/event-test", state, reader=reader))
        self.assertEqual(state.devices["/dev/input/event-test"], set())

    def test_aggregate_alt_across_devices(self):
        writes = []
        state = MODULE.AltState(writer=writes.append)
        state.event("a", MODULE.EV_KEY, 56, 1)
        state.event("b", MODULE.EV_KEY, 100, 1)
        state.event("a", MODULE.EV_KEY, 56, 0)
        self.assertEqual(writes, [True])
        state.event("b", MODULE.EV_KEY, 100, 0)
        self.assertEqual(writes, [True, False])

    def test_one_device_release_does_not_clear_other_device(self):
        writes = []
        state = MODULE.AltState(writer=writes.append)
        state.set_device_state("a", {56})
        state.set_device_state("b", {100})
        state.event("a", MODULE.EV_KEY, 56, 0)
        self.assertEqual(writes, [True])
        self.assertTrue(state.held)

    def test_device_removal_recomputes_aggregate(self):
        writes = []
        state = MODULE.AltState(writer=writes.append)
        state.set_device_state("a", {56})
        state.set_device_state("b", {100})
        state.remove_device("a")
        self.assertEqual(writes, [True])
        state.remove_device("b")
        self.assertEqual(writes, [True, False])

    def test_reconnect_initial_key_state(self):
        writes = []
        state = MODULE.AltState(writer=writes.append)
        state.set_device_state("a", {100})
        self.assertEqual(writes, [True])

    def test_atomic_output_contract(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "alt-held"
            temporary = path.with_name("alt-held.tmp")

            def writer(held):
                temporary.write_text("1\n" if held else "0\n", encoding="ascii")
                os.replace(temporary, path)

            state = MODULE.AltState(writer=writer)
            state.event("a", MODULE.EV_KEY, 56, 1)
            state.event("a", MODULE.EV_KEY, 56, 0)
            self.assertEqual(path.read_text(encoding="ascii"), "0\n")
            self.assertFalse(temporary.exists())


if __name__ == "__main__":
    unittest.main()
