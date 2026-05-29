#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
端到端集成测试

验证对话路径测试工具的完整流程。

功能：
    1. 测试静态分析器
    2. 测试 MCP 指令生成
    3. 测试报告生成
    4. 验证所有组件协同工作

用法：
    python3 tools/regression/test_integration.py
"""

from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
TOOLS_DIR = REPO_ROOT / "tools" / "regression"
REPORTS_DIR = TOOLS_DIR / "reports"


def test_static_analyzer():
    """测试静态分析器"""
    print("\n测试静态分析器...")

    # 导入静态分析器
    sys.path.insert(0, str(TOOLS_DIR))
    try:
        from analyze_dialogue_paths import build_dialogue_graph, check_goto_targets, check_unreachable_nodes

        # 测试序章数据
        graph = build_dialogue_graph("prologue_ferry")

        # 验证基本结构
        assert len(graph.nodes) > 0, "对话图不应为空"
        assert len(graph.npc_start_nodes) > 0, "应有起始节点"
        assert len(graph.all_flags) > 0, "应有标志位"

        # 运行检查
        goto_errors = check_goto_targets(graph)
        unreachable_errors = check_unreachable_nodes(graph)

        print(f"  ✓ 静态分析器测试通过")
        print(f"    - 节点数: {len(graph.nodes)}")
        print(f"    - NPC 数: {len(graph.npc_start_nodes)}")
        print(f"    - goto 错误: {len(goto_errors)}")
        print(f"    - 不可达节点: {len(unreachable_errors)}")

        return True

    except Exception as e:
        print(f"  ✗ 静态分析器测试失败: {e}")
        return False


def test_mcp_instruction_generation():
    """测试 MCP 指令生成"""
    print("\n测试 MCP 指令生成...")

    # 导入编排脚本
    try:
        from run_dialogue_tests import generate_mcp_instructions

        instructions = generate_mcp_instructions("prologue_ferry")

        # 验证结构
        assert "steps" in instructions, "应有 steps 字段"
        assert "expected_output" in instructions, "应有 expected_output 字段"
        assert len(instructions["steps"]) > 0, "步骤不应为空"

        # 验证每个步骤
        for step in instructions["steps"]:
            assert "description" in step, "步骤应有描述"
            if "mcp_tool" in step:
                assert "params" in step, "MCP 工具步骤应有参数"

        print(f"  ✓ MCP 指令生成测试通过")
        print(f"    - 步骤数: {len(instructions['steps'])}")
        print(f"    - 期望输出字段: {len(instructions['expected_output'])}")

        return True

    except Exception as e:
        print(f"  ✗ MCP 指令生成测试失败: {e}")
        return False


def test_report_generation():
    """测试报告生成"""
    print("\n测试报告生成...")

    # 导入编排脚本
    try:
        from run_dialogue_tests import generate_markdown_report, run_static_analysis

        # 运行静态分析
        static_analysis = run_static_analysis("prologue_ferry")

        # 创建测试结果
        test_results = {
            "case_id": "prologue_ferry",
            "npc_count": 6,
            "path_count": 100,
            "error_count": 0,
            "test_status": "PASS",
            "npc_results": {
                "agui": {
                    "nodes": [
                        {"node": "agui.hub", "status": "PASS"},
                        {"node": "agui.intro", "status": "PASS"},
                    ],
                    "errors": []
                }
            }
        }

        # 生成报告
        report = generate_markdown_report(static_analysis, test_results, "prologue_ferry")

        # 验证报告内容
        assert "# 对话路径测试报告" in report, "报告应有标题"
        assert "prologue_ferry" in report, "报告应包含案件 ID"
        assert "测试摘要" in report, "报告应有摘要部分"
        assert "静态分析结果" in report, "报告应有静态分析结果"
        assert "运行时测试结果" in report, "报告应有运行时测试结果"

        print(f"  ✓ 报告生成测试通过")
        print(f"    - 报告长度: {len(report)} 字符")
        print(f"    - 包含章节: 测试摘要、静态分析结果、运行时测试结果")

        return True

    except Exception as e:
        print(f"  ✗ 报告生成测试失败: {e}")
        return False


def test_output_parsing():
    """测试输出解析"""
    print("\n测试输出解析...")

    # 导入编排脚本
    try:
        from run_dialogue_tests import parse_test_output

        # 模拟测试输出
        sample_output = """
