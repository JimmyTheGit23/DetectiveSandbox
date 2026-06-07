#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Export existing runtime JSON into first-stage CSV authoring tables."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any, Dict, Iterable, List

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
DATA = REPO_ROOT / "data"


JsonDict = Dict[str, Any]


def load_json(path: Path) -> JsonDict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def compact(value: Any) -> str:
    if value is None or value == "":
        return ""
    if isinstance(value, list):
        if all(not isinstance(x, (dict, list)) for x in value):
            return ";".join(str(x) for x in value)
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return str(value)


def write_csv(path: Path, fieldnames: List[str], rows: Iterable[JsonDict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, "") for k in fieldnames})
    print("[OK] wrote %s" % path.relative_to(REPO_ROOT))


def export_characters(case_dir: Path, out_dir: Path, case_id: str) -> None:
    npcs = load_json(case_dir / "npcs.json")
    casting = load_json(case_dir / "casting.json").get("casting", {})
    ids = sorted({k for k in npcs if not k.startswith("_")} | set(casting.keys()))
    rows: List[JsonDict] = []
    for npc_id in ids:
        n = npcs.get(npc_id, {}) if isinstance(npcs.get(npc_id, {}), dict) else {}
        c = casting.get(npc_id, {}) if isinstance(casting.get(npc_id, {}), dict) else {}
        rows.append({
            "npc_id": npc_id,
            "name": n.get("name", c.get("role_name", "")),
            "title": n.get("title", c.get("role_title", "")),
            "intro": n.get("intro", c.get("role_intro", "")),
            "dialogue_id": n.get("dialogue", npc_id if (case_dir / "dialogues" / (npc_id + ".json")).exists() else ""),
            "actor_id": c.get("actor_id", ""),
            "portrait": n.get("portrait", c.get("portrait", "")),
            "always_in_notebook": compact(n.get("always_in_notebook", "")),
            "is_victim": compact(n.get("is_victim", c.get("is_victim", ""))),
            "is_player": compact(c.get("is_player", "")),
            "is_culprit": compact(c.get("is_culprit", "")),
        })
    write_csv(out_dir / "characters.csv", [
        "npc_id", "name", "title", "intro", "dialogue_id", "actor_id", "portrait",
        "always_in_notebook", "is_victim", "is_player", "is_culprit",
    ], rows)


def export_evidence(case_dir: Path, out_dir: Path) -> None:
    evidence = load_json(case_dir / "evidence.json")
    rows: List[JsonDict] = []
    for item_id, item in evidence.items():
        if item_id.startswith("_") or not isinstance(item, dict):
            continue
        rows.append({
            "item_id": item_id,
            "type": item.get("type", "evidence"),
            "category": item.get("category", ""),
            "name": item.get("name", ""),
            "description": item.get("description", ""),
            "hidden": compact(item.get("hidden", "")),
            "meta_clue": compact(item.get("meta_clue", "")),
            "icon": item.get("icon", ""),
            "tags": compact(item.get("tags", "")),
            "phase": item.get("phase", ""),
            "source": "",
            "writer_note": "",
        })
    write_csv(out_dir / "evidence_items.csv", [
        "item_id", "type", "category", "name", "description", "hidden", "meta_clue",
        "icon", "tags", "phase", "source", "writer_note",
    ], rows)


def export_locations(case_dir: Path, out_dir: Path) -> None:
    locations = load_json(case_dir / "locations.json")
    loc_rows: List[JsonDict] = []
    link_rows: List[JsonDict] = []
    point_rows: List[JsonDict] = []
    for loc_id, loc in locations.items():
        if loc_id.startswith("_") or not isinstance(loc, dict):
            continue
        loc_rows.append({
            "location_id": loc_id,
            "name": loc.get("name", ""),
            "parent": loc.get("parent", ""),
            "description": loc.get("description", ""),
            "unlock_phase": loc.get("unlock_phase", ""),
            "background": loc.get("background", ""),
            "scene_type": loc.get("scene_type", ""),
            "npcs": compact(loc.get("npcs", [])),
        })
        for link in loc.get("sub_locations", []):
            if not isinstance(link, dict):
                continue
            link_rows.append({
                "from_location": loc_id,
                "target_location": link.get("target", ""),
                "name": link.get("name", ""),
                "description": link.get("description", ""),
                "requires": compact(link.get("requires", "")),
                "time_cost": link.get("time_cost", ""),
            })
        for point in loc.get("search_points", []):
            if not isinstance(point, dict):
                continue
            point_rows.append({
                "location_id": loc_id,
                "point_id": point.get("id", ""),
                "name": point.get("name", ""),
                "time_cost": point.get("time_cost", ""),
                "hint_rect": compact(point.get("hint_rect", [])),
                "unlock_condition": compact(point.get("unlock_condition", "")),
                "locked_hint": point.get("locked_hint", ""),
            })
    write_csv(out_dir / "locations.csv", ["location_id", "name", "parent", "description", "unlock_phase", "background", "scene_type", "npcs"], loc_rows)
    write_csv(out_dir / "location_links.csv", ["from_location", "target_location", "name", "description", "requires", "time_cost"], link_rows)
    write_csv(out_dir / "search_points.csv", ["location_id", "point_id", "name", "time_cost", "hint_rect", "unlock_condition", "locked_hint"], point_rows)


