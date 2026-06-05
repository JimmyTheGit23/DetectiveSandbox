#!/usr/bin/env python3
"""
Shared portrait generation specs for NPC portrait pipelines.

This module keeps generation-time framing rules in one place so different
generators do not drift into waist-up / close-up / full-body variants.
"""

from __future__ import annotations

from dataclasses import dataclass
import re

import numpy as np
from PIL import Image


@dataclass(frozen=True)
class PortraitSpec:
    key: str
    canvas_width: int
    canvas_height: int
    subject_height_ratio: float
    crop_padding: int
    bottom_margin_px: int
    framing_prompt: str

    @property
    def canvas(self) -> tuple[int, int]:
        return (self.canvas_width, self.canvas_height)


NPC_KNEE_UP_SPEC = PortraitSpec(
    key="npc_knee_up",
    canvas_width=848,
    canvas_height=1264,
    subject_height_ratio=0.965,
    crop_padding=16,
    bottom_margin_px=0,
    framing_prompt=(
        "COMPOSITION LOCK:\n"
        "- Show exactly one character from the top of the hair to around the knees.\n"
        "- This is NOT waist-up, NOT bust portrait, NOT close-up, and NOT full body.\n"
        "- The character should follow the assistant standard standing portrait scale: about 96% of the total canvas height after cutout.\n"
        "- Keep the top of the hair close to the top margin and let the lower body reach the bottom edge naturally.\n"
        "- Keep hands, sleeves, belt, and knee line fully inside frame, with the dialogue UI expected to cover the lower crop.\n"
        "- Keep the figure centered and consistently grounded for game portrait usage.\n"
        "- Do not crop at the chest, waist, hips, upper thigh, mid-thigh, ankles, or feet.\n"
        "- A portrait ending at the belt, pouch, hip, or thigh is invalid; extend the lower robe/body to the knee area.\n"
    ),
)


PROTAGONIST_IDS = {"lu_zhao", "xia_lingyao"}
RED_TONE_PATTERN = re.compile(
    r"\b(red|dark red|maroon|burgundy|wine|crimson|scarlet|plum|rose|pink|magenta)\b",
    flags=re.IGNORECASE,
)
RED_TONE_HINTS_ZH = ("红", "酒红", "暗红", "绯", "朱", "胭脂", "紫红")


def spec_for_character(char_id: str) -> PortraitSpec | None:
    if char_id in PROTAGONIST_IDS:
        return None
    return NPC_KNEE_UP_SPEC


def chroma_for_text(text: str) -> str:
    if RED_TONE_PATTERN.search(text):
        return "green"
    if any(token in text for token in RED_TONE_HINTS_ZH):
        return "green"
    return "magenta"


def chroma_for_character(char_id: str, description: str = "") -> str:
    if char_id == "shen_qingyue":
        return "green"
    return chroma_for_text(description)


def chroma_background_phrase(chroma: str) -> str:
    if chroma == "green":
        return (
            "Solid pure high-contrast chroma green background #00FF00 "
            "(RGB 0,255,0), flat, no gradient, no sage/olive/moss/desaturated green. "
            "Use this green for red/burgundy/magenta/purple characters before cutout."
        )
    return "Solid pure MAGENTA background #FF00FF, flat, no gradient."


def autocrop_rgba(img: Image.Image, padding: int) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def alpha_bbox(img: Image.Image, threshold: int = 8) -> tuple[int, int, int, int] | None:
    alpha = np.array(img.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > threshold)
    if len(xs) == 0 or len(ys) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def fit_subject_to_spec(img: Image.Image, spec: PortraitSpec) -> Image.Image:
    img = img.convert("RGBA")
    bbox = alpha_bbox(img)
    if bbox is None:
        return Image.new("RGBA", spec.canvas, (0, 0, 0, 0))

    left, top, right, bottom = bbox
    crop_left = max(0, left - spec.crop_padding)
    crop_top = max(0, top - spec.crop_padding)
    crop_right = min(img.width, right + spec.crop_padding)
    crop_bottom = min(img.height, bottom + spec.crop_padding)
    cropped = img.crop((crop_left, crop_top, crop_right, crop_bottom))

    visible_w = right - left
    visible_h = bottom - top
    rel_left = left - crop_left
    rel_bottom = bottom - crop_top

    desired_h = max(1, int(round(spec.canvas_height * spec.subject_height_ratio)))
    scale = min(spec.canvas_width / cropped.width, desired_h / visible_h)
    new_w = max(1, int(round(cropped.width * scale)))
    new_h = max(1, int(round(cropped.height * scale)))
    visible_w_scaled = visible_w * scale
    rel_left_scaled = rel_left * scale
    rel_bottom_scaled = rel_bottom * scale

    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", spec.canvas, (0, 0, 0, 0))
    paste_x = int(round((spec.canvas_width - visible_w_scaled) / 2 - rel_left_scaled))
    paste_y = int(round(spec.canvas_height - spec.bottom_margin_px - rel_bottom_scaled))
    canvas.paste(resized, (paste_x, paste_y), resized)
    return canvas
