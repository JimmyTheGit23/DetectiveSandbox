#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
注册表完整性校验脚本

用途：
    在不启动 Godot 的情况下，独立校验三大注册表（演员库 / 场景库 / BGM 库）
    与各案件 casting.json / locations.json / bgm_config.json 之间的引用一致性。

校验项：
    1) actors/registry.json 中每个 actor 引用的 portrait 文件实际存在
    2) scenes/registry.json 中每个 scene 引用的 background 文件实际存在
    3) bgm/registry.json 中每个 track 引用的 wav 文件实际存在
    4) bgm/registry.json 的 mood_index 中所有 track_id 都能在 tracks 找到
    5) 各案件 casting.json 中的 actor_id 都能在 actors registry 找到
    6) 各案件 locations.json 中的 scene_type 都能在 scenes registry 找到
    7) 各案件 bgm_config.json 中的 mood:xxx / track:xxx 引用合法

退出码：
    0 = 全部通过
    非 0 = 至少一项失败（具体错误打印到 stderr）

用法：
    python tools/validate_registry.py
    python tools/validate_registry.py --case linchuan_inn
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA = REPO_ROOT / "data"


def _strip_res(path: str) -> Path:
    """把 res:// 前缀转成相对仓库根目录的路径。"""
    if path.startswith("res://"):
        return REPO_ROOT / path[len("res://"):]
    return REPO_ROOT / path


def _load_json(p: Path) -> dict:
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def _filter_underscore(d: dict) -> dict:
    """剔除 _comment / _schema 等元数据字段。"""
    return {k: v for k, v in d.items() if not (isinstance(k, str) and k.startswith("_"))}


# ───────────────────────────── 校验函数 ─────────────────────────────


def check_actors(errors: list[str]) -> dict:
    p = DATA / "actors" / "registry.json"
    root = _load_json(p)
    actors = _filter_underscore(root.get("actors", {}))
    if not actors:
        errors.append(f"[actors] 注册表为空或不存在: {p}")
        return {}
    for aid, a in actors.items():
        portrait = a.get("portrait", "")
        if not portrait:
            errors.append(f"[actors:{aid}] 缺少 portrait 字段")
            continue
        fp = _strip_res(portrait)
        if not fp.exists():
            errors.append(f"[actors:{aid}] portrait 文件不存在: {portrait}")
        if "voice_config" not in a:
            errors.append(f"[actors:{aid}] 缺少 voice_config 字段（推荐至少 style）")
    return actors


def check_scenes(errors: list[str]) -> dict:
    p = DATA / "scenes" / "registry.json"
    root = _load_json(p)
    scenes = _filter_underscore(root.get("scenes", {}))
    if not scenes:
        errors.append(f"[scenes] 注册表为空或不存在: {p}")
        return {}
    for sid, s in scenes.items():
        bg = s.get("background", "")
        if not bg:
            errors.append(f"[scenes:{sid}] 缺少 background 字段")
            continue
        fp = _strip_res(bg)
        if not fp.exists():
            errors.append(f"[scenes:{sid}] background 文件不存在: {bg}")
    return scenes


def check_bgm(errors: list[str]) -> tuple[dict, dict]:
    p = DATA / "bgm" / "registry.json"
    root = _load_json(p)
    tracks = root.get("tracks", {})
    mood_index = root.get("mood_index", {})
    # mood_index 里也允许带 _comment
    mood_index = _filter_underscore(mood_index)
    if not tracks:
        errors.append(f"[bgm] 注册表为空或不存在: {p}")
        return {}, {}
    for tid, t in tracks.items():
        f = t.get("file", "")
        if not f:
            errors.append(f"[bgm:{tid}] 缺少 file 字段")
            continue
        fp = _strip_res(f)
        if not fp.exists():
            errors.append(f"[bgm:{tid}] 音频文件不存在: {f}")
    # mood_index 反查
    for mood, arr in mood_index.items():
        if not isinstance(arr, list):
            errors.append(f"[bgm.mood_index:{mood}] 应为数组")
            continue
        for tid in arr:
            if tid not in tracks:
                errors.append(f"[bgm.mood_index:{mood}] 引用未注册 track_id: {tid}")
    return tracks, mood_index


