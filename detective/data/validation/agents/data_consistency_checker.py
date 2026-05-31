#!/usr/bin/env python3
"""
数据一致性检查Agent
检查CSV/JSON文件之间的引用关系、ID一致性、字段格式等
"""

import os
import re
import csv
import json
import yaml
from pathlib import Path
from typing import Dict, List, Set, Tuple, Any
from dataclasses import dataclass
from enum import Enum


class Severity(Enum):
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
    HINT = "hint"


@dataclass
class ValidationResult:
    severity: Severity
    message: str
    file: str
    line: int
    details: str


class DataConsistencyChecker:
    """数据一致性检查器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.validation_dir = self.project_root / "data" / "validation"
        self.results: List[ValidationResult] = []
        self.rules = self._load_rules()
        
    def _load_rules(self) -> Dict:
        """加载规则配置"""
        rules_file = self.validation_dir / "data_consistency_rules.yaml"
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
    
    def check_csv_file(self, csv_path: Path, file_type: str) -> Dict[str, Set[str]]:
        """检查CSV文件，返回提取的ID集合"""
        ids = {}
        
        if not csv_path.exists():
            self._add_result(
                Severity.ERROR,
                f"CSV文件不存在: {csv_path.name}",
                str(csv_path),
                0
            )
            return ids
        
        try:
            # 使用csv模块正确解析CSV文件
            with open(csv_path, 'r', encoding='utf-8-sig') as f:  # utf-8-sig 处理BOM
                # 使用csv.reader解析整个文件
                reader = csv.reader(f)
                
                # 跳过注释行和空行，找到表头
                headers = None
                line_num = 0
                
                for row in reader:
                    line_num += 1
                    
                    # 跳过空行
                    if not row:
                        continue
                    
                    # 跳过注释行
                    if row[0].startswith('#'):
                        continue
                    
                    # 第一个非注释、非空行是表头
                    if headers is None:
                        headers = row
                        continue
                    
                    # 数据行
                    if len(row) < len(headers):
                        # 补齐缺失的列
                        row.extend([''] * (len(headers) - len(row)))
                    
                    # 创建行字典
                    row_dict = {}
                    for i, header in enumerate(headers):
                        if i < len(row):
                            row_dict[header] = row[i]
                        else:
                            row_dict[header] = ''
                    
                    # 提取ID
                    for field in ['node_id', 'npc_id', 'character_id', 'evidence_id', 'event_id']:
                        if field in row_dict and row_dict[field]:
                            if field not in ids:
                                ids[field] = set()
                            ids[field].add(row_dict[field])
                    
                    # 检查ID格式
                    self._check_id_format(row_dict, file_type, line_num)
                    
                    # 检查必填字段
                    self._check_required_fields(row_dict, file_type, line_num)
                    
                    # 检查枚举值
                    self._check_enum_values(row_dict, file_type, line_num)
                    
        except Exception as e:
            self._add_result(
                Severity.ERROR,
                f"读取CSV文件失败: {str(e)}",
                str(csv_path),
                0
            )
        
        return ids
    
    def _check_id_format(self, row: Dict, file_type: str, line_num: int):
        """检查ID格式"""
        id_rules = self.rules.get('id_naming_rules', {})
        
        for field, rule in id_rules.items():
            if field in row and row[field]:
                pattern = rule.get('pattern')
                if pattern and not re.match(pattern, row[field]):
                    self._add_result(
                        Severity.ERROR,
                        f"ID格式不符合规范: {row[field]}",
                        f"行 {line_num}",
                        line_num,
                        f"期望格式: {rule.get('description', pattern)}"
                    )
    
    def _check_required_fields(self, row: Dict, file_type: str, line_num: int):
        """检查必填字段"""
        required_fields = self.rules.get('required_fields', {})
        
        if file_type in required_fields:
            required = required_fields[file_type].get('required', [])
            for field in required:
                if field not in row or not row[field]:
                    self._add_result(
                        Severity.ERROR,
                        f"必填字段缺失: {field}",
                        f"行 {line_num}",
                        line_num
                    )
    
    def _check_enum_values(self, row: Dict, file_type: str, line_num: int):
        """检查枚举值"""
        enum_values = self.rules.get('enum_values', {})
        
        for field, valid_values in enum_values.items():
            if field in row and row[field]:
                if row[field] not in valid_values:
                    self._add_result(
                        Severity.WARNING,
                        f"字段值不在允许范围内: {field}={row[field]}",
                        f"行 {line_num}",
                        line_num,
                        f"允许的值: {', '.join(valid_values)}"
                    )
    
    def check_reference_integrity(self, case_dir: Path):
        """检查引用完整性"""
        ref_rules = self.rules.get('reference_integrity', {})
        
        # 检查节点引用
        node_refs = ref_rules.get('node_references', [])
        for ref in node_refs:
            source_file = case_dir / ref['source_file']
            target_file = case_dir / ref['target_file']
            
            if source_file.exists() and target_file.exists():
                # 收集目标文件中的所有ID
                target_ids = set()
                with open(target_file, 'r', encoding='utf-8-sig') as f:
                    reader = csv.reader(f)
                    headers = None
                    for row in reader:
                        if not row or row[0].startswith('#'):
                            continue
                        if headers is None:
                            headers = row
                            continue
                        # 查找目标字段的索引
                        if ref['target_field'] in headers:
                            idx = headers.index(ref['target_field'])
                            if idx < len(row) and row[idx]:
                                target_ids.add(row[idx])
                
                # 特殊关键字列表，这些不是实际的节点ID
                special_keywords = ['__exit__', '__return__', '__end__', '__back__', '__confront__']
                
                # 检查源文件中的引用
                with open(source_file, 'r', encoding='utf-8-sig') as f:
                    reader = csv.reader(f)
                    headers = None
                    line_num = 0
                    for row in reader:
                        line_num += 1
                        if not row or row[0].startswith('#'):
                            continue
                        if headers is None:
                            headers = row
                            continue
                        # 查找源字段的索引
                        if ref['source_field'] in headers:
                            idx = headers.index(ref['source_field'])
                            if idx < len(row) and row[idx]:
                                # 跳过特殊关键字
                                if row[idx] in special_keywords:
                                    continue
                                if row[idx] not in target_ids:
                                    self._add_result(
                                        Severity.ERROR,
                                        f"引用不存在: {row[idx]}",
                                        str(source_file),
                                        line_num,
                                        ref['description']
                                    )
    
    def check_asset_references(self, case_dir: Path):
        """检查资源引用"""
        asset_rules = self.rules.get('asset_references', [])
        
        for ref in asset_rules:
            source_file = case_dir / ref['source_file']
            
            if source_file.exists():
                with open(source_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for line_num, row in enumerate(reader, start=2):
                        if ref['source_field'] in row and row[ref['source_field']]:
                            asset_path = row[ref['source_field']]
                            
                            # 检查路径格式
                            pattern = ref.get('pattern')
                            if pattern and not re.match(pattern, asset_path):
                                self._add_result(
                                    Severity.WARNING,
                                    f"资源路径格式不规范: {asset_path}",
                                    str(source_file),
                                    line_num,
                                    ref['description']
                                )
                            
                            # 检查文件是否存在
                            full_path = self.project_root / asset_path.replace("res://", "")
                            if not full_path.exists():
                                self._add_result(
                                    Severity.ERROR,
                                    f"资源文件不存在: {asset_path}",
                                    str(source_file),
                                    line_num
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
        
        print(f"\n检查案件: {case_name}")
        print("-" * 50)
        
        # 检查CSV文件
        csv_files = [
            ("prologue_nodes.csv", "prologue_nodes"),
            ("prologue_lines.csv", "prologue_lines"),
            ("prologue_choices.csv", "prologue_choices"),
            ("characters.csv", "characters"),
            ("dialogue_nodes.csv", "dialogue_nodes"),
            ("dialogue_options.csv", "dialogue_options"),
            ("dialogue_lines.csv", "dialogue_lines"),
        ]
        
        for filename, file_type in csv_files:
            csv_path = case_dir / filename
            if csv_path.exists():
                print(f"  检查: {filename}")
                self.check_csv_file(csv_path, file_type)
        
        # 检查引用完整性
        print("  检查引用完整性...")
        self.check_reference_integrity(case_dir)
        
        # 检查资源引用
        print("  检查资源引用...")
        self.check_asset_references(case_dir)
    
    def check_all_cases(self):
        """检查所有案件"""
        case_tables_dir = self.project_root / "data" / "case_tables"
        
        if not case_tables_dir.exists():
            self._add_result(
                Severity.ERROR,
                "案件表目录不存在",
                str(case_tables_dir),
                0
            )
            return
        
        for case_dir in case_tables_dir.iterdir():
            if case_dir.is_dir() and not case_dir.name.startswith('_'):
                self.check_case(case_dir.name)
    
    def generate_report(self) -> str:
        """生成检查报告"""
        report = []
        report.append("# 数据一致性检查报告")
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
        
        return "\n".join(report)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="数据一致性检查")
    parser.add_argument("--project-root", default="/Users/zhoujiong/Documents/UGit/DetectiveSandbox/detective",
                       help="项目根目录")
    parser.add_argument("--case", help="指定检查的案件名称")
    parser.add_argument("--output", help="输出报告文件路径")
    
    args = parser.parse_args()
    
    checker = DataConsistencyChecker(args.project_root)
    
    if args.case:
        checker.check_case(args.case)
    else:
        checker.check_all_cases()
    
    report = checker.generate_report()
    
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"\n报告已保存到: {args.output}")
    else:
        print("\n" + report)


if __name__ == "__main__":
    main()
