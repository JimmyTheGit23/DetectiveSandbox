#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
合并静态分析和运行时测试结果，生成最终 Markdown 报告。

用法：
    python3 tools/regression/generate_final_report.py <case_id> '<runtime_json>'
    
    runtime_json: 运行时测试的 JSON 输出（从 execute_game_script 的 return_value 解析）
    
    或使用 --from-file 指定运行时结果文件：
    python3 tools/regression/generate_final_report.py <case_id> --from-file <path>
"""

from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
TOOLS_DIR = REPO_ROOT / "tools" / "regression"
REPORTS_DIR = TOOLS_DIR / "reports"


def load_static_analysis(case_id: str) -> dict:
    """加载静态分析报告"""
    report_file = REPORTS_DIR / f"dialogue_graph_{case_id}.json"
    if report_file.exists():
        with open(report_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def parse_runtime_output(output_lines: list[str]) -> dict:
    """解析运行时测试输出"""
    results = {
        "case_id": "",
        "npc_count": 0,
        "npc_results": {},
        "path_count": 0,
        "error_count": 0,
        "warning_count": 0,
        "test_status": "UNKNOWN",
        "warnings": []
    }
    
    current_npc = ""
    
    for line in output_lines:
        line = line.strip()
        if "=" not in line:
            continue
        
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        
        if key == "case_id":
            results["case_id"] = value
        elif key == "npc_count":
            results["npc_count"] = int(value)
        elif key == "npc_id":
            current_npc = value
            results["npc_results"][current_npc] = {
                "node_count": 0,
                "option_count": 0,
                "checks": [],
                "warnings": []
            }
        elif key == "node_count" and current_npc:
            results["npc_results"][current_npc]["node_count"] = int(value)
        elif key == "option_count" and current_npc:
            results["npc_results"][current_npc]["option_count"] = int(value)
        elif key == "node_check" and current_npc:
            results["npc_results"][current_npc]["current_check"] = value
        elif key == "status" and current_npc:
            check_name = results["npc_results"][current_npc].get("current_check", "")
            results["npc_results"][current_npc]["checks"].append({
                "check": check_name,
                "status": value
            })
        elif key == "message" and current_npc:
            checks = results["npc_results"][current_npc]["checks"]
            if checks:
                checks[-1]["message"] = value
                if checks[-1]["status"] == "WARN":
                    results["npc_results"][current_npc]["warnings"].append(value)
                    results["warnings"].append(f"{current_npc}: {value}")
        elif key == "path_count":
            results["path_count"] = int(value)
        elif key == "error_count":
            results["error_count"] = int(value)
        elif key == "warning_count":
            results["warning_count"] = int(value)
        elif key == "TEST_STATUS":
            results["test_status"] = value
        elif key == "npc_complete":
            current_npc = ""
    
    return results


def generate_final_report(static: dict, runtime: dict, case_id: str) -> str:
    """生成最终 Markdown 报告"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 统计数据
    stats = static.get("stats", {})
    error_summary = static.get("error_summary", {})
    
    report = f"""# 对话路径测试报告

**案件**: {case_id}
**时间**: {timestamp}
**测试类型**: 对话路径完整性验证（静态分析 + 运行时验证）

---

## 测试摘要

| 指标 | 静态分析 | 运行时验证 |
|------|----------|------------|
| 总节点数 | {stats.get('total_nodes', 'N/A')} | {runtime.get('path_count', 'N/A')} |
| NPC 数量 | {stats.get('total_npcs', 'N/A')} | {runtime.get('npc_count', 'N/A')} |
| 选项数量 | {stats.get('total_options', 'N/A')} | — |
| 错误数量 | {static.get('total_errors', 0)} | {runtime.get('error_count', 0)} |
| 警告数量 | — | {runtime.get('warning_count', 0)} |
| 测试状态 | {'❌ 失败' if static.get('total_errors', 0) > 0 else '✅ 通过'} | {'✅ 通过' if runtime.get('test_status') == 'PASS' else '❌ 失败'} |

### 综合评估

| 维度 | 结果 |
|------|------|
| goto 目标完整性 | {'✅ 通过' if error_summary.get('goto_targets', 0) == 0 else '❌ 发现 %d 个缺失' % error_summary.get('goto_targets', 0)} |
| 节点可达性 | {'✅ 通过' if error_summary.get('unreachable_nodes', 0) == 0 else '❌ 发现 %d 个不可达节点' % error_summary.get('unreachable_nodes', 0)} |
| 对话内容完整性 | {'✅ 通过' if error_summary.get('missing_content', 0) == 0 else '⚠️ 发现 %d 个缺失内容' % error_summary.get('missing_content', 0)} |
| 运行时结构验证 | {'✅ 通过' if runtime.get('error_count', 0) == 0 else '❌ 发现 %d 个运行时错误' % runtime.get('error_count', 0)} |
| 条件语法合法性 | {'✅ 通过' if runtime.get('warning_count', 0) == 0 else '⚠️ 发现 %d 个未知条件类型' % runtime.get('warning_count', 0)} |

---

## 1. 静态分析结果

### 1.1 数据统计

| 统计项 | 值 |
|--------|-----|
| 总节点数 | {stats.get('total_nodes', 0)} |
| NPC 数量 | {stats.get('total_npcs', 0)} |
| 起始节点数 | {stats.get('start_nodes', 0)} |
| 总选项数 | {stats.get('total_options', 0)} |
| 总 Flag 数 | {stats.get('total_flags', 0)} |
| 总证据数 | {stats.get('total_evidence', 0)} |
| 总线索数 | {stats.get('total_clues', 0)} |

### 1.2 NPC 统计

| NPC | 节点数 | 选项数 | 有起始节点 |
|-----|--------|--------|------------|
"""
    
    npc_stats = static.get("npc_stats", {})
    for npc_id, ns in npc_stats.items():
        report += f"| {npc_id} | {ns.get('nodes', 0)} | {ns.get('options', 0)} | {'✅' if ns.get('has_start') else '❌'} |\n"
    
    report += f"""
### 1.3 错误详情

| 检查项 | 错误数 | 状态 |
|--------|--------|------|
| goto 目标缺失 | {error_summary.get('goto_targets', 0)} | {'✅' if error_summary.get('goto_targets', 0) == 0 else '❌'} |
| 不可达节点 | {error_summary.get('unreachable_nodes', 0)} | {'✅' if error_summary.get('unreachable_nodes', 0) == 0 else '❌'} |
| 死胡同节点 | {error_summary.get('dead_end_nodes', 0)} | {'✅' if error_summary.get('dead_end_nodes', 0) == 0 else '⚠️'} |
| 缺失内容 | {error_summary.get('missing_content', 0)} | {'✅' if error_summary.get('missing_content', 0) == 0 else '⚠️'} |
| 死循环路径 | {error_summary.get('dead_cycles', 0)} | {'✅' if error_summary.get('dead_cycles', 0) == 0 else '❌'} |
"""
    
    # 添加静态分析错误详情
    checks = static.get("checks", {})
    has_errors = False
    for check_name, errors in checks.items():
        if errors:
            if not has_errors:
                report += "\n**发现的问题**:\n\n"
                has_errors = True
            for error in errors:
                report += f"- **{error.get('type', 'unknown')}** (`{error.get('npc_id', '?')}.{error.get('node_id', '?')}`): {error.get('message', 'No message')}\n"
    
    report += f"""
---

## 2. 运行时测试结果

### 2.1 总体结果

| 指标 | 值 |
|------|-----|
| 测试状态 | {'✅ 通过' if runtime.get('test_status') == 'PASS' else '❌ 失败'} |
| 已验证节点数 | {runtime.get('path_count', 0)} |
| 运行时错误数 | {runtime.get('error_count', 0)} |
| 运行时警告数 | {runtime.get('warning_count', 0)} |

### 2.2 各 NPC 测试详情

"""
    
    npc_results = runtime.get("npc_results", {})
    for npc_id, npc_data in npc_results.items():
        has_warnings = len(npc_data.get("warnings", [])) > 0
        status_icon = "✅" if not has_warnings else "⚠️"
        report += f"#### {npc_id} {status_icon}\n\n"
        report += f"| 指标 | 值 |\n|------|-----|\n"
        report += f"| 节点数 | {npc_data.get('node_count', 0)} |\n"
        report += f"| 选项数 | {npc_data.get('option_count', 0)} |\n"
        
        checks = npc_data.get("checks", [])
        passed = sum(1 for c in checks if c.get("status") == "PASS")
        warned = sum(1 for c in checks if c.get("status") == "WARN")
        failed = sum(1 for c in checks if c.get("status") == "FAIL")
        report += f"| 通过检查 | {passed} |\n"
        report += f"| 警告 | {warned} |\n"
        report += f"| 失败 | {failed} |\n\n"
        
        warnings = npc_data.get("warnings", [])
        if warnings:
            report += "**警告**:\n\n"
            for w in warnings:
                report += f"- {w}\n"
            report += "\n"
    
    # 运行时警告汇总
    all_warnings = runtime.get("warnings", [])
    if all_warnings:
        report += f"""### 2.3 运行时警告汇总

"""
        for w in all_warnings:
            report += f"- {w}\n"
        report += "\n"
    
    report += f"""---

## 3. 问题修复建议

### 优先级高（影响功能）

"""
    
    # 根据发现的问题生成修复建议
    suggestions = []
    
    if error_summary.get('unreachable_nodes', 0) > 0:
        for err in checks.get('unreachable_nodes', []):
            suggestions.append({
                "priority": "高",
                "problem": f"节点 `{err.get('npc_id')}.{err.get('node_id')}` 从起始节点不可达",
                "suggestion": "检查该节点是否需要通过特定条件解锁，或将其添加为起始节点/连接到对话树中"
            })
    
    if error_summary.get('missing_content', 0) > 0:
        for err in checks.get('missing_content', []):
            suggestions.append({
                "priority": "高",
                "problem": f"节点 `{err.get('npc_id')}.{err.get('node_id')}` 没有对话内容",
                "suggestion": "在 dialogue_lines.csv 中为该节点添加对话文本"
            })
    
    if error_summary.get('goto_targets', 0) > 0:
        for err in checks.get('goto_targets', []):
            suggestions.append({
                "priority": "高",
                "problem": f"goto 目标缺失: {err.get('message', '')}",
                "suggestion": "检查 goto 引用的节点 ID 是否存在于 dialogue_nodes.csv 中"
            })
    
    if runtime.get('warning_count', 0) > 0:
        for w in all_warnings:
            suggestions.append({
                "priority": "中",
                "problem": f"未知条件类型: {w}",
                "suggestion": "检查 CaseTableLoader 是否支持该条件类型，或修正条件 DSL"
            })
    
    if not suggestions:
        report += "未发现需要修复的问题。\n\n"
    else:
        for i, s in enumerate(suggestions, 1):
            report += f"#### {i}. [{s['priority']}] {s['problem']}\n\n"
            report += f"**建议**: {s['suggestion']}\n\n"
    
    report += f"""---

## 4. 测试配置

- **静态分析器**: `tools/regression/analyze_dialogue_paths.py`
- **运行时测试器**: `tools/regression/dialogue_path_tester.gd`
- **报告生成器**: `tools/regression/generate_final_report.py`
- **MCP 工具**: `godot-mcp-pro.execute_game_script`

---

## 附录

### 测试的 NPC 列表

"""
    
    for npc_id in npc_stats.keys():
        report += f"- `{npc_id}`\n"
    
    report += f"""
### 数据文件

- `data/case_tables/{case_id}/dialogue_nodes.csv`
- `data/case_tables/{case_id}/dialogue_options.csv`
- `data/case_tables/{case_id}/dialogue_lines.csv`

---

*报告由对话路径测试工具自动生成 — {timestamp}*
"""
    
    return report


