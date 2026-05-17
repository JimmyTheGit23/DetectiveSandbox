#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
模板可视化检查工具（template inspector）

把一份犯罪骨架模板渲染成人类可读的多视图报告，方便策划/审稿快速把握骨架结构。

视图：
    1) META 元信息：ID / 类型 / 难度 / logline / 标签
    2) ROLES 角色卡：每个角色的画像、功能、知识/谎言、信任、不在场证明
    3) TIMELINE 时间线：按 phase 排序，标注谁/在哪里/做什么/产出什么证据
    4) EVIDENCE 物证表：分 key/supporting/red_herring 三档列出，含发现路径
    5) CONTRADICTIONS 矛盾对：每个矛盾的反驳来源数量
    6) DEDUCTION 推理链：solution_skeleton.deduction_chain 的步进图
    7) HEALTH 自检：列出潜在结构问题（不读 schema，只跑常识规则）

用法：
    python tools/pcg/inspect_template.py tools/pcg/templates/tpl_001_old_grudge_poisoning.json
    python tools/pcg/inspect_template.py --all          # 渲染 templates/*.json 全部
    python tools/pcg/inspect_template.py --all --brief  # 仅打印每模板一行摘要

退出码：
    0 = 全部模板健康
    1 = 至少一个模板自检发现问题
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
TEMPLATES_DIR = REPO_ROOT / "tools" / "pcg" / "templates"


def _phase_sort_key(phase: str) -> tuple[int, int, str]:
    """把 phase 字符串排序成可比较的元组。"""
    order = {"pre_crime": 0, "crime_moment": 1, "post_crime": 2}
    if phase in order:
        return (order[phase], 0, phase)
    # D{n}.{period}
    if phase.startswith("D") and "." in phase:
        try:
            day = int(phase[1:].split(".")[0])
            period_map = {
                "morning": 0, "noon": 1, "afternoon": 2,
                "evening": 3, "night": 4,
            }
            period = phase.split(".", 1)[1]
            return (10 + day, period_map.get(period, 99), phase)
        except ValueError:
            return (99, 99, phase)
    return (99, 99, phase)


def render_meta(tpl: dict, lines: list[str]) -> None:
    lines.append("┌─ META ─" + "─" * 60)
    lines.append(f"│ id          : {tpl.get('id')}")
    lines.append(f"│ version     : {tpl.get('version')}")
    lines.append(f"│ crime_type  : {tpl.get('crime_type')}")
    diff = tpl.get("difficulty", {})
    star = "★" * int(diff.get("star", 0))
    lines.append(f"│ difficulty  : {star}  ({diff.get('star')}/5)")
    factors = diff.get("factors", {})
    if factors:
        for k, v in factors.items():
            lines.append(f"│   {k:<24}: {v}")
    summary = tpl.get("summary", {})
    if summary:
        lines.append(f"│ logline     : {summary.get('logline', '')}")
        if summary.get("tags"):
            lines.append(f"│ tags        : {', '.join(summary['tags'])}")
    lines.append("└" + "─" * 67)


def render_roles(tpl: dict, lines: list[str]) -> None:
    lines.append("┌─ ROLES ─" + "─" * 59)
    roles = tpl.get("roles", [])
    for r in roles:
        flag = " 🔪" if r.get("is_culprit") else ""
        func = r.get("function", "?")
        tags = ",".join(r.get("archetype_tags", []))
        lines.append(f"│ [{func:<10}] {r['slot_id']}{flag}")
        lines.append(f"│   tags     : {tags}")
        if r.get("knowledge_topics"):
            lines.append(f"│   knows    : {', '.join(r['knowledge_topics'])}")
        if r.get("lie_topics"):
            lines.append(f"│   lies on  : {', '.join(r['lie_topics'])}")
        if r.get("trust_pattern"):
            lines.append(f"│   trust    : {r['trust_pattern']}")
        if r.get("alibi"):
            a = r["alibi"]
            lines.append(
                f"│   alibi    : claims @ {a.get('claim_location')} "
                f"during {a.get('claim_time_window')}, weakness = {a.get('weakness_topic')}"
            )
        lines.append("│")
    lines.append("└" + "─" * 67)


