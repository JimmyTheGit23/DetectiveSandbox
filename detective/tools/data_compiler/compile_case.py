#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compile case CSV tables into Godot runtime JSON.

Default output is data/case_tables/<case_id>/_compiled/ for safe preview.
Use --write-runtime to write into data/cases/<case_id>/.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
DATA = REPO_ROOT / "data"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from dsl import (  # noqa: E402
    compact_json,
    is_blank,
    parse_bool,
    parse_condition,
    parse_float_list,
    parse_int,
    parse_list,
)


JsonDict = Dict[str, Any]


def _cell(row: JsonDict, key: str, default: str = "") -> str:
    value = row.get(key, default)
    if value is None:
        return default
    return str(value).strip()


def _rows(path: Path) -> List[JsonDict]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        out: List[JsonDict] = []
        for row in reader:
            if not row:
                continue
            values = [str(v).strip() for v in row.values() if v is not None]
            if not any(values):
                continue
            first = values[0] if values else ""
            if first.startswith("#"):
                continue
            out.append({str(k).strip(): (v if v is not None else "") for k, v in row.items()})
        return out


def _set_if(d: JsonDict, key: str, value: Any) -> None:
    if value is None:
        return
    if isinstance(value, str) and value == "":
        return
    if isinstance(value, list) and not value:
        return
    d[key] = value


def _set_condition(d: JsonDict, key: str, value: Any) -> None:
    if is_blank(value):
        return
    d[key] = parse_condition(value)


def _set_flags_from_cell(d: JsonDict, value: Any) -> None:
    flags = parse_list(value)
    if flags:
        d["set_flags"] = flags


def _result_payload(row: JsonDict) -> JsonDict:
    d: JsonDict = {}
    _set_if(d, "intro_text", _cell(row, "intro_text"))
    _set_if(d, "narration", _cell(row, "narration"))
    evidence = _cell(row, "gain_evidence") or _cell(row, "evidence")
    clue = _cell(row, "gain_clue") or _cell(row, "clue")
    _set_if(d, "evidence", evidence)
    _set_if(d, "clue", clue)
    _set_flags_from_cell(d, row.get("set_flags", ""))
    _set_if(d, "trigger_dialogue", _cell(row, "trigger_dialogue"))
    _set_if(d, "trigger_dialogue_start", _cell(row, "trigger_dialogue_start"))
    time_cost = parse_int(row.get("time_cost", ""))
    if time_cost is not None:
        d["time_cost"] = time_cost
    return d


def _parse_json_any_cell(value: Any, default: Any) -> Any:
    if is_blank(value):
        return default
    try:
        return json.loads(str(value))
    except json.JSONDecodeError:
        return default


def compile_evidence(src: Path) -> JsonDict:
    out: JsonDict = {"_comment": "Generated from data/case_tables evidence_items.csv. Do not hand-edit long term."}
    for row in _rows(src / "evidence_items.csv"):
        item_id = _cell(row, "item_id")
        if not item_id:
            continue
        item: JsonDict = {}
        _set_if(item, "type", _cell(row, "type", "evidence"))
        _set_if(item, "category", _cell(row, "category"))
        _set_if(item, "name", _cell(row, "name"))
        _set_if(item, "description", _cell(row, "description"))
        if parse_bool(row.get("hidden", "")):
            item["hidden"] = True
        if parse_bool(row.get("meta_clue", "")):
            item["meta_clue"] = True
        _set_if(item, "icon", _cell(row, "icon"))
        tags = parse_list(row.get("tags", ""))
        _set_if(item, "tags", tags)
        _set_if(item, "phase", _cell(row, "phase"))
        out[item_id] = item
    return out


def compile_characters(src: Path, case_id: str) -> Tuple[JsonDict, JsonDict]:
    npcs: JsonDict = {"_comment": "Generated from data/case_tables characters.csv. Runtime fallback NPC data."}
    casting: JsonDict = {
        "_comment": "Generated from data/case_tables characters.csv.",
        "case_id": case_id,
        "casting": {},
    }
    for row in _rows(src / "characters.csv"):
        npc_id = _cell(row, "npc_id")
        if not npc_id:
            continue
        name = _cell(row, "name")
        title = _cell(row, "title")
        intro = _cell(row, "intro")
        dialogue_id = _cell(row, "dialogue_id") or _cell(row, "dialogue")
        portrait = _cell(row, "portrait")

        n: JsonDict = {}
        _set_if(n, "name", name)
        _set_if(n, "title", title)
        _set_if(n, "intro", intro)
        _set_if(n, "dialogue", dialogue_id)
        _set_if(n, "portrait", portrait)
        for flag in ["always_in_notebook", "is_victim"]:
            if parse_bool(row.get(flag, "")):
                n[flag] = True
        npcs[npc_id] = n

        c: JsonDict = {}
        _set_if(c, "actor_id", _cell(row, "actor_id"))
        _set_if(c, "role_name", name)
        _set_if(c, "role_title", title)
        _set_if(c, "role_intro", intro)
        _set_if(c, "portrait", portrait)
        for flag in ["is_player", "is_culprit", "is_victim"]:
            if parse_bool(row.get(flag, "")):
                c[flag] = True
        casting["casting"][npc_id] = c
    return npcs, casting


