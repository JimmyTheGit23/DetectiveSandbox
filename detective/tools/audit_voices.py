#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
案件语音清单提取工具

扫描 data/cases/<case_id>/ 下所有对话节点和事件叙述，按"演员制"路径
（actor_id/case_id/{node_id}.wav 或 actor_id/{node_id}.wav 或 npc_id/{node_id}.wav）
检查每条语音是否已生成，未生成的写入 docs/MISSING_VOICES.md，便于后续批量 TTS。

输出 Markdown 表格，每条含：
    - case_id / npc_id / actor_id（若有 casting）
    - node_id
    - 期望的 wav 路径（按新规范优先）
    - 文本预览
    - 已存在的回退路径（若有）

用法：
    python tools/audit_voices.py                       # 扫所有案件，写 docs/MISSING_VOICES.md
    python tools/audit_voices.py --case xunyang_pavilion  # 只扫某案
    python tools/audit_voices.py --print               # 不写文件，仅 stdout
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA = REPO_ROOT / "data"
ASSETS_VOICE_ROOT = REPO_ROOT / "assets" / "cn" / "voices"
DOCS_DIR = REPO_ROOT / "docs"


def _load_json(p: Path) -> dict:
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def _truncate(text: str, n: int = 80) -> str:
    text = text.replace("\n", " ").strip()
    if len(text) <= n:
        return text
    return text[: n - 1] + "…"


def voice_paths_for(actor_id: str, case_id: str, npc_id: str, node_id: str, voice_status: str) -> list[Path]:
    """按 AssetResolver 的查找顺序枚举可能的 wav 路径。
    严格隔离：不再考虑 voices/{npc_id}/ 旧目录（防跨案件错乱）。
    voice_status="full"  → 案件专属 + 演员通用
    voice_status="partial"→ 仅案件专属
    voice_status="missing"→ 仅案件专属（即使没有也不回退）
    """
    out: list[Path] = []
    if actor_id and case_id:
        out.append(ASSETS_VOICE_ROOT / actor_id / case_id / f"{node_id}.wav")
    if actor_id and voice_status == "full":
        out.append(ASSETS_VOICE_ROOT / actor_id / f"{node_id}.wav")
    return out


def existing_voice(actor_id: str, case_id: str, npc_id: str, node_id: str, voice_status: str) -> Path | None:
    if voice_status == "missing":
        # missing 状态明确：完全静默，不命中即未生成（不区分回退）
        # 但仍然需要看案件专属是否存在（万一已经先生成了几条）
        if actor_id and case_id:
            p = ASSETS_VOICE_ROOT / actor_id / case_id / f"{node_id}.wav"
            if p.exists():
                return p
        return None
    for p in voice_paths_for(actor_id, case_id, npc_id, node_id, voice_status):
        if p.exists():
            return p
    return None


def expected_voice_path(actor_id: str, case_id: str, npc_id: str, node_id: str) -> Path:
    """新规范路径：actor_id/case_id/node_id.wav。无 actor_id 时退化为 npc_id/node_id（兼容字段）。"""
    if actor_id:
        return ASSETS_VOICE_ROOT / actor_id / case_id / f"{node_id}.wav"
    return ASSETS_VOICE_ROOT / npc_id / f"{node_id}.wav"


def collect_dialogue_nodes(case_id: str, npc_id: str, dialogue_path: Path) -> list[tuple[str, str]]:
    """返回 [(node_id, text)] 列表。"""
    raw = _load_json(dialogue_path)
    nodes = raw.get("nodes", {})
    result: list[tuple[str, str]] = []
    for node_id, n in nodes.items():
        if not isinstance(n, dict):
            continue
        text = n.get("text", "")
        # silent 节点跳过（如序章中的操作说明面板）
        if n.get("silent"):
            continue
        if text:
            result.append((node_id, text))
    return result


