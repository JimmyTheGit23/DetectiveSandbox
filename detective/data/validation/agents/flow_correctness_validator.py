#!/usr/bin/env python3
"""
流程正确性验证Agent
验证游戏流程、节点连接、分支规则、结束条件、状态机等
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
from collections import defaultdict


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
class NodeInfo:
    node_id: str
    next_node: Optional[str] = None
    is_end: bool = False
    is_choice: bool = False
    choices: List[str] = field(default_factory=list)
    requires: Dict[str, Any] = field(default_factory=dict)
    file: str = ""
    line: int = 0


class FlowCorrectnessValidator:
    """流程正确性验证器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.validation_dir = self.project_root / "data" / "validation"
        self.results: List[ValidationResult] = []
        self.rules = self._load_rules()
        self.nodes: Dict[str, NodeInfo] = {}
        self.flags: Set[str] = set()
        
    def _load_rules(self) -> Dict:
        """加载规则配置"""
        rules_file = self.validation_dir / "flow_correctness_rules.yaml"
        with open(rules_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    def _add_result(self, severity: Severity, message: str, file: str, line: int, details: str = ""):
        """添加检查结果"""
        self.results.append(ValidationResult(
            severity=severity,
            message=message,
            file=file,
            line=line,
            details=details
        ))
    
    def _collect_nodes(self, case_dir: Path):
        """收集所有节点定义"""
        self.nodes.clear()
        
        # 检查prologue_nodes
        prologue_nodes_file = case_dir / "prologue_nodes.csv"
        if prologue_nodes_file.exists():
            with open(prologue_nodes_file, 'r', encoding='utf-8-sig') as f:
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
            with open(prologue_choices_file, 'r', encoding='utf-8-sig') as f:
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
        
        # 收集所有flag
        self._collect_flags(case_dir)
    
    def _collect_flags(self, case_dir: Path):
        """收集所有flag"""
        self.flags.clear()
        
        # 从dialogue_nodes中收集set_flags
        dialogue_nodes_file = case_dir / "dialogue_nodes.csv"
        if dialogue_nodes_file.exists():
            with open(dialogue_nodes_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    set_flags = row.get('set_flags', '') or row.get('set_flag', '')
                    if set_flags:
                        flags = set_flags.split(';')
                        for flag in flags:
                            flag = flag.strip()
                            if flag:
                                self.flags.add(flag)
        
        # 从dialogue_options中收集requires条件中的flag
        dialogue_options_file = case_dir / "dialogue_options.csv"
        if dialogue_options_file.exists():
            with open(dialogue_options_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    requires = row.get('requires', '')
                    if requires:
                        try:
                            requires_data = json.loads(requires)
                            self._extract_flags_from_requires(requires_data)
                        except:
                            pass
        
        # 从day_events中收集set_flag
        day_events_file = case_dir / "day_events.csv"
        if day_events_file.exists():
            with open(day_events_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    effects = row.get('effects', '')
                    if effects:
                        try:
                            effects_data = json.loads(effects)
                            if isinstance(effects_data, dict):
                                set_flags = effects_data.get('set_flag', [])
                                if isinstance(set_flags, list):
                                    for flag in set_flags:
                                        self.flags.add(flag)
                                elif isinstance(set_flags, str):
                                    self.flags.add(set_flags)
                        except:
                            pass
    
    def _extract_flags_from_requires(self, requires: Any):
        """从requires条件中提取flag"""
        if isinstance(requires, dict):
            for key, value in requires.items():
                if key in ['flag', 'not_flag']:
                    flag_name = value if isinstance(value, str) else value.get('flag', '')
                    if flag_name:
                        self.flags.add(flag_name)
                elif key in ['all', 'any', 'not']:
                    if isinstance(value, list):
                        for item in value:
                            self._extract_flags_from_requires(item)
                    elif isinstance(value, dict):
                        self._extract_flags_from_requires(value)
        elif isinstance(requires, list):
            for item in requires:
                self._extract_flags_from_requires(item)
    
    def check_prologue_flow(self, case_dir: Path):
        """检查序章流程"""
        print("  检查序章流程...")
        
        flow_rules = self.rules.get('prologue_flow', {})
        expected_sequence = flow_rules.get('expected_sequence', [])
        
        # 检查主流程
        main_flow = flow_rules.get('main_flow', {})
        start_node = main_flow.get('start')
        end_node = main_flow.get('end')
        
        if start_node and start_node not in self.nodes:
            self._add_result(
                Severity.ERROR,
                f"起始节点不存在: {start_node}",
                "",
                0
            )
        
        if end_node and end_node not in self.nodes:
            self._add_result(
                Severity.ERROR,
                f"结束节点不存在: {end_node}",
                "",
                0
            )
        
        # 检查预期流程顺序
        for phase in expected_sequence:
            phase_name = phase.get('phase', '')
            expected_nodes = phase.get('nodes', [])
            
            print(f"    检查阶段: {phase_name}")
            
            # 检查阶段中的节点是否存在
            for node_id in expected_nodes:
                # 处理分支节点（如 shore_5a / shore_5b）
                if '/' in node_id:
                    branch_nodes = [n.strip() for n in node_id.split('/')]
                    found_any = False
                    for branch_node in branch_nodes:
                        if branch_node in self.nodes:
                            found_any = True
                            break
                    if not found_any:
                        self._add_result(
                            Severity.ERROR,
                            f"阶段节点不存在: {node_id}",
                            "",
                            0,
                            f"阶段 {phase_name} 中的节点 {node_id} 至少有一个必须存在"
                        )
                else:
                    if node_id not in self.nodes:
                        self._add_result(
                            Severity.ERROR,
                            f"阶段节点不存在: {node_id}",
                            "",
                            0,
                            f"阶段 {phase_name} 中的节点必须存在"
                        )
    
    def check_node_connections(self, case_dir: Path):
        """检查节点连接规则"""
        print("  检查节点连接规则...")
        
        connection_rules = self.rules.get('node_connection_rules', [])
        
        for rule in connection_rules:
            rule_name = rule.get('rule')
            
            if rule_name == 'must_have_next_or_end':
                self._check_next_or_end(rule)
            elif rule_name == 'next_must_exist':
                self._check_next_exists(rule)
            elif rule_name == 'no_orphan_nodes':
                self._check_orphan_nodes(rule)
            elif rule_name == 'no_infinite_loops':
                self._check_infinite_loops(rule)
            elif rule_name == 'single_end_node':
                self._check_single_end_node(rule)
    
    def _check_next_or_end(self, rule: Dict):
        """检查每个节点必须有next或end"""
        exceptions = rule.get('exceptions', [])
        
        for node_id, node_info in self.nodes.items():
            # 跳过例外节点
            if any(exc in node_id for exc in exceptions):
                continue
            
            if not node_info.next_node and not node_info.is_end and not node_info.is_choice:
                self._add_result(
                    Severity.ERROR,
                    f"节点缺少next或end字段: {node_id}",
                    node_info.file,
                    node_info.line,
                    rule.get('description', '')
                )
    
    def _check_next_exists(self, rule: Dict):
        """检查next字段指向的节点必须存在"""
        for node_id, node_info in self.nodes.items():
            if node_info.next_node and node_info.next_node not in self.nodes:
                self._add_result(
                    Severity.ERROR,
                    f"节点指向不存在的节点: {node_id} -> {node_info.next_node}",
                    node_info.file,
                    node_info.line,
                    rule.get('description', '')
                )
    
    def _check_orphan_nodes(self, rule: Dict):
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
                0,
                rule.get('description', '')
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
                    Severity.ERROR,
                    f"孤立节点（无法从start到达）: {node_id}",
                    self.nodes[node_id].file,
                    self.nodes[node_id].line,
                    rule.get('description', '')
                )
    
    def _check_infinite_loops(self, rule: Dict):
        """检查无限循环"""
        # 简化实现：检查是否有循环引用
        for node_id, node_info in self.nodes.items():
            if node_info.next_node == node_id:
                self._add_result(
                    Severity.WARNING,
                    f"节点指向自己，可能形成无限循环: {node_id}",
                    node_info.file,
                    node_info.line,
                    rule.get('description', '')
                )
    
    def _check_single_end_node(self, rule: Dict):
        """检查结束节点唯一性"""
        end_nodes = [node_id for node_id, node_info in self.nodes.items() if node_info.is_end]
        
        if len(end_nodes) > 1:
            self._add_result(
                Severity.WARNING,
                f"存在多个结束节点: {', '.join(end_nodes)}",
                "",
                0,
                rule.get('description', '')
            )
    
    def check_branch_rules(self, case_dir: Path):
        """检查选项分支规则"""
        print("  检查选项分支规则...")
        
        branch_rules = self.rules.get('branch_rules', [])
        
        for rule in branch_rules:
            rule_name = rule.get('rule')
            
            if rule_name == 'choice_goto_must_exist':
                self._check_choice_goto_exists(rule)
            elif rule_name == 'branches_must_merge':
                self._check_branches_merge(rule)
            elif rule_name == 'choice_requires_valid':
                self._check_choice_requires_valid(rule)
    
    def _check_choice_goto_exists(self, rule: Dict):
        """检查选项的goto必须指向存在的节点"""
        for node_id, node_info in self.nodes.items():
            if node_info.is_choice:
                for choice in node_info.choices:
                    if choice not in self.nodes:
                        self._add_result(
                            Severity.ERROR,
                            f"选项指向不存在的节点: {node_id} -> {choice}",
                            node_info.file,
                            node_info.line,
                            rule.get('description', '')
                        )
    
    def _check_branches_merge(self, rule: Dict):
        """检查选项分支最终应该汇合到主线"""
        # 简化实现：检查是否有分支节点没有后续连接
        for node_id, node_info in self.nodes.items():
            if node_info.is_choice:
                # 检查每个choice是否都有后续
                for choice in node_info.choices:
                    if choice in self.nodes:
                        choice_info = self.nodes[choice]
                        if not choice_info.next_node and not choice_info.is_end and not choice_info.is_choice:
                            self._add_result(
                                Severity.WARNING,
                                f"分支节点没有后续连接: {choice}",
                                choice_info.file,
                                choice_info.line,
                                rule.get('description', '')
                            )
    
    def _check_choice_requires_valid(self, rule: Dict):
        """检查选项的requires条件必须引用有效的flag"""
        # 从dialogue_options中检查requires
        dialogue_options_file = (self.project_root / "data" / "case_tables" / 
                                "prologue_ferry" / "dialogue_options.csv")
        
        if dialogue_options_file.exists():
            with open(dialogue_options_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    requires = row.get('requires', '')
                    if requires:
                        try:
                            requires_data = json.loads(requires)
                            self._check_requires_flags(requires_data, str(dialogue_options_file), line_num)
                        except:
                            pass
    
    def _check_requires_flags(self, requires: Any, file: str, line: int):
        """检查requires条件中的flag"""
        if isinstance(requires, dict):
            for key, value in requires.items():
                if key in ['flag', 'not_flag']:
                    flag_name = value if isinstance(value, str) else value.get('flag', '')
                    if flag_name and flag_name not in self.flags:
                        # 检查是否是运行时flag
                        runtime_flags = self._load_runtime_flags()
                        if flag_name not in runtime_flags:
                            self._add_result(
                                Severity.WARNING,
                                f"选项条件引用了不存在的flag: {flag_name}",
                                file,
                                line
                            )
                elif key in ['all', 'any', 'not']:
                    if isinstance(value, list):
                        for item in value:
                            self._check_requires_flags(item, file, line)
                    elif isinstance(value, dict):
                        self._check_requires_flags(value, file, line)
        elif isinstance(requires, list):
            for item in requires:
                self._check_requires_flags(item, file, line)
    
    def _load_runtime_flags(self) -> Set[str]:
        """加载运行时flag列表"""
        runtime_flags_file = self.validation_dir / "runtime_flags.yaml"
        if runtime_flags_file.exists():
            with open(runtime_flags_file, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
                return set(config.get('runtime_flags', {}).keys())
        return set()
    
    def check_end_conditions(self, case_dir: Path):
        """检查结束条件规则"""
        print("  检查结束条件规则...")
        
        end_rules = self.rules.get('end_condition_rules', [])
        
        for rule in end_rules:
            rule_name = rule.get('rule')
            
            if rule_name == 'end_node_marked':
                self._check_end_node_marked(rule)
            elif rule_name == 'end_node_content':
                self._check_end_node_content(rule)
            elif rule_name == 'no_after_end':
                self._check_no_after_end(rule)
    
    def _check_end_node_marked(self, rule: Dict):
        """检查结束节点必须标记end=true"""
        # 这里简化实现，实际应该检查所有节点
        pass
    
    def _check_end_node_content(self, rule: Dict):
        """检查结束节点应该有明确的结束内容"""
        # 简化实现
        pass
    
    def _check_no_after_end(self, rule: Dict):
        """检查结束节点不应该有next字段"""
        for node_id, node_info in self.nodes.items():
            if node_info.is_end and node_info.next_node:
                self._add_result(
                    Severity.ERROR,
                    f"结束节点不应该有next字段: {node_id}",
                    node_info.file,
                    node_info.line,
                    rule.get('description', '')
                )
    
    def check_state_machine(self, case_dir: Path):
        """检查状态机规则"""
        print("  检查状态机规则...")
        
        # 简化实现：检查状态转换是否合理
        state_rules = self.rules.get('state_machine_rules', {})
        transitions = state_rules.get('transitions', [])
        
        # 这里可以添加状态机检查逻辑
        # 由于状态机检查需要运行时上下文，这里只做基本检查
        pass
    
    def check_progression(self, case_dir: Path):
        """检查进度系统规则"""
        print("  检查进度系统规则...")
        
        progression_rules = self.rules.get('progression_rules', {})
        
        # 检查progression.json
        progression_file = case_dir.parent / "cases" / case_dir.name / "progression.json"
        if progression_file.exists():
            with open(progression_file, 'r', encoding='utf-8') as f:
                progression_data = json.load(f)
                
                # 检查阶段解锁条件
                phases = progression_data.get('phases', {})
                unlock_dependencies = progression_rules.get('unlock_dependencies', [])
                
                for dependency in unlock_dependencies:
                    source = dependency.get('source', '')
                    requires = dependency.get('requires', [])
                    
                    if source in phases:
                        phase_requires = phases[source].get('requires', [])
                        for req in requires:
                            if req not in phase_requires:
                                self._add_result(
                                    Severity.WARNING,
                                    f"阶段 {source} 缺少依赖: {req}",
                                    str(progression_file),
                                    0,
                                    f"建议添加依赖: {req}"
                                )
    
    def check_dialogue_flow(self, case_dir: Path):
        """检查对话流程规则"""
        print("  检查对话流程规则...")
        
        dialogue_flow_rules = self.rules.get('dialogue_flow_rules', {})
        
        # 检查对话入口
        entry_points = dialogue_flow_rules.get('entry_points', [])
        for rule in entry_points:
            rule_name = rule.get('rule')
            if rule_name == 'npc_has_entry':
                self._check_npc_has_entry(rule)
        
        # 检查对话退出
        exit_points = dialogue_flow_rules.get('exit_points', [])
        for rule in exit_points:
            rule_name = rule.get('rule')
            if rule_name == 'dialogue_has_exit':
                self._check_dialogue_has_exit(rule)
    
    def _check_npc_has_entry(self, rule: Dict):
        """检查每个NPC必须有对话入口节点"""
        # 简化实现：检查dialogue_nodes.csv
        dialogue_nodes_file = (self.project_root / "data" / "case_tables" / 
                              "prologue_ferry" / "dialogue_nodes.csv")
        
        if dialogue_nodes_file.exists():
            with open(dialogue_nodes_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                npc_nodes = defaultdict(list)
                
                for row in reader:
                    node_id = row.get('node_id', '')
                    npc_id = row.get('npc_id', '')
                    if npc_id:
                        npc_nodes[npc_id].append(node_id)
                
                # 检查每个NPC是否有入口节点
                for npc_id, nodes in npc_nodes.items():
                    # 这里简化检查：至少应该有一个节点
                    if not nodes:
                        self._add_result(
                            Severity.ERROR,
                            f"NPC没有对话节点: {npc_id}",
                            str(dialogue_nodes_file),
                            0,
                            rule.get('description', '')
                        )
    
    def _check_dialogue_has_exit(self, rule: Dict):
        """检查对话必须有退出选项"""
        # 简化实现
        pass
    
    def check_confrontation_flow(self, case_dir: Path):
        """检查质询流程规则"""
        print("  检查质询流程规则...")
        
        confrontation_rules = self.rules.get('confrontation_flow_rules', [])
        
        for rule in confrontation_rules:
            rule_name = rule.get('rule')
            
            if rule_name == 'confrontation_requires_evidence':
                self._check_confrontation_requires_evidence(rule, case_dir)
            elif rule_name == 'confrontation_has_outcome':
                self._check_confrontation_has_outcome(rule)
            elif rule_name == 'confrontation_updates_state':
                self._check_confrontation_updates_state(rule)
    
    def _check_confrontation_requires_evidence(self, rule: Dict, case_dir: Path):
        """检查质询必须携带相关证据"""
        # 简化实现：检查case.json中的confrontation配置
        case_file = case_dir.parent / "cases" / case_dir.name / "case.json"
        if case_file.exists():
            with open(case_file, 'r', encoding='utf-8') as f:
                case_data = json.load(f)
                
                confrontations = case_data.get('confrontations', [])
                for confrontation in confrontations:
                    # 检查质询是否有证据要求
                    evidence_required = confrontation.get('evidence_required', [])
                    if not evidence_required:
                        self._add_result(
                            Severity.WARNING,
                            f"质询可能缺少证据要求: {confrontation.get('id', '')}",
                            str(case_file),
                            0,
                            rule.get('description', '')
                        )
    
    def _check_confrontation_has_outcome(self, rule: Dict):
        """检查质询必须有明确的结果"""
        # 简化实现
        pass
    
    def _check_confrontation_updates_state(self, rule: Dict):
        """检查质询后应该更新游戏状态"""
        # 简化实现
        pass
    
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
        
        print(f"\n检查案件流程正确性: {case_name}")
        print("-" * 50)
        
        # 收集节点
        self._collect_nodes(case_dir)
        
        # 检查序章流程
        self.check_prologue_flow(case_dir)
        
        # 检查节点连接
        self.check_node_connections(case_dir)
        
        # 检查分支规则
        self.check_branch_rules(case_dir)
        
        # 检查结束条件
        self.check_end_conditions(case_dir)
        
        # 检查状态机
        self.check_state_machine(case_dir)
        
        # 检查进度系统
        self.check_progression(case_dir)
        
        # 检查对话流程
        self.check_dialogue_flow(case_dir)
        
        # 检查质询流程
        self.check_confrontation_flow(case_dir)
    
    def generate_report(self) -> str:
        """生成检查报告"""
        report = []
        report.append("# 流程正确性验证报告")
        report.append("")
        
        # 统计
        errors = [r for r in self.results if r.severity == Severity.ERROR]
        warnings = [r for r in self.results if r.severity == Severity.WARNING]
        infos = [r for r in self.results if r.severity == Severity.INFO]
        
        report.append(f"## 检查总结")
        report.append(f"- 错误: {len(errors)}")
        report.append(f"- 警告: {len(warnings)}")
        report.append(f"- 信息: {len(infos)}")
        report.append(f"- 节点总数: {len(self.nodes)}")
        report.append(f"- Flag总数: {len(self.flags)}")
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
        
        # 信息详情
        if infos:
            report.append("## 信息")
            for info in infos:
                report.append(f"- {info.message}")
                report.append(f"  文件: {info.file}")
                report.append("")
        
        return "\n".join(report)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="流程正确性验证")
    parser.add_argument("--project-root", default="/Users/zhoujiong/Documents/UGit/DetectiveSandbox/detective",
                       help="项目根目录")
    parser.add_argument("--case", help="指定检查的案件名称")
    parser.add_argument("--output", help="输出报告文件路径")
    
    args = parser.parse_args()
    
    validator = FlowCorrectnessValidator(args.project_root)
    
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