def render_timeline(tpl: dict, lines: list[str]) -> None:
    lines.append("┌─ TIMELINE ─" + "─" * 56)
    slots = sorted(tpl.get("timeline_slots", []), key=lambda s: _phase_sort_key(s.get("phase", "")))
    for s in slots:
        visible = "👁 " if s.get("visible_to_player") else "   "
        produces = ""
        if s.get("produces_evidence"):
            produces = " → produces: " + ", ".join(s["produces_evidence"])
        loc = f" @ {s.get('location')}" if s.get("location") else ""
        lines.append(
            f"│ {visible}{s.get('phase'):<14} | {s.get('actor'):<22} | "
            f"{s.get('action_type'):<20}{loc}"
        )
        if produces:
            lines.append(f"│              {produces}")
    lines.append("└" + "─" * 67)


def render_evidence(tpl: dict, lines: list[str]) -> None:
    lines.append("┌─ EVIDENCE ─" + "─" * 56)
    by_kind: dict[str, list[dict]] = defaultdict(list)
    for e in tpl.get("evidence_slots", []):
        by_kind[e.get("kind", "?")].append(e)
    for kind in ("key", "supporting", "red_herring"):
        if not by_kind.get(kind):
            continue
        lines.append(f"│ ── {kind.upper()} ({len(by_kind[kind])}) ──")
        for e in by_kind[kind]:
            dp = e.get("discovery_path", {})
            t = dp.get("type", "?")
            if t == "search":
                where = f"search@{dp.get('hint_location')}"
            elif t == "dialogue":
                where = f"dialogue<-{dp.get('from_actor')}"
            elif t == "derived":
                where = "derived"
            else:
                where = t
            pre = dp.get("preconditions") or []
            pre_str = (" pre=" + ",".join(pre)) if pre else ""
            ptr = e.get("points_to", "")
            ptr_str = f" → {ptr}" if ptr else ""
            blocks = e.get("blocks_red_herring") or []
            blocks_str = (" blocks=" + ",".join(blocks)) if blocks else ""
            lines.append(
                f"│   {e['id']:<32} [{e.get('category', '?'):<20}] "
                f"{where}{pre_str}{ptr_str}{blocks_str}"
            )
    lines.append("└" + "─" * 67)


def render_contradictions(tpl: dict, lines: list[str]) -> None:
    lines.append("┌─ CONTRADICTIONS ─" + "─" * 50)
    for c in tpl.get("contradictions", []):
        srcs = c.get("rebuttal_sources", [])
        warn = "" if len(srcs) >= 2 else "  ⚠ <2 sources!"
        lines.append(
            f"│ {c['id']}: actor={c.get('actor')} claim={c.get('claim')}{warn}"
        )
        lines.append(f"│   rebut by: {', '.join(srcs)}")
        lines.append(f"│   exposes : {c.get('exposes', '')}")
    lines.append("└" + "─" * 67)


def render_red_herrings(tpl: dict, lines: list[str]) -> None:
    rhs = tpl.get("red_herrings", [])
    if not rhs:
        return
    lines.append("┌─ RED HERRINGS ─" + "─" * 51)
    for rh in rhs:
        rebuttal = rh.get("rebuttal", [])
        warn = "" if rebuttal else "  ⚠ no rebuttal!"
        lines.append(
            f"│ {rh['id']}: false_target={rh.get('false_target')}, "
            f"motive={rh.get('false_motive')}{warn}"
        )
        if rebuttal:
            lines.append(f"│   rebut by: {', '.join(rebuttal)}")
    lines.append("└" + "─" * 67)