def audit_case(case_id: str) -> dict:
    case_dir = DATA / "cases" / case_id
    casting_root = _load_json(case_dir / "casting.json")
    casting = casting_root.get("casting", {})
    npc_to_actor = {nid: e.get("actor_id", "") for nid, e in casting.items() if isinstance(e, dict)}
    manifest = _load_json(case_dir / "manifest.json")
    voice_status: str = manifest.get("voice_status", "full")

    missing: list[dict] = []
    have: list[dict] = []

    # 1) 各 NPC 对话树
    dialogues_dir = case_dir / "dialogues"
    if dialogues_dir.exists():
        for dlg in sorted(dialogues_dir.glob("*.json")):
            npc_id = dlg.stem
            actor_id = npc_to_actor.get(npc_id, "")
            for node_id, text in collect_dialogue_nodes(case_id, npc_id, dlg):
                exist = existing_voice(actor_id, case_id, npc_id, node_id, voice_status)
                entry = {
                    "kind": "dialogue",
                    "case_id": case_id,
                    "npc_id": npc_id,
                    "actor_id": actor_id,
                    "node_id": node_id,
                    "expected": expected_voice_path(actor_id, case_id, npc_id, node_id).relative_to(REPO_ROOT).as_posix(),
                    "existing": exist.relative_to(REPO_ROOT).as_posix() if exist else "",
                    "text_preview": _truncate(text),
                }
                if exist:
                    have.append(entry)
                else:
                    missing.append(entry)

    # 2) 序章（按案件分槽：_prologue/{case_id}/{node_id}.wav）
    prologue = _load_json(case_dir / "prologue.json")
    for node_id, n in prologue.get("nodes", {}).items():
        if not isinstance(n, dict):
            continue
        if n.get("silent"):
            continue
        text = n.get("text", "")
        if not text:
            continue
        expected = ASSETS_VOICE_ROOT / "_prologue" / case_id / f"{node_id}.wav"
        # full 状态允许回退到 _prologue/{node_id}.wav 旧路径
        existing = None
        if expected.exists():
            existing = expected
        elif voice_status == "full":
            fallback = ASSETS_VOICE_ROOT / "_prologue" / f"{node_id}.wav"
            if fallback.exists():
                existing = fallback
        entry = {
            "kind": "prologue",
            "case_id": case_id,
            "npc_id": "_prologue",
            "actor_id": "",
            "node_id": node_id,
            "expected": expected.relative_to(REPO_ROOT).as_posix(),
            "existing": existing.relative_to(REPO_ROOT).as_posix() if existing else "",
            "text_preview": _truncate(text),
        }
        if existing:
            have.append(entry)
        else:
            missing.append(entry)

    # 3) 日程事件叙述（按案件分槽：_events/{case_id}/{evt_id}_{idx}.wav）
    day_events = _load_json(case_dir / "day_events.json")
    for evt in day_events.get("events", []):
        if not isinstance(evt, dict):
            continue
        evt_id = evt.get("id", "")
        for idx, line in enumerate(evt.get("narration", [])):
            text = line if isinstance(line, str) else (line.get("text", "") if isinstance(line, dict) else "")
            if not text:
                continue
            expected = ASSETS_VOICE_ROOT / "_events" / case_id / f"{evt_id}_{idx}.wav"
            existing = None
            if expected.exists():
                existing = expected
            elif voice_status == "full":
                fallback = ASSETS_VOICE_ROOT / "_events" / f"{evt_id}_{idx}.wav"
                if fallback.exists():
                    existing = fallback
            entry = {
                "kind": "event",
                "case_id": case_id,
                "npc_id": "_events",
                "actor_id": "",
                "node_id": f"{evt_id}_{idx}",
                "expected": expected.relative_to(REPO_ROOT).as_posix(),
                "existing": existing.relative_to(REPO_ROOT).as_posix() if existing else "",
                "text_preview": _truncate(text),
            }
            if existing:
                have.append(entry)
            else:
                missing.append(entry)

    return {
        "case_id": case_id,
        "title": manifest.get("title", case_id),
        "voice_status": voice_status,
        "missing": missing,
        "have": have,
    }


def discover_cases() -> list[str]:
    cases_dir = DATA / "cases"
    if not cases_dir.exists():
        return []
    out = []
    for p in sorted(cases_dir.iterdir()):
        if p.is_dir() and not p.name.startswith("_"):
            out.append(p.name)
    return out