def export_search_results(case_dir: Path, out_dir: Path) -> None:
    data = load_json(case_dir / "search_results.json")
    result_rows: List[JsonDict] = []
    sub_rows: List[JsonDict] = []
    for full_key, variants in data.items():
        if full_key.startswith("_") or "." not in full_key or not isinstance(variants, dict):
            continue
        loc, point = full_key.split(".", 1)
        for variant_id, entry in variants.items():
            if variant_id == "conditional" and isinstance(entry, list):
                for idx, cond_entry in enumerate(entry, start=1):
                    if isinstance(cond_entry, dict):
                        _append_search_row(result_rows, sub_rows, loc, point, "conditional_%d" % idx, cond_entry, cond_entry.get("when", ""))
                continue
            if isinstance(entry, dict):
                _append_search_row(result_rows, sub_rows, loc, point, variant_id, entry, "")
    write_csv(out_dir / "search_results.csv", [
        "location_id", "point_id", "variant_id", "when", "intro_text", "narration",
        "gain_evidence", "gain_clue", "set_flags", "trigger_dialogue", "trigger_dialogue_start", "time_cost",
    ], result_rows)
    write_csv(out_dir / "search_sub_choices.csv", [
        "location_id", "point_id", "variant_id", "choice_id", "order", "text", "narration",
        "gain_evidence", "gain_clue", "set_flags", "requires",
    ], sub_rows)


def _append_search_row(result_rows: List[JsonDict], sub_rows: List[JsonDict], loc: str, point: str, variant_id: str, entry: JsonDict, when: Any) -> None:
    result_rows.append({
        "location_id": loc,
        "point_id": point,
        "variant_id": variant_id or "default",
        "when": compact(when),
        "intro_text": entry.get("intro_text", ""),
        "narration": entry.get("narration", ""),
        "gain_evidence": entry.get("evidence", entry.get("gain_evidence", "")),
        "gain_clue": entry.get("clue", entry.get("gain_clue", "")),
        "set_flags": compact(entry.get("set_flags", "")),
        "trigger_dialogue": entry.get("trigger_dialogue", ""),
        "trigger_dialogue_start": entry.get("trigger_dialogue_start", ""),
        "time_cost": entry.get("time_cost", ""),
    })
    for idx, choice in enumerate(entry.get("sub_choices", []), start=1):
        if not isinstance(choice, dict):
            continue
        sub_rows.append({
            "location_id": loc,
            "point_id": point,
            "variant_id": variant_id or "default",
            "choice_id": "choice_%02d" % idx,
            "order": idx,
            "text": choice.get("text", ""),
            "narration": choice.get("narration", ""),
            "gain_evidence": choice.get("evidence", choice.get("gain_evidence", "")),
            "gain_clue": choice.get("clue", choice.get("gain_clue", "")),
            "set_flags": compact(choice.get("set_flags", "")),
            "requires": compact(choice.get("requires", "")),
        })