def check_case(case_id: str, actors: dict, scenes: dict, tracks: dict, mood_index: dict, errors: list[str]) -> None:
    case_dir = DATA / "cases" / case_id
    if not case_dir.exists():
        errors.append(f"[case:{case_id}] 案件目录不存在")
        return
    # casting.json
    casting_root = _load_json(case_dir / "casting.json")
    casting = casting_root.get("casting", {})
    npcs = _load_json(case_dir / "npcs.json")  # 加载npcs.json用于检查portrait
    for nid, entry in casting.items():
        if not isinstance(entry, dict):
            errors.append(f"[case:{case_id}/casting:{nid}] 必须是字典")
            continue
        aid = entry.get("actor_id", "")
        if not aid:
            # 允许空actor_id，如果npcs.json中有portrait字段或角色是受害者
            npc_data = npcs.get(nid, {})
            if not npc_data.get("portrait") and not npc_data.get("is_victim"):
                errors.append(f"[case:{case_id}/casting:{nid}] 缺少 actor_id 且 npcs.json 无 portrait")
        elif aid not in actors:
            errors.append(f"[case:{case_id}/casting:{nid}] 引用未注册 actor_id: {aid}")
    # locations.json
    locations = _load_json(case_dir / "locations.json")
    for lid, ldef in locations.items():
        if not isinstance(ldef, dict):
            continue
        st = ldef.get("scene_type", "")
        if st and st not in scenes:
            errors.append(f"[case:{case_id}/locations:{lid}] 引用未注册 scene_type: {st}")
        # 至少要有 scene_type 或 background 之一
        if not st and not ldef.get("background", ""):
            errors.append(f"[case:{case_id}/locations:{lid}] 既无 scene_type 也无 background")
    # bgm_config.json
    bgm_cfg = _load_json(case_dir / "bgm_config.json")
    for section in ("locations", "states"):
        for k, v in bgm_cfg.get(section, {}).items():
            if not isinstance(v, str):
                errors.append(f"[case:{case_id}/bgm_config:{section}.{k}] 值必须是字符串")
                continue
            if v.startswith("mood:"):
                mood = v[len("mood:"):]
                if mood not in mood_index:
                    errors.append(f"[case:{case_id}/bgm_config:{section}.{k}] 引用未注册 mood: {mood}")
            elif v.startswith("track:"):
                tid = v[len("track:"):]
                if tid not in tracks:
                    errors.append(f"[case:{case_id}/bgm_config:{section}.{k}] 引用未注册 track: {tid}")
            else:
                # 裸字符串视为 track_id
                if v not in tracks:
                    errors.append(f"[case:{case_id}/bgm_config:{section}.{k}] 引用未注册 track: {v}")


# ───────────────────────────── 主入口 ─────────────────────────────


def discover_cases() -> list[str]:
    cases_dir = DATA / "cases"
    if not cases_dir.exists():
        return []
    return sorted([p.name for p in cases_dir.iterdir() if p.is_dir()])


def main() -> int:
    ap = argparse.ArgumentParser(description="校验资产注册表与案件引用一致性")
    ap.add_argument("--case", action="append", default=None,
                    help="指定要校验的案件 id（可重复）。默认校验所有 data/cases/* 目录。")
    args = ap.parse_args()

    errors: list[str] = []
    actors = check_actors(errors)
    scenes = check_scenes(errors)
    tracks, mood_index = check_bgm(errors)

    cases = args.case if args.case else discover_cases()
    for cid in cases:
        check_case(cid, actors, scenes, tracks, mood_index, errors)

    print(f"演员库: {len(actors)} 个 actor")
    print(f"场景库: {len(scenes)} 个 scene")
    print(f"BGM 库: {len(tracks)} 首曲目，{len(mood_index)} 个 mood")
    print(f"案件: {', '.join(cases) if cases else '(无)'}")
    print()

    if errors:
        print(f"[FAIL] 发现 {len(errors)} 个问题：", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print("[OK] 注册表与案件引用全部合法。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
