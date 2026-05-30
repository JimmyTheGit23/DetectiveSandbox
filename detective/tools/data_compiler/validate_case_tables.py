#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Validate case authoring CSV tables."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Set, Tuple

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
DATA = REPO_ROOT / "data"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from dsl import is_blank, parse_condition, parse_list  # noqa: E402


JsonDict = Dict[str, Any]


class Reporter:
    def __init__(self) -> None:
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def error(self, msg: str) -> None:
        self.errors.append(msg)
        print("[FAIL] " + msg, file=sys.stderr)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)
        print("[WARN] " + msg)

    def ok(self, msg: str) -> None:
        print("[OK] " + msg)


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
            if values and values[0].startswith("#"):
                continue
            out.append({str(k).strip(): (v if v is not None else "") for k, v in row.items()})
        return out


def _load_json(path: Path) -> JsonDict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _non_meta_keys(d: JsonDict) -> Set[str]:
    return {k for k in d.keys() if not str(k).startswith("_")}


def _res_path_exists(res_path: str) -> bool:
    if not res_path:
        return False
    if res_path.startswith("res://"):
        return (REPO_ROOT / res_path[len("res://"):]).exists()
    return Path(res_path).exists()


def _check_unique(rows: List[JsonDict], key_fields: List[str], label: str, rep: Reporter) -> Set[Tuple[str, ...]]:
    seen: Set[Tuple[str, ...]] = set()
    for idx, row in enumerate(rows, start=2):
        key = tuple(_cell(row, f) for f in key_fields)
        if any(not x for x in key):
            rep.error("%s 第 %d 行缺必填字段: %s" % (label, idx, ", ".join(key_fields)))
            continue
        if key in seen:
            rep.error("%s 重复 ID: %s" % (label, ".".join(key)))
        seen.add(key)
    return seen


def _check_condition_cell(value: Any, label: str, rep: Reporter) -> None:
    if is_blank(value):
        return
    # 允许字符串"null"作为空值处理
    text = str(value).strip()
    if text.lower() == "null":
        return
    try:
        parse_condition(value)
    except Exception as e:
        rep.error("%s 条件解析失败: %s" % (label, e))


SPECIAL_SPEAKER_IDS = {"lu_zhao", "xia_lingyao", "lingyao", "you", "player"}


def _check_portrait_line_fields(row: JsonDict, table_name: str, npc_ids: Set[str], rep: Reporter) -> None:
    speaker_id = _cell(row, "speaker_id")
    if speaker_id and speaker_id not in npc_ids and speaker_id not in SPECIAL_SPEAKER_IDS:
        rep.warn("%s speaker_id 未在 NPC/特殊说话人中声明: %s" % (table_name, speaker_id))
    portrait_override = _cell(row, "portrait_override")
    if portrait_override and not _res_path_exists(portrait_override):
        rep.error("%s portrait_override 资源不存在: %s" % (table_name, portrait_override))


def _runtime_sets(case_id: str) -> Tuple[Set[str], Set[str], Set[str]]:
    case_dir = DATA / "cases" / case_id
    npcs = _non_meta_keys(_load_json(case_dir / "npcs.json"))
    locs = _non_meta_keys(_load_json(case_dir / "locations.json"))
    items = _non_meta_keys(_load_json(case_dir / "evidence.json"))
    return npcs, locs, items