def export_dialogues(case_dir: Path, out_dir: Path) -> None:
    node_rows: List[JsonDict] = []
    line_rows: List[JsonDict] = []
    option_rows: List[JsonDict] = []
    dlg_dir = case_dir / "dialogues"
    for path in sorted(dlg_dir.glob("*.json")):
        npc_id = path.stem
        tree = load_json(path)
        start = tree.get("start", "hub")
        nodes = tree.get("nodes", {})
        if not isinstance(nodes, dict):
            continue
        for node_id, node in nodes.items():
            if not isinstance(node, dict):
                continue
            node_rows.append({
                "npc_id": npc_id,
                "node_id": node_id,
                "is_start": "true" if node_id == start else "",
                "text": node.get("text", ""),
                "emotion": node.get("emotion", ""),
                "set_flags": compact(node.get("set_flags", "")),
                "gain_evidence": node.get("gain_evidence", ""),
                "gain_clue": node.get("gain_clue", ""),
                "trigger_confrontation": compact(node.get("trigger_confrontation", "")),
                "confrontation_key": node.get("confrontation_key", ""),
                "end": compact(node.get("end", "")),
                "writer_note": "",
            })
            for idx, line in enumerate(node.get("lines", []), start=1):
                if not isinstance(line, dict):
                    continue
                line_rows.append({
                    "npc_id": npc_id,
                    "node_id": node_id,
                    "order": idx,
                    "speaker_id": line.get("speaker_id", ""),
                    "speaker": line.get("speaker", ""),
                    "type": line.get("type", ""),
                    "text": line.get("text", ""),
                    "emotion": line.get("emotion", ""),
                    "requires": compact(line.get("requires", "")),
                    "highlight": compact(line.get("highlight", "")),
                    "record_type": line.get("record_type", ""),
                    "record_title": line.get("record_title", ""),
                    "record_text": line.get("record_text", ""),
                    "record_id": line.get("record_id", ""),
                })
            for idx, opt in enumerate(node.get("options", []), start=1):
                if not isinstance(opt, dict):
                    continue
                option_rows.append({
                    "npc_id": npc_id,
                    "node_id": node_id,
                    "order": idx,
                    "text": opt.get("text", ""),
                    "goto": opt.get("goto", ""),
                    "type": opt.get("type", ""),
                    "requires": compact(opt.get("requires", "")),
                    "set_flags": compact(opt.get("set_flags", "")),
                    "hide_after_visit": compact(opt.get("hide_after_visit", "")),
                    "min_hub_visits": opt.get("min_hub_visits", ""),
                    "cost_time": opt.get("cost_time", ""),
                })
    write_csv(out_dir / "dialogue_nodes.csv", [
        "npc_id", "node_id", "is_start", "text", "emotion", "set_flags", "gain_evidence",
        "gain_clue", "trigger_confrontation", "confrontation_key", "end", "writer_note",
    ], node_rows)
    write_csv(out_dir / "dialogue_lines.csv", [
        "npc_id", "node_id", "order", "speaker_id", "speaker", "type", "text", "emotion",
        "requires", "highlight", "record_type", "record_title", "record_text", "record_id",
    ], line_rows)
    write_csv(out_dir / "dialogue_options.csv", [
        "npc_id", "node_id", "order", "text", "goto", "type", "requires", "set_flags",
        "hide_after_visit", "min_hub_visits", "cost_time",
    ], option_rows)


