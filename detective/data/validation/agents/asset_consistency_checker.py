#!/usr/bin/env python3
"""
美术资源一致性检查Agent
检查资源路径、命名、尺寸、格式、引用完整性等
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
import hashlib
from datetime import datetime


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
class ResourceInfo:
    path: str
    file_type: str  # background, portrait, cg, sfx, bgm
    size: Tuple[int, int] = (0, 0)
    format: str = ""
    is_orphan: bool = False
    is_missing: bool = False


class AssetConsistencyChecker:
    """美术资源一致性检查器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.validation_dir = self.project_root / "data" / "validation"
        self.results: List[ValidationResult] = []
        self.rules = self._load_rules()
        self.resources: Dict[str, ResourceInfo] = {}
        
    def _load_rules(self) -> Dict:
        """加载规则配置"""
        rules_file = self.validation_dir / "asset_consistency_rules.yaml"
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
    
    def check_path_patterns(self, case_dir: Path):
        """检查资源路径模式"""
        print("  检查资源路径模式...")
        
        path_patterns = self.rules.get('path_patterns', {})
        
        # 检查prologue_nodes.csv中的资源引用
        prologue_nodes_file = case_dir / "prologue_nodes.csv"
        if prologue_nodes_file.exists():
            with open(prologue_nodes_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    # 检查背景图路径
                    background = row.get('background', '')
                    if background:
                        self._check_resource_path(background, 'background', 
                                                 path_patterns.get('background', {}), 
                                                 str(prologue_nodes_file), line_num)
                    
                    # 检查音效路径
                    sfx = row.get('fx.sfx', '')
                    if sfx:
                        self._check_resource_path(sfx, 'sfx', 
                                                 path_patterns.get('sfx', {}), 
                                                 str(prologue_nodes_file), line_num)
        
        # 检查characters.csv中的资源引用
        characters_file = case_dir / "characters.csv"
        if characters_file.exists():
            with open(characters_file, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    # 检查立绘路径
                    portrait = row.get('portrait', '')
                    if portrait:
                        self._check_resource_path(portrait, 'portrait', 
                                                 path_patterns.get('portrait', {}), 
                                                 str(characters_file), line_num)
    
    def _check_resource_path(self, path: str, resource_type: str, pattern_info: Dict, 
                            file: str, line: int):
        """检查单个资源路径"""
        if not path:
            return
        
        # 检查路径格式
        pattern = pattern_info.get('pattern')
        if pattern and not re.match(pattern, path):
            self._add_result(
                Severity.WARNING,
                f"资源路径格式不规范: {path}",
                file,
                line,
                pattern_info.get('description', f"期望格式: {pattern}")
            )
        
        # 检查文件是否存在
        full_path = self.project_root / path.replace("res://", "")
        if not full_path.exists():
            # 检查是否在允许缺失列表中
            missing_check = self.rules.get('missing_resource_check', {})
            allowed_missing = missing_check.get('allowed_missing', [])
            
            if path not in allowed_missing:
                self._add_result(
                    Severity.ERROR,
                    f"资源文件不存在: {path}",
                    file,
                    line
                )
                self.resources[path] = ResourceInfo(
                    path=path,
                    file_type=resource_type,
                    is_missing=True
                )
            else:
                self._add_result(
                    Severity.INFO,
                    f"资源文件缺失但允许: {path}",
                    file,
                    line
                )
        else:
            # 资源存在，添加到资源列表
            if path not in self.resources:
                self.resources[path] = ResourceInfo(
                    path=path,
                    file_type=resource_type
                )
    
    def check_naming_conventions(self):
        """检查资源命名规范"""
        print("  检查资源命名规范...")
        
        naming_conventions = self.rules.get('naming_conventions', {})
        
        for resource_path, resource_info in self.resources.items():
            if resource_info.is_missing:
                continue
            
            # 获取文件名
            filename = Path(resource_path).stem
            
            # 根据资源类型检查命名
            if resource_info.file_type in naming_conventions:
                convention = naming_conventions[resource_info.file_type]
                pattern = convention.get('pattern')
                
                if pattern and not re.match(pattern, filename):
                    self._add_result(
                        Severity.WARNING,
                        f"资源命名不符合规范: {filename}",
                        resource_path,
                        0,
                        f"期望格式: {pattern}"
                    )
    
    def check_reference_integrity(self, case_dir: Path):
        """检查资源引用完整性"""
        print("  检查资源引用完整性...")
        
        ref_rules = self.rules.get('reference_integrity', {}).get('checks', [])
        
        for check in ref_rules:
            source_files = check.get('source_files', [])
            source_field = check.get('source_field', '')
            
            for source_filename in source_files:
                source_file = case_dir / source_filename
                
                if source_file.exists():
                    with open(source_file, 'r', encoding='utf-8-sig') as f:
                        reader = csv.DictReader(f)
                        for line_num, row in enumerate(reader, start=2):
                            if source_field in row and row[source_field]:
                                resource_path = row[source_field]
                                
                                # 检查资源是否在资源列表中
                                if resource_path not in self.resources:
                                    # 添加到资源列表
                                    self.resources[resource_path] = ResourceInfo(
                                        path=resource_path,
                                        file_type=self._determine_resource_type(source_field)
                                    )
    
    def _determine_resource_type(self, field_name: str) -> str:
        """根据字段名确定资源类型"""
        type_mapping = {
            'background': 'background',
            'portrait': 'portrait',
            'fx.sfx': 'sfx',
            'bgm': 'bgm'
        }
        return type_mapping.get(field_name, 'unknown')
    
    def check_size_requirements(self):
        """检查资源尺寸要求"""
        print("  检查资源尺寸要求...")
        
        size_requirements = self.rules.get('size_requirements', {})
        
        # 这里简化实现，实际应该读取图片文件检查尺寸
        # 由于需要PIL库，这里只做路径检查
        for resource_path, resource_info in self.resources.items():
            if resource_info.is_missing:
                continue
            
            # 检查文件是否存在
            full_path = self.project_root / resource_path.replace("res://", "")
            if full_path.exists():
                # 这里可以添加实际尺寸检查逻辑
                # 例如使用PIL库读取图片尺寸
                pass
    
    def check_format_requirements(self):
        """检查资源格式要求"""
        print("  检查资源格式要求...")
        
        format_requirements = self.rules.get('format_requirements', {})
        
        for resource_path, resource_info in self.resources.items():
            if resource_info.is_missing:
                continue
            
            # 检查文件格式
            file_ext = Path(resource_path).suffix.lower()
            
            if resource_info.file_type in ['background', 'portrait', 'cg']:
                # 图片文件
                expected_formats = format_requirements.get('images', {}).get('formats', [])
                if expected_formats and file_ext not in [f'.{fmt}' for fmt in expected_formats]:
                    self._add_result(
                        Severity.WARNING,
                        f"资源格式不符合要求: {file_ext}",
                        resource_path,
                        0,
                        f"期望格式: {', '.join(expected_formats)}"
                    )
            
            elif resource_info.file_type in ['sfx', 'bgm']:
                # 音频文件
                audio_config = format_requirements.get('audio', {}).get(resource_info.file_type, {})
                expected_formats = audio_config.get('formats', [])
                if expected_formats and file_ext not in [f'.{fmt}' for fmt in expected_formats]:
                    self._add_result(
                        Severity.WARNING,
                        f"资源格式不符合要求: {file_ext}",
                        resource_path,
                        0,
                        f"期望格式: {', '.join(expected_formats)}"
                    )
    
    def check_orphan_resources(self):
        """检查孤立资源"""
        print("  检查孤立资源...")
        
        orphan_check = self.rules.get('orphan_resource_check', {})
        if not orphan_check.get('enabled', True):
            return
        
        # 收集所有被引用的资源
        referenced_resources = set()
        
        # 这里需要从CSV/JSON文件中收集所有引用
        # 简化实现：只检查resources中的资源是否被引用
        for resource_path in self.resources.keys():
            referenced_resources.add(resource_path)
        
        # 扫描项目目录中的资源文件
        assets_dir = self.project_root / "assets"
        if assets_dir.exists():
            for root, dirs, files in os.walk(assets_dir):
                # 跳过忽略的目录
                ignore_patterns = orphan_check.get('ignore_patterns', [])
                skip = False
                for pattern in ignore_patterns:
                    if pattern in root:
                        skip = True
                        break
                if skip:
                    continue
                
                for file in files:
                    if file.endswith(('.png', '.jpg', '.wav', '.ogg')):
                        # 构造资源路径
                        rel_path = Path(root).relative_to(self.project_root)
                        resource_path = f"res://{rel_path / file}"
                        
                        # 检查是否在引用列表中
                        if resource_path not in referenced_resources:
                            self._add_result(
                                Severity.INFO,
                                f"孤立资源（未被引用）: {resource_path}",
                                str(rel_path / file),
                                0
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
        
        print(f"\n检查案件美术资源: {case_name}")
        print("-" * 50)
        
        # 清空资源列表
        self.resources.clear()
        
        # 检查路径模式
        self.check_path_patterns(case_dir)
        
        # 检查引用完整性
        self.check_reference_integrity(case_dir)
        
        # 检查命名规范
        self.check_naming_conventions()
        
        # 检查尺寸要求
        self.check_size_requirements()
        
        # 检查格式要求
        self.check_format_requirements()
        
        # 检查孤立资源
        self.check_orphan_resources()
    
    def generate_report(self) -> str:
        """生成检查报告"""
        report = []
        report.append("# 美术资源一致性检查报告")
        report.append("")
        
        # 统计
        errors = [r for r in self.results if r.severity == Severity.ERROR]
        warnings = [r for r in self.results if r.severity == Severity.WARNING]
        infos = [r for r in self.results if r.severity == Severity.INFO]
        
        report.append(f"## 检查总结")
        report.append(f"- 错误: {len(errors)}")
        report.append(f"- 警告: {len(warnings)}")
        report.append(f"- 信息: {len(infos)}")
        report.append(f"- 资源总数: {len(self.resources)}")
        report.append("")
        
        # 资源统计
        report.append("## 资源统计")
        report.append("| 资源类型 | 数量 |")
        report.append("|---------|------|")
        
        type_counts = {}
        for resource_info in self.resources.values():
            resource_type = resource_info.file_type
            type_counts[resource_type] = type_counts.get(resource_type, 0) + 1
        
        for resource_type, count in sorted(type_counts.items()):
            report.append(f"| {resource_type} | {count} |")
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
    
    parser = argparse.ArgumentParser(description="美术资源一致性检查")
    parser.add_argument("--project-root", default="/Users/zhoujiong/Documents/UGit/DetectiveSandbox/detective",
                       help="项目根目录")
    parser.add_argument("--case", help="指定检查的案件名称")
    parser.add_argument("--output", help="输出报告文件路径")
    
    args = parser.parse_args()
    
    checker = AssetConsistencyChecker(args.project_root)
    
    if args.case:
        checker.check_case(args.case)
    else:
        # 检查所有案件
        case_tables_dir = Path(args.project_root) / "data" / "case_tables"
        for case_dir in case_tables_dir.iterdir():
            if case_dir.is_dir() and not case_dir.name.startswith('_'):
                checker.check_case(case_dir.name)
    
    report = checker.generate_report()
    
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"\n报告已保存到: {args.output}")
    else:
        print("\n" + report)


if __name__ == "__main__":
    main()