def compile_locations(src: Path) -> JsonDict:
    out: JsonDict = {"_comment": "Generated from data/case_tables locations/search_points/location_links CSV."}
    for row in _rows(src / "locations.csv"):
        loc_id = _cell(row, "location_id")
        if not loc_id:
            continue
        loc: JsonDict = {}
        for key in ["name", "parent", "description", "unlock_phase", "background", "scene_type"]:
            _set_if(loc, key, _cell(row, key))
        _set_if(loc, "npcs", parse_list(row.get("npcs", "")))
        loc["search_points"] = []
        out[loc_id] = loc

    for row in _rows(src / "location_links.csv"):
        from_loc = _cell(row, "from_location")
        if not from_loc:
            continue
        out.setdefault(from_loc, {"search_points": []})
        link: JsonDict = {}
        _set_if(link, "target", _cell(row, "target_location"))
        _set_if(link, "name", _cell(row, "name"))
        _set_if(link, "description", _cell(row, "description"))
        _set_condition(link, "requires", row.get("requires", ""))
        time_cost = parse_int(row.get("time_cost", ""))
        if time_cost is not None:
            link["time_cost"] = time_cost
        out[from_loc].setdefault("sub_locations", []).append(link)

    for row in _rows(src / "search_points.csv"):
        loc_id = _cell(row, "location_id")
        point_id = _cell(row, "point_id")
        if not loc_id or not point_id:
            continue
        out.setdefault(loc_id, {"search_points": []})
        point: JsonDict = {"id": point_id}
        _set_if(point, "name", _cell(row, "name"))
        time_cost = parse_int(row.get("time_cost", ""))
        if time_cost is not None:
            point["time_cost"] = time_cost
        rect = parse_float_list(row.get("hint_rect", ""))
        if rect:
            point["hint_rect"] = rect
        _set_condition(point, "unlock_condition", row.get("unlock_condition", ""))
        _set_if(point, "locked_hint", _cell(row, "locked_hint"))
        out[loc_id].setdefault("search_points", []).append(point)
    return out


def compile_search_results(src: Path) -> JsonDict:
    out: JsonDict = {"_comment": "Generated from data/case_tables search_results/search_sub_choices CSV."}
    sub_choices: Dict[Tuple[str, str, str], List[JsonDict]] = defaultdict(list)
    for row in sorted(_rows(src / "search_sub_choices.csv"), key=lambda r: parse_int(r.get("order", "0"), 0) or 0):
        loc = _cell(row, "location_id")
        point = _cell(row, "point_id")
        variant = _cell(row, "variant_id", "default") or "default"
        if not loc or not point:
            continue
        choice: JsonDict = {}
        _set_if(choice, "text", _cell(row, "text"))
        _set_if(choice, "narration", _cell(row, "narration"))
        evidence = _cell(row, "gain_evidence") or _cell(row, "evidence")
        clue = _cell(row, "gain_clue") or _cell(row, "clue")
        _set_if(choice, "evidence", evidence)
        _set_if(choice, "clue", clue)
        _set_flags_from_cell(choice, row.get("set_flags", ""))
        _set_condition(choice, "requires", row.get("requires", ""))
        sub_choices[(loc, point, variant)].append(choice)

    for row in _rows(src / "search_results.csv"):
        loc = _cell(row, "location_id")
        point = _cell(row, "point_id")
        if not loc or not point:
            continue
        key = "%s.%s" % (loc, point)
        variant = _cell(row, "variant_id", "default") or "default"
        entry = _result_payload(row)
        choices = sub_choices.get((loc, point, variant), [])
        if choices:
            entry["sub_choices"] = choices
        when = row.get("when", "")
        if not is_blank(when):
            entry["when"] = parse_condition(when)
            out.setdefault(key, {})
            out[key].setdefault("conditional", []).append(entry)
        else:
            out.setdefault(key, {})[variant] = entry
    return out