def render_markdown(reports: list[dict]) -> str:
    lines: list[str] = []
    lines.append("# 未生成语音清单")
    lines.append("")
    lines.append(
        "> **自动生成**: `python tools/audit_voices.py`  "
        "**最后扫描**: 见 git blame  "
        "**用途**: 跟踪每个案件中尚未生成 TTS 的对话/序章/事件节点。新案件 PR 必跑此脚本。"
    )
    lines.append("")
    lines.append("## 总览")
    lines.append("")
    lines.append("| 案件 | 标题 | voice_status | 已有 | 缺失 | 状态 |")
    lines.append("|------|------|------|------|------|------|")
    for r in reports:
        if not r["missing"]:
            status = "✅ 全量"
        elif r["voice_status"] == "missing":
            status = f"⚠ 全部待生成（{len(r['missing'])} 条）"
        else:
            status = f"⚠ 缺 {len(r['missing'])} 条"
        lines.append(
            f"| `{r['case_id']}` | {r['title']} | `{r['voice_status']}` | {len(r['have'])} | {len(r['missing'])} | {status} |"
        )
    lines.append("")

    for r in reports:
        if not r["missing"]:
            continue
        lines.append(f"## {r['title']} (`{r['case_id']}`)")
        lines.append("")
        lines.append(f"缺失 {len(r['missing'])} 条。")
        lines.append("")

        # 按类型分组
        by_kind: dict[str, list[dict]] = {"dialogue": [], "prologue": [], "event": []}
        for e in r["missing"]:
            by_kind.setdefault(e["kind"], []).append(e)

        # 对话部分按 npc 分组
        if by_kind["dialogue"]:
            lines.append("### 对话")
            lines.append("")
            by_npc: dict[str, list[dict]] = {}
            for e in by_kind["dialogue"]:
                by_npc.setdefault(e["npc_id"], []).append(e)
            for npc_id in sorted(by_npc.keys()):
                items = by_npc[npc_id]
                actor = items[0]["actor_id"] or "(无 casting)"
                lines.append(f"#### {npc_id} → {actor}（{len(items)} 条）")
                lines.append("")
                lines.append("| node_id | 预期路径 | 文本预览 |")
                lines.append("|---------|---------|---------|")
                for e in items:
                    lines.append(f"| `{e['node_id']}` | `{e['expected']}` | {e['text_preview']} |")
                lines.append("")

        if by_kind["prologue"]:
            lines.append("### 序章")
            lines.append("")
            lines.append("| node_id | 预期路径 | 文本预览 |")
            lines.append("|---------|---------|---------|")
            for e in by_kind["prologue"]:
                lines.append(f"| `{e['node_id']}` | `{e['expected']}` | {e['text_preview']} |")
            lines.append("")

        if by_kind["event"]:
            lines.append("### 日程事件")
            lines.append("")
            lines.append("| node_id | 预期路径 | 文本预览 |")
            lines.append("|---------|---------|---------|")
            for e in by_kind["event"]:
                lines.append(f"| `{e['node_id']}` | `{e['expected']}` | {e['text_preview']} |")
            lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## 后续 TTS 生成提示")
    lines.append("")
    lines.append(
        "1. 每条缺失语音的 `actor_id` 决定了用哪个 voice_config —— 见 `data/actors/registry.json`。\n"
        "2. 缺失列表按 `actor_id` 聚合后跑 `tools/generate_voices.py` 可批量生成。\n"
        "3. 序章和事件类语音不区分 actor，按 `_prologue/` / `_events/` 旧目录约定生成。\n"
        "4. 重新跑本脚本即可看到差量更新。"
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="扫描案件数据，统计未生成的语音节点")
    ap.add_argument("--case", action="append", default=None, help="只扫指定案件，可重复")
    ap.add_argument("--print", action="store_true", help="不写文件，仅输出到 stdout")
    args = ap.parse_args()

    cases = args.case if args.case else discover_cases()
    reports = [audit_case(c) for c in cases]
    md = render_markdown(reports)

    if args.print:
        print(md)
    else:
        out = DOCS_DIR / "MISSING_VOICES.md"
        out.write_text(md, encoding="utf-8")
        print(f"Wrote {out.relative_to(REPO_ROOT)}")
        # 摘要也打到 stdout
        for r in reports:
            tag = "OK" if not r["missing"] else f"!{len(r['missing'])}"
            print(f"  [{tag}] {r['case_id']}: have={len(r['have'])} missing={len(r['missing'])}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