def validate_case(case_id: str, tables_root: Path) -> bool:
    rep = Reporter()
    src = tables_root / case_id
    if not src.exists():
        rep.error("表格目录不存在: %s" % src)
        return False

    runtime_npcs, runtime_locations, runtime_items = _runtime_sets(case_id)

    characters = _rows(src / "characters.csv")
    evidence = _rows(src / "evidence_items.csv")
    locations = _rows(src / "locations.csv")
    links = _rows(src / "location_links.csv")
    points = _rows(src / "search_points.csv")
    search_results = _rows(src / "search_results.csv")
    sub_choices = _rows(src / "search_sub_choices.csv")
    nodes = _rows(src / "dialogue_nodes.csv")
    lines = _rows(src / "dialogue_lines.csv")
    options = _rows(src / "dialogue_options.csv")
    confrontations = _rows(src / "confrontations.csv")
    confrontation_lines = _rows(src / "confrontation_lines.csv")
    testimony_sets = _rows(src / "testimony_sets.csv")
    testimony_lines = _rows(src / "testimony_lines.csv")
    testimony_statements = _rows(src / "testimony_statements.csv")
    testimony_press_lines = _rows(src / "testimony_press_lines.csv")
    testimony_break_lines = _rows(src / "testimony_break_lines.csv")
    testimony_wrong_reactions = _rows(src / "testimony_wrong_reactions.csv")
    progression_phases = _rows(src / "progression_phases.csv")
    progression_unlocks = _rows(src / "progression_unlocks.csv")
    phase_notifications = _rows(src / "phase_notifications.csv")
    npc_state_initial = _rows(src / "npc_state_initial.csv")
    npc_state_transitions = _rows(src / "npc_state_transitions.csv")
    day_events = _rows(src / "day_events.csv")
    day_event_lines = _rows(src / "day_event_lines.csv")
    schedule_defaults = _rows(src / "schedule_defaults.csv")
    schedule_overrides = _rows(src / "schedule_overrides.csv")
    schedule_conditional_overrides = _rows(src / "schedule_conditional_overrides.csv")
    culprit_actions = _rows(src / "culprit_actions.csv")
    portrait_expressions = _rows(src / "portrait_expressions.csv")

    npc_ids = {key[0] for key in _check_unique(characters, ["npc_id"], "characters.csv", rep)} or runtime_npcs
    character_portraits = {_cell(row, "portrait") for row in characters if _cell(row, "portrait")}
    known_base_portraits = character_portraits | {"res://assets/cn/portraits/companion_lingyao.png"}
    item_ids = {key[0] for key in _check_unique(evidence, ["item_id"], "evidence_items.csv", rep)} or runtime_items
    loc_ids = {key[0] for key in _check_unique(locations, ["location_id"], "locations.csv", rep)} or runtime_locations
    point_ids = _check_unique(points, ["location_id", "point_id"], "search_points.csv", rep)
    node_ids = _check_unique(nodes, ["npc_id", "node_id"], "dialogue_nodes.csv", rep)
    confrontation_ids = {key[0] for key in _check_unique(confrontations, ["confrontation_id"], "confrontations.csv", rep)}
    testimony_ids = {key[0] for key in _check_unique(testimony_sets, ["testimony_id"], "testimony_sets.csv", rep)}
    statement_ids = {key[0] for key in _check_unique(testimony_statements, ["statement_id"], "testimony_statements.csv", rep)}
    phase_ids = {key[0] for key in _check_unique(progression_phases, ["phase_id"], "progression_phases.csv", rep)}
    _check_unique(npc_state_initial, ["npc_id", "stat"], "npc_state_initial.csv", rep)
    event_ids = {key[0] for key in _check_unique(day_events, ["event_id"], "day_events.csv", rep)}
    _check_unique(schedule_defaults, ["npc_id"], "schedule_defaults.csv", rep)
    _check_unique(schedule_overrides, ["npc_id", "time_key"], "schedule_overrides.csv", rep)
    action_ids = {key[0] for key in _check_unique(culprit_actions, ["action_id"], "culprit_actions.csv", rep)}
    _check_unique(portrait_expressions, ["base_portrait", "emotion"], "portrait_expressions.csv", rep)

    for row in characters:
        if not _cell(row, "name"):
            rep.error("characters.csv npc_id=%s 缺 name" % _cell(row, "npc_id"))

    for row in evidence:
        item_id = _cell(row, "item_id")
        if not _cell(row, "name"):
            rep.error("evidence_items.csv item_id=%s 缺 name" % item_id)
        if not _cell(row, "description"):
            rep.warn("evidence_items.csv item_id=%s 缺 description" % item_id)

    for row in links:
        src_loc = _cell(row, "from_location")
        dst_loc = _cell(row, "target_location")
        if src_loc and src_loc not in loc_ids:
            rep.error("location_links.csv from_location 不存在: %s" % src_loc)
        if dst_loc and dst_loc not in loc_ids:
            rep.error("location_links.csv target_location 不存在: %s" % dst_loc)
        _check_condition_cell(row.get("requires", ""), "location_links.csv %s→%s" % (src_loc, dst_loc), rep)

    for row in points:
        loc = _cell(row, "location_id")
        if loc not in loc_ids:
            rep.error("search_points.csv location_id 不存在: %s" % loc)
        _check_condition_cell(row.get("unlock_condition", ""), "search_points.csv %s.%s" % (loc, _cell(row, "point_id")), rep)

    for row in search_results:
        loc = _cell(row, "location_id")
        point = _cell(row, "point_id")
        if point_ids and (loc, point) not in point_ids:
            rep.error("search_results.csv 搜索点不存在: %s.%s" % (loc, point))
        _check_condition_cell(row.get("when", ""), "search_results.csv %s.%s" % (loc, point), rep)
        for field in ["gain_evidence", "gain_clue", "evidence", "clue"]:
            item = _cell(row, field)
            if item and item not in item_ids:
                rep.error("search_results.csv %s 引用不存在: %s" % (field, item))

    for row in sub_choices:
        loc = _cell(row, "location_id")
        point = _cell(row, "point_id")
        if point_ids and (loc, point) not in point_ids:
            rep.error("search_sub_choices.csv 搜索点不存在: %s.%s" % (loc, point))
        _check_condition_cell(row.get("requires", ""), "search_sub_choices.csv %s.%s" % (loc, point), rep)
        for field in ["gain_evidence", "gain_clue", "evidence", "clue"]:
            item = _cell(row, field)
            if item and item not in item_ids:
                rep.error("search_sub_choices.csv %s 引用不存在: %s" % (field, item))

    starts: Dict[str, int] = {}
    for row in nodes:
        npc = _cell(row, "npc_id")
        if npc_ids and npc not in npc_ids:
            rep.warn("dialogue_nodes.csv npc_id 未在 characters/runtime npcs 中声明: %s" % npc)
        if str(row.get("is_start", "")).strip().lower() in {"1", "true", "yes", "是"}:
            starts[npc] = starts.get(npc, 0) + 1
        for field in ["gain_evidence", "gain_clue"]:
            item = _cell(row, field)
            if item and item not in item_ids:
                rep.error("dialogue_nodes.csv %s 引用不存在: %s" % (field, item))

    for npc, count in starts.items():
        if count > 1:
            rep.error("dialogue_nodes.csv npc_id=%s 有多个 is_start" % npc)

    for row in lines:
        key = (_cell(row, "npc_id"), _cell(row, "node_id"))
        if node_ids and key not in node_ids:
            rep.error("dialogue_lines.csv 指向不存在节点: %s.%s" % key)
        _check_condition_cell(row.get("requires", ""), "dialogue_lines.csv %s.%s" % key, rep)

    special_goto = {"__exit__", "__confront__", ""}
    for row in options:
        key = (_cell(row, "npc_id"), _cell(row, "node_id"))
        if node_ids and key not in node_ids:
            rep.error("dialogue_options.csv 指向不存在节点: %s.%s" % key)
        goto = _cell(row, "goto")
        if goto not in special_goto and node_ids and (key[0], goto) not in node_ids:
            rep.error("dialogue_options.csv goto 不存在: %s.%s -> %s" % (key[0], key[1], goto))
        _check_condition_cell(row.get("requires", ""), "dialogue_options.csv %s.%s" % key, rep)

    for row in confrontations:
        confrontation_id = _cell(row, "confrontation_id")
        suspect = _cell(row, "suspect")
        if suspect and npc_ids and suspect not in npc_ids:
            rep.error("confrontations.csv suspect 不存在: %s" % suspect)
        if not _cell(row, "confidence"):
            rep.warn("confrontations.csv confrontation_id=%s 未设置 confidence" % confrontation_id)

    valid_confrontation_sections = {"intro_dialogue", "victory_dialogue", "defeat_dialogue", "epilogue_text"}
    for row in confrontation_lines:
        confrontation_id = _cell(row, "confrontation_id")
        section = _cell(row, "section")
        if confrontation_ids and confrontation_id not in confrontation_ids:
            rep.error("confrontation_lines.csv confrontation_id 不存在: %s" % confrontation_id)
        if section not in valid_confrontation_sections:
            rep.error("confrontation_lines.csv section 非法: %s" % section)
        if not _cell(row, "text"):
            rep.error("confrontation_lines.csv %s.%s 缺 text" % (confrontation_id, section))
        _check_portrait_line_fields(row, "confrontation_lines.csv", npc_ids, rep)

    for row in testimony_sets:
        confrontation_id = _cell(row, "confrontation_id")
        testimony_id = _cell(row, "testimony_id")
        if confrontation_ids and confrontation_id not in confrontation_ids:
            rep.error("testimony_sets.csv confrontation_id 不存在: %s" % confrontation_id)
        witness = _cell(row, "witness")
        if witness and npc_ids and witness not in npc_ids:
            rep.warn("testimony_sets.csv witness 未在 NPC 表中声明: %s" % witness)
        if not _cell(row, "title"):
            rep.error("testimony_sets.csv testimony_id=%s 缺 title" % testimony_id)

    valid_testimony_sections = {"preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"}
    for row in testimony_lines:
        testimony_id = _cell(row, "testimony_id")
        section = _cell(row, "section")
        if testimony_ids and testimony_id not in testimony_ids:
            rep.error("testimony_lines.csv testimony_id 不存在: %s" % testimony_id)
        if section not in valid_testimony_sections:
            rep.error("testimony_lines.csv section 非法: %s" % section)
        if not _cell(row, "text"):
            rep.error("testimony_lines.csv %s.%s 缺 text" % (testimony_id, section))
        _check_portrait_line_fields(row, "testimony_lines.csv", npc_ids, rep)

    contradiction_by_testimony: Dict[str, int] = {}
    for row in testimony_statements:
        testimony_id = _cell(row, "testimony_id")
        statement_id = _cell(row, "statement_id")
        if testimony_ids and testimony_id not in testimony_ids:
            rep.error("testimony_statements.csv testimony_id 不存在: %s" % testimony_id)
        if not _cell(row, "text"):
            rep.error("testimony_statements.csv statement_id=%s 缺 text" % statement_id)
        _check_portrait_line_fields(row, "testimony_statements.csv", npc_ids, rep)
        counter = _cell(row, "counter_evidence")
        if counter and counter not in item_ids:
            rep.error("testimony_statements.csv counter_evidence 不存在: %s" % counter)
        for alt in parse_list(row.get("alt_evidence", "")):
            if alt and alt not in item_ids:
                rep.error("testimony_statements.csv alt_evidence 不存在: %s" % alt)
        trigger = _cell(row, "press_add_trigger")
        if trigger and trigger not in statement_ids:
            rep.error("testimony_statements.csv press_add_trigger 不存在: %s" % trigger)
        is_contradiction = str(row.get("is_contradiction", "")).strip().lower() in {"1", "true", "yes", "是"}
        if is_contradiction:
            contradiction_by_testimony[testimony_id] = contradiction_by_testimony.get(testimony_id, 0) + 1
            if not counter and not parse_list(row.get("alt_evidence", "")):
                rep.error("testimony_statements.csv 矛盾句缺 counter_evidence/alt_evidence: %s" % statement_id)

    for testimony_id in testimony_ids:
        if contradiction_by_testimony.get(testimony_id, 0) <= 0:
            rep.warn("testimony_sets.csv testimony_id=%s 没有矛盾句" % testimony_id)

    for table_name, rows_to_check in [
        ("testimony_press_lines.csv", testimony_press_lines),
        ("testimony_break_lines.csv", testimony_break_lines),
        ("testimony_wrong_reactions.csv", testimony_wrong_reactions),
    ]:
        for row in rows_to_check:
            statement_id = _cell(row, "statement_id")
            if statement_ids and statement_id not in statement_ids:
                rep.error("%s statement_id 不存在: %s" % (table_name, statement_id))
            if not _cell(row, "text"):
                rep.error("%s statement_id=%s 缺 text" % (table_name, statement_id))
            _check_portrait_line_fields(row, table_name, npc_ids, rep)
            if table_name == "testimony_wrong_reactions.csv":
                evidence_id = _cell(row, "evidence_id")
                if evidence_id != "_default" and evidence_id and evidence_id not in item_ids:
                    rep.error("testimony_wrong_reactions.csv evidence_id 不存在: %s" % evidence_id)

    for row in progression_phases:
        phase_id = _cell(row, "phase_id")
        for loc in parse_list(row.get("locations", "")):
            if loc and loc not in loc_ids:
                rep.error("progression_phases.csv phase_id=%s locations 引用不存在: %s" % (phase_id, loc))
        _check_condition_cell(row.get("unlock_condition", ""), "progression_phases.csv %s" % phase_id, rep)

    valid_unlock_types = {"panel_unlock", "search_point_unlock", "npc_unlock", "confrontation_unlock"}
    for row in progression_unlocks:
        unlock_type = _cell(row, "unlock_type")
        target_id = _cell(row, "target_id")
        if unlock_type not in valid_unlock_types:
            rep.error("progression_unlocks.csv unlock_type 非法: %s" % unlock_type)
        if unlock_type == "search_point_unlock" and point_ids and "." in target_id:
            loc, point = target_id.split(".", 1)
            if (loc, point) not in point_ids:
                rep.warn("progression_unlocks.csv search_point 不在 search_points.csv 中: %s" % target_id)
        elif unlock_type == "npc_unlock" and npc_ids and target_id not in npc_ids:
            rep.error("progression_unlocks.csv npc_id 不存在: %s" % target_id)
        elif unlock_type == "confrontation_unlock" and confrontation_ids and target_id not in confrontation_ids:
            rep.warn("progression_unlocks.csv confrontation_id 未在 confrontations.csv 中声明: %s" % target_id)
        _check_condition_cell(row.get("condition", ""), "progression_unlocks.csv %s:%s" % (unlock_type, target_id), rep)

    for row in phase_notifications:
        phase_id = _cell(row, "phase_id")
        if phase_ids and phase_id not in phase_ids:
            rep.error("phase_notifications.csv phase_id 不存在: %s" % phase_id)
        if not _cell(row, "text"):
            rep.error("phase_notifications.csv phase_id=%s 缺 text" % phase_id)

    for row in npc_state_initial:
        npc_id = _cell(row, "npc_id")
        if npc_ids and npc_id not in npc_ids:
            rep.warn("npc_state_initial.csv npc_id 未在 NPC 表中声明: %s" % npc_id)
        if not _cell(row, "stat"):
            rep.error("npc_state_initial.csv npc_id=%s 缺 stat" % npc_id)

    for row in npc_state_transitions:
        npc_id = _cell(row, "npc_id")
        if npc_ids and npc_id not in npc_ids:
            rep.warn("npc_state_transitions.csv npc_id 未在 NPC 表中声明: %s" % npc_id)
        if not _cell(row, "event"):
            rep.error("npc_state_transitions.csv npc_id=%s 缺 event" % npc_id)
        delta_raw = row.get("delta", "")
        if is_blank(delta_raw):
            rep.error("npc_state_transitions.csv npc_id=%s 缺 delta" % npc_id)
        else:
            try:
                parsed = json.loads(str(delta_raw))
                if not isinstance(parsed, dict):
                    rep.error("npc_state_transitions.csv delta 不是 JSON 对象: %s" % npc_id)
            except Exception as e:
                rep.error("npc_state_transitions.csv delta 解析失败: %s" % e)

    for row in day_events:
        event_id = _cell(row, "event_id")
        if not _cell(row, "title"):
            rep.error("day_events.csv event_id=%s 缺 title" % event_id)
        try:
            parsed_trigger = json.loads(str(row.get("trigger", "{}"))) if not is_blank(row.get("trigger", "")) else {}
            if not isinstance(parsed_trigger, dict):
                rep.error("day_events.csv trigger 不是 JSON 对象: %s" % event_id)
        except Exception as e:
            rep.error("day_events.csv trigger 解析失败 %s: %s" % (event_id, e))
        try:
            parsed_effects = json.loads(str(row.get("effects", "{}"))) if not is_blank(row.get("effects", "")) else {}
            if not isinstance(parsed_effects, dict):
                rep.error("day_events.csv effects 不是 JSON 对象: %s" % event_id)
        except Exception as e:
            rep.error("day_events.csv effects 解析失败 %s: %s" % (event_id, e))

    for row in day_event_lines:
        event_id = _cell(row, "event_id")
        if event_ids and event_id not in event_ids:
            rep.error("day_event_lines.csv event_id 不存在: %s" % event_id)
        if _cell(row, "line_kind") not in {"text", "dict", "dialogue"}:
            rep.error("day_event_lines.csv line_kind 非法: %s" % _cell(row, "line_kind"))
        if not _cell(row, "text"):
            rep.error("day_event_lines.csv event_id=%s 缺 text" % event_id)

    for row in schedule_defaults:
        npc_id = _cell(row, "npc_id")
        if npc_ids and npc_id not in npc_ids:
            rep.warn("schedule_defaults.csv npc_id 未在 NPC 表中声明: %s" % npc_id)
        loc = _cell(row, "location")
        if loc and loc_ids and loc not in loc_ids:
            rep.error("schedule_defaults.csv location 不存在: %s" % loc)

    for table_name, rows_to_check in [
        ("schedule_overrides.csv", schedule_overrides),
        ("schedule_conditional_overrides.csv", schedule_conditional_overrides),
    ]:
        for row in rows_to_check:
            npc_id = _cell(row, "npc_id")
            if npc_ids and npc_id not in npc_ids:
                rep.warn("%s npc_id 未在 NPC 表中声明: %s" % (table_name, npc_id))
            loc = _cell(row, "location")
            if loc and loc_ids and loc not in loc_ids:
                rep.error("%s location 不存在: %s" % (table_name, loc))
            if table_name == "schedule_overrides.csv" and not _cell(row, "time_key"):
                rep.error("schedule_overrides.csv npc_id=%s 缺 time_key" % npc_id)
            if table_name == "schedule_conditional_overrides.csv" and not _cell(row, "if_flag"):
                rep.error("schedule_conditional_overrides.csv npc_id=%s 缺 if_flag" % npc_id)

    for row in culprit_actions:
        action_id = _cell(row, "action_id")
        culprit = _cell(row, "culprit")
        if culprit and npc_ids and culprit not in npc_ids:
            rep.warn("culprit_actions.csv culprit 未在 NPC 表中声明: %s" % culprit)
        if not _cell(row, "day_period"):
            rep.error("culprit_actions.csv action_id=%s 缺 day_period" % action_id)
        evidence_id = _cell(row, "trace_evidence_id")
        if evidence_id and item_ids and evidence_id not in item_ids:
            rep.error("culprit_actions.csv trace_evidence_id 不存在: %s" % evidence_id)
        loc = _cell(row, "trace_location")
        if loc and loc_ids and loc not in loc_ids:
            rep.error("culprit_actions.csv trace_location 不存在: %s" % loc)

    for row in portrait_expressions:
        npc_id = _cell(row, "npc_id")
        if npc_id and npc_ids and npc_id not in npc_ids:
            rep.warn("portrait_expressions.csv npc_id 未在 NPC 表中声明: %s" % npc_id)
        base_portrait = _cell(row, "base_portrait")
        portrait = _cell(row, "portrait")
        if not base_portrait:
            rep.error("portrait_expressions.csv 缺 base_portrait")
        elif not _res_path_exists(base_portrait):
            rep.error("portrait_expressions.csv base_portrait 资源不存在: %s" % base_portrait)
        elif known_base_portraits and base_portrait not in known_base_portraits:
            rep.warn("portrait_expressions.csv base_portrait 未在 characters.csv/助手基础立绘中出现: %s" % base_portrait)
        if not _cell(row, "emotion"):
            rep.error("portrait_expressions.csv base_portrait=%s 缺 emotion" % base_portrait)
        if not portrait:
            rep.error("portrait_expressions.csv base_portrait=%s 缺 portrait" % base_portrait)
        elif not _res_path_exists(portrait):
            rep.error("portrait_expressions.csv portrait 资源不存在: %s" % portrait)

    if rep.errors:
        print("\ncase=%s 校验失败：%d error, %d warning" % (case_id, len(rep.errors), len(rep.warnings)), file=sys.stderr)
        return False
    rep.ok("case=%s 表格校验通过（%d warning）" % (case_id, len(rep.warnings)))
    return True


def iter_cases(tables_root: Path) -> Iterable[str]:
    if not tables_root.exists():
        return []
    return [p.name for p in sorted(tables_root.iterdir()) if p.is_dir() and not p.name.startswith("_")]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--case", dest="case_id")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--tables-root", default=str(DATA / "case_tables"))
    args = ap.parse_args()

    tables_root = Path(args.tables_root).resolve()
    if args.all:
        cases = list(iter_cases(tables_root))
    elif args.case_id:
        cases = [args.case_id]
    else:
        ap.error("use --case <case_id> or --all")

    ok = True
    for case_id in cases:
        ok = validate_case(case_id, tables_root) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