def compile_dialogues(src: Path) -> Dict[str, JsonDict]:
    node_rows = _rows(src / "dialogue_nodes.csv")
    if not node_rows:
        return {}
    line_rows = sorted(_rows(src / "dialogue_lines.csv"), key=lambda r: parse_int(r.get("order", "0"), 0) or 0)
    option_rows = sorted(_rows(src / "dialogue_options.csv"), key=lambda r: parse_int(r.get("order", "0"), 0) or 0)
    lines_by_node: Dict[Tuple[str, str], List[JsonDict]] = defaultdict(list)
    options_by_node: Dict[Tuple[str, str], List[JsonDict]] = defaultdict(list)

    for row in line_rows:
        npc_id = _cell(row, "npc_id")
        node_id = _cell(row, "node_id")
        text = _cell(row, "text")
        if not npc_id or not node_id or not text:
            continue
        line: JsonDict = {"text": text}
        for key in ["speaker_id", "speaker", "type", "emotion", "mood", "record_type", "record_title", "record_text", "record_id"]:
            _set_if(line, key, _cell(row, key))
        highlights = parse_list(row.get("highlight", ""))
        _set_if(line, "highlight", highlights)
        _set_condition(line, "requires", row.get("requires", ""))
        lines_by_node[(npc_id, node_id)].append(line)

    for row in option_rows:
        npc_id = _cell(row, "npc_id")
        node_id = _cell(row, "node_id")
        text = _cell(row, "text")
        goto = _cell(row, "goto")
        if not npc_id or not node_id or not text or not goto:
            continue
        opt: JsonDict = {"text": text, "goto": goto}
        _set_if(opt, "type", _cell(row, "type"))
        _set_condition(opt, "requires", row.get("requires", ""))
        _set_flags_from_cell(opt, row.get("set_flags", ""))
        if parse_bool(row.get("hide_after_visit", "")):
            opt["hide_after_visit"] = True
        min_visits = parse_int(row.get("min_hub_visits", ""))
        if min_visits is not None:
            opt["min_hub_visits"] = min_visits
        cost_time = parse_int(row.get("cost_time", ""))
        if cost_time is not None:
            opt["cost_time"] = cost_time
        options_by_node[(npc_id, node_id)].append(opt)

    dialogues: Dict[str, JsonDict] = {}
    start_by_npc: Dict[str, str] = {}
    for row in node_rows:
        npc_id = _cell(row, "npc_id")
        node_id = _cell(row, "node_id")
        if not npc_id or not node_id:
            continue
        dialogues.setdefault(npc_id, {"_comment": "Generated from data/case_tables dialogue CSV.", "start": node_id, "nodes": {}})
        if parse_bool(row.get("is_start", "")) or npc_id not in start_by_npc:
            start_by_npc[npc_id] = node_id
            dialogues[npc_id]["start"] = node_id
        node: JsonDict = {}
        for key in ["text", "emotion"]:
            _set_if(node, key, _cell(row, key))
        _set_flags_from_cell(node, row.get("set_flags", ""))
        _set_if(node, "gain_evidence", _cell(row, "gain_evidence"))
        _set_if(node, "gain_clue", _cell(row, "gain_clue"))
        if parse_bool(row.get("trigger_confrontation", "")):
            node["trigger_confrontation"] = True
        _set_if(node, "confrontation_key", _cell(row, "confrontation_key"))
        if parse_bool(row.get("end", "")):
            node["end"] = True
        node_lines = lines_by_node.get((npc_id, node_id), [])
        if node_lines:
            node["lines"] = node_lines
        node_options = options_by_node.get((npc_id, node_id), [])
        if node_options:
            node["options"] = node_options
        dialogues[npc_id]["nodes"][node_id] = node
    return dialogues


def compile_epilogue_meta(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "epilogue_meta.json")
    scene_rows = _rows(src / "epilogue_scenes.csv")
    if not scene_rows:
        return base

    line_rows = sorted(_rows(src / "epilogue_lines.csv"), key=_sort_key)
    lines_by_scene: Dict[str, List[JsonDict]] = defaultdict(list)
    for row in line_rows:
        scene_id = _cell(row, "scene_id")
        if scene_id:
            lines_by_scene[scene_id].append(row)

    scenes: List[JsonDict] = []
    for row in sorted(scene_rows, key=_sort_key):
        scene_id = _cell(row, "scene_id")
        if not scene_id:
            continue
        scene: JsonDict = {"id": scene_id}
        for key in ["type", "background", "bgm"]:
            _set_if(scene, key, _cell(row, key))
        lines: List[JsonDict] = []
        for line_row in lines_by_scene.get(scene_id, []):
            line = {"speaker": _cell(line_row, "speaker"), "text": _cell(line_row, "text")}
            _set_if(line, "emotion", _cell(line_row, "emotion"))
            lines.append(line)
        if lines:
            scene["lines"] = lines
        scenes.append(scene)

    if case_id == "prologue_ferry":
        triggers = ["prologue_fixed"]
    else:
        triggers = base.get("trigger_endings", [])
    if not triggers:
        triggers = ["prologue_fixed", "perfect", "good", "partial"]

    return {
        "_comment": base.get("_comment", "Generated from epilogue_scenes.csv and epilogue_lines.csv."),
        "trigger_endings": triggers,
        "scenes": scenes,
    }


def compile_companion_config(src: Path) -> JsonDict:
    rows = _rows(src / "companion_config.csv")
    if not rows:
        return {}
    row = rows[0]
    out: JsonDict = {}
    for key in ["companion_id", "role_name", "actor_id", "intro_hint"]:
        _set_if(out, key, _cell(row, key))
    topics = _parse_json_any_cell(row.get("available_topics", ""), [])
    _set_if(out, "available_topics", topics)
    limits = _parse_json_any_cell(row.get("limits", ""), {})
    _set_if(out, "limits", limits)
    if parse_bool(row.get("lock_on_final_day", "")):
        out["lock_on_final_day"] = True
    banter_max = parse_int(row.get("banter_max_per_day", ""))
    if banter_max is not None:
        out["banter_max_per_day"] = banter_max
    if parse_bool(row.get("tutorial_mode", "")):
        out["tutorial_mode"] = True

    hints: JsonDict = {}
    for hint_row in _rows(src / "companion_tutorial_hints.csv"):
        hint_key = _cell(hint_row, "hint_key")
        text = _cell(hint_row, "text")
        if hint_key and text:
            hints[hint_key] = text
    if hints:
        out["tutorial_hints"] = hints
    return out


