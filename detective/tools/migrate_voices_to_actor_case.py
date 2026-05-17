#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
一次性语音目录迁移工具

把旧布局 voices/{npc_id}/{node_id}.wav 迁到新布局 voices/{actor_id}/{case_id}/{node_id}.wav，
按 data/cases/<case_id>/casting.json 的映射进行。

用法：
    python3 tools/migrate_voices_to_actor_case.py --case linchuan_inn          # 迁移指定案件
    python3 tools/migrate_voices_to_actor_case.py --case linchuan_inn --dry    # 预览不执行

策略：
    - 仅迁移 .wav + .wav.import 一对，避免 Godot 重导入
    - 源目录若被搬空则保留空目录（不删，防止误删第三方未列出的文件）
    - 同名目标已存在时报警（safety check）
    - 输出操作清单，便于回滚
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
VOICES = REPO_ROOT / "assets" / "cn" / "voices"


def load_casting(case_id: str) -> dict:
    p = REPO_ROOT / "data" / "cases" / case_id / "casting.json"
    if not p.exists():
        print(f"[ERROR] casting.json 不存在: {p}", file=sys.stderr)
        sys.exit(2)
    return json.loads(p.read_text(encoding="utf-8")).get("casting", {})


def migrate(case_id: str, dry: bool) -> int:
    casting = load_casting(case_id)
    moved = 0
    skipped = 0
    issues = 0

    for npc_id, entry in casting.items():
        if not isinstance(entry, dict):
            continue
        actor_id = entry.get("actor_id", "")
        if not actor_id:
            continue
        src_dir = VOICES / npc_id
        if not src_dir.is_dir():
            continue
        dst_dir = VOICES / actor_id / case_id
        dst_dir.mkdir(parents=True, exist_ok=True)

        for src in sorted(src_dir.iterdir()):
            if not (src.suffix == ".wav" or src.name.endswith(".wav.import")):
                continue
            dst = dst_dir / src.name
            if dst.exists():
                print(f"  [SKIP] target exists: {dst.relative_to(REPO_ROOT)}")
                skipped += 1
                continue
            print(f"  {'[DRY] ' if dry else ''}MOVE {src.relative_to(REPO_ROOT)} -> {dst.relative_to(REPO_ROOT)}")
            if not dry:
                shutil.move(str(src), str(dst))
            moved += 1

    print()
    print(f"==> case={case_id}: moved={moved}, skipped={skipped}, issues={issues}")
    return 0 if issues == 0 else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--case", required=True, help="案件 ID")
    ap.add_argument("--dry", action="store_true", help="只打印不执行")
    args = ap.parse_args()
    return migrate(args.case, args.dry)


if __name__ == "__main__":
    sys.exit(main())