def render_deduction(tpl: dict, lines: list[str]) -> None:
    sol = tpl.get("solution_skeleton", {})
    lines.append("┌─ SOLUTION ─" + "─" * 56)
    lines.append(f"│ culprit_slot : {sol.get('culprit_slot')}")
    lines.append(f"│ motive_id    : {sol.get('motive_id')}")
    lines.append(f"│ method_id    : {sol.get('method_id')}")
    lines.append(
        f"│ key_evidence : ({sol.get('min_evidence_required', '?')} "
        f"of {len(sol.get('key_evidence_slots', []))}) "
        f"{', '.join(sol.get('key_evidence_slots', []))}"
    )
    chain = sol.get("deduction_chain", [])
    if chain:
        lines.append("│ ── deduction chain ──")
        for step in chain:
            uses = ", ".join(step.get("uses", []))
            lines.append(
                f"│   step {step.get('step')}: [{uses}]  ⇒  {step.get('concludes')}"
            )
    lines.append("└" + "─" * 67)


def health_check(tpl: dict) -> list[str]:
    """非 schema 层的常识健康检查。返回问题字符串列表（空=健康）。"""
    issues: list[str] = []
    role_ids = {r["slot_id"] for r in tpl.get("roles", [])}
    evidence_ids = {e["id"] for e in tpl.get("evidence_slots", [])}
    timeline_ids = {t["id"] for t in tpl.get("timeline_slots", [])}
    contradiction_ids = {c["id"] for c in tpl.get("contradictions", [])}

    # 1. solution.culprit_slot 必须指向一个 is_culprit=true 的角色
    sol = tpl.get("solution_skeleton", {})
    cs = sol.get("culprit_slot")
    if cs not in role_ids:
        issues.append(f"solution.culprit_slot '{cs}' 不在 roles 中")
    else:
        culprit = next(r for r in tpl["roles"] if r["slot_id"] == cs)
        if not culprit.get("is_culprit"):
            issues.append(f"solution.culprit_slot '{cs}' 未标记 is_culprit=true")

    # 2. 必须只有一个 is_culprit=true
    culprits = [r for r in tpl.get("roles", []) if r.get("is_culprit")]
    if len(culprits) != 1:
        issues.append(f"is_culprit=true 的角色数 = {len(culprits)}（应为 1）")

    # 3. key_evidence_slots 全部存在
    for k in sol.get("key_evidence_slots", []):
        if k not in evidence_ids:
            issues.append(f"solution.key_evidence_slots 含未定义 evidence: {k}")

    # 4. discovery_path 内的引用合法
    for e in tpl.get("evidence_slots", []):
        dp = e.get("discovery_path", {})
        if dp.get("type") == "search":
            loc = dp.get("hint_location", "")
            loc_ids = {l["slot_id"] for l in tpl.get("location_slots", [])}
            if loc and loc not in loc_ids:
                issues.append(f"evidence '{e['id']}' search@{loc}: 地点未定义")
        elif dp.get("type") == "dialogue":
            actor = dp.get("from_actor", "")
            if actor and actor not in role_ids:
                issues.append(f"evidence '{e['id']}' dialogue<-{actor}: 角色未定义")
        for pre in dp.get("preconditions", []) or []:
            # 前置条件可以是 evidence 或 lie_exposed:slot.topic 等
            if pre.startswith("lie_exposed:"):
                continue
            if pre not in evidence_ids and pre not in contradiction_ids:
                issues.append(
                    f"evidence '{e['id']}' precondition '{pre}' 既不是 evidence 也不是 contradiction"
                )

    # 5. contradictions 的 rebuttal_sources 至少 2 条且全部存在
    for c in tpl.get("contradictions", []):
        srcs = c.get("rebuttal_sources", [])
        if len(srcs) < 2:
            issues.append(f"contradiction '{c['id']}' rebuttal_sources < 2")
        for s in srcs:
            if s not in evidence_ids and s not in timeline_ids:
                issues.append(f"contradiction '{c['id']}' rebuttal '{s}' 未定义")

    # 6. red_herring 必须有 rebuttal
    for rh in tpl.get("red_herrings", []) or []:
        if not rh.get("rebuttal"):
            issues.append(f"red_herring '{rh['id']}' 没有 rebuttal 路径")
        else:
            for r in rh["rebuttal"]:
                if r not in evidence_ids and r not in contradiction_ids:
                    issues.append(f"red_herring '{rh['id']}' rebuttal '{r}' 未定义")

    # 7. timeline_slots 中的 actor 全在 roles 内（unknown 例外）
    for t in tpl.get("timeline_slots", []):
        a = t.get("actor", "")
        if a and a != "unknown" and a not in role_ids:
            issues.append(f"timeline '{t['id']}' actor '{a}' 未在 roles 中")

    # 8. 真凶必须至少有一条对话路径会暴露身份
    if cs in role_ids:
        culprit = next(r for r in tpl["roles"] if r["slot_id"] == cs)
        if not culprit.get("lie_topics"):
            issues.append(f"culprit '{cs}' 未配置 lie_topics（无谎言可识破）")

    # 9. 推理链最后一步应直接 concludes 真凶
    chain = sol.get("deduction_chain", [])
    if chain:
        last = chain[-1]
        concl = last.get("concludes", "").lower()
        if cs and cs.lower() not in concl and "killer" not in concl and "culprit" not in concl:
            issues.append(
                f"deduction_chain 最后一步 concludes='{last.get('concludes')}' "
                f"未直接指向真凶 '{cs}'（建议结论中提及）"
            )

    return issues