def compile_companion_discussions(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "companion" / "discussions.json")
    out: JsonDict = {}
    for row in _rows(src / "companion_discussions.csv"):
        topic_id = _cell(row, "topic_id")
        if not topic_id:
            continue
        topic = out.setdefault(topic_id, {"rules": []})
        rule: JsonDict = {}
        when = _parse_json_any_cell(row.get("when", ""), {})
        _set_if(rule, "when", when)
        lines = _parse_json_any_cell(row.get("lines", ""), [])
        _set_if(rule, "lines", lines)
        if parse_bool(row.get("once", "")):
            rule["once"] = True
        priority = parse_int(row.get("priority", ""))
        if priority is not None:
            rule["priority"] = priority

        if isinstance(when, dict) and when.get("default", False) and topic.get("rules", []) == [] and lines:
            topic["pool"] = lines
            continue
        topic.setdefault("rules", []).append(rule)

    for key, value in base.items():
        if key.startswith("_") and key not in out:
            out[key] = value
    return out


def compile_companion_banter(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "companion" / "banter.json")
    rules: List[JsonDict] = []
    for row in _rows(src / "companion_banter.csv"):
        rule: JsonDict = {}
        _set_if(rule, "id", _cell(row, "banter_id"))
        when = _parse_json_any_cell(row.get("when", ""), {})
        _set_if(rule, "when", when)
        requires = _parse_json_any_cell(row.get("requires", ""), {})
        _set_if(rule, "requires", requires)
        lines = _parse_json_any_cell(row.get("lines", ""), [])
        _set_if(rule, "lines", lines)
        effect = _parse_json_any_cell(row.get("effect", ""), {})
        _set_if(rule, "effect", effect)
        if parse_bool(row.get("once", "")):
            rule["once"] = True
        priority = parse_int(row.get("priority", ""))
        if priority is not None:
            rule["priority"] = priority
        if rule:
            rules.append(rule)
    return {"_comment": base.get("_comment", "Generated from companion_banter.csv."), "rules": rules}


def _load_json(path: Path) -> JsonDict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _sort_key(row: JsonDict) -> float:
    value = _cell(row, "order", "0")
    try:
        return float(value)
    except ValueError:
        m = re.match(r"^\s*([+-]?\d+(?:\.\d+)?)([A-Za-z]+)\s*$", value)
        if m:
            suffix_offset = 0.0
            divisor = 100.0
            for ch in m.group(2).lower():
                if "a" <= ch <= "z":
                    suffix_offset += (ord(ch) - ord("a") + 1) / divisor
                    divisor *= 100.0
            return float(m.group(1)) + suffix_offset
        return 0.0


def _line(row: JsonDict) -> JsonDict:
    d: JsonDict = {"speaker": _cell(row, "speaker"), "text": _cell(row, "text")}
    _set_if(d, "emotion", _cell(row, "emotion"))
    return d


