#!/usr/bin/env python3
"""Canonical Orbit shape values and derived geometry tokens."""

from __future__ import annotations

import math


SHAPE_RADIUS_MIN = 0
SHAPE_RADIUS_MAX = 32
SHAPE_BUTTONS = ("rounded", "square", "pill")
DEFAULT_SHAPE = {"corner_radius": 10, "button_shape": "rounded"}


def normalise_shape(value: object) -> dict:
    source = value if isinstance(value, dict) else {}
    radius = source.get("corner_radius", DEFAULT_SHAPE["corner_radius"])
    try:
        numeric_radius = float(radius)
        if not math.isfinite(numeric_radius) or numeric_radius != int(numeric_radius):
            raise ValueError
        radius = int(numeric_radius)
    except (TypeError, ValueError):
        radius = DEFAULT_SHAPE["corner_radius"]
    button_shape = str(source.get("button_shape", DEFAULT_SHAPE["button_shape"])).strip()
    return {"corner_radius": radius, "button_shape": button_shape}


def validate_shape(value: object) -> None:
    if not isinstance(value, dict):
        raise ValueError("Shape settings must be an object")
    button_shape = str(value.get("button_shape", "")).strip()
    if button_shape not in SHAPE_BUTTONS:
        raise ValueError("Invalid button shape")
    raw_radius = value.get("corner_radius")
    if isinstance(raw_radius, bool):
        raise ValueError("Corner radius must be numeric")
    try:
        radius = float(raw_radius)
    except (TypeError, ValueError) as error:
        raise ValueError("Corner radius must be numeric") from error
    if not math.isfinite(radius) or radius != int(radius):
        raise ValueError("Corner radius must be a whole number of pixels")
    if radius < SHAPE_RADIUS_MIN or radius > SHAPE_RADIUS_MAX:
        raise ValueError(
            f"Corner radius must be between {SHAPE_RADIUS_MIN} and {SHAPE_RADIUS_MAX} pixels"
        )


def derived_shape_tokens(value: dict) -> dict:
    """Derive semantic consumer values from one canonical base radius.

    Compact controls stay two pixels tighter than surfaces at the default, while
    the clamps prevent pathological geometry on very small or large controls.
    """
    shape = normalise_shape(value)
    radius = shape["corner_radius"]
    return {
        "window_radius": radius,
        "surface_radius": radius,
        "popup_radius": radius,
        "control_radius": max(0, min(12, radius - 2)),
        "compact_radius": max(0, min(8, radius - 4)),
    }