def export_confrontations(case_dir: Path, out_dir: Path) -> None:
    case = load_json(case_dir / "case.json")
    confrontation_rows: List[JsonDict] = []
    confrontation_line_rows: List[JsonDict] = []
    testimony_rows: List[JsonDict] = []
    testimony_line_rows: List[JsonDict] = []
    statement_rows: List[JsonDict] = []
    press_rows: List[JsonDict] = []
    break_rows: List[JsonDict] = []
    wrong_rows: List[JsonDict] = []

    for confrontation_id, data in case.items():
        if confrontation_id.startswith("_") or not isinstance(data, dict) or "testimonies" not in data:
            continue
        confrontation_rows.append({
            "confrontation_id": confrontation_id,
            "suspect": data.get("suspect", ""),
            "is_final": compact(data.get("is_final", "")),
            "background": data.get("background", ""),
            "bgm": data.get("bgm", ""),
            "bgm_break": data.get("bgm_break", ""),
            "bgm_break_actual": data.get("bgm_break_actual", ""),
            "bgm_final_round": data.get("bgm_final_round", ""),
            "confidence": data.get("confidence", ""),
            "writer_note": data.get("_comment", ""),
        })
        for section in ["intro_dialogue", "victory_dialogue", "defeat_dialogue", "epilogue_text"]:
            for idx, line in enumerate(data.get(section, []), start=1):
                if isinstance(line, dict):
                    confrontation_line_rows.append({
                        "confrontation_id": confrontation_id,
                        "section": section,
                        "order": idx,
                        "speaker_id": line.get("speaker_id", ""),
                        "speaker": line.get("speaker", ""),
                        "text": line.get("text", ""),
                        "emotion": line.get("emotion", ""),
                        "portrait_emotion": line.get("portrait_emotion", ""),
                        "portrait_override": line.get("portrait_override", ""),
                    })
                else:
                    confrontation_line_rows.append({
                        "confrontation_id": confrontation_id,
                        "section": section,
                        "order": idx,
                        "speaker_id": "",
                        "speaker": "",
                        "text": str(line),
                        "emotion": "",
                        "portrait_emotion": "",
                        "portrait_override": "",
                    })
        for t_idx, testimony in enumerate(data.get("testimonies", []), start=1):
            if not isinstance(testimony, dict):
                continue
            testimony_id = testimony.get("id", "")
            testimony_rows.append({
                "confrontation_id": confrontation_id,
                "order": t_idx,
                "testimony_id": testimony_id,
                "witness": testimony.get("witness", ""),
                "title": testimony.get("title", ""),
                "writer_note": "",
            })
            for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
                for idx, line in enumerate(testimony.get(section, []), start=1):
                    if not isinstance(line, dict):
                        continue
                    testimony_line_rows.append({
                        "testimony_id": testimony_id,
                        "section": section,
                        "order": idx,
                        "speaker_id": line.get("speaker_id", ""),
                        "speaker": line.get("speaker", ""),
                        "text": line.get("text", ""),
                        "emotion": line.get("emotion", ""),
                        "portrait_emotion": line.get("portrait_emotion", ""),
                        "portrait_override": line.get("portrait_override", ""),
                    })
            for s_idx, stmt in enumerate(testimony.get("statements", []), start=1):
                if not isinstance(stmt, dict):
                    continue
                _append_statement_rows(statement_rows, press_rows, break_rows, wrong_rows, testimony_id, stmt, str(s_idx), "", "")
                press_adds = stmt.get("press_adds", {})
                if isinstance(press_adds, dict):
                    add_stmt = press_adds.get("statement", {})
                    if isinstance(add_stmt, dict) and add_stmt:
                        _append_statement_rows(
                            statement_rows,
                            press_rows,
                            break_rows,
                            wrong_rows,
                            testimony_id,
                            add_stmt,
                            "%s.1" % s_idx,
                            stmt.get("id", ""),
                            press_adds.get("after", stmt.get("id", "")),
                        )

    write_csv(out_dir / "confrontations.csv", [
        "confrontation_id", "suspect", "is_final", "background", "bgm", "bgm_break",
        "bgm_break_actual", "bgm_final_round", "confidence", "writer_note",
    ], confrontation_rows)
    write_csv(out_dir / "confrontation_lines.csv", [
        "confrontation_id", "section", "order", "speaker_id", "speaker", "text", "emotion",
        "portrait_emotion", "portrait_override",
    ], confrontation_line_rows)
    write_csv(out_dir / "testimony_sets.csv", [
        "confrontation_id", "order", "testimony_id", "witness", "title", "writer_note",
    ], testimony_rows)
    write_csv(out_dir / "testimony_lines.csv", [
        "testimony_id", "section", "order", "speaker_id", "speaker", "text", "emotion",
        "portrait_emotion", "portrait_override",
    ], testimony_line_rows)
    write_csv(out_dir / "testimony_statements.csv", [
        "testimony_id", "statement_id", "order", "speaker_id", "speaker", "text", "emotion",
        "portrait_emotion", "portrait_override", "is_contradiction", "counter_evidence", "alt_evidence",
        "break_evidence", "press_add_trigger", "press_add_after", "writer_note",
    ], statement_rows)
    write_csv(out_dir / "testimony_press_lines.csv", [
        "statement_id", "order", "speaker_id", "speaker", "text", "emotion", "portrait_emotion", "portrait_override",
    ], press_rows)
    write_csv(out_dir / "testimony_break_lines.csv", [
        "statement_id", "order", "speaker_id", "speaker", "text", "emotion", "portrait_emotion", "portrait_override",
    ], break_rows)
    write_csv(out_dir / "testimony_wrong_reactions.csv", [
        "statement_id", "evidence_id", "order", "speaker_id", "speaker", "text", "emotion",
        "portrait_emotion", "portrait_override",
    ], wrong_rows)


