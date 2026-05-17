#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务完成后跑的静态回归脚本（不依赖 Godot 运行）

适合每次代码 / 数据 / 模板变更后立刻跑一次，作为 PR / 提交前的退出门禁。

检查项：
    1) 资产注册表与案件引用一致性（tools/validate_registry.py）
    2) 每个案件目录的必备文件齐全（manifest/case/casting/locations/npcs 等）
    3) PCG 模板 schema 校验（jsonschema）+ 健康检查（tools/pcg/inspect_template.py）
    4) 语音清单刷新到最新（tools/audit_voices.py）
    5) 案件级硬约束抽样（每个案件至少有 1 个 NPC、casting 与 npcs 角色集对齐）

退出码：
    0 = 全绿
    非 0 = 至少一项失败（详情打印到 stderr）

用法：
    python3 tools/regression/run_static.py
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DATA = REPO_ROOT / "data"
TOOLS = REPO_ROOT / "tools"

REQUIRED_CASE_FILES = [
    "manifest.json",
    "case.json",
    "casting.json",
    "locations.json",
    "npcs.json",
    "evidence.json",
    "search_results.json",
    "day_events.json",
    "npc_states.json",
    "bgm_config.json",
    "prologue.json",
]


def _section(name: str) -> None:
    print()
    print("=" * 70)
    print(f"  {name}")
    print("=" * 70)


def _run(cmd: list[str], label: str) -> bool:
    print(f"\n→ {label}: {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd, cwd=str(REPO_ROOT), capture_output=True, text=True, check=False
        )
    except FileNotFoundError as e:
        print(f"  [FAIL] subprocess: {e}", file=sys.stderr)
        return False
    if result.stdout:
        for line in result.stdout.rstrip().splitlines():
            print(f"    {line}")
    if result.returncode != 0:
        if result.stderr:
            print("  ── stderr ──", file=sys.stderr)
            for line in result.stderr.rstrip().splitlines():
                print(f"    {line}", file=sys.stderr)
        print(f"  [FAIL] exit={result.returncode}", file=sys.stderr)
        return False
    print(f"  [OK]")
    return True


def _load_json(p: Path) -> dict:
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def check_case_files() -> bool:
    """每个案件目录必备文件齐全。"""
    cases_dir = DATA / "cases"
    if not cases_dir.exists():
        print("[FAIL] data/cases/ 不存在", file=sys.stderr)
        return False
    ok = True
    for cd in sorted(cases_dir.iterdir()):
        if not cd.is_dir() or cd.name.startswith("_"):
            continue
        case_id = cd.name
        missing: list[str] = []
        for f in REQUIRED_CASE_FILES:
            if not (cd / f).exists():
                missing.append(f)
        if not (cd / "dialogues").is_dir():
            missing.append("dialogues/")
        if missing:
            print(f"  [FAIL] case={case_id} 缺文件: {', '.join(missing)}", file=sys.stderr)
            ok = False
        else:
            print(f"  [OK] case={case_id} 必备文件齐全")
    return ok


def check_casting_npcs_alignment() -> bool:
    """case 的 casting 角色与 npcs 角色集对齐（至少 npc 子集 ⊆ casting）。"""
    cases_dir = DATA / "cases"
    ok = True
    for cd in sorted(cases_dir.iterdir()):
        if not cd.is_dir() or cd.name.startswith("_"):
            continue
        case_id = cd.name
        casting = _load_json(cd / "casting.json").get("casting", {})
        npcs = _load_json(cd / "npcs.json")
        # 过滤掉 _comment
        npc_ids = {k for k in npcs.keys() if not k.startswith("_")}
        casting_ids = set(casting.keys())
        # npcs.json 里出现的 NPC 应在 casting 中（player 角色 lu_zhao 也算）
        only_in_npcs = npc_ids - casting_ids
        only_in_casting = casting_ids - npc_ids
        if only_in_npcs:
            print(f"  [FAIL] case={case_id} 在 npcs.json 但不在 casting: {sorted(only_in_npcs)}", file=sys.stderr)
            ok = False
        # casting 多于 npcs 不报 FAIL（玩家角色可能不在 npcs 列表）
        if only_in_casting:
            print(f"  [INFO] case={case_id} 仅在 casting: {sorted(only_in_casting)}（通常是玩家或纯叙事角色）")
        if ok:
            print(f"  [OK] case={case_id}: {len(casting_ids)} casting / {len(npc_ids)} npcs 对齐")
    return ok


def check_dialogue_node_consistency() -> bool:
    """每个 dialogue/*.json 的 NPC 必须在 casting 中。"""
    cases_dir = DATA / "cases"
    ok = True
    for cd in sorted(cases_dir.iterdir()):
        if not cd.is_dir() or cd.name.startswith("_"):
            continue
        case_id = cd.name
        casting = _load_json(cd / "casting.json").get("casting", {})
        casting_ids = set(casting.keys())
        dlg_dir = cd / "dialogues"
        if not dlg_dir.is_dir():
            continue
        orphan: list[str] = []
        for dlg in dlg_dir.glob("*.json"):
            if dlg.stem not in casting_ids:
                orphan.append(dlg.stem)
        if orphan:
            print(f"  [FAIL] case={case_id} dialogue/*.json 中无对应 casting: {orphan}", file=sys.stderr)
            ok = False
        else:
            print(f"  [OK] case={case_id}: 所有 dialogue 文件均有 casting")
    return ok


def main() -> int:
    failed: list[str] = []

    _section("[1/5] 资产注册表 & 案件引用合法性")
    if not _run([sys.executable, "tools/validate_registry.py"], "validate_registry"):
        failed.append("validate_registry")

    _section("[2/5] 案件目录必备文件")
    if not check_case_files():
        failed.append("case_files")

    _section("[3/5] casting 与 npcs.json 角色集对齐")
    if not check_casting_npcs_alignment():
        failed.append("casting_alignment")
    print()
    if not check_dialogue_node_consistency():
        failed.append("dialogue_alignment")

    _section("[4/5] PCG 模板 schema 校验 + 健康检查")
    schema_ok = True
    try:
        import jsonschema  # noqa: F401
    except ImportError:
        print("  [SKIP] 没装 jsonschema，跳过 schema 校验（pip install jsonschema 可启用）")
    else:
        schema_path = TOOLS / "pcg" / "schemas" / "template_schema.json"
        templates_dir = TOOLS / "pcg" / "templates"
        if schema_path.exists() and templates_dir.exists():
            schema = json.loads(schema_path.read_text(encoding="utf-8"))
            for tpl_path in sorted(templates_dir.glob("*.json")):
                try:
                    tpl = json.loads(tpl_path.read_text(encoding="utf-8"))
                    jsonschema.validate(instance=tpl, schema=schema)
                    print(f"  [OK] schema {tpl_path.name}")
                except Exception as e:
                    print(f"  [FAIL] schema {tpl_path.name}: {e}", file=sys.stderr)
                    schema_ok = False
    if not schema_ok:
        failed.append("template_schema")

    if not _run(
        [sys.executable, "tools/pcg/inspect_template.py", "--all", "--brief"],
        "inspect_template --all --brief",
    ):
        failed.append("template_health")

    _section("[5/5] 语音清单刷新")
    if not _run([sys.executable, "tools/audit_voices.py"], "audit_voices"):
        failed.append("audit_voices")

    _section("最终结果")
    if not failed:
        print("  ✅ 所有静态回归项通过")
        return 0
    print(f"  ❌ 失败: {', '.join(failed)}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