def compile_case_json(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "case.json")
    if not isinstance(base, dict):
        base = {}

    for meta_row in _rows(src / "case_meta.csv"):
        meta_key = _cell(meta_row, "key")
        meta_value = _cell(meta_row, "value")
        if not meta_key:
            continue
        if meta_value.startswith("{") or meta_value.startswith("["):
            try:
                base[meta_key] = json.loads(meta_value)
            except json.JSONDecodeError:
                base[meta_key] = meta_value
        else:
            base[meta_key] = _parse_scalar(meta_value)

    confrontation_rows = _rows(src / "confrontations.csv")
    if not confrontation_rows:
        return base

    confrontation_lines = sorted(_rows(src / "confrontation_lines.csv"), key=_sort_key)
    testimony_rows = sorted(_rows(src / "testimony_sets.csv"), key=_sort_key)
    testimony_lines = sorted(_rows(src / "testimony_lines.csv"), key=_sort_key)
    statement_rows = sorted(_rows(src / "testimony_statements.csv"), key=_sort_key)
    press_rows = sorted(_rows(src / "testimony_press_lines.csv"), key=_sort_key)
    break_rows = sorted(_rows(src / "testimony_break_lines.csv"), key=_sort_key)
    wrong_rows = sorted(_rows(src / "testimony_wrong_reactions.csv"), key=_sort_key)

    confrontation_lines_by_key: Dict[Tuple[str, str], List[JsonDict]] = defaultdict(list)
    for row in confrontation_lines:
        confrontation_lines_by_key[(_cell(row, "confrontation_id"), _cell(row, "section"))].append(row)

    testimony_lines_by_key: Dict[Tuple[str, str], List[JsonDict]] = defaultdict(list)
    for row in testimony_lines:
        testimony_lines_by_key[(_cell(row, "testimony_id"), _cell(row, "section"))].append(row)

    press_by_statement: Dict[str, List[JsonDict]] = defaultdict(list)
    for row in press_rows:
        press_by_statement[_cell(row, "statement_id")].append(_line(row))

    break_by_statement: Dict[str, List[JsonDict]] = defaultdict(list)
    for row in break_rows:
        break_by_statement[_cell(row, "statement_id")].append(_line(row))

    wrong_by_statement: Dict[str, Dict[str, List[JsonDict]]] = defaultdict(lambda: defaultdict(list))
    for row in wrong_rows:
        wrong_by_statement[_cell(row, "statement_id")][_cell(row, "evidence_id")].append(_line(row))

    statements_by_testimony: Dict[str, List[JsonDict]] = defaultdict(list)
    add_rows: List[JsonDict] = []
    for row in statement_rows:
        if _cell(row, "press_add_trigger"):
            add_rows.append(row)
        else:
            statements_by_testimony[_cell(row, "testimony_id")].append(row)

    statement_objects: Dict[str, JsonDict] = {}
    for row in statement_rows:
        stmt = _compile_statement(row, press_by_statement, break_by_statement, wrong_by_statement)
        if stmt.get("id", ""):
            statement_objects[stmt["id"]] = stmt

    for row in add_rows:
        trigger_id = _cell(row, "press_add_trigger")
        add_stmt_id = _cell(row, "statement_id")
        parent = statement_objects.get(trigger_id)
        add_stmt = statement_objects.get(add_stmt_id)
        if parent is not None and add_stmt is not None:
            parent["press_adds"] = {
                "after": _cell(row, "press_add_after") or trigger_id,
                "statement": add_stmt,
            }

    testimonies_by_confrontation: Dict[str, List[JsonDict]] = defaultdict(list)
    for row in testimony_rows:
        testimony_id = _cell(row, "testimony_id")
        testimony: JsonDict = {}
        _set_if(testimony, "id", testimony_id)
        _set_if(testimony, "witness", _cell(row, "witness"))
        _set_if(testimony, "title", _cell(row, "title"))
        _set_if(testimony, "grant_evidence", _cell(row, "grant_evidence"))
        for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
            lines = [_line(x) for x in testimony_lines_by_key.get((testimony_id, section), [])]
            _set_if(testimony, section, lines)
        statements: List[JsonDict] = []
        for stmt_row in statements_by_testimony.get(testimony_id, []):
            stmt_id = _cell(stmt_row, "statement_id")
            stmt = statement_objects.get(stmt_id)
            if stmt:
                statements.append(stmt)
        testimony["statements"] = statements
        testimonies_by_confrontation[_cell(row, "confrontation_id")].append(testimony)

    for row in confrontation_rows:
        confrontation_id = _cell(row, "confrontation_id")
        if not confrontation_id:
            continue
        data: JsonDict = {}
        _set_if(data, "_comment", _cell(row, "writer_note"))
        _set_if(data, "suspect", _cell(row, "suspect"))
        if not is_blank(row.get("is_final", "")):
            data["is_final"] = parse_bool(row.get("is_final", ""))
        for key in ["background", "bgm", "bgm_break", "bgm_break_actual", "bgm_final_round"]:
            _set_if(data, key, _cell(row, key))
        confidence = parse_int(row.get("confidence", ""))
        if confidence is not None:
            data["confidence"] = confidence
        for section in ["intro_dialogue", "victory_dialogue", "defeat_dialogue"]:
            lines = [_line(x) for x in confrontation_lines_by_key.get((confrontation_id, section), [])]
            _set_if(data, section, lines)
        epilogue = [_cell(x, "text") for x in confrontation_lines_by_key.get((confrontation_id, "epilogue_text"), []) if _cell(x, "text")]
        _set_if(data, "epilogue_text", epilogue)
        data["testimonies"] = testimonies_by_confrontation.get(confrontation_id, [])
        base[confrontation_id] = data
    return base


def _compile_statement(
    row: JsonDict,
    press_by_statement: Dict[str, List[JsonDict]],
    break_by_statement: Dict[str, List[JsonDict]],
    wrong_by_statement: Dict[str, Dict[str, List[JsonDict]]],
) -> JsonDict:
    statement_id = _cell(row, "statement_id")
    stmt: JsonDict = {}
    _set_if(stmt, "id", statement_id)
    _set_if(stmt, "speaker", _cell(row, "speaker"))
    _set_if(stmt, "text", _cell(row, "text"))
    is_contradiction = False
    if not is_blank(row.get("is_contradiction", "")):
        is_contradiction = parse_bool(row.get("is_contradiction", ""))
        stmt["is_contradiction"] = is_contradiction
    _set_if(stmt, "counter_evidence", _cell(row, "counter_evidence"))
    alt = parse_list(row.get("alt_evidence", ""))
    if alt or not is_blank(row.get("alt_evidence", "")):
        stmt["alt_evidence"] = alt
    _set_if(stmt, "break_evidence", _cell(row, "break_evidence"))
    _set_if(stmt, "press", press_by_statement.get(statement_id, []))
    _set_if(stmt, "break_dialogue", break_by_statement.get(statement_id, []))
    wrong = wrong_by_statement.get(statement_id, {})
    if wrong:
        stmt["wrong_reactions"] = {k: v for k, v in wrong.items()}
    return stmt