def _append_statement_rows(
    statement_rows: List[JsonDict],
    press_rows: List[JsonDict],
    break_rows: List[JsonDict],
    wrong_rows: List[JsonDict],
    testimony_id: str,
    stmt: JsonDict,
    order: str,
    press_add_trigger: str,
    press_add_after: str,
) -> None:
    statement_id = stmt.get("id", "")
    statement_rows.append({
        "testimony_id": testimony_id,
        "statement_id": statement_id,
        "order": order,
        "speaker_id": stmt.get("speaker_id", ""),
        "speaker": stmt.get("speaker", ""),
        "text": stmt.get("text", ""),
        "emotion": stmt.get("emotion", ""),
        "portrait_emotion": stmt.get("portrait_emotion", ""),
        "portrait_override": stmt.get("portrait_override", ""),
        "is_contradiction": compact(stmt.get("is_contradiction", "")),
        "counter_evidence": stmt.get("counter_evidence", ""),
        "alt_evidence": json.dumps(stmt["alt_evidence"], ensure_ascii=False, separators=(",", ":")) if "alt_evidence" in stmt else "",
        "break_evidence": stmt.get("break_evidence", ""),
        "press_add_trigger": press_add_trigger,
        "press_add_after": press_add_after,
        "writer_note": "",
    })
    for idx, line in enumerate(stmt.get("press", []), start=1):
        if isinstance(line, dict):
            press_rows.append({
                "statement_id": statement_id,
                "order": idx,
                "speaker_id": line.get("speaker_id", ""),
                "speaker": line.get("speaker", ""),
                "text": line.get("text", ""),
                "emotion": line.get("emotion", ""),
                "portrait_emotion": line.get("portrait_emotion", ""),
                "portrait_override": line.get("portrait_override", ""),
            })
    for idx, line in enumerate(stmt.get("break_dialogue", []), start=1):
        if isinstance(line, dict):
            break_rows.append({
                "statement_id": statement_id,
                "order": idx,
                "speaker_id": line.get("speaker_id", ""),
                "speaker": line.get("speaker", ""),
                "text": line.get("text", ""),
                "emotion": line.get("emotion", ""),
                "portrait_emotion": line.get("portrait_emotion", ""),
                "portrait_override": line.get("portrait_override", ""),
            })
    wrong_reactions = stmt.get("wrong_reactions", {})
    if isinstance(wrong_reactions, dict):
        for evidence_id, lines in wrong_reactions.items():
            if not isinstance(lines, list):
                continue
            for idx, line in enumerate(lines, start=1):
                if isinstance(line, dict):
                    wrong_rows.append({
                        "statement_id": statement_id,
                        "evidence_id": evidence_id,
                        "order": idx,
                        "speaker_id": line.get("speaker_id", ""),
                        "speaker": line.get("speaker", ""),
                        "text": line.get("text", ""),
                        "emotion": line.get("emotion", ""),
                        "portrait_emotion": line.get("portrait_emotion", ""),
                        "portrait_override": line.get("portrait_override", ""),
                    })


def export_progression(case_dir: Path, out_dir: Path) -> None:
    data = load_json(case_dir / "progression.json")
    phase_rows: List[JsonDict] = []
    unlock_rows: List[JsonDict] = []
    notification_rows: List[JsonDict] = []

    for idx, phase in enumerate(data.get("phases", []), start=1):
        if not isinstance(phase, dict):
            continue
        phase_rows.append({
            "phase_id": phase.get("id", ""),
            "order": idx,
            "title": phase.get("title", ""),
            "description": phase.get("description", ""),
            "hint": phase.get("hint", ""),
            "locations": compact(phase.get("locations", [])),
            "unlock_condition": compact(phase.get("unlock_condition", "")),
            "writer_note": phase.get("_comment", ""),
        })

    for group in ["panel_unlock", "search_point_unlock", "npc_unlock", "confrontation_unlock"]:
        entries = data.get(group, {})
        if not isinstance(entries, dict):
            continue
        for target_id, entry in entries.items():
            if not isinstance(entry, dict):
                continue
            unlock_rows.append({
                "unlock_type": group,
                "target_id": target_id,
                "condition": compact(entry.get("condition", "")),
                "locked_hint": entry.get("locked_hint", ""),
                "writer_note": entry.get("_comment", ""),
            })

    notifications = data.get("phase_notifications", {})
    if isinstance(notifications, dict):
        for phase_id, entry in notifications.items():
            if not isinstance(entry, dict):
                continue
            notification_rows.append({
                "phase_id": phase_id,
                "speaker": entry.get("speaker", ""),
                "text": entry.get("text", ""),
            })

    write_csv(out_dir / "progression_phases.csv", [
        "phase_id", "order", "title", "description", "hint", "locations", "unlock_condition", "writer_note",
    ], phase_rows)
    write_csv(out_dir / "progression_unlocks.csv", [
        "unlock_type", "target_id", "condition", "locked_hint", "writer_note",
    ], unlock_rows)
    write_csv(out_dir / "phase_notifications.csv", ["phase_id", "speaker", "text"], notification_rows)


