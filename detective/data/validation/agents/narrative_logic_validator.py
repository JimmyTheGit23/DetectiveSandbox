#!/usr/bin/env python3
"""
剧情逻辑验证Agent
验证对话流程、事件触发条件、flag逻辑、证据链的一致性
"""

import os
import re
import csv
import json
import yaml
from pathlib import Path
from typing import Dict, List, Set, Tuple, Any, Optional
from dataclasses import dataclass, field
from enum import Enum


class Severity(Enum):
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"


@dataclass
class ValidationResult:
    severity: Severity
    message: str
    file: str
    line: int
    details: str


@dataclass
class FlagInfo:
    name: str
    set_locations: List[Tuple[str, int]] = field(default_factory=list)
    check_locations: List[Tuple[str, int]] = field(default_factory=list)


@dataclass
class NodeInfo:
    node_id: str
    next_node: Optional[str] = None
    is_end: bool = False
    is_choice: bool = False
    choices: List[str] = field(default_factory=list)
    file: str = ""
    line: int = 0


class NarrativeLogicValidator:
    """剧情逻辑验证器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.validation_dir = self.project_root / "data" / "validation"
        self.results: List[ValidationResult] = []
        self.rules = self._load_rules()
        self.flags: Dict[str, FlagInfo] = {}
        self.nodes: Dict[str, NodeInfo] = {}
        self.runtime_flags = self._load_runtime_flags()
        
    def _load_rules(self) -> Dict:
        """加载规则配置"""
        rules_file = self.validation_dir / "narrative_logic_rules.yaml"
        with open(rules_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    def _load_runtime_flags(self) -> Set[str]:
        """加载运行时flag列表"""
        runtime_flags_file = self.validation_dir / "runtime_flags.yaml"
        if runtime_flags_file.exists():
            with open(runtime_flags_file, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
                return set(config.get('runtime_flags', {}).keys())
        return set()
    
    def _add_result(self, severity: Severity, message: str, file: str, line: int, details: str = ""):
        """添加检查结果"""
        self.results.append(ValidationResult(
            severity=severity,
            message=message,
            file=file,
            line=line,
            details=details
        ))
    
    def _collect_flags(self, case_dir: Path):
        """收集所有flag定义和使用"""
        self.flags.clear()
        
        # 检查dialogue_nodes中的set_flag
        dialogue_nodes_file = case_dir / "dialogue_nodes.csv"
        if dialogue_nodes_file.exists():
            with open(dialogue_nodes_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    # 检查set_flags列（复数）和set_flag列（单数）
                    set_flags_value = row.get('set_flags', '') or row.get('set_flag', '')
                    if set_flags_value:
                        flags = set_flags_value.split(';')
                        for flag in flags:
                            flag = flag.strip()
                            if flag:
                                if flag not in self.flags:
                                    self.flags[flag] = FlagInfo(name=flag)
                                self.flags[flag].set_locations.append((str(dialogue_nodes_file), line_num))
        
        # 检查dialogue_options中的requires
        dialogue_options_file = case_dir / "dialogue_options.csv"
        if dialogue_options_file.exists():
            with open(dialogue_options_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    if 'requires' in row and row['requires']:
                        try:
                            requires = json.loads(row['requires'])
                            self._extract_flags_from_requires(requires, str(dialogue_options_file), line_num)
                        except:
                            pass
        
        # 检查day_events中的set_flag（在effects列中）
        day_events_file = case_dir / "day_events.csv"
        if day_events_file.exists():
            with open(day_events_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    # effects列包含JSON格式的set_flag信息
                    effects_value = row.get('effects', '')
                    if effects_value:
                        try:
                            effects = json.loads(effects_value)
                            # effects可能是对象或数组
                            if isinstance(effects, dict):
                                set_flags = effects.get('set_flag', [])
                                if isinstance(set_flags, list):
                                    for flag in set_flags:
                                        if flag not in self.flags:
                                            self.flags[flag] = FlagInfo(name=flag)
                                        self.flags[flag].set_locations.append((str(day_events_file), line_num))
                                elif isinstance(set_flags, str):
                                    if set_flags not in self.flags:
                                        self.flags[set_flags] = FlagInfo(name=set_flags)
                                    self.flags[set_flags].set_locations.append((str(day_events_file), line_num))
                            elif isinstance(effects, list):
                                for effect in effects:
                                    if isinstance(effect, dict):
                                        set_flags = effect.get('set_flag', [])
                                        if isinstance(set_flags, list):
                                            for flag in set_flags:
                                                if flag not in self.flags:
                                                    self.flags[flag] = FlagInfo(name=flag)
                                                self.flags[flag].set_locations.append((str(day_events_file), line_num))
                        except:
                            pass
    
    def _extract_flags_from_requires(self, requires: Any, file: str, line: int):
        """从requires条件中提取flag"""
        if isinstance(requires, dict):
            for key, value in requires.items():
                if key in ['flag', 'not_flag']:
                    flag_name = value if isinstance(value, str) else value.get('flag', '')
                    if flag_name:
                        if flag_name not in self.flags:
                            self.flags[flag_name] = FlagInfo(name=flag_name)
                        self.flags[flag_name].check_locations.append((file, line))
                elif key in ['all', 'any', 'not']:
                    if isinstance(value, list):
                        for item in value:
                            self._extract_flags_from_requires(item, file, line)
                    elif isinstance(value, dict):
                        self._extract_flags_from_requires(value, file, line)
        elif isinstance(requires, list):
            for item in requires:
                self._extract_flags_from_requires(item, file, line)
    
    def _collect_nodes(self, case_dir: Path):
        """收集所有节点定义"""
        self.nodes.clear()
        
        # 检查prologue_nodes
        prologue_nodes_file = case_dir / "prologue_nodes.csv"
        if prologue_nodes_file.exists():
            with open(prologue_nodes_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    node_id = row.get('node_id', '')
                    if node_id:
                        node_info = NodeInfo(
                            node_id=node_id,
                            next_node=row.get('next') or None,
                            is_end=row.get('end', '').lower() == 'true',
                            file=str(prologue_nodes_file),
                            line=line_num
                        )
                        self.nodes[node_id] = node_info
        
        # 检查prologue_choices
        prologue_choices_file = case_dir / "prologue_choices.csv"
        if prologue_choices_file.exists():
            with open(prologue_choices_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    node_id = row.get('node_id', '')
                    goto = row.get('goto', '')
                    if node_id and goto:
                        if node_id in self.nodes:
                            self.nodes[node_id].is_choice = True
                            self.nodes[node_id].choices.append(goto)
                        else:
                            self.nodes[node_id] = NodeInfo(
                                node_id=node_id,
                                is_choice=True,
                                choices=[goto],
                                file=str(prologue_choices_file),
                                line=line_num
                            )
    
    def check_flag_logic(self, case_dir: Path):
        """检查flag逻辑"""
        print("  检查flag逻辑...")
        
        # 收集所有flag
        self._collect_flags(case_dir)
        
        # 检查：set_flag的flag是否在requires中被使用
        for flag_name, flag_info in self.flags.items():
            # 跳过运行时flag
            if flag_name in self.runtime_flags:
                continue
            
            if flag_info.set_locations and not flag_info.check_locations:
                self._add_result(
                    Severity.WARNING,
                    f"Flag被设置但从未被检查: {flag_name}",
                    flag_info.set_locations[0][0],
                    flag_info.set_locations[0][1],
                    "可能是一个未使用的flag"
                )
            elif flag_info.check_locations and not flag_info.set_locations:
                self._add_result(
                    Severity.ERROR,
                    f"Flag被检查但从未被设置: {flag_name}",
                    flag_info.check_locations[0][0],
                    flag_info.check_locations[0][1],
                    "这个flag永远不会被设置，导致条件永远不满足。如果这是运行时flag，请添加到runtime_flags.yaml"
                )
    
    def check_dialogue_flow(self, case_dir: Path):
        """检查对话流程"""
        print("  检查对话流程...")
        
        # 收集所有节点
        self._collect_nodes(case_dir)
        
        # 检查：next指向的节点是否存在
        for node_id, node_info in self.nodes.items():
            if node_info.next_node and node_info.next_node not in self.nodes:
                self._add_result(
                    Severity.ERROR,
                    f"节点指向不存在的节点: {node_id} -> {node_info.next_node}",
                    node_info.file,
                    node_info.line
                )
        
        # 检查：choice指向的节点是否存在
        for node_id, node_info in self.nodes.items():
            if node_info.is_choice:
                for choice in node_info.choices:
                    if choice not in self.nodes:
                        self._add_result(
                            Severity.ERROR,
                            f"选项指向不存在的节点: {node_id} -> {choice}",
                            node_info.file,
                            node_info.line
                        )
        
        # 检查：是否有孤立节点
        self._check_orphan_nodes()
    
    def _check_orphan_nodes(self):
        """检查孤立节点"""
        # 找到start节点
        start_nodes = set()
        for node_id, node_info in self.nodes.items():
            if 'prologue_1' in node_id or node_id.startswith('cabin_prologue'):
                start_nodes.add(node_id)
        
        if not start_nodes:
            self._add_result(
                Severity.WARNING,
                "未找到明确的start节点",
                "",
                0
            )
            return
        
        # BFS遍历所有可达节点
        visited = set()
        queue = list(start_nodes)
        
        while queue:
            current = queue.pop(0)
            if current in visited:
                continue
            
            visited.add(current)
            
            if current in self.nodes:
                node_info = self.nodes[current]
                
                # 添加next节点
                if node_info.next_node and node_info.next_node not in visited:
                    queue.append(node_info.next_node)
                
                # 添加choice节点
                for choice in node_info.choices:
                    if choice not in visited:
                        queue.append(choice)
        
        # 检查未访问的节点
        for node_id in self.nodes:
            if node_id not in visited:
                self._add_result(
                    Severity.WARNING,
                    f"孤立节点（无法从start到达）: {node_id}",
                    self.nodes[node_id].file,
                    self.nodes[node_id].line
                )
    
    def check_event_triggers(self, case_dir: Path):
        """检查事件触发条件"""
        print("  检查事件触发条件...")
        
        # 加载事件规则
        event_rules = self.rules.get('event_triggers', {})
        dependencies = event_rules.get('dependencies', {})
        
        # 检查day_events
        day_events_file = case_dir / "day_events.csv"
        if day_events_file.exists():
            with open(day_events_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    event_id = row.get('event_id', '')
                    requires = row.get('requires', '')
                    
                    if event_id in dependencies:
                        expected_requires = dependencies[event_id].get('requires', [])
                        
                        # 检查requires是否包含所有必要的依赖
                        for dep in expected_requires:
                            if dep not in requires:
                                self._add_result(
                                    Severity.WARNING,
                                    f"事件可能缺少依赖: {event_id}",
                                    str(day_events_file),
                                    line_num,
                                    f"建议添加依赖: {dep}"
                                )
    
    def check_evidence_chain(self, case_dir: Path):
        """检查证据链"""
        print("  检查证据链...")
        
        # 加载证据规则
        evidence_rules = self.rules.get('evidence_chain', {})
        acquisition_order = evidence_rules.get('acquisition_order', [])
        
        # 检查evidence.json
        evidence_file = case_dir.parent / "cases" / case_dir.name / "evidence.json"
        if evidence_file.exists():
            with open(evidence_file, 'r', encoding='utf-8') as f:
                evidence_data = json.load(f)
                
                # 收集所有证据ID
                evidence_ids = set()
                for evidence in evidence_data.get('evidence', []):
                    evidence_ids.add(evidence.get('id', ''))
                
                # 检查质询所需证据是否存在
                confrontation_reqs = evidence_rules.get('confrontation_requirements', {})
                for confrontation, reqs in confrontation_reqs.items():
                    required = reqs.get('required_evidence', [])
                    for evidence_id in required:
                        if evidence_id not in evidence_ids:
                            self._add_result(
                                Severity.ERROR,
                                f"质询所需证据不存在: {evidence_id}",
                                str(evidence_file),
                                0,
                                f"质询 {confrontation} 需要此证据"
                            )
    
    def check_progression(self, case_dir: Path):
        """检查进度系统"""
        print("  检查进度系统...")
        
        # 检查progression.json
        progression_file = case_dir.parent / "cases" / case_dir.name / "progression.json"
        if progression_file.exists():
            with open(progression_file, 'r', encoding='utf-8') as f:
                progression_data = json.load(f)
                
                # 检查阶段解锁条件
                phases = progression_data.get('phases', {})
                for phase_name, phase_data in phases.items():
                    requires = phase_data.get('requires', [])
                    
                    # 检查是否有死锁
                    self._check_deadlock(phase_name, requires, phases)
    
    def _check_deadlock(self, phase_name: str, requires: List[str], all_phases: Dict):
        """检查是否有死锁"""
        # 简单的死锁检查：如果A依赖B，B依赖A，则有死锁
        for req in requires:
            if req in all_phases:
                req_requires = all_phases[req].get('requires', [])
                if phase_name in req_requires:
                    self._add_result(
                        Severity.ERROR,
                        f"检测到死锁: {phase_name} <-> {req}",
                        "",
                        0,
                        "两个阶段相互依赖，导致永远无法解锁"
                    )
    
    def check_case(self, case_name: str):
        """检查单个案件"""
        case_dir = self.project_root / "data" / "case_tables" / case_name
        
        if not case_dir.exists():
            self._add_result(
                Severity.ERROR,
                f"案件目录不存在: {case_name}",
                str(case_dir),
                0
            )
            return
        
        print(f"\n检查案件剧情逻辑: {case_name}")
        print("-" * 50)
        
        self.check_flag_logic(case_dir)
        self.check_dialogue_flow(case_dir)
        self.check_event_triggers(case_dir)
        self.check_evidence_chain(case_dir)
        self.check_progression(case_dir)
    
    def generate_report(self) -> str:
        """生成检查报告"""
        report = []
        report.append("# 剧情逻辑验证报告")
        report.append("")
        
        # 统计
        errors = [r for r in self.results if r.severity == Severity.ERROR]
        warnings = [r for r in self.results if r.severity == Severity.WARNING]
        
        report.append(f"## 检查总结")
        report.append(f"- 错误: {len(errors)}")
        report.append(f"- 警告: {len(warnings)}")
        report.append("")
        
        # 错误详情
        if errors:
            report.append("## 错误")
            for error in errors:
                report.append(f"- **{error.message}**")
                report.append(f"  文件: {error.file}")
                if error.line > 0:
                    report.append(f"  行号: {error.line}")
                if error.details:
                    report.append(f"  详情: {error.details}")
                report.append("")
        
        # 警告详情
        if warnings:
            report.append("## 警告")
            for warning in warnings:
                report.append(f"- {warning.message}")
                report.append(f"  文件: {warning.file}")
                if warning.line > 0:
                    report.append(f"  行号: {warning.line}")
                report.append("")
        
        # Flag统计
        if self.flags:
            report.append("## Flag统计")
            report.append(f"总Flag数: {len(self.flags)}")
            report.append("")
            report.append("| Flag名称 | 设置位置数 | 检查位置数 |")
            report.append("|---------|-----------|-----------|")
            for flag_name, flag_info in sorted(self.flags.items()):
                report.append(f"| {flag_name} | {len(flag_info.set_locations)} | {len(flag_info.check_locations)} |")
            report.append("")
        
        return "\n".join(report)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="剧情逻辑验证")
    parser.add_argument("--project-root", default="/Users/zhoujiong/Documents/UGit/DetectiveSandbox/detective",
                       help="项目根目录")
    parser.add_argument("--case", help="指定检查的案件名称")
    parser.add_argument("--output", help="输出报告文件路径")
    
    args = parser.parse_args()
    
    validator = NarrativeLogicValidator(args.project_root)
    
    if args.case:
        validator.check_case(args.case)
    else:
        # 检查所有案件
        case_tables_dir = Path(args.project_root) / "data" / "case_tables"
        for case_dir in case_tables_dir.iterdir():
            if case_dir.is_dir() and not case_dir.name.startswith('_'):
                validator.check_case(case_dir.name)
    
    report = validator.generate_report()
    
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"\n报告已保存到: {args.output}")
    else:
        print("\n" + report)


if __name__ == "__main__":
    main()
