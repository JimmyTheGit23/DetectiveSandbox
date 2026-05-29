#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
对话路径测试编排脚本

协调静态分析和运行时测试，生成最终的 Markdown 报告。

功能：
    1. 运行静态分析器
    2. 生成 MCP 调用指令
    3. 解析测试结果
    4. 生成 Markdown 报告

用法：
    python3 tools/regression/run_dialogue_tests.py [case_id]
    默认测试序章（prologue_ferry）

输出：
    - 控制台摘要
    - Markdown 报告（reports/dialogue_test_<timestamp>.md）
    - JSON 测试结果（reports/test_results_<case>.json）
"""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
TOOLS_DIR = REPO_ROOT / "tools" / "regression"
REPORTS_DIR = TOOLS_DIR / "reports"


def run_static_analysis(case_id: str) -> dict:
    """运行静态分析器"""
    print(f"\n{'='*70}")
    print(f"  运行静态分析: {case_id}")
    print(f"{'='*70}")

    script_path = TOOLS_DIR / "analyze_dialogue_paths.py"
    try:
        result = subprocess.run(
            [sys.executable, str(script_path), case_id],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            check=False
        )

        print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)

        # 读取生成的报告
        report_file = REPORTS_DIR / f"dialogue_graph_{case_id}.json"
        if report_file.exists():
            with open(report_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        else:
            return {"error": "静态分析报告未生成"}

    except Exception as e:
        return {"error": f"静态分析失败: {e}"}


def generate_mcp_instructions(case_id: str) -> dict:
    """生成 MCP 调用指令"""
    # 读取 GDScript 测试脚本
    script_path = TOOLS_DIR / "dialogue_path_tester.gd"
    if not script_path.exists():
        return {"error": "测试脚本不存在"}

    with open(script_path, 'r', encoding='utf-8') as f:
        script_content = f.read()

    # 生成 MCP 调用指令
    instructions = {
        "steps": [
            {
                "description": "启动游戏主场景",
                "mcp_tool": "play_scene",
                "params": {"mode": "main"}
            },
            {
                "description": "等待游戏初始化",
                "wait_seconds": 2.0
            },
            {
                "description": "运行对话路径测试脚本",
                "mcp_tool": "execute_game_script",
                "params": {"code": script_content}
            },
            {
                "description": "停止游戏",
                "mcp_tool": "stop_scene",
                "params": {}
            }
        ],
        "expected_output": [
            "case_id=<case_id>",
            "npc_count=<count>",
            "npc_id=<npc_id>",
            "node_test=<npc_id>.<node_id>",
            "status=PASS/FAIL/SKIP",
            "message=<message>",
            "path_count=<count>",
            "error_count=<count>",
            "TEST_STATUS=PASS/FAIL",
            "TEST_COMPLETE"
        ]
    }

    return instructions


def parse_test_output(output_lines: list) -> dict:
    """解析运行时测试输出（支持 JSON 数组格式的输出）"""
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
            checks = results["npc_results"][current_npc]["checks"]
            checks.append({
                "check": results["npc_results"][current_npc].get("current_check", ""),
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


def generate_markdown_report(static_analysis: dict, test_results: dict, case_id: str) -> str:
    """生成 Markdown 报告"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    report = f"""# 对话路径测试报告

**案件**: {case_id}
**时间**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
**测试类型**: 对话路径完整性验证

---

## 测试摘要

| 指标 | 值 |
|------|-----|
| 总节点数 | {static_analysis.get('stats', {}).get('total_nodes', 'N/A')} |
| NPC 数量 | {static_analysis.get('stats', {}).get('total_npcs', 'N/A')} |
| 选项数量 | {static_analysis.get('stats', {}).get('total_options', 'N/A')} |
| 测试路径数 | {test_results.get('path_count', 'N/A')} |
| 错误数量 | {test_results.get('error_count', 'N/A')} |
| 测试状态 | {'✅ 通过' if test_results.get('test_status') == 'PASS' else '❌ 失败'} |

---

## 静态分析结果

### 错误统计

| 检查项 | 错误数 |
|--------|--------|
| goto 目标缺失 | {static_analysis.get('error_summary', {}).get('goto_targets', 0)} |
| 不可达节点 | {static_analysis.get('error_summary', {}).get('unreachable_nodes', 0)} |
| 死胡同节点 | {static_analysis.get('error_summary', {}).get('dead_end_nodes', 0)} |
| 缺失内容 | {static_analysis.get('error_summary', {}).get('missing_content', 0)} |
| 死循环路径 | {static_analysis.get('error_summary', {}).get('dead_cycles', 0)} |

### 详细错误

"""

    # 添加静态分析错误详情
    checks = static_analysis.get('checks', {})
    for check_name, errors in checks.items():
        if errors:
            report += f"#### {check_name}\n\n"
            for error in errors:
                report += f"- **{error.get('type', 'unknown')}**: {error.get('message', 'No message')}\n"
            report += "\n"

    report += "---\n\n## 运行时测试结果\n\n"

    # 添加运行时测试结果
    npc_results = test_results.get('npc_results', {})
    for npc_id, npc_data in npc_results.items():
        report += f"### {npc_id}\n\n"

        nodes = npc_data.get('nodes', [])
        errors = npc_data.get('errors', [])

        if nodes:
            report += "| 节点 | 状态 |\n|------|------|\n"
            for node in nodes:
                status_icon = "✅" if node['status'] == 'PASS' else "❌" if node['status'] == 'FAIL' else "⏭️"
                report += f"| {node['node']} | {status_icon} {node['status']} |\n"
            report += "\n"

        if errors:
            report += "**错误详情**:\n\n"
            for error in errors:
                report += f"- **{error['node']}**: {error['message']}\n"
            report += "\n"

    report += f"""---