def export_npc_states(case_dir: Path, out_dir: Path) -> None:
    data = load_json(case_dir / "npc_states.json")
    initial_rows: List[JsonDict] = []
    transition_rows: List[JsonDict] = []
    for npc_id, conf in data.items():
        if str(npc_id).startswith("_") or not isinstance(conf, dict):
            continue
        initial = conf.get("initial", {})
        if isinstance(initial, dict):
            for stat, value in initial.items():
                initial_rows.append({"npc_id": npc_id, "stat": stat, "value": value})
        for idx, transition in enumerate(conf.get("transitions", []), start=1):
            if not isinstance(transition, dict):
                continue
            transition_rows.append({
                "npc_id": npc_id,
                "order": idx,
                "event": transition.get("on", ""),
                "delta": compact(transition.get("delta", {})),
                "writer_note": transition.get("_comment", ""),
            })
    write_csv(out_dir / "npc_state_initial.csv", ["npc_id", "stat", "value"], initial_rows)
    write_csv(out_dir / "npc_state_transitions.csv", ["npc_id", "order", "event", "delta", "writer_note"], transition_rows)


def _res_to_path(res_path: str) -> Path:
    if not res_path.startswith("res://"):
        return Path(res_path)
    return REPO_ROOT / res_path[len("res://"):]


def export_portrait_expressions(case_dir: Path, out_dir: Path) -> None:
    npcs = load_json(case_dir / "npcs.json")
    casting = load_json(case_dir / "casting.json").get("casting", {})
    ids = sorted({k for k in npcs if not k.startswith("_")} | set(casting.keys()))
    rows: List[JsonDict] = []
    excluded_tokens = {"greenscreen", "backup", "old", "new"}
    for npc_id in ids:
        n = npcs.get(npc_id, {}) if isinstance(npcs.get(npc_id, {}), dict) else {}
        c = casting.get(npc_id, {}) if isinstance(casting.get(npc_id, {}), dict) else {}
        base_portrait = n.get("portrait", c.get("portrait", ""))
        if not base_portrait:
            continue
        rows.append({
            "npc_id": npc_id,
            "base_portrait": base_portrait,
            "emotion": "base",
            "portrait": base_portrait,
            "writer_note": "",
        })
        base_path = _res_to_path(base_portrait)
        if not base_path.exists() or base_path.suffix.lower() != ".png":
            continue
        stem = base_path.stem
        for path in sorted(base_path.parent.glob(stem + "_*.png")):
            suffix = path.stem[len(stem) + 1:]
            if not suffix:
                continue
            parts = set(suffix.split("_"))
            if parts & excluded_tokens:
                continue
            if suffix.startswith("v") and suffix[1:].isdigit():
                continue
            rows.append({
                "npc_id": npc_id,
                "base_portrait": base_portrait,
                "emotion": suffix,
                "portrait": "res://" + str(path.relative_to(REPO_ROOT)).replace("\\", "/"),
                "writer_note": "",
            })
    write_csv(out_dir / "portrait_expressions.csv", [
        "npc_id", "base_portrait", "emotion", "portrait", "writer_note",
    ], rows)


def export_day_events(case_dir: Path, out_dir: Path) -> None:
    data = load_json(case_dir / "day_events.json")
    event_rows: List[JsonDict] = []
    line_rows: List[JsonDict] = []
    for idx, evt in enumerate(data.get("events", []), start=1):
        if not isinstance(evt, dict):
            continue
        event_id = evt.get("id", "")
        event_rows.append({
            "event_id": event_id,
            "order": idx,
            "title": evt.get("title", ""),
            "hint": evt.get("hint", ""),
            "trigger": compact(evt.get("trigger", "")),
            "effects": compact(evt.get("effects", {})),
            "auto_play": compact(evt.get("auto_play", "")),
            "writer_note": evt.get("_comment", ""),
        })
        for line_idx, line in enumerate(evt.get("narration", []), start=1):
            if isinstance(line, dict):
                line_rows.append({
                    "event_id": event_id,
                    "order": line_idx,
                    "line_kind": "dict",
                    "speaker": line.get("speaker", ""),
                    "text": line.get("text", ""),
                    "emotion": line.get("emotion", ""),
                    "voice_path": line.get("voice_path", ""),
                    "background": line.get("background", ""),
                    "effect": json.dumps(line.get("effect", {}), ensure_ascii=False) if line.get("effect") else "",
                })
            else:
                line_rows.append({
                    "event_id": event_id,
                    "order": line_idx,
                    "line_kind": "text",
                    "speaker": "",
                    "text": str(line),
                    "emotion": "",
                    "voice_path": "",
                    "background": "",
                    "effect": "",
                })
    write_csv(out_dir / "day_events.csv", [
        "event_id", "order", "title", "hint", "trigger", "effects", "auto_play", "writer_note",
    ], event_rows)
    write_csv(out_dir / "day_event_lines.csv", [
        "event_id", "order", "line_kind", "speaker", "text", "emotion", "voice_path", "background", "effect",
    ], line_rows)


