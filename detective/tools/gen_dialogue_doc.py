#!/usr/bin/env python3
"""Generate PROLOGUE_DIALOGUE_COMPLETE.md from CSV data."""
import csv, os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(BASE, "data", "case_tables", "prologue_ferry")
OUT = os.path.join(BASE, "docs", "PROLOGUE_DIALOGUE_COMPLETE.md")

def read_csv(name):
    path = os.path.join(DATA, name)
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8-sig") as f:
        all_lines = f.readlines()
    # Filter comment lines
    filtered = [l for l in all_lines if not l.strip().startswith("#")]
    reader = csv.DictReader(filtered)
    return list(reader)

def main():
    dl = read_csv("dialogue_lines.csv")
    tl = read_csv("testimony_lines.csv")
    cl = read_csv("confrontation_lines.csv")
    banter = read_csv("companion_banter.csv")
    events = read_csv("day_event_lines.csv")
    sr = read_csv("search_results.csv")
    chars = read_csv("characters.csv")
    
    # Build character name map
    char_map = {}
    for c in chars:
        char_map[c.get("npc_id","")] = c.get("name","")
    
    lines = []
    def w(s=""): lines.append(s)
    def h1(s): w(f"# {s}\n")
    def h2(s): w(f"## {s}\n")
    def h3(s): w(f"### {s}\n")
    def h4(s): w(f"#### {s}\n")
    def quote(s): w(f"> {s}\n")
    def p(s): w(f"{s}\n")
    def table_row(cols): w("| " + " | ".join(cols) + " |")
    def table_sep(n): w("|" + "|".join(["---"]*n) + "|")
    
    w("# 序章「渡口沉舟」完整对话文档\n")
    w("> 版本：2026-06-02 | 数据来源：prologue_ferry/*.csv 全量整合")
    w("> 用途：游戏对话系统接入参考")
    w("> 格式：speaker {emotion} → 台词")
    w("> 标记：[narration] 旁白 | [inner_thought] 内心独白\n")
    w("---\n")
    
    # ===== Phase 0: Cabin =====
    h1("Phase 0 · 船舱夜话")
    
    cabin_npcs = {
        "agui_cabin": "阿贵船舱",
        "lao_fan_cabin": "老范船舱",
        "zhou_de_gui_cabin": "周德贵船舱"
    }
    
    # Search results for cabin
    h2("陆昭船舱（搜索）")
    table_row(["搜索点", "描述", "获得"])
    table_sep(3)
    for r in sr:
        if r["location_id"] == "cabin_lu_room":
            table_row([
                r["point_id"],
                (r.get("narration","") or r.get("intro_text",""))[:60] + "…",
                r.get("gain_evidence","") or r.get("gain_clue","") or "—"
            ])
    w()
    
    for npc_id, title in cabin_npcs.items():
        h2(title)
        npc_lines = [l for l in dl if l.get("npc_id","") == npc_id]
        nodes = {}
        for l in npc_lines:
            nid = l.get("node_id","")
            if nid not in nodes:
                nodes[nid] = []
            nodes[nid].append(l)
        for nid, nlines in nodes.items():
            h3(f"对话：{nid}")
            table_row(["#", "speaker", "text", "emotion"])
            table_sep(4)
            for l in sorted(nlines, key=lambda x: int(x.get("order",0))):
                table_row([
                    l.get("order",""),
                    l.get("speaker_id","") or l.get("speaker",""),
                    l.get("text",""),
                    l.get("emotion","") or "—"
                ])
            w()
    
    # ===== 沉船事件 =====
    h1("沉船事件（Phase 0→1）")
    evt_lines = [e for e in events if e["event_id"] == "evt_cabin_sleep"]
    for e in sorted(evt_lines, key=lambda x: int(x.get("order",0))):
        spk = e.get("speaker","")
        txt = e.get("text","")
        emo = e.get("emotion","")
        kind = e.get("line_kind","")
        if kind == "text":
            p(f"[narration] {txt}")
        elif kind == "dialogue":
            emo_str = f" {{{emo}}}" if emo else ""
            p(f"{spk}{emo_str} → {txt}")
    w()
    
    # ===== 王大爷对峙 =====
    h1("王大爷对峙 (confrontation_wang)")
    for section in ["intro_dialogue", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
        sec_lines = [l for l in cl if l.get("confrontation_id","") == "confrontation_wang" and l.get("section","") == section]
        if not sec_lines:
            continue
        h3(section)
        table_row(["#", "speaker", "text", "emotion"])
        table_sep(4)
        for l in sorted(sec_lines, key=lambda x: int(x.get("order",0))):
            table_row([
                l.get("order",""),
                l.get("speaker",""),
                l.get("text",""),
                l.get("emotion","") or "—"
            ])
        w()
    
    # ===== Phase 2 探索对话 =====
    h1("Phase 2 · 深入追查探索对话")
    phase2_npcs = ["li_zheng", "zhou_wife", "agui", "lao_fan", "fisherman_wang", "shen_qingyue"]
    for npc_id in phase2_npcs:
        npc_lines = [l for l in dl if l.get("npc_id","") == npc_id]
        if not npc_lines:
            continue
        name = char_map.get(npc_id, npc_id)
        h2(f"NPC: {name} ({npc_id})")
        nodes = {}
        for l in npc_lines:
            nid = l.get("node_id","")
            if nid not in nodes:
                nodes[nid] = []
            nodes[nid].append(l)
        for nid, nlines in nodes.items():
            h3(f"对话：{nid}")
            table_row(["#", "speaker", "text", "emotion"])
            table_sep(4)
            for l in sorted(nlines, key=lambda x: int(x.get("order",0))):
                table_row([
                    l.get("order",""),
                    l.get("speaker_id","") or l.get("speaker",""),
                    l.get("text",""),
                    l.get("emotion","") or "—"
                ])
            w()
    
    # ===== 阿贵对峙 =====
    h1("阿贵对峙 (confrontation)")
    for section in ["intro_dialogue", "victory_dialogue", "defeat_dialogue"]:
        sec_lines = [l for l in cl if l.get("confrontation_id","") == "confrontation" and l.get("section","") == section]
        if not sec_lines:
            continue
        h3(section)
        table_row(["#", "speaker", "text", "emotion"])
        table_sep(4)
        for l in sorted(sec_lines, key=lambda x: (x.get("order",""), x.get("order",""))):
            table_row([
                l.get("order",""),
                l.get("speaker",""),
                (l.get("text","") or "")[:80],
                l.get("emotion","") or "—"
            ])
        w()
    
    # ===== 证词（testimony_lines）=====
    h1("阿贵对峙 · 四轮证词 (testimony_lines)")
    testimony_ids = ["testimony_0", "testimony_1", "testimony_2", "testimony_3"]
    for tid in testimony_ids:
        t_lines = [l for l in tl if l.get("testimony_id","") == tid]
        if not t_lines:
            continue
        h2(tid)
        for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
            sec_lines = [l for l in t_lines if l.get("section","") == section]
            if not sec_lines:
                continue
            h3(section)
            table_row(["#", "speaker", "text", "emotion"])
            table_sep(4)
            for l in sorted(sec_lines, key=lambda x: int(x.get("order",0))):
                table_row([
                    l.get("order",""),
                    l.get("speaker",""),
                    l.get("text",""),
                    l.get("emotion","") or "—"
                ])
            w()
    
    # ===== 老范证词 =====
    h1("老范证词 (testimony_lao_fan_*)")
    fan_ids = ["testimony_lao_fan_route", "testimony_lao_fan_rescue", "testimony_lao_fan_motive"]
    for tid in fan_ids:
        t_lines = [l for l in tl if l.get("testimony_id","") == tid]
        if not t_lines:
            continue
        h2(tid)
        for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
            sec_lines = [l for l in t_lines if l.get("section","") == section]
            if not sec_lines:
                continue
            h3(section)
            table_row(["#", "speaker", "text", "emotion"])
            table_sep(4)
            for l in sorted(sec_lines, key=lambda x: int(x.get("order",0))):
                table_row([
                    l.get("order",""),
                    l.get("speaker",""),
                    l.get("text",""),
                    l.get("emotion","") or "—"
                ])
            w()
    
    # ===== 王大爷证词 =====
    h1("王大爷证词 (testimony_wang)")
    t_lines = [l for l in tl if l.get("testimony_id","") == "testimony_wang"]
    for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
        sec_lines = [l for l in t_lines if l.get("section","") == section]
        if not sec_lines:
            continue
        h3(section)
        table_row(["#", "speaker", "text", "emotion"])
        table_sep(4)
        for l in sorted(sec_lines, key=lambda x: int(x.get("order",0))):
            table_row([
                l.get("order",""),
                l.get("speaker",""),
                l.get("text",""),
                l.get("emotion","") or "—"
            ])
        w()
    
    # ===== 沈清月对峙 =====
    h1("沈清月终局对峙 (confrontation_final)")
    for section in ["intro_dialogue", "victory_dialogue", "defeat_dialogue"]:
        sec_lines = [l for l in cl if l.get("confrontation_id","") == "confrontation_final" and l.get("section","") == section]
        if not sec_lines:
            continue
        h3(section)
        table_row(["#", "speaker", "text", "emotion"])
        table_sep(4)
        for l in sorted(sec_lines, key=lambda x: int(x.get("order",0))):
            table_row([
                l.get("order",""),
                l.get("speaker",""),
                (l.get("text","") or "")[:100],
                l.get("emotion","") or "—"
            ])
        w()
    
    # ===== 沈清月证词 =====
    h1("沈清月对峙 · 三轮证词")
    shen_ids = ["shen_testimony_1", "shen_testimony_2", "shen_testimony_3"]
    for tid in shen_ids:
        t_lines = [l for l in tl if l.get("testimony_id","") == tid]
        if not t_lines:
            continue
        h2(tid)
        for section in ["preamble", "readthrough_end_hint", "transition_dialogue", "fail_dialogue"]:
            sec_lines = [l for l in t_lines if l.get("section","") == section]
            if not sec_lines:
                continue
            h3(section)
            table_row(["#", "speaker", "text", "emotion"])
            table_sep(4)
            for l in sorted(sec_lines, key=lambda x: int(x.get("order",0))):
                table_row([
                    l.get("order",""),
                    l.get("speaker",""),
                    l.get("text",""),
                    l.get("emotion","") or "—"
                ])
            w()
    
    # ===== 搭档互动 =====
    h1("搭档互动 (companion_banter)")
    for b in banter:
        bid = b.get("banter_id","")
        h3(bid)
        lines_text = b.get("lines","")
        # Parse the JSON-like lines
        p(f"**触发条件**: `{b.get('when','')}`")
        if b.get("requires"):
            p(f"**前置条件**: `{b.get('requires','')}`")
        p(f"**对话内容**:")
        # Simple display
        p(f"```")
        p(lines_text[:500] if lines_text else "(空)")
        p(f"```")
        w()
    
    # ===== 搜索发现 =====
    h1("搜索发现对话 (search_results)")
    table_row(["场景", "搜索点", "描述", "获得证据/线索"])
    table_sep(4)
    for r in sr:
        if r["location_id"].startswith("cabin_"):
            continue
        desc = r.get("narration","") or r.get("intro_text","")
        gain = r.get("gain_evidence","") or r.get("gain_clue","") or "—"
        table_row([
            r["location_id"],
            r["point_id"],
            desc[:50] + ("…" if len(desc)>50 else ""),
            gain
        ])
    w()
    
    # Write
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Written {len(lines)} lines to {OUT}")

if __name__ == "__main__":
    main()
