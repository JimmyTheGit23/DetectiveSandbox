#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Condition DSL helpers for case table authoring."""

from __future__ import annotations

import json
import re
from typing import Any, Dict, List, Optional


_OP_KEYS = {
    ">=": "gte",
    "<=": "lte",
    "==": "eq",
    ">": "gt",
    "<": "lt",
}


def is_blank(value: Any) -> bool:
    return value is None or str(value).strip() == ""


def split_top_level(text: str, sep: str = ",") -> List[str]:
    parts: List[str] = []
    buf: List[str] = []
    depth = 0
    in_quote = False
    quote_char = ""
    escape = False
    for ch in text:
        if escape:
            buf.append(ch)
            escape = False
            continue
        if ch == "\\" and in_quote:
            buf.append(ch)
            escape = True
            continue
        if ch in ('"', "'"):
            if in_quote and ch == quote_char:
                in_quote = False
                quote_char = ""
            elif not in_quote:
                in_quote = True
                quote_char = ch
            buf.append(ch)
            continue
        if not in_quote:
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
            elif ch == sep and depth == 0:
                item = "".join(buf).strip()
                if item:
                    parts.append(item)
                buf = []
                continue
        buf.append(ch)
    item = "".join(buf).strip()
    if item:
        parts.append(item)
    return parts


def parse_list(value: Any) -> List[str]:
    if is_blank(value):
        return []
    if isinstance(value, list):
        return [str(x).strip() for x in value if str(x).strip()]
    text = str(value).strip()
    if text.startswith("["):
        parsed = json.loads(text)
        if isinstance(parsed, list):
            return [str(x).strip() for x in parsed if str(x).strip()]
    sep = ";" if ";" in text else ","
    return [x.strip() for x in split_top_level(text, sep) if x.strip()]


def parse_bool(value: Any, default: bool = False) -> bool:
    if is_blank(value):
        return default
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() in {"1", "true", "yes", "y", "是", "对"}


def parse_int(value: Any, default: Optional[int] = None) -> Optional[int]:
    if is_blank(value):
        return default
    return int(float(str(value).strip()))


def parse_float_list(value: Any) -> List[float]:
    if is_blank(value):
        return []
    if isinstance(value, list):
        return [float(x) for x in value]
    return [float(x) for x in parse_list(value)]


def compact_json(value: Any) -> str:
    if value is None or value == "":
        return ""
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def _parse_call(name: str, text: str) -> Optional[str]:
    prefix = name + "("
    if not text.startswith(prefix) or not text.endswith(")"):
        return None
    return text[len(prefix):-1].strip()


def parse_condition(value: Any) -> Any:
    """Parse a table condition cell into the runtime condition dictionary.

    Blank cells return None. JSON dictionaries/lists are accepted as-is.
    """
    if is_blank(value):
        return None
    if isinstance(value, (dict, list)):
        return value
    text = str(value).strip()
    if text.startswith("{") or text.startswith("["):
        return json.loads(text)

    # Semicolon at top level is shorthand for all(...).
    if ";" in text:
        parts = split_top_level(text, ";")
        if len(parts) > 1:
            return {"all": [parse_condition(p) for p in parts]}

    inner = _parse_call("all", text)
    if inner is not None:
        return {"all": [parse_condition(p) for p in split_top_level(inner)]}
    inner = _parse_call("any", text)
    if inner is not None:
        return {"any": [parse_condition(p) for p in split_top_level(inner)]}
    inner = _parse_call("not", text)
    if inner is not None:
        return {"not": parse_condition(inner)}
    inner = _parse_call("state", text)
    if inner is not None:
        m = re.match(r"^([A-Za-z0-9_]+\.[A-Za-z0-9_]+)\s*(>=|<=|==|>|<)\s*(-?\d+)$", inner)
        if not m:
            raise ValueError("invalid state condition: %s" % text)
        return {"state": m.group(1), _OP_KEYS[m.group(2)]: int(m.group(3))}

    for prefix, key in [
        ("evidence:", "evidence"),
        ("clue:", "clue"),
        ("flag:", "flag"),
        ("not_flag:", "not_flag"),
        ("visited:", "visited"),
        ("location:", "location"),
        ("location_unlocked:", "location_unlocked"),
    ]:
        if text.startswith(prefix):
            ident = text[len(prefix):].strip()
            if not ident:
                raise ValueError("empty identifier in condition: %s" % text)
            return {key: ident}

    for field, runtime_prefix in [
        ("day", "day"),
        ("period", "period"),
        ("total_periods_used", "total_periods_used"),
        ("evidence_count", "evidence_count"),
        ("clue_count", "clue_count"),
    ]:
        m = re.match(r"^%s\s*(>=|<=|==)\s*(-?\d+)$" % re.escape(field), text)
        if m:
            suffix = {">=": "gte", "<=": "lte", "==": "eq"}[m.group(1)]
            return {"%s_%s" % (runtime_prefix, suffix): int(m.group(2))}

    raise ValueError("unknown condition DSL: %s" % text)


def condition_to_cell(value: Any) -> str:
    return compact_json(value)