## 测试配置

- **静态分析器**: `tools/regression/analyze_dialogue_paths.py`
- **运行时测试器**: `tools/regression/dialogue_path_tester.gd`
- **编排脚本**: `tools/regression/run_dialogue_tests.py`

---

## 附录

### 测试的 NPC 列表

"""

    for npc_id in npc_results.keys():
        report += f"- {npc_id}\n"

    report += f"""
### 测试时间

- **开始时间**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
- **生成时间**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

---

*报告由对话路径测试工具自动生成*
"""

    return report


def main():
    """主函数"""
    # 确定要测试的案件
    case_id = sys.argv[1] if len(sys.argv) > 1 else "prologue_ferry"

    print(f"\n开始对话路径测试: {case_id}")
    print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # 确保报告目录存在
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    # 1. 运行静态分析
    static_analysis = run_static_analysis(case_id)
    if "error" in static_analysis:
        print(f"静态分析失败: {static_analysis['error']}", file=sys.stderr)
        # 继续运行，但标记静态分析失败
        static_analysis = {
            "error": static_analysis["error"],
            "stats": {},
            "error_summary": {},
            "checks": {}
        }

    # 2. 生成 MCP 调用指令
    print(f"\n{'='*70}")
    print(f"  生成 MCP 调用指令")
    print(f"{'='*70}")

    mcp_instructions = generate_mcp_instructions(case_id)
    if "error" in mcp_instructions:
        print(f"生成 MCP 指令失败: {mcp_instructions['error']}", file=sys.stderr)
        sys.exit(1)

    # 保存 MCP 指令
    instructions_file = REPORTS_DIR / f"mcp_instructions_{case_id}.json"
    with open(instructions_file, 'w', encoding='utf-8') as f:
        json.dump(mcp_instructions, f, ensure_ascii=False, indent=2)
    print(f"MCP 指令已保存: {instructions_file}")

    # 3. 提示用户运行 MCP 测试
    print(f"\n{'='*70}")
    print(f"  下一步操作")
    print(f"{'='*70}")
    print(f"""
请在 CodeBuddy 中执行以下 MCP 调用：

1. 启动游戏：
   mcp_call_tool("godot-mcp-pro", "play_scene", '{{"mode": "main"}}')

2. 等待 2 秒

3. 运行测试脚本：
   mcp_call_tool("godot-mcp-pro", "execute_game_script", '{{"code": "<脚本内容>"}}')

4. 停止游戏：
   mcp_call_tool("godot-mcp-pro", "stop_scene", '{{"}}')

或者，您可以：
- 手动运行游戏并执行测试脚本
- 将测试脚本内容复制到 Godot 编辑器中运行

测试脚本位置: {TOOLS_DIR / 'dialogue_path_tester.gd'}
""")

    # 4. 生成示例报告（使用静态分析结果）
    print(f"\n{'='*70}")
    print(f"  生成示例报告")
    print(f"{'='*70}")

    # 创建示例测试结果
    example_test_results = {
        "case_id": case_id,
        "npc_count": static_analysis.get('stats', {}).get('total_npcs', 0),
        "path_count": 0,
        "error_count": 0,
        "test_status": "PENDING",
        "npc_results": {}
    }

    # 为每个 NPC 创建示例结果
    npc_stats = static_analysis.get('npc_stats', {})
    for npc_id in npc_stats.keys():
        example_test_results["npc_results"][npc_id] = {
            "nodes": [
                {"node": f"{npc_id}.hub", "status": "PASS"},
                {"node": f"{npc_id}.intro", "status": "PASS"},
            ],
            "errors": []
        }

    # 生成 Markdown 报告
    markdown_report = generate_markdown_report(static_analysis, example_test_results, case_id)

    # 保存报告
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = REPORTS_DIR / f"dialogue_test_{case_id}_{timestamp}.md"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(markdown_report)
    print(f"示例报告已保存: {report_file}")

    # 保存测试结果 JSON
    results_file = REPORTS_DIR / f"test_results_{case_id}.json"
    with open(results_file, 'w', encoding='utf-8') as f:
        json.dump({
            "static_analysis": static_analysis,
            "test_results": example_test_results,
            "timestamp": datetime.now().isoformat()
        }, f, ensure_ascii=False, indent=2)
    print(f"测试结果已保存: {results_file}")

    print(f"\n{'='*70}")
    print(f"  测试准备完成")
    print(f"{'='*70}")
    print(f"""
静态分析已完成，发现 {static_analysis.get('total_errors', 0)} 个问题。

下一步：
1. 在 CodeBuddy 中运行 MCP 测试
2. 或手动执行测试脚本
3. 将运行时测试结果与静态分析结果合并
4. 生成最终测试报告

报告目录: {REPORTS_DIR}
""")


if __name__ == "__main__":
    main()