def export_schedules(case_dir: Path, out_dir: Path) -> None:
    data = load_json(case_dir / "schedules.json")
    default_rows: List[JsonDict] = []
    override_rows: List[JsonDict] = []
    conditional_rows: List[JsonDict] = []
    for npc_id, conf in data.items():
        if str(npc_id).startswith("_") or not isinstance(conf, dict):
            continue
        default = conf.get("default", {})
        default_rows.append({
            "npc_id": npc_id,
            "role_note": conf.get("_role", ""),
            "location": default.get("location", "") if isinstance(default, dict) else "",
            "activity": default.get("activity", "") if isinstance(default, dict) else "",
            "public": compact(default.get("public", "")) if isinstance(default, dict) else "",
        })
        overrides = conf.get("overrides", {})
        if isinstance(overrides, dict):
            for time_key, sched in overrides.items():
                if not isinstance(sched, dict):
                    continue
                override_rows.append({
                    "npc_id": npc_id,
                    "time_key": time_key,
                    "location": sched.get("location", ""),
                    "activity": sched.get("activity", ""),
                    "public": compact(sched.get("public", "")),
                })
        for idx, co in enumerate(conf.get("conditional_overrides", []), start=1):
            if not isinstance(co, dict):
                continue
            sched = co.get("schedule", {})
            conditional_rows.append({
                "npc_id": npc_id,
                "order": idx,
                "if_flag": co.get("if_flag", ""),
                "location": sched.get("location", "") if isinstance(sched, dict) else "",
                "activity": sched.get("activity", "") if isinstance(sched, dict) else "",
                "public": compact(sched.get("public", "")) if isinstance(sched, dict) else "",
            })
    write_csv(out_dir / "schedule_defaults.csv", ["npc_id", "role_note", "location", "activity", "public"], default_rows)
    write_csv(out_dir / "schedule_overrides.csv", ["npc_id", "time_key", "location", "activity", "public"], override_rows)
    write_csv(out_dir / "schedule_conditional_overrides.csv", ["npc_id", "order", "if_flag", "location", "activity", "public"], conditional_rows)


def export_culprit_actions(case_dir: Path, out_dir: Path) -> None:
    data = load_json(case_dir / "culprit_actions.json")
    rows: List[JsonDict] = []
    for idx, action in enumerate(data.get("actions", []), start=1):
        if not isinstance(action, dict):
            continue
        trace = action.get("leaves_trace", {})
        rows.append({
            "action_id": action.get("id", ""),
            "order": idx,
            "culprit": action.get("culprit", ""),
            "day_period": action.get("day_period", ""),
            "jitter": action.get("jitter", ""),
            "intent": action.get("intent", ""),
            "trace_evidence_id": trace.get("evidence_id", "") if isinstance(trace, dict) else "",
            "trace_location": trace.get("location", "") if isinstance(trace, dict) else "",
            "trace_discoverable_after": trace.get("discoverable_after", "") if isinstance(trace, dict) else "",
            "if_witnessed": action.get("if_witnessed", ""),
            "writer_note": action.get("_comment", ""),
        })
    write_csv(out_dir / "culprit_actions.csv", [
        "action_id", "order", "culprit", "day_period", "jitter", "intent", "trace_evidence_id",
        "trace_location", "trace_discoverable_after", "if_witnessed", "writer_note",
    ], rows)


