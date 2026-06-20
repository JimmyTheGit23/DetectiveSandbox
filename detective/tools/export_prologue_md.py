#!/usr/bin/env python3
"""
Export all prologue dialogue/text into a single, editable MD.
Format: human-readable, with stable IDs for re-import.
Other authors can edit the MD, then run tools/import_prologue_md.py to
write changes back to the source CSV/JSON files.

Usage: python3 tools/export_prologue_md.py > docs/prologue_full_script.md
"""

import csv
import json
import os
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TABLES = os.path.join(BASE, 'data', 'case_tables', 'prologue_ferry')
CASES = os.path.join(BASE, 'data', 'cases', 'prologue_ferry')

def read_csv(filename):
    path = os.path.join(TABLES, filename)
    if not os.path.exists(path):
        return []
    with open(path, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            first_val = list(row.values())[0] if row else ''
            if first_val and str(first_val).strip().startswith('#'):
                continue
            rows.append(row)
        return rows

def safe(row, field, default=''):
    val = row.get(field, None)
    if val is None:
        return default
    return str(val).strip()

def ensure_dir(p):
    os.makedirs(os.path.dirname(p), exist_ok=True)

# ── output helpers ──────────────────────────────────────────
out_lines = []

def h1(text):
    out_lines.append(f"\n# {text}\n")

def h2(text):
    out_lines.append(f"\n## {text}\n")

def h3(text):
    out_lines.append(f"\n### {text}\n")

def line(id_tag, speaker, text, emotion='', note=''):
    """Write one dialogue line with a stable ID for re-import tracking."""
    em = f" `[{emotion}]`" if emotion else ''
    nt = f" *({note})*" if note else ''
    out_lines.append(f"`[{id_tag}]` **{speaker}**{em}: {text}{nt}")

def br():
    out_lines.append('')

def section(name):
    out_lines.append(f"\n---\n## {name}\n")

def meta(k, v):
    out_lines.append(f"- **{k}**: {v}")
# ────────────────────────────────────────────────────────────

# ── HEADER ──────────────────────────────────────────────────
out_lines.append("# 序章·渡口沉舟 — 全剧本")
out_lines.append("")
out_lines.append("> **说明**：")
out_lines.append("> - 每行格式: `[ID] 角色 [情绪]: 台词`")
out_lines.append("> - ID 格式: `文件名:行号`，用于重新导入时定位")
out_lines.append("> - 修改台词后，运行 `python3 tools/import_prologue_md.py` 写回源文件")
out_lines.append("> - 请勿改动 ID 或行首的 `[` `]` 标记")
out_lines.append("")

# ── CASE INFO ───────────────────────────────────────────────
h1("案件信息")
for row in read_csv('case_info.csv'):
    for k, v in row.items():
        if k.strip() and v.strip():
            meta(k.strip(), v.strip())

# ── CAST ────────────────────────────────────────────────────
h1("角色表")
for row in read_csv('characters.csv'):
    name = safe(row, 'name', safe(row, 'actor_id', '?'))
    title = safe(row, 'title') or safe(row, 'role', '')
    intro = safe(row, 'intro')
    out_lines.append(f"- **{name}**{f' ({title})' if title else ''}: {intro}")

# ── PROLOGUE: 船舱 ─────────────────────────────────────────
h1("第一幕 · 船舱")
h2("开场独白")
line_no = 0
for row in read_csv('prologue_lines.csv'):
    line_no += 1
    spk = safe(row, 'speaker')
    txt = safe(row, 'text')
    emo = safe(row, 'emotion')
    typ = safe(row, 'type')
    if typ == 'time_card':
        out_lines.append(f"\n> ⏱ {txt}\n")
    else:
        tag = f"prologue_l:{line_no}"
        tp = '内心' if typ == 'inner_thought' else ''
        line(tag, spk or '叙述', txt, emo, tp)

# ── NPC DIALOGUES (JSON) ────────────────────────────────────
h2("NPC对话 (JSON)")
for fname in sorted(os.listdir(CASES + '/dialogues')):
    if not fname.endswith('.json'):
        continue
    with open(CASES + '/dialogues/' + fname, 'r', encoding='utf-8') as f:
        data = json.load(f)
    npc = fname.replace('.json', '')
    h3(f"NPC: {npc}")

    # Try common JSON structures: nodes dict, or list
    nodes = data.get('nodes', data if isinstance(data, list) else {})
    if isinstance(nodes, dict):
        for nid, nval in nodes.items():
            if isinstance(nval, dict):
                for msg in nval.get('messages', nval.get('lines', [])):
                    if isinstance(msg, dict):
                        spk = msg.get('speaker', msg.get('character', ''))
                        txt = msg.get('text', msg.get('content', ''))
                        emo = msg.get('emotion', '')
                        if txt:
                            tag = f"dialogue:{fname}:{nid}"
                            line(tag, spk, txt, emo)

# ── DIALOGUE LINES (CSV format) ─────────────────────────────
h2("调查对话 (CSV)")
for row in read_csv('dialogue_lines.csv'):
    spk = safe(row, 'speaker') or safe(row, 'speaker_id', '?')
    txt = safe(row, 'text')
    if not txt:
        continue
    emo = safe(row, 'emotion')
    nid = safe(row, 'node_id')
    oid = safe(row, 'order')
    tag = f"dl:{nid}:{oid}"
    line(tag, spk, txt, emo)

# ── DAY EVENTS ──────────────────────────────────────────────
h1("第三幕 · 日程事件")

# day_events.json
with open(CASES + '/day_events.json', 'r') as f:
    day_events_raw = json.load(f)

day_events = day_events_raw.get('events', day_events_raw) if isinstance(day_events_raw, dict) else day_events_raw

for event in day_events:
    if not isinstance(event, dict):
        continue
    title = event.get('title', '')
    h2(f"事件: {title}")
    meta('触发', event.get('trigger', ''))
    meta('提示', event.get('hint', ''))

for row in read_csv('day_event_lines.csv'):
    spk = safe(row, 'speaker')
    txt = safe(row, 'text')
    emo = safe(row, 'emotion')
    bg = safe(row, 'background')
    if not txt:
        continue
    oid = safe(row, 'order')
    tag = f"del:{oid}"
    if bg:
        out_lines.append(f"  *背景: {bg}*")
    line(tag, spk or '叙述', txt, emo)

# ── TESTIMONY ───────────────────────────────────────────────
h1("第四幕 · 证词对峙")

# testimony_statements first
h2("证人陈述")
for row in read_csv('testimony_statements.csv'):
    tid = safe(row, 'testimony_id')
    if not tid or tid.startswith('#'):  # skip comment rows
        continue
    sid = safe(row, 'statement_id')
    spk = safe(row, 'speaker')
    txt = safe(row, 'text')
    emo = safe(row, 'emotion')
    if not txt:
        continue
    tag = f"ts:{tid}:{sid}"
    line(tag, spk, txt, emo)

h2("证词流程台词")
for row in read_csv('testimony_lines.csv'):
    tid = safe(row, 'testimony_id')
    sec = safe(row, 'section')
    oid = safe(row, 'order')
    spk = safe(row, 'speaker')
    txt = safe(row, 'text')
    emo = safe(row, 'emotion')
    if not txt:
        continue
    tag = f"tl:{tid}:{sec}:{oid}"
    note = sec if sec not in ('preamble', 'transition_dialogue') else ''
    line(tag, spk or '叙述', txt, emo, note)

# ── CONFRONTATION ───────────────────────────────────────────
h1("第五幕 · 最终对峙")
for row in read_csv('confrontation_lines.csv'):
    cid = safe(row, 'confrontation_id', safe(row, 'id', ''))
    sec = safe(row, 'section')
    oid = safe(row, 'order')
    spk = safe(row, 'speaker')
    txt = safe(row, 'text')
    emo = safe(row, 'emotion')
    if not txt:
        continue
    tag = f"cl:{cid}:{sec}:{oid}"
    line(tag, spk or '叙述', txt, emo)

# ── EPILOGUE ────────────────────────────────────────────────
h1("第六幕 · 尾声")
for row in read_csv('epilogue_lines.csv'):
    oid = safe(row, 'order')
    spk = safe(row, 'speaker')
    txt = safe(row, 'text')
    emo = safe(row, 'emotion')
    tag = f"ep:{oid}"
    line(tag, spk or '叙述', txt, emo)

# ── COMPANION ───────────────────────────────────────────────
h1("附录 · 搭档互动")
h2("闲聊")
for row in read_csv('companion_banter.csv'):
    spk = safe(row, 'speaker', safe(row, 'character', ''))
    txt = safe(row, 'text', safe(row, 'lines', ''))
    if not txt:
        continue
    tag = f"cb:{safe(row, 'id', '?')}"
    line(tag, spk or '?', txt)

h2("讨论")
for row in read_csv('companion_discussions.csv'):
    spk = safe(row, 'speaker', safe(row, 'character', ''))
    txt = safe(row, 'text', safe(row, 'lines', ''))
    if not txt:
        continue
    tag = f"cd:{safe(row, 'id', '?')}"
    line(tag, spk or '?', txt)


# ── FOOTER ──────────────────────────────────────────────────
out_lines.append("\n---\n")
out_lines.append("*本文档由 tools/export_prologue_md.py 自动生成。*")
out_lines.append("*修改后运行 tools/import_prologue_md.py 写回源文件。*")

print('\n'.join(out_lines))