def compile_progression(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "progression.json")
    if not isinstance(base, dict):
        base = {}

    phase_rows = sorted(_rows(src / "progression_phases.csv"), key=_sort_key)
    if phase_rows:
        phases: List[JsonDict] = []
        for row in phase_rows:
            phase: JsonDict = {}
            _set_if(phase, "id", _cell(row, "phase_id"))
            _set_if(phase, "title", _cell(row, "title"))
            _set_if(phase, "description", _cell(row, "description"))
            _set_if(phase, "hint", _cell(row, "hint"))
            phase["locations"] = parse_list(row.get("locations", ""))
            cond = row.get("unlock_condition", "")
            phase["unlock_condition"] = None if is_blank(cond) else parse_condition(cond)
            _set_if(phase, "_comment", _cell(row, "writer_note"))
            phases.append(phase)
        base["phases"] = phases

    unlock_rows = _rows(src / "progression_unlocks.csv")
    if unlock_rows or (src / "progression_unlocks.csv").exists():
        grouped: Dict[str, JsonDict] = {
            "panel_unlock": {},
            "search_point_unlock": {},
            "npc_unlock": {},
            "confrontation_unlock": {},
        }
        for row in unlock_rows:
            group = _cell(row, "unlock_type")
            target = _cell(row, "target_id")
            if group not in grouped or not target:
                continue
            entry: JsonDict = {}
            cond = row.get("condition", "")
            entry["condition"] = None if is_blank(cond) else parse_condition(cond)
            _set_if(entry, "locked_hint", _cell(row, "locked_hint"))
            _set_if(entry, "_comment", _cell(row, "writer_note"))
            grouped[group][target] = entry
        for group, value in grouped.items():
            base[group] = value

    notification_rows = _rows(src / "phase_notifications.csv")
    if notification_rows or (src / "phase_notifications.csv").exists():
        notifications: JsonDict = {}
        for row in notification_rows:
            phase_id = _cell(row, "phase_id")
            if not phase_id:
                continue
            notifications[phase_id] = {
                "speaker": _cell(row, "speaker"),
                "text": _cell(row, "text"),
            }
        base["phase_notifications"] = notifications
    return base


def _parse_scalar(value: Any):
    if is_blank(value):
        return ""
    text = str(value).strip()
    try:
        return int(text)
    except ValueError:
        pass
    try:
        return float(text)
    except ValueError:
        pass
    lower = text.lower()
    if lower in {"true", "false"}:
        return lower == "true"
    return text


def _parse_json_cell(value: Any) -> JsonDict:
    if is_blank(value):
        return {}
    parsed = json.loads(str(value))
    return parsed if isinstance(parsed, dict) else {}


def compile_npc_states(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "npc_states.json")
    comment = base.get("_comment", "") if isinstance(base, dict) else ""
    out: JsonDict = {}
    _set_if(out, "_comment", comment)

    npc_order: List[str] = []
    for row in _rows(src / "npc_state_initial.csv") + _rows(src / "npc_state_transitions.csv"):
        npc_id = _cell(row, "npc_id")
        if npc_id and npc_id not in npc_order:
            npc_order.append(npc_id)

    for npc_id in npc_order:
        out[npc_id] = {"initial": {}, "transitions": []}

    for row in _rows(src / "npc_state_initial.csv"):
        npc_id = _cell(row, "npc_id")
        stat = _cell(row, "stat")
        if not npc_id or not stat:
            continue
        out.setdefault(npc_id, {"initial": {}, "transitions": []})
        out[npc_id].setdefault("initial", {})[stat] = _parse_scalar(row.get("value", ""))

    for row in sorted(_rows(src / "npc_state_transitions.csv"), key=_sort_key):
        npc_id = _cell(row, "npc_id")
        event = _cell(row, "event")
        if not npc_id or not event:
            continue
        transition: JsonDict = {"on": event, "delta": _parse_json_cell(row.get("delta", "{}"))}
        _set_if(transition, "_comment", _cell(row, "writer_note"))
        out.setdefault(npc_id, {"initial": {}, "transitions": []})
        out[npc_id].setdefault("transitions", []).append(transition)
    return out


def _parse_json_any(value: Any, default):
    if is_blank(value):
        return default
    return json.loads(str(value))


def compile_portrait_expressions(src: Path) -> JsonDict:
    portraits: JsonDict = {}
    for row in _rows(src / "portrait_expressions.csv"):
        base = _cell(row, "base_portrait")
        emotion = _cell(row, "emotion")
        portrait = _cell(row, "portrait")
        if not base or not emotion or not portrait:
            continue
        portraits.setdefault(base, {})[emotion] = portrait
    return {
        "_comment": "Generated from data/case_tables portrait_expressions.csv. Maps base portrait + emotion to actual portrait resource.",
        "portraits": portraits,
    }