def main():
    if len(sys.argv) < 2:
        print("用法: python3 generate_final_report.py <case_id> [runtime_json_string]")
        sys.exit(1)
    
    case_id = sys.argv[1]
    
    # 加载静态分析
    static = load_static_analysis(case_id)
    if not static:
        print(f"警告: 未找到静态分析报告 for {case_id}", file=sys.stderr)
        static = {"stats": {}, "error_summary": {}, "checks": {}, "total_errors": 0}
    
    # 解析运行时测试结果
    runtime = {
        "case_id": case_id,
        "npc_count": 0,
        "npc_results": {},
        "path_count": 0,
        "error_count": 0,
        "warning_count": 0,
        "test_status": "UNKNOWN",
        "warnings": []
    }
    
    if len(sys.argv) > 2:
        runtime_json_str = sys.argv[2]
        if runtime_json_str == "--from-file" and len(sys.argv) > 3:
            with open(sys.argv[3], 'r', encoding='utf-8') as f:
                runtime_output = json.load(f)
        else:
            # 直接解析 JSON 数组
            runtime_output = json.loads(runtime_json_str)
        
        if isinstance(runtime_output, list):
            runtime = parse_runtime_output(runtime_output)
        elif isinstance(runtime_output, dict) and "output" in runtime_output:
            runtime = parse_runtime_output(runtime_output["output"])
    
    # 生成报告
    report = generate_final_report(static, runtime, case_id)
    
    # 保存报告
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = REPORTS_DIR / f"final_report_{case_id}_{timestamp}.md"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"最终报告已生成: {report_file}")
    
    # 也保存合并的 JSON 结果
    json_file = REPORTS_DIR / f"final_results_{case_id}.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump({
            "static_analysis": static,
            "runtime_test": runtime,
            "timestamp": datetime.now().isoformat()
        }, f, ensure_ascii=False, indent=2)
    
    print(f"合并结果已保存: {json_file}")


if __name__ == "__main__":
    main()
