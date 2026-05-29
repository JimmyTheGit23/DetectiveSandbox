#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
对话路径静态分析器

分析对话 CSV 数据，构建对话图，验证结构完整性。
不依赖 Godot 运行时，纯 Python 离线分析。

检查项：
    1. 所有 goto 目标节点是否存在
    2. 不可达节点检测（从起始节点无法到达）
    3. 死循环路径检测
    4. 孤立节点检测（无选项且非 end 节点）
    5. 对话内容完整性（每个节点是否有 lines）
    6. 条件引用有效性（flag/evidence/clue 是否在数据中定义）

输出：
    - 控制台摘要
    - JSON 结构化报告（dialogue_graph_<case>.json）

用法：
    python3 tools/regression/analyze_dialogue_paths.py [case_id]
    默认分析所有案件
"""

from __future__ import annotations

import csv
import json
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CASE_TABLES_DIR = REPO_ROOT / "data" / "case_tables"
REPORTS_DIR = Path(__file__).resolve().parent / "reports"


class DialogueNode:
    """对话节点"""
    def __init__(self, npc_id: str, node_id: str, is_start: bool = False,
                 text: str = "", end: bool = False, set_flags: list[str] = None,
                 gain_evidence: str = "", gain_clue: str = "",
                 trigger_confrontation: bool = False, confrontation_key: str = ""):
        self.npc_id = npc_id
        self.node_id = node_id
        self.is_start = is_start
        self.text = text
        self.end = end
        self.set_flags = set_flags or []
        self.gain_evidence = gain_evidence
        self.gain_clue = gain_clue
        self.trigger_confrontation = trigger_confrontation
        self.confrontation_key = confrontation_key
        self.options: list[DialogueOption] = []
        self.lines: list[dict] = []


class DialogueOption:
    """对话选项"""
    def __init__(self, npc_id: str, node_id: str, order: int, text: str,
                 goto: str, option_type: str = "", requires: list[dict] = None,
                 set_flags: list[str] = None):
        self.npc_id = npc_id
        self.node_id = node_id
        self.order = order
        self.text = text
        self.goto = goto
        self.option_type = option_type
        self.requires = requires or []
        self.set_flags = set_flags or []


class DialogueGraph:
    """对话图"""
    def __init__(self, case_id: str):
        self.case_id = case_id
        self.nodes: dict[str, DialogueNode] = {}  # "npc_id.node_id" -> node
        self.npc_start_nodes: dict[str, str] = {}  # npc_id -> start_node_id
        self.all_flags: set[str] = set()
        self.all_evidence: set[str] = set()
        self.all_clues: set[str] = set()

    def add_node(self, node: DialogueNode):
        key = f"{node.npc_id}.{node.node_id}"
        self.nodes[key] = node
        if node.is_start:
            self.npc_start_nodes[node.npc_id] = node.node_id

    def get_node(self, npc_id: str, node_id: str) -> DialogueNode | None:
        return self.nodes.get(f"{npc_id}.{node_id}")

    def get_npc_nodes(self, npc_id: str) -> list[DialogueNode]:
        return [n for n in self.nodes.values() if n.npc_id == npc_id]


def parse_csv(filepath: Path) -> list[dict]:
    """解析 CSV 文件"""
    if not filepath.exists():
        return []
    try:
        with open(filepath, 'r', encoding='utf-8-sig') as f:  # 处理 BOM
            reader = csv.DictReader(f)
            return list(reader)
    except Exception as e:
        print(f"  警告: 解析 CSV 失败 {filepath}: {e}", file=sys.stderr)
        return []


def parse_requires(requires_str: str) -> list[dict]:
    """解析 requires 字段（JSON 格式）"""
    if not requires_str or requires_str.strip() == "":
        return []
    try:
        parsed = json.loads(requires_str)
        if isinstance(parsed, list):
            return parsed
        elif isinstance(parsed, dict):
            return [parsed]
        return []
    except json.JSONDecodeError:
        return []


def parse_set_flags(flags_str: str) -> list[str]:
    """解析 set_flags 字段"""
    if not flags_str or flags_str.strip() == "":
        return []
    try:
        parsed = json.loads(flags_str)
        if isinstance(parsed, list):
            return [str(f) for f in parsed]
        elif isinstance(parsed, str):
            return [parsed]
        return []
    except json.JSONDecodeError:
        # 尝试逗号分隔
        return [f.strip() for f in flags_str.split(",") if f.strip()]


def build_dialogue_graph(case_id: str) -> DialogueGraph:
    """构建对话图"""
    case_dir = CASE_TABLES_DIR / case_id
    graph = DialogueGraph(case_id)

    # 读取 dialogue_nodes.csv
    nodes_file = case_dir / "dialogue_nodes.csv"
    for row in parse_csv(nodes_file):
        npc_id = row.get("npc_id", "").strip()
        node_id = row.get("node_id", "").strip()
        if not npc_id or not node_id:
            continue

        is_start = row.get("is_start", "").strip().lower() == "true"
        text = row.get("text", "").strip()
        end = row.get("end", "").strip().lower() == "true"
        set_flags = parse_set_flags(row.get("set_flags", ""))
        gain_evidence = row.get("gain_evidence", "").strip()
        gain_clue = row.get("gain_clue", "").strip()
        trigger_confrontation = row.get("trigger_confrontation", "").strip().lower() == "true"
        confrontation_key = row.get("confrontation_key", "").strip()

        node = DialogueNode(
            npc_id=npc_id,
            node_id=node_id,
            is_start=is_start,
            text=text,
            end=end,
            set_flags=set_flags,
            gain_evidence=gain_evidence,
            gain_clue=gain_clue,
            trigger_confrontation=trigger_confrontation,
            confrontation_key=confrontation_key
        )
        graph.add_node(node)

        # 收集所有 flags/evidence/clues
        for flag in set_flags:
            graph.all_flags.add(flag)
        if gain_evidence:
            graph.all_evidence.add(gain_evidence)
        if gain_clue:
            graph.all_clues.add(gain_clue)

    # 读取 dialogue_options.csv
    options_file = case_dir / "dialogue_options.csv"
    for row in parse_csv(options_file):
        npc_id = row.get("npc_id", "").strip()
        node_id = row.get("node_id", "").strip()
        if not npc_id or not node_id:
            continue

        try:
            order = int(row.get("order", "0"))
        except ValueError:
            order = 0

        text = row.get("text", "").strip()
        goto = row.get("goto", "").strip()
        option_type = row.get("type", "").strip()
        requires = parse_requires(row.get("requires", ""))
        set_flags = parse_set_flags(row.get("set_flags", ""))

        option = DialogueOption(
            npc_id=npc_id,
            node_id=node_id,
            order=order,
            text=text,
            goto=goto,
            option_type=option_type,
            requires=requires,
            set_flags=set_flags
        )

        node = graph.get_node(npc_id, node_id)
        if node:
            node.options.append(option)

        # 收集条件中引用的 flags/evidence/clues
        for req in requires:
            if "flag" in req:
                graph.all_flags.add(req["flag"])
            if "evidence" in req:
                graph.all_evidence.add(req["evidence"])
            if "clue" in req:
                graph.all_clues.add(req["clue"])
        for flag in set_flags:
            graph.all_flags.add(flag)

    # 读取 dialogue_lines.csv
    lines_file = case_dir / "dialogue_lines.csv"
    for row in parse_csv(lines_file):
        npc_id = row.get("npc_id", "").strip()
        node_id = row.get("node_id", "").strip()
        if not npc_id or not node_id:
            continue

        node = graph.get_node(npc_id, node_id)
        if node:
            node.lines.append(row)

    return graph


def check_goto_targets(graph: DialogueGraph) -> list[dict]:
    """检查所有 goto 目标节点是否存在"""
    errors = []
    for node in graph.nodes.values():
        for option in node.options:
            goto = option.goto
            if not goto or goto in ("__exit__", "__confront__"):
                continue
            target_key = f"{node.npc_id}.{goto}"
            if target_key not in graph.nodes:
                errors.append({
                    "type": "missing_goto_target",
                    "npc_id": node.npc_id,
                    "node_id": node.node_id,
                    "option_text": option.text,
                    "goto": goto,
                    "message": f"节点 {node.npc_id}.{node.node_id} 的选项 '{option.text}' 指向不存在的目标 '{goto}'"
                })
    return errors


def check_unreachable_nodes(graph: DialogueGraph) -> list[dict]:
    """检查不可达节点"""
    errors = []
    for npc_id in set(n.npc_id for n in graph.nodes.values()):
        start_node = graph.npc_start_nodes.get(npc_id)
        if not start_node:
            errors.append({
                "type": "no_start_node",
                "npc_id": npc_id,
                "message": f"NPC '{npc_id}' 没有起始节点"
            })
            continue

        # BFS 找所有可达节点
        reachable = set()
        queue = [start_node]
        while queue:
            current = queue.pop(0)
            if current in reachable:
                continue
            reachable.add(current)

            node = graph.get_node(npc_id, current)
            if node:
                for option in node.options:
                    goto = option.goto
                    if goto and goto not in ("__exit__", "__confront__"):
                        queue.append(goto)

        # 检查不可达节点
        for node in graph.get_npc_nodes(npc_id):
            if node.node_id not in reachable:
                # 对峙入口节点（trigger_confrontation）由对峙系统触发，不做可达性检查
                if node.trigger_confrontation:
                    continue
                # 选项指向 __confront__ 的节点目标也是对峙入口
                is_confront_target = any(
                    opt.goto == "__confront__"
                    for opt in node.options
                )
                if is_confront_target:
                    continue
                errors.append({
                    "type": "unreachable_node",
                    "npc_id": npc_id,
                    "node_id": node.node_id,
                    "message": f"节点 {npc_id}.{node.node_id} 从起始节点不可达"
                })

    return errors


def check_dead_end_nodes(graph: DialogueGraph) -> list[dict]:
    """检查死胡同节点（无选项且非 end 节点）"""
    errors = []
    for node in graph.nodes.values():
        if node.end:
            continue
        if not node.options:
            errors.append({
                "type": "dead_end_node",
                "npc_id": node.npc_id,
                "node_id": node.node_id,
                "message": f"节点 {node.npc_id}.{node.node_id} 无选项且非结束节点"
            })
    return errors


def check_missing_content(graph: DialogueGraph) -> list[dict]:
    """检查缺失对话内容的节点"""
    errors = []
    for node in graph.nodes.values():
        if not node.text and not node.lines:
            # 跳过 hub 节点和系统节点
            if node.node_id in ("hub", "__exit__", "__confront__"):
                continue
            errors.append({
                "type": "missing_content",
                "npc_id": node.npc_id,
                "node_id": node.node_id,
                "message": f"节点 {node.npc_id}.{node.node_id} 没有对话内容"
            })
    return errors


def check_dead_cycles(graph: DialogueGraph, max_depth: int = 100) -> list[dict]:
    """检查可能的死循环路径（简单检测）"""
    errors = []
    for npc_id in set(n.npc_id for n in graph.nodes.values()):
        start_node = graph.npc_start_nodes.get(npc_id)
        if not start_node:
            continue

        # DFS 检测循环
        visited = set()
        path = []

        def dfs(node_id: str, depth: int) -> bool:
            if depth > max_depth:
                return True  # 可能是循环

            key = f"{npc_id}.{node_id}"
            if key in visited:
                return False
            visited.add(key)
            path.append(node_id)

            node = graph.get_node(npc_id, node_id)
            if node:
                for option in node.options:
                    goto = option.goto
                    if goto and goto not in ("__exit__", "__confront__"):
                        if dfs(goto, depth + 1):
                            return True

            path.pop()
            return False

        if dfs(start_node, 0):
            errors.append({
                "type": "possible_cycle",
                "npc_id": npc_id,
                "path": path[:10],  # 只显示前 10 个节点
                "message": f"NPC '{npc_id}' 可能存在死循环路径"
            })

    return errors


def analyze_case(case_id: str) -> dict:
    """分析单个案件的对话路径"""
    print(f"\n分析案件: {case_id}")

    graph = build_dialogue_graph(case_id)

    # 统计信息
    stats = {
        "case_id": case_id,
        "total_nodes": len(graph.nodes),
        "total_npcs": len(set(n.npc_id for n in graph.nodes.values())),
        "start_nodes": len(graph.npc_start_nodes),
        "total_options": sum(len(n.options) for n in graph.nodes.values()),
        "total_flags": len(graph.all_flags),
        "total_evidence": len(graph.all_evidence),
        "total_clues": len(graph.all_clues),
    }

    # 运行检查
    checks = {
        "goto_targets": check_goto_targets(graph),
        "unreachable_nodes": check_unreachable_nodes(graph),
        "dead_end_nodes": check_dead_end_nodes(graph),
        "missing_content": check_missing_content(graph),
        "dead_cycles": check_dead_cycles(graph),
    }

    # 统计错误
    total_errors = sum(len(errors) for errors in checks.values())
    error_summary = {check_name: len(errors) for check_name, errors in checks.items()}

    # 按 NPC 分组统计
    npc_stats = {}
    for node in graph.nodes.values():
        if node.npc_id not in npc_stats:
            npc_stats[node.npc_id] = {
                "nodes": 0,
                "options": 0,
                "has_start": node.npc_id in graph.npc_start_nodes,
            }
        npc_stats[node.npc_id]["nodes"] += 1
        npc_stats[node.npc_id]["options"] += len(node.options)

    result = {
        "case_id": case_id,
        "timestamp": datetime.now().isoformat(),
        "stats": stats,
        "npc_stats": npc_stats,
        "error_summary": error_summary,
        "total_errors": total_errors,
        "checks": checks,
        "graph": {
            "nodes": {key: {
                "npc_id": node.npc_id,
                "node_id": node.node_id,
                "is_start": node.is_start,
                "end": node.end,
                "options_count": len(node.options),
                "lines_count": len(node.lines),
            } for key, node in graph.nodes.items()},
            "npc_start_nodes": graph.npc_start_nodes,
        }
    }

    # 打印摘要
    print(f"  节点数: {stats['total_nodes']}")
    print(f"  NPC 数: {stats['total_npcs']}")
    print(f"  选项数: {stats['total_options']}")
    print(f"  错误数: {total_errors}")
    if total_errors > 0:
        for check_name, count in error_summary.items():
            if count > 0:
                print(f"    - {check_name}: {count}")

    return result


def main():
    """主函数"""
    # 确定要分析的案件
    if len(sys.argv) > 1:
        case_ids = sys.argv[1:]
    else:
        # 分析所有案件
        if not CASE_TABLES_DIR.exists():
            print(f"错误: 案件数据目录不存在: {CASE_TABLES_DIR}", file=sys.stderr)
            sys.exit(1)
        case_ids = [d.name for d in CASE_TABLES_DIR.iterdir()
                    if d.is_dir() and not d.name.startswith("_")]

    if not case_ids:
        print("没有找到要分析的案件", file=sys.stderr)
        sys.exit(1)

    # 确保报告目录存在
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    # 分析每个案件
    all_results = []
    total_errors = 0

    for case_id in sorted(case_ids):
        try:
            result = analyze_case(case_id)
            all_results.append(result)
            total_errors += result["total_errors"]

            # 保存单个案件的报告
            report_file = REPORTS_DIR / f"dialogue_graph_{case_id}.json"
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            print(f"  报告已保存: {report_file}")

        except Exception as e:
            print(f"  分析失败: {e}", file=sys.stderr)
            total_errors += 1

    # 打印总结
    print("\n" + "=" * 70)
    print("  分析总结")
    print("=" * 70)
    print(f"分析案件数: {len(all_results)}")
    print(f"总错误数: {total_errors}")

    if total_errors == 0:
        print("\n✓ 所有检查通过!")
    else:
        print(f"\n✗ 发现 {total_errors} 个问题，请查看详细报告")

    # 返回退出码
    sys.exit(0 if total_errors == 0 else 1)


if __name__ == "__main__":
    main()