def compile_day_events(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "day_events.json")
    comment = base.get("_comment", "") if isinstance(base, dict) else ""
    lines_by_event: Dict[str, List[JsonDict]] = defaultdict(list)
    for row in sorted(_rows(src / "day_event_lines.csv"), key=_sort_key):
        lines_by_event[_cell(row, "event_id")].append(row)

    events: List[JsonDict] = []
    for row in sorted(_rows(src / "day_events.csv"), key=_sort_key):
        event_id = _cell(row, "event_id")
        if not event_id:
            continue
        evt: JsonDict = {"id": event_id}
        _set_if(evt, "title", _cell(row, "title"))
        _set_if(evt, "hint", _cell(row, "hint"))
        evt["trigger"] = _parse_json_any(row.get("trigger", ""), {})
        narration: List[Any] = []
        for line in lines_by_event.get(event_id, []):
            if _cell(line, "line_kind") == "text":
                text_item: JsonDict = {"speaker": "", "text": _cell(line, "text")}
                _set_if(text_item, "background", _cell(line, "background"))
                _set_if(text_item, "voice_path", _cell(line, "voice_path"))
                effect = _parse_json_any(line.get("effect", ""), {})
                if isinstance(effect, dict) and effect:
                    text_item["effect"] = effect
                if "background" in text_item or "voice_path" in text_item or "effect" in text_item:
                    narration.append(text_item)
                else:
                    narration.append(_cell(line, "text"))
            else:
                item: JsonDict = {"speaker": _cell(line, "speaker"), "text": _cell(line, "text")}
                _set_if(item, "emotion", _cell(line, "emotion"))
                _set_if(item, "voice_path", _cell(line, "voice_path"))
                _set_if(item, "background", _cell(line, "background"))
                effect = _parse_json_any(line.get("effect", ""), {})
                if isinstance(effect, dict) and effect:
                    item["effect"] = effect
                narration.append(item)
        evt["narration"] = narration
        evt["effects"] = _parse_json_any(row.get("effects", ""), {})
        if not is_blank(row.get("auto_play", "")):
            evt["auto_play"] = parse_bool(row.get("auto_play", ""))
        _set_if(evt, "_comment", _cell(row, "writer_note"))
        events.append(evt)
    out: JsonDict = {}
    _set_if(out, "_comment", comment)
    out["events"] = events
    return out


def _schedule_from_row(row: JsonDict) -> JsonDict:
    sched: JsonDict = {}
    _set_if(sched, "location", _cell(row, "location"))
    _set_if(sched, "activity", _cell(row, "activity"))
    if not is_blank(row.get("public", "")):
        sched["public"] = parse_bool(row.get("public", ""))
    return sched


def compile_schedules(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "schedules.json")
    comment = base.get("_comment", "") if isinstance(base, dict) else ""
    out: JsonDict = {}
    _set_if(out, "_comment", comment)

    for row in _rows(src / "schedule_defaults.csv"):
        npc_id = _cell(row, "npc_id")
        if not npc_id:
            continue
        entry: JsonDict = {}
        _set_if(entry, "_role", _cell(row, "role_note"))
        default = _schedule_from_row(row)
        if default:
            entry["default"] = default
        out[npc_id] = entry

    for row in _rows(src / "schedule_overrides.csv"):
        npc_id = _cell(row, "npc_id")
        time_key = _cell(row, "time_key")
        if not npc_id or not time_key:
            continue
        out.setdefault(npc_id, {})
        out[npc_id].setdefault("overrides", {})[time_key] = _schedule_from_row(row)

    for row in sorted(_rows(src / "schedule_conditional_overrides.csv"), key=_sort_key):
        npc_id = _cell(row, "npc_id")
        if_flag = _cell(row, "if_flag")
        if not npc_id or not if_flag:
            continue
        out.setdefault(npc_id, {})
        out[npc_id].setdefault("conditional_overrides", []).append({
            "if_flag": if_flag,
            "schedule": _schedule_from_row(row),
        })
    return out


def compile_culprit_actions(src: Path, case_id: str) -> JsonDict:
    base = _load_json(DATA / "cases" / case_id / "culprit_actions.json")
    comment = base.get("_comment", "") if isinstance(base, dict) else ""
    actions: List[JsonDict] = []
    for row in sorted(_rows(src / "culprit_actions.csv"), key=_sort_key):
        action_id = _cell(row, "action_id")
        if not action_id:
            continue
        action: JsonDict = {"id": action_id}
        _set_if(action, "culprit", _cell(row, "culprit"))
        _set_if(action, "day_period", _cell(row, "day_period"))
        jitter = parse_int(row.get("jitter", ""))
        if jitter is not None:
            action["jitter"] = jitter
        _set_if(action, "intent", _cell(row, "intent"))
        trace: JsonDict = {}
        _set_if(trace, "evidence_id", _cell(row, "trace_evidence_id"))
        _set_if(trace, "location", _cell(row, "trace_location"))
        _set_if(trace, "discoverable_after", _cell(row, "trace_discoverable_after"))
        if trace:
            action["leaves_trace"] = trace
        _set_if(action, "if_witnessed", _cell(row, "if_witnessed"))
        _set_if(action, "_comment", _cell(row, "writer_note"))
        actions.append(action)
    out: JsonDict = {}
    _set_if(out, "_comment", comment)
    out["actions"] = actions
    return out