def export_json_docs(case_dir: Path, out_dir: Path) -> None:
    """Export complex runtime documents that are not normalized yet into CSV-backed docs.

    Godot runtime reads this CSV, not the original JSON files. Structured tables still remain
    the preferred authoring surface; these docs preserve metadata, prologue/cinematics,
    companion rules, BGM maps, and legacy fields while the table model expands.
    """
    doc_paths = {
        "manifest": case_dir / "manifest.json",
        "key_info": case_dir / "key_info.json",
        "bgm_config": case_dir / "bgm_config.json",
        "prologue": case_dir / "prologue.json",
        "epilogue_meta": case_dir / "epilogue_meta.json",
        "companion_config": case_dir / "companion" / "companion.json",
        "companion_discussions": case_dir / "companion" / "discussions.json",
        "companion_banter": case_dir / "companion" / "banter.json",
        # Base docs preserve fields that are not yet represented by the normalized CSV tables.
        "case_base": case_dir / "case.json",
        "progression_base": case_dir / "progression.json",
        "npc_states_base": case_dir / "npc_states.json",
        "day_events_base": case_dir / "day_events.json",
        "schedules_base": case_dir / "schedules.json",
        "culprit_actions_base": case_dir / "culprit_actions.json",
    }
    rows: List[JsonDict] = []
    for doc_id, path in doc_paths.items():
        if not path.exists():
            continue
        data = load_json(path)
        rows.append({
            "doc_id": doc_id,
            "json": json.dumps(data, ensure_ascii=False, separators=(",", ":")),
        })

    dialogues_base: JsonDict = {}
    dlg_dir = case_dir / "dialogues"
    if dlg_dir.exists():
        for path in sorted(dlg_dir.glob("*.json")):
            dialogues_base[path.stem] = load_json(path)
    if dialogues_base:
        rows.append({
            "doc_id": "dialogues_base",
            "json": json.dumps(dialogues_base, ensure_ascii=False, separators=(",", ":")),
        })
    write_csv(out_dir / "json_docs.csv", ["doc_id", "json"], rows)


def export_case_index(out_root: Path) -> None:
    index = load_json(DATA / "cases" / "_index.json")
    default_case = index.get("default_case", "")
    rows: List[JsonDict] = []
    for entry in index.get("cases", []):
        if not isinstance(entry, dict):
            continue
        rows.append({
            "id": entry.get("id", ""),
            "default": "true" if entry.get("id", "") == default_case else "",
            "order": entry.get("order", ""),
            "locked": compact(entry.get("locked", "")),
            "lock_reason": entry.get("lock_reason", ""),
            "tag": entry.get("tag", ""),
            "voice_status": entry.get("voice_status", "full"),
            "unlock_after": entry.get("unlock_after", ""),
            "style": entry.get("style", ""),
            "category": entry.get("category", ""),
            "era": entry.get("era", "ancient"),
            "is_tutorial": compact(entry.get("is_tutorial", "")),
            "preview_blurb": entry.get("preview_blurb", ""),
        })
    write_csv(out_root / "case_index.csv", [
        "id", "default", "order", "locked", "lock_reason", "tag", "voice_status",
        "unlock_after", "style", "category", "era", "is_tutorial", "preview_blurb",
    ], rows)


def export_case(case_id: str, out_root: Path) -> None:
    case_dir = DATA / "cases" / case_id
    if not case_dir.exists():
        raise FileNotFoundError("case runtime directory not found: %s" % case_dir)
    out_dir = out_root / case_id
    export_characters(case_dir, out_dir, case_id)
    export_evidence(case_dir, out_dir)
    export_locations(case_dir, out_dir)
    export_search_results(case_dir, out_dir)
    export_dialogues(case_dir, out_dir)
    export_confrontations(case_dir, out_dir)
    export_progression(case_dir, out_dir)
    export_npc_states(case_dir, out_dir)
    export_day_events(case_dir, out_dir)
    export_schedules(case_dir, out_dir)
    export_culprit_actions(case_dir, out_dir)
    export_portrait_expressions(case_dir, out_dir)
    export_json_docs(case_dir, out_dir)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--case", dest="case_id", help="case id to export")
    ap.add_argument("--all", action="store_true", help="export all cases listed in data/cases/_index.json")
    ap.add_argument("--index", action="store_true", help="export data/case_tables/case_index.csv")
    ap.add_argument("--out-root", default=str(DATA / "case_tables"))
    args = ap.parse_args()
    out_root = Path(args.out_root).resolve()
    if args.index or args.all:
        export_case_index(out_root)
    if args.all:
        index = load_json(DATA / "cases" / "_index.json")
        for entry in index.get("cases", []):
            if isinstance(entry, dict) and entry.get("id", ""):
                export_case(entry["id"], out_root)
    elif args.case_id:
        export_case(args.case_id, out_root)
    elif not args.index:
        ap.error("use --case <case_id>, --all, or --index")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