case_id=prologue_ferry
npc_count=6
npc_id=agui
node_test=agui.hub
status=PASS
message=exit_option
node_test=agui.intro
status=PASS
message=exit_option
npc_complete=agui
path_count=100
error_count=0
TEST_STATUS=PASS
TEST_COMPLETE
"""

        # 解析输出
        results = parse_test_output(sample_output)

        # 验证解析结果
        assert results["case_id"] == "prologue_ferry", "应正确解析 case_id"
        assert results["npc_count"] == 6, "应正确解析 npc_count"
        assert results["path_count"] == 100, "应正确解析 path_count"
        assert results["error_count"] == 0, "应正确解析 error_count"
        assert results["test_status"] == "PASS", "应正确解析 TEST_STATUS"
        assert "agui" in results["npc_results"], "应包含 NPC 结果"

        print(f"  ✓ 输出解析测试通过")
        print(f"    - 解析 case_id: {results['case_id']}")
        print(f"    - 解析 npc_count: {results['npc_count']}")
        print(f"    - 解析 path_count: {results['path_count']}")
        print(f"    - 解析 test_status: {results['test_status']}")

        return True

    except Exception as e:
        print(f"  ✗ 输出解析测试失败: {e}")
        return False


def test_file_structure():
    """测试文件结构"""
    print("\n测试文件结构...")

    required_files = [
        "analyze_dialogue_paths.py",
        "dialogue_path_tester.gd",
        "run_dialogue_tests.py",
        "runtime_check.gd",
    ]

    missing_files = []
    for file_name in required_files:
        file_path = TOOLS_DIR / file_name
        if not file_path.exists():
            missing_files.append(file_name)

    if missing_files:
        print(f"  ✗ 文件结构测试失败")
        print(f"    - 缺失文件: {', '.join(missing_files)}")
        return False

    print(f"  ✓ 文件结构测试通过")
    print(f"    - 所有必需文件存在")
    for file_name in required_files:
        print(f"      - {file_name}")

    return True


def main():
    """主函数"""
    print(f"\n{'='*70}")
    print(f"  对话路径测试工具 - 端到端集成测试")
    print(f"{'='*70}")
    print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # 确保报告目录存在
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    # 运行所有测试
    tests = [
        ("文件结构", test_file_structure),
        ("静态分析器", test_static_analyzer),
        ("MCP 指令生成", test_mcp_instruction_generation),
        ("报告生成", test_report_generation),
        ("输出解析", test_output_parsing),
    ]

    results = []
    for test_name, test_func in tests:
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"  ✗ {test_name} 测试异常: {e}")
            results.append((test_name, False))

    # 打印总结
    print(f"\n{'='*70}")
    print(f"  测试总结")
    print(f"{'='*70}")

    passed = sum(1 for _, success in results if success)
    total = len(results)

    for test_name, success in results:
        status = "✓ 通过" if success else "✗ 失败"
        print(f"  {status} - {test_name}")

    print(f"\n总计: {passed}/{total} 测试通过")

    if passed == total:
        print(f"\n🎉 所有测试通过！工具已准备就绪。")
        print(f"\n使用方法:")
        print(f"  1. 运行完整测试: python3 tools/regression/run_dialogue_tests.py prologue_ferry")
        print(f"  2. 只运行静态分析: python3 tools/regression/analyze_dialogue_paths.py prologue_ferry")
        print(f"  3. 查看报告: tools/regression/reports/")
        return 0
    else:
        print(f"\n❌ {total - passed} 个测试失败，请检查问题。")
        return 1


if __name__ == "__main__":
    sys.exit(main())