def write_json(path: Path, data: JsonDict, dry_run: bool = False) -> None:
    if dry_run:
        print("[DRY] %s" % path.relative_to(REPO_ROOT))
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("[OK] wrote %s" % path.relative_to(REPO_ROOT))


def compile_case(case_id: str, tables_root: Path, out_dir: Path, dry_run: bool = False) -> List[Path]:
    src = tables_root / case_id
    if not src.exists():
        raise FileNotFoundError("case table directory not found: %s" % src)
    written: List[Path] = []

    if (src / "evidence_items.csv").exists():
        path = out_dir / "evidence.json"
        write_json(path, compile_evidence(src), dry_run)
        written.append(path)
    if (src / "characters.csv").exists():
        npcs, casting = compile_characters(src, case_id)
        for name, data in [("npcs.json", npcs), ("casting.json", casting)]:
            path = out_dir / name
            write_json(path, data, dry_run)
            written.append(path)
    if (src / "locations.csv").exists():
        path = out_dir / "locations.json"
        write_json(path, compile_locations(src), dry_run)
        written.append(path)
    if (src / "search_results.csv").exists():
        path = out_dir / "search_results.json"
        write_json(path, compile_search_results(src), dry_run)
        written.append(path)
    if (src / "confrontations.csv").exists():
        path = out_dir / "case.json"
        write_json(path, compile_case_json(src, case_id), dry_run)
        written.append(path)
    if (src / "progression_phases.csv").exists():
        path = out_dir / "progression.json"
        write_json(path, compile_progression(src, case_id), dry_run)
        written.append(path)
    if (src / "npc_state_initial.csv").exists() or (src / "npc_state_transitions.csv").exists():
        path = out_dir / "npc_states.json"
        write_json(path, compile_npc_states(src, case_id), dry_run)
        written.append(path)
    if (src / "day_events.csv").exists():
        path = out_dir / "day_events.json"
        write_json(path, compile_day_events(src, case_id), dry_run)
        written.append(path)
    if (src / "epilogue_scenes.csv").exists():
        path = out_dir / "epilogue_meta.json"
        write_json(path, compile_epilogue_meta(src, case_id), dry_run)
        written.append(path)
    if (src / "companion_config.csv").exists():
        path = out_dir / "companion" / "companion.json"
        write_json(path, compile_companion_config(src), dry_run)
        written.append(path)
    if (src / "companion_discussions.csv").exists():
        path = out_dir / "companion" / "discussions.json"
        write_json(path, compile_companion_discussions(src, case_id), dry_run)
        written.append(path)
    if (src / "companion_banter.csv").exists():
        path = out_dir / "companion" / "banter.json"
        write_json(path, compile_companion_banter(src, case_id), dry_run)
        written.append(path)
    if (src / "schedule_defaults.csv").exists():
        path = out_dir / "schedules.json"
        write_json(path, compile_schedules(src, case_id), dry_run)
        written.append(path)
    if (src / "culprit_actions.csv").exists():
        path = out_dir / "culprit_actions.json"
        write_json(path, compile_culprit_actions(src, case_id), dry_run)
        written.append(path)
    if (src / "portrait_expressions.csv").exists():
        path = out_dir / "portrait_expressions.json"
        write_json(path, compile_portrait_expressions(src), dry_run)
        written.append(path)
    dialogues = compile_dialogues(src)
    for npc_id, data in dialogues.items():
        path = out_dir / "dialogues" / (npc_id + ".json")
        write_json(path, data, dry_run)
        written.append(path)
    return written


def iter_cases(tables_root: Path) -> Iterable[str]:
    if not tables_root.exists():
        return []
    return [p.name for p in sorted(tables_root.iterdir()) if p.is_dir() and not p.name.startswith("_")]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--case", dest="case_id", help="case id, e.g. prologue_ferry")
    ap.add_argument("--all", action="store_true", help="compile all case table directories")
    ap.add_argument("--tables-root", default=str(DATA / "case_tables"))
    ap.add_argument("--out", default="", help="custom output root; default is safe _compiled preview")
    ap.add_argument("--write-runtime", action="store_true", help="write into data/cases/<case_id>/")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    tables_root = Path(args.tables_root).resolve()

    cases: List[str]
    if args.all:
        cases = list(iter_cases(tables_root))
    elif args.case_id:
        cases = [args.case_id]
    else:
        ap.error("use --case <case_id> or --all")

    custom_out = Path(args.out).resolve() if args.out else None
    for case_id in cases:
        if args.write_runtime:
            out_dir = DATA / "cases" / case_id
        elif custom_out is not None:
            out_dir = custom_out / case_id if args.all else custom_out
        else:
            out_dir = tables_root / case_id / "_compiled"
        compile_case(case_id, tables_root, out_dir, args.dry_run)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
