#!/usr/bin/env python3
"""
Extract text from prologue_ferry's json_docs.csv into proper CSV tables.
Works for:
  1. prologue → prologue_nodes.csv + prologue_lines.csv (new tables)
  2. case_base confrontation → confrontation_lines.csv, testimony_sets.csv, 
     testimony_lines.csv, testimony_statements.csv, testimony_press_lines.csv,
     testimony_break_lines.csv, testimony_wrong_reactions.csv
  3. confrontation_final → same tables (appended)
  4. day_events_base → day_events.csv + day_event_lines.csv
  5. companion_banter / companion_discussions → companion_banter.csv, companion_discussions.csv (new)
  6. epilogue_meta → epilogue_scenes.csv + epilogue_lines.csv (new)
"""
import csv
import json
import os
import sys
from pathlib import Path

CASE_DIR = Path(__file__).resolve().parent.parent / "data" / "case_tables" / "prologue_ferry"
JSON_DOCS = CASE_DIR / "json_docs.csv"

def read_json_docs():
    """Read json_docs.csv and return dict of doc_id → parsed JSON."""
    docs = {}
    with open(JSON_DOCS, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            doc_id = row.get("doc_id", "").strip()
            if not doc_id:
                continue
            json_str = row.get("json", "")
            try:
                docs[doc_id] = json.loads(json_str)
            except json.JSONDecodeError as e:
                print(f"  WARN: Could not parse JSON for doc_id={doc_id}: {e}")
    return docs


def write_csv(path, headers, rows):
    """Write CSV with UTF-8 BOM for Godot compatibility."""
    with open(path, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        for row in rows:
            writer.writerow(row)
    print(f"  → {path.name}: {len(rows)} rows")


def extract_dialogue_line(line, order, **extra):
    """Convert a dialogue line dict to a flat dict."""
    d = {"order": order}
    d["speaker"] = line.get("speaker", "")
    d["speaker_id"] = line.get("speaker_id", "")
    d["text"] = line.get("text", "")
    d["emotion"] = line.get("emotion", "")
    d["type"] = line.get("type", "")
    d.update(extra)
    return d


# ─── 1. PROLOGUE ────────────────────────────────────────────────────────────

def extract_prologue(prologue_data):
    """Extract prologue nodes into CSV tables."""
    if not prologue_data or "nodes" not in prologue_data:
        print("  No prologue data found.")
        return

    nodes = prologue_data["nodes"]
    node_rows = []
    line_rows = []
    choice_rows = []

    for node_id, node in nodes.items():
        if node_id.startswith("_sep") or node_id.startswith("_"):
            continue
        if not isinstance(node, dict):
            continue

        # Node metadata
        nrow = {
            "node_id": node_id,
            "type": node.get("type", ""),
            "background": node.get("background", ""),
            "next": node.get("next", ""),
            "centered": "true" if node.get("centered") else "",
            "end": "true" if node.get("end") else "",
            "portrait": node.get("portrait", ""),
            "emotion": node.get("emotion", ""),
        }
        # Serialize fx as JSON
        if "fx" in node:
            nrow["fx"] = json.dumps(node["fx"], ensure_ascii=False)
        if "effect" in node:
            nrow["effect"] = json.dumps(node["effect"], ensure_ascii=False)
        node_rows.append(nrow)

        # Text content
        text = node.get("text", "")
        if text:
            line_rows.append({
                "node_id": node_id,
                "order": 0,
                "speaker": node.get("speaker", ""),
                "text": text,
                "emotion": node.get("emotion", ""),
                "type": "",
            })

        # Choices
        for ci, choice in enumerate(node.get("choices", [])):
            crow = {
                "node_id": node_id,
                "order": ci,
                "text": choice.get("text", ""),
                "goto": choice.get("goto", ""),
            }
            if "requires" in choice:
                crow["requires"] = json.dumps(choice["requires"], ensure_ascii=False)
            choice_rows.append(crow)

    # Write prologue_nodes.csv
    node_headers = ["node_id", "type", "background", "next", "centered", "end", "portrait", "emotion", "fx", "effect"]
    node_data = []
    for n in node_rows:
        node_data.append([n.get(h, "") for h in node_headers])
    write_csv(CASE_DIR / "prologue_nodes.csv", node_headers, node_data)

    # Write prologue_lines.csv
    line_headers = ["node_id", "order", "speaker", "text", "emotion", "type"]
    line_data = []
    for l in line_rows:
        line_data.append([l.get(h, "") for h in line_headers])
    write_csv(CASE_DIR / "prologue_lines.csv", line_headers, line_data)

    # Write prologue_choices.csv
    choice_headers = ["node_id", "order", "text", "goto", "requires"]
    choice_data = []
    for c in choice_rows:
        choice_data.append([c.get(h, "") for h in choice_headers])
    write_csv(CASE_DIR / "prologue_choices.csv", choice_headers, choice_data)


# ─── 2. CONFRONTATION SYSTEM ────────────────────────────────────────────────

def extract_confrontation(conf_data, confrontation_id, out):
    """Extract one confrontation into CSV rows."""
    if not conf_data:
        return

    # Confrontation meta
    conf_row = {
        "confrontation_id": confrontation_id,
        "suspect": conf_data.get("suspect", ""),
        "is_final": "true" if conf_data.get("is_final") else "",
        "background": conf_data.get("background", ""),
        "bgm": conf_data.get("bgm", ""),
        "bgm_break": conf_data.get("bgm_break", ""),
        "bgm_break_actual": conf_data.get("bgm_break_actual", ""),
        "bgm_final_round": conf_data.get("bgm_final_round", ""),
        "confidence": conf_data.get("confidence", ""),
        "writer_note": conf_data.get("_comment", ""),
    }
    out["confrontations"].append(conf_row)

    # Confrontation-level dialogue sections
    for section in ["intro_dialogue", "victory_dialogue", "defeat_dialogue"]:
        lines = conf_data.get(section, [])
        for order, line in enumerate(lines):
            out["confrontation_lines"].append({
                "confrontation_id": confrontation_id,
                "section": section,
                "order": order,
                "speaker": line.get("speaker", ""),
                "speaker_id": line.get("speaker_id", ""),
                "text": line.get("text", ""),
                "emotion": line.get("emotion", ""),
            })

    # Epilogue text
    for order, text in enumerate(conf_data.get("epilogue_text", [])):
        out["confrontation_lines"].append({
            "confrontation_id": confrontation_id,
            "section": "epilogue_text",
            "order": order,
            "speaker": "",
            "speaker_id": "",
            "text": text if isinstance(text, str) else str(text),
            "emotion": "",
        })

    # Testimonies
    for testimony in conf_data.get("testimonies", []):
        tid = testimony.get("id", "")
        t_row = {
            "confrontation_id": confrontation_id,
            "testimony_id": tid,
            "witness": testimony.get("witness", ""),
            "title": testimony.get("title", ""),
            "order": len(out["testimony_sets"]),
        }
        out["testimony_sets"].append(t_row)

        # Testimony-level line sections
        for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
            lines = testimony.get(section, [])
            for order, line in enumerate(lines):
                out["testimony_lines"].append({
                    "testimony_id": tid,
                    "section": section,
                    "order": order,
                    "speaker": line.get("speaker", ""),
                    "speaker_id": line.get("speaker_id", ""),
                    "text": line.get("text", ""),
                    "emotion": line.get("emotion", ""),
                })

        # Statements
        for stmt in testimony.get("statements", []):
            sid = stmt.get("id", "")
            stmt_row = {
                "testimony_id": tid,
                "statement_id": sid,
                "speaker": stmt.get("speaker", ""),
                "text": stmt.get("text", ""),
                "emotion": stmt.get("emotion", ""),
                "is_contradiction": "true" if stmt.get("is_contradiction") else "",
                "counter_evidence": stmt.get("counter_evidence", ""),
                "alt_evidence": ",".join(stmt.get("alt_evidence", [])),
                "break_evidence": stmt.get("break_evidence", ""),
            }
            # Handle press_adds
            if "press_adds" in stmt:
                pa = stmt["press_adds"]
                stmt_row["press_add_trigger"] = sid
                stmt_row["press_add_after"] = pa.get("after", sid)
                out["testimony_statements"].append(stmt_row)
                # Also add the added statement
                add_stmt = pa.get("statement", {})
                if add_stmt:
                    add_sid = add_stmt.get("id", "")
                    add_row = {
                        "testimony_id": tid,
                        "statement_id": add_sid,
                        "speaker": add_stmt.get("speaker", ""),
                        "text": add_stmt.get("text", ""),
                        "emotion": add_stmt.get("emotion", ""),
                        "is_contradiction": "true" if add_stmt.get("is_contradiction") else "",
                        "counter_evidence": add_stmt.get("counter_evidence", ""),
                        "alt_evidence": ",".join(add_stmt.get("alt_evidence", [])),
                        "break_evidence": add_stmt.get("break_evidence", ""),
                        "press_add_trigger": "",
                        "press_add_after": "",
                    }
                    out["testimony_statements"].append(add_row)
                    # Press lines for added statement
                    for order, line in enumerate(add_stmt.get("press", [])):
                        out["testimony_press_lines"].append({
                            "statement_id": add_sid,
                            "order": order,
                            "speaker": line.get("speaker", ""),
                            "text": line.get("text", ""),
                            "emotion": line.get("emotion", ""),
                        })
                    # Break lines for added statement
                    for order, line in enumerate(add_stmt.get("break_dialogue", [])):
                        out["testimony_break_lines"].append({
                            "statement_id": add_sid,
                            "order": order,
                            "speaker": line.get("speaker", ""),
                            "text": line.get("text", ""),
                            "emotion": line.get("emotion", ""),
                        })
            else:
                out["testimony_statements"].append(stmt_row)

            # Press lines
            for order, line in enumerate(stmt.get("press", [])):
                out["testimony_press_lines"].append({
                    "statement_id": sid,
                    "order": order,
                    "speaker": line.get("speaker", ""),
                    "text": line.get("text", ""),
                    "emotion": line.get("emotion", ""),
                })

            # Break dialogue
            for order, line in enumerate(stmt.get("break_dialogue", [])):
                out["testimony_break_lines"].append({
                    "statement_id": sid,
                    "order": order,
                    "speaker": line.get("speaker", ""),
                    "text": line.get("text", ""),
                    "emotion": line.get("emotion", ""),
                })

            # Wrong reactions
            for evidence_id, reactions in stmt.get("wrong_reactions", {}).items():
                for order, line in enumerate(reactions):
                    out["testimony_wrong_reactions"].append({
                        "statement_id": sid,
                        "evidence_id": evidence_id,
                        "order": order,
                        "speaker": line.get("speaker", ""),
                        "text": line.get("text", ""),
                        "emotion": line.get("emotion", ""),
                    })


def write_confrontation_csvs(out):
    """Write all confrontation CSV files."""
    headers = {
        "confrontations": ["confrontation_id", "suspect", "is_final", "background", "bgm", "bgm_break", "bgm_break_actual", "bgm_final_round", "confidence", "writer_note"],
        "confrontation_lines": ["confrontation_id", "section", "order", "speaker", "speaker_id", "text", "emotion"],
        "testimony_sets": ["confrontation_id", "testimony_id", "witness", "title", "order"],
        "testimony_lines": ["testimony_id", "section", "order", "speaker", "speaker_id", "text", "emotion"],
        "testimony_statements": ["testimony_id", "statement_id", "speaker", "text", "emotion", "is_contradiction", "counter_evidence", "alt_evidence", "break_evidence", "press_add_trigger", "press_add_after"],
        "testimony_press_lines": ["statement_id", "order", "speaker", "text", "emotion"],
        "testimony_break_lines": ["statement_id", "order", "speaker", "text", "emotion"],
        "testimony_wrong_reactions": ["statement_id", "evidence_id", "order", "speaker", "text", "emotion"],
    }
    for key, hdrs in headers.items():
        rows = []
        for item in out[key]:
            rows.append([item.get(h, "") for h in hdrs])
        write_csv(CASE_DIR / f"{key}.csv", hdrs, rows)


# ─── 3. DAY EVENTS ──────────────────────────────────────────────────────────

def extract_day_events(day_data):
    """Extract day_events_base into CSV."""
    if not day_data:
        return
    events = day_data.get("events", [])
    event_rows = []
    line_rows = []
    for event in events:
        eid = event.get("id", "")
        event_rows.append({
            "event_id": eid,
            "title": event.get("title", ""),
            "hint": event.get("hint", ""),
            "trigger": json.dumps(event.get("trigger", {}), ensure_ascii=False),
            "effects": json.dumps(event.get("effects", {}), ensure_ascii=False),
            "auto_play": "true" if event.get("auto_play") else "",
            "writer_note": event.get("_comment", ""),
        })
        for order, narr in enumerate(event.get("narration", [])):
            if isinstance(narr, str):
                line_rows.append({
                    "event_id": eid,
                    "line_kind": "text",
                    "order": order,
                    "speaker": "",
                    "text": narr,
                    "emotion": "",
                    "voice_path": "",
                })
            elif isinstance(narr, dict):
                line_rows.append({
                    "event_id": eid,
                    "line_kind": "dialogue",
                    "order": order,
                    "speaker": narr.get("speaker", ""),
                    "text": narr.get("text", ""),
                    "emotion": narr.get("emotion", ""),
                    "voice_path": narr.get("voice_path", ""),
                })

    evt_headers = ["event_id", "title", "hint", "trigger", "effects", "auto_play", "writer_note"]
    evt_data = [[e.get(h, "") for h in evt_headers] for e in event_rows]
    write_csv(CASE_DIR / "day_events.csv", evt_headers, evt_data)

    line_headers = ["event_id", "line_kind", "order", "speaker", "text", "emotion", "voice_path"]
    line_data = [[l.get(h, "") for h in line_headers] for l in line_rows]
    write_csv(CASE_DIR / "day_event_lines.csv", line_headers, line_data)


# ─── 4. COMPANION ───────────────────────────────────────────────────────────

def extract_companion_discussions(disc_data):
    """Extract companion_discussions rules into CSV."""
    if not disc_data:
        return
    rows = []
    for topic_id, topic_data in disc_data.items():
        if topic_id.startswith("_"):
            continue
        if not isinstance(topic_data, dict):
            continue
        rules = topic_data.get("rules", [])
        for order, rule in enumerate(rules):
            when = rule.get("when", {})
            lines = rule.get("lines", [])
            once = "true" if rule.get("once") else ""
            priority = rule.get("priority", "")
            rows.append({
                "topic_id": topic_id,
                "rule_order": order,
                "when": json.dumps(when, ensure_ascii=False),
                "lines": json.dumps(lines, ensure_ascii=False),
                "once": once,
                "priority": priority,
            })
        # Handle pool (chitchat)
        pool = topic_data.get("pool", [])
        if pool:
            rows.append({
                "topic_id": topic_id,
                "rule_order": 0,
                "when": json.dumps({"default": True}, ensure_ascii=False),
                "lines": json.dumps(pool, ensure_ascii=False),
                "once": "",
                "priority": "",
            })

    headers = ["topic_id", "rule_order", "when", "lines", "once", "priority"]
    data = [[r.get(h, "") for h in headers] for r in rows]
    write_csv(CASE_DIR / "companion_discussions.csv", headers, data)


def extract_companion_banter(banter_data):
    """Extract companion_banter rules into CSV."""
    if not banter_data:
        return
    rules = banter_data.get("rules", [])
    rows = []
    for rule in rules:
        rows.append({
            "banter_id": rule.get("id", ""),
            "when": json.dumps(rule.get("when", {}), ensure_ascii=False),
            "requires": json.dumps(rule.get("requires", {}), ensure_ascii=False) if "requires" in rule else "",
            "lines": json.dumps(rule.get("lines", []), ensure_ascii=False),
            "effect": json.dumps(rule.get("effect", {}), ensure_ascii=False) if "effect" in rule else "",
            "once": "true" if rule.get("once") else "",
            "priority": rule.get("priority", ""),
        })

    headers = ["banter_id", "when", "requires", "lines", "effect", "once", "priority"]
    data = [[r.get(h, "") for h in headers] for r in rows]
    write_csv(CASE_DIR / "companion_banter.csv", headers, data)


# ─── 5. EPILOGUE META ────────────────────────────────────────────────────────

def extract_epilogue_meta(epi_data):
    """Extract epilogue_meta scenes into CSV."""
    if not epi_data:
        return
    scene_rows = []
    line_rows = []
    for scene in epi_data.get("scenes", []):
        sid = scene.get("id", "")
        scene_rows.append({
            "scene_id": sid,
            "type": scene.get("type", ""),
            "background": scene.get("background", ""),
            "bgm": scene.get("bgm", ""),
            "order": len(scene_rows),
        })
        for order, line in enumerate(scene.get("lines", [])):
            line_rows.append({
                "scene_id": sid,
                "order": order,
                "speaker": line.get("speaker", ""),
                "text": line.get("text", ""),
                "emotion": line.get("emotion", ""),
            })

    scene_headers = ["scene_id", "type", "background", "bgm", "order"]
    scene_data = [[s.get(h, "") for h in scene_headers] for s in scene_rows]
    write_csv(CASE_DIR / "epilogue_scenes.csv", scene_headers, scene_data)

    line_headers = ["scene_id", "order", "speaker", "text", "emotion"]
    line_data = [[l.get(h, "") for h in line_headers] for l in line_rows]
    write_csv(CASE_DIR / "epilogue_lines.csv", line_headers, line_data)


# ─── 6. SCHEDULES / NPC STATES / PROGRESSION ────────────────────────────────

def extract_schedules(sched_data):
    """Extract schedules_base into schedule_defaults + schedule_conditional_overrides CSV."""
    if not sched_data:
        return
    default_rows = []
    override_rows = []
    for npc_id, npc_data in sched_data.items():
        if npc_id.startswith("_"):
            continue
        if not isinstance(npc_data, dict):
            continue
        # Default schedule
        default = npc_data.get("default", {})
        default_rows.append({
            "npc_id": npc_id,
            "role_note": npc_data.get("_role", ""),
            "location": default.get("location", ""),
            "activity": default.get("activity", ""),
            "public": "true" if default.get("public") else "",
        })
        # Conditional overrides
        for co in npc_data.get("conditional_overrides", []):
            sched = co.get("schedule", {})
            override_rows.append({
                "npc_id": npc_id,
                "if_flag": co.get("if_flag", ""),
                "location": sched.get("location", ""),
                "activity": sched.get("activity", ""),
                "public": "true" if sched.get("public") else "",
            })

    default_headers = ["npc_id", "role_note", "location", "activity", "public"]
    default_data = [[r.get(h, "") for h in default_headers] for r in default_rows]
    write_csv(CASE_DIR / "schedule_defaults.csv", default_headers, default_data)

    override_headers = ["npc_id", "if_flag", "location", "activity", "public"]
    override_data = [[r.get(h, "") for h in override_headers] for r in override_rows]
    write_csv(CASE_DIR / "schedule_conditional_overrides.csv", override_headers, override_data)


def extract_npc_states(states_data):
    """Extract npc_states_base into CSV."""
    if not states_data:
        return
    initial_rows = []
    transition_rows = []
    for npc_id, npc_data in states_data.items():
        if npc_id.startswith("_"):
            continue
        if not isinstance(npc_data, dict):
            continue
        # Initial states
        initial = npc_data.get("initial", {})
        for stat, value in initial.items():
            initial_rows.append({
                "npc_id": npc_id,
                "stat": stat,
                "value": value,
            })
        # Transitions
        for trans in npc_data.get("transitions", []):
            transition_rows.append({
                "npc_id": npc_id,
                "event": trans.get("on", ""),
                "delta": json.dumps(trans.get("delta", {}), ensure_ascii=False),
                "writer_note": trans.get("_comment", ""),
            })

    initial_headers = ["npc_id", "stat", "value"]
    initial_data = [[r.get(h, "") for h in initial_headers] for r in initial_rows]
    write_csv(CASE_DIR / "npc_state_initial.csv", initial_headers, initial_data)

    transition_headers = ["npc_id", "event", "delta", "writer_note"]
    transition_data = [[r.get(h, "") for h in transition_headers] for r in transition_rows]
    write_csv(CASE_DIR / "npc_state_transitions.csv", transition_headers, transition_data)


def extract_progression(prog_data):
    """Extract progression_base into CSV."""
    if not prog_data:
        return
    # Phases
    phase_rows = []
    for order, phase in enumerate(prog_data.get("phases", [])):
        phase_rows.append({
            "phase_id": phase.get("id", ""),
            "title": phase.get("title", ""),
            "description": phase.get("description", ""),
            "hint": phase.get("hint", ""),
            "locations": ",".join(phase.get("locations", [])),
            "unlock_condition": json.dumps(phase.get("unlock_condition", ""), ensure_ascii=False) if phase.get("unlock_condition") else "",
            "writer_note": phase.get("_comment", ""),
        })
    phase_headers = ["phase_id", "title", "description", "hint", "locations", "unlock_condition", "writer_note"]
    phase_data = [[r.get(h, "") for h in phase_headers] for r in phase_rows]
    write_csv(CASE_DIR / "progression_phases.csv", phase_headers, phase_data)

    # Unlocks
    unlock_rows = []
    for unlock_type in ["panel_unlock", "search_point_unlock", "npc_unlock", "confrontation_unlock"]:
        entries = prog_data.get(unlock_type, {})
        if not isinstance(entries, dict):
            continue
        for target_id, entry in entries.items():
            if not isinstance(entry, dict):
                continue
            unlock_rows.append({
                "unlock_type": unlock_type,
                "target_id": target_id,
                "condition": json.dumps(entry.get("condition", {}), ensure_ascii=False),
                "locked_hint": entry.get("locked_hint", ""),
                "writer_note": entry.get("_comment", ""),
            })
    unlock_headers = ["unlock_type", "target_id", "condition", "locked_hint", "writer_note"]
    unlock_data = [[r.get(h, "") for h in unlock_headers] for r in unlock_rows]
    write_csv(CASE_DIR / "progression_unlocks.csv", unlock_headers, unlock_data)

    # Phase notifications
    notif_rows = []
    for phase_id, notif in prog_data.get("phase_notifications", {}).items():
        notif_rows.append({
            "phase_id": phase_id,
            "speaker": notif.get("speaker", ""),
            "text": notif.get("text", ""),
        })
    notif_headers = ["phase_id", "speaker", "text"]
    notif_data = [[r.get(h, "") for h in notif_headers] for r in notif_rows]
    write_csv(CASE_DIR / "phase_notifications.csv", notif_headers, notif_data)


# ─── MAIN ────────────────────────────────────────────────────────────────────

def main():
    print("=== prologue_ferry 文字提取 ===")
    print(f"读取: {JSON_DOCS}")
    docs = read_json_docs()
    print(f"找到文档: {list(docs.keys())}")

    # 1. Prologue
    print("\n--- 序章对话 (prologue) ---")
    extract_prologue(docs.get("prologue", {}))

    # 2. Confrontation system
    print("\n--- 对峙系统 (case_base + confrontation_final) ---")
    conf_out = {
        "confrontations": [],
        "confrontation_lines": [],
        "testimony_sets": [],
        "testimony_lines": [],
        "testimony_statements": [],
        "testimony_press_lines": [],
        "testimony_break_lines": [],
        "testimony_wrong_reactions": [],
    }
    case_base = docs.get("case_base", {})
    if "confrontation" in case_base:
        extract_confrontation(case_base["confrontation"], "confrontation", conf_out)
    if "confrontation_final" in case_base:
        extract_confrontation(case_base["confrontation_final"], "confrontation_final", conf_out)
    write_confrontation_csvs(conf_out)

    # Also extract case_base metadata (suspects, motives, methods, endings)
    print("\n--- 案件元数据 ---")
    meta_rows = []
    for key in ["culprit", "motive", "method", "min_evidence_required"]:
        if key in case_base:
            meta_rows.append({"key": key, "value": json.dumps(case_base[key], ensure_ascii=False) if not isinstance(case_base[key], (str, int, float)) else str(case_base[key])})
    for key in ["key_evidence", "suspects", "motives", "methods", "endings"]:
        if key in case_base:
            meta_rows.append({"key": key, "value": json.dumps(case_base[key], ensure_ascii=False)})
    meta_headers = ["key", "value"]
    meta_data = [[r.get(h, "") for h in meta_headers] for r in meta_rows]
    write_csv(CASE_DIR / "case_meta.csv", meta_headers, meta_data)

    # 3. Day events
    print("\n--- 日程事件 (day_events_base) ---")
    extract_day_events(docs.get("day_events_base", {}))

    # 4. Companion
    print("\n--- 伙伴系统 (companion_discussions + companion_banter) ---")
    extract_companion_discussions(docs.get("companion_discussions", {}))
    extract_companion_banter(docs.get("companion_banter", {}))

    # 5. Epilogue meta
    print("\n--- 尾声 (epilogue_meta) ---")
    extract_epilogue_meta(docs.get("epilogue_meta", {}))

    # 6. Schedules / NPC states / Progression
    print("\n--- 日程 (schedules_base) ---")
    extract_schedules(docs.get("schedules_base", {}))
    print("\n--- NPC状态 (npc_states_base) ---")
    extract_npc_states(docs.get("npc_states_base", {}))
    print("\n--- 进度系统 (progression_base) ---")
    extract_progression(docs.get("progression_base", {}))

    # Now create stripped json_docs.csv with only non-extracted data
    print("\n--- 更新 json_docs.csv ---")
    remaining_docs = {}
    # Keep docs that are NOT extracted to CSV
    keep_keys = ["manifest", "key_info", "bgm_config", "companion_config", "culprit_actions_base", "dialogues_base"]
    for key in keep_keys:
        if key in docs:
            remaining_docs[key] = docs[key]
    
    # For case_base, keep only non-confrontation parts
    stripped_case = {}
    for k, v in case_base.items():
        if k not in ["confrontation", "confrontation_final", "culprit", "motive", "method", 
                      "key_evidence", "min_evidence_required", "suspects", "motives", "methods", "endings"]:
            stripped_case[k] = v
    if stripped_case:
        remaining_docs["case_base"] = stripped_case

    # Write updated json_docs.csv
    with open(JSON_DOCS, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["doc_id", "json"])
        for doc_id, data in remaining_docs.items():
            writer.writerow([doc_id, json.dumps(data, ensure_ascii=False)])
    
    print(f"\n=== 完成！已从 json_docs.csv 移除 {len(docs) - len(remaining_docs)} 个文档 ===")
    print(f"保留的文档: {list(remaining_docs.keys())}")


if __name__ == "__main__":
    main()