def inspect_one(path: Path, brief: bool = False) -> bool:
    tpl = json.loads(path.read_text(encoding="utf-8"))
    issues = health_check(tpl)

    if brief:
        flag = "OK " if not issues else f"[!{len(issues)}]"
        diff = tpl.get("difficulty", {}).get("star", 0)
        print(
            f"{flag} {tpl.get('id'):<40} | {tpl.get('crime_type'):<18} | "
            f"★{diff} | {len(tpl.get('roles', []))} roles | "
            f"{len(tpl.get('evidence_slots', []))} evidence"
        )
        return not issues

    lines: list[str] = []
    lines.append("=" * 75)
    try:
        rel = path.resolve().relative_to(REPO_ROOT)
    except ValueError:
        rel = path
    lines.append(f"FILE: {rel}")
    lines.append("=" * 75)
    render_meta(tpl, lines)
    render_roles(tpl, lines)
    render_timeline(tpl, lines)
    render_evidence(tpl, lines)
    render_contradictions(tpl, lines)
    render_red_herrings(tpl, lines)
    render_deduction(tpl, lines)

    lines.append("┌─ HEALTH CHECK ─" + "─" * 51)
    if not issues:
        lines.append("│ ✓ ALL GREEN")
    else:
        for i in issues:
            lines.append(f"│ ⚠ {i}")
    lines.append("└" + "─" * 67)
    print("\n".join(lines))
    return not issues


def main() -> int:
    ap = argparse.ArgumentParser(description="渲染犯罪骨架模板的可视化检查报告")
    ap.add_argument("path", nargs="?", help="单个模板 JSON 路径")
    ap.add_argument("--all", action="store_true", help="渲染 templates/*.json 全部")
    ap.add_argument("--brief", action="store_true", help="仅每模板一行摘要")
    args = ap.parse_args()

    paths: list[Path] = []
    if args.all:
        paths = sorted(TEMPLATES_DIR.glob("*.json"))
    elif args.path:
        paths = [Path(args.path)]
    else:
        ap.print_help()
        return 0

    all_ok = True
    for i, p in enumerate(paths):
        if not p.exists():
            print(f"[ERROR] not found: {p}", file=sys.stderr)
            all_ok = False
            continue
        ok = inspect_one(p, brief=args.brief)
        all_ok = all_ok and ok
        if not args.brief and i + 1 < len(paths):
            print()
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
