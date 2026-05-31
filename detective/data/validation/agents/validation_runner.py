#!/usr/bin/env python3
"""
验证系统主协调器
运行所有检查Agent并生成综合报告
"""

import os
import sys
import yaml
import time
from pathlib import Path
from typing import Dict, List
from datetime import datetime

# 添加当前目录到Python路径
sys.path.insert(0, str(Path(__file__).parent))

from data_consistency_checker import DataConsistencyChecker
from narrative_logic_validator import NarrativeLogicValidator
from director_agent import DirectorAgent
from asset_consistency_checker import AssetConsistencyChecker
from flow_correctness_validator import FlowCorrectnessValidator


class ValidationRunner:
    """验证系统主协调器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.validation_dir = self.project_root / "data" / "validation"
        self.config = self._load_config()
        self.results: Dict[str, str] = {}
        
    def _load_config(self) -> Dict:
        """加载验证配置"""
        config_file = self.validation_dir / "validation_config.yaml"
        with open(config_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    def run_data_consistency_check(self, case_name: str = None) -> str:
        """运行数据一致性检查"""
        print("\n" + "=" * 60)
        print("运行数据一致性检查")
        print("=" * 60)
        
        checker = DataConsistencyChecker(str(self.project_root))
        
        if case_name:
            checker.check_case(case_name)
        else:
            checker.check_all_cases()
        
        return checker.generate_report()
    
    def run_narrative_logic_check(self, case_name: str = None) -> str:
        """运行剧情逻辑验证"""
        print("\n" + "=" * 60)
        print("运行剧情逻辑验证")
        print("=" * 60)
        
        validator = NarrativeLogicValidator(str(self.project_root))
        
        if case_name:
            validator.check_case(case_name)
        else:
            # 检查所有案件
            case_tables_dir = self.project_root / "data" / "case_tables"
            for case_dir in case_tables_dir.iterdir():
                if case_dir.is_dir() and not case_dir.name.startswith('_'):
                    validator.check_case(case_dir.name)
        
        return validator.generate_report()
    
    def run_director_check(self, case_name: str = None) -> str:
        """运行导演检查"""
        print("\n" + "=" * 60)
        print("运行导演检查")
        print("=" * 60)
        
        director = DirectorAgent(str(self.project_root))
        
        if case_name:
            director.check_case(case_name)
        else:
            # 检查所有案件
            case_tables_dir = self.project_root / "data" / "case_tables"
            for case_dir in case_tables_dir.iterdir():
                if case_dir.is_dir() and not case_dir.name.startswith('_'):
                    director.check_case(case_dir.name)
        
        return director.generate_report()
    
    def run_asset_consistency_check(self, case_name: str = None) -> str:
        """运行美术资源一致性检查"""
        print("\n" + "=" * 60)
        print("运行美术资源一致性检查")
        print("=" * 60)
        
        checker = AssetConsistencyChecker(str(self.project_root))
        
        if case_name:
            checker.check_case(case_name)
        else:
            # 检查所有案件
            case_tables_dir = self.project_root / "data" / "case_tables"
            for case_dir in case_tables_dir.iterdir():
                if case_dir.is_dir() and not case_dir.name.startswith('_'):
                    checker.check_case(case_dir.name)
        
        return checker.generate_report()
    
    def run_flow_correctness_check(self, case_name: str = None) -> str:
        """运行流程正确性验证"""
        print("\n" + "=" * 60)
        print("运行流程正确性验证")
        print("=" * 60)
        
        validator = FlowCorrectnessValidator(str(self.project_root))
        
        if case_name:
            validator.check_case(case_name)
        else:
            # 检查所有案件
            case_tables_dir = self.project_root / "data" / "case_tables"
            for case_dir in case_tables_dir.iterdir():
                if case_dir.is_dir() and not case_dir.name.startswith('_'):
                    validator.check_case(case_dir.name)
        
        return validator.generate_report()
    
    def run_all_checks(self, case_name: str = None) -> str:
        """运行所有检查"""
        start_time = time.time()
        
        # 收集所有报告
        reports = {}
        
        # 检查哪些agent启用
        agents_config = self.config.get('agents', {})
        
        if agents_config.get('data_consistency', {}).get('enabled', True):
            reports['数据一致性检查'] = self.run_data_consistency_check(case_name)
        
        if agents_config.get('narrative_logic', {}).get('enabled', True):
            reports['剧情逻辑验证'] = self.run_narrative_logic_check(case_name)
        
        if agents_config.get('asset_consistency', {}).get('enabled', True):
            reports['美术资源一致性检查'] = self.run_asset_consistency_check(case_name)
        
        if agents_config.get('flow_correctness', {}).get('enabled', True):
            reports['流程正确性验证'] = self.run_flow_correctness_check(case_name)
        
        if agents_config.get('director', {}).get('enabled', True):
            reports['导演检查'] = self.run_director_check(case_name)
        
        # 生成综合报告
        end_time = time.time()
        duration = end_time - start_time
        
        combined_report = self._generate_combined_report(reports, duration, case_name)
        
        return combined_report
    
    def _generate_combined_report(self, reports: Dict[str, str], duration: float, case_name: str = None) -> str:
        """生成综合报告"""
        report = []
        
        # 报告头
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        case_display = case_name if case_name else "所有案件"
        
        report.append("# 项目验证综合报告")
        report.append("")
        report.append(f"**生成时间**: {timestamp}")
        report.append(f"**检查案件**: {case_display}")
        report.append(f"**耗时**: {duration:.2f} 秒")
        report.append("")
        report.append("---")
        report.append("")
        
        # 目录
        report.append("## 目录")
        for i, section_name in enumerate(reports.keys(), 1):
            report.append(f"{i}. [{section_name}](#{section_name.replace(' ', '-')})")
        report.append("")
        
        # 各个报告
        for section_name, section_report in reports.items():
            report.append(f"## {section_name}")
            report.append("")
            report.append(section_report)
            report.append("")
            report.append("---")
            report.append("")
        
        # 总结
        report.append("## 总结")
        report.append("")
        
        # 统计错误和警告数量
        total_errors = 0
        total_warnings = 0
        
        for section_report in reports.values():
            # 简单的文本解析来统计错误和警告
            lines = section_report.split('\n')
            for line in lines:
                if '- 错误:' in line:
                    try:
                        count = int(line.split(':')[1].strip())
                        total_errors += count
                    except:
                        pass
                elif '- 警告:' in line:
                    try:
                        count = int(line.split(':')[1].strip())
                        total_warnings += count
                    except:
                        pass
        
        report.append(f"- **总错误数**: {total_errors}")
        report.append(f"- **总警告数**: {total_warnings}")
        report.append("")
        
        if total_errors > 0:
            report.append("### 需要修复的问题")
            report.append("")
            report.append("发现严重错误，请优先修复以下问题：")
            report.append("")
            
            # 提取错误信息
            for section_name, section_report in reports.items():
                if '错误' in section_report:
                    lines = section_report.split('\n')
                    in_error_section = False
                    for line in lines:
                        if '## 错误' in line:
                            in_error_section = True
                            report.append(f"**{section_name}**:")
                            continue
                        elif in_error_section and line.startswith('## '):
                            in_error_section = False
                            continue
                        elif in_error_section and line.startswith('- **'):
                            report.append(f"  {line}")
                    report.append("")
        
        if total_warnings > 0:
            report.append("### 建议优化的问题")
            report.append("")
            report.append("以下警告建议修复以提高代码质量：")
            report.append("")
            
            # 提取警告信息
            for section_name, section_report in reports.items():
                if '警告' in section_report:
                    lines = section_report.split('\n')
                    in_warning_section = False
                    warning_count = 0
                    for line in lines:
                        if '## 警告' in line:
                            in_warning_section = True
                            report.append(f"**{section_name}**:")
                            continue
                        elif in_warning_section and line.startswith('## '):
                            in_warning_section = False
                            continue
                        elif in_warning_section and line.startswith('- '):
                            warning_count += 1
                            if warning_count <= 5:  # 只显示前5个警告
                                report.append(f"  {line}")
                    if warning_count > 5:
                        report.append(f"  ... 还有 {warning_count - 5} 个警告")
                    report.append("")
        
        # 建议
        report.append("### 建议")
        report.append("")
        
        if total_errors == 0 and total_warnings == 0:
            report.append("所有检查通过！项目质量良好。")
        elif total_errors == 0:
            report.append("没有发现严重错误，但有警告需要关注。建议逐步修复警告项。")
        else:
            report.append("发现严重错误，建议按以下优先级修复：")
            report.append("")
            report.append("1. **高优先级**：数据一致性错误（引用缺失、格式错误）")
            report.append("2. **中优先级**：剧情逻辑错误（flag缺失、流程断裂）")
            report.append("3. **低优先级**：导演检查错误（人物/时间/认知不匹配）")
        
        report.append("")
        report.append("---")
        report.append("")
        report.append("*报告生成完毕*")
        
        return "\n".join(report)
    
    def save_report(self, report: str, output_file: str = None):
        """保存报告到文件"""
        if output_file is None:
            output_file = self.validation_dir / "validation_report.md"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"\n报告已保存到: {output_file}")
    
    def print_summary(self, report: str):
        """打印报告摘要"""
        lines = report.split('\n')
        
        print("\n" + "=" * 60)
        print("验证摘要")
        print("=" * 60)
        
        for line in lines:
            if '总错误数' in line or '总警告数' in line:
                print(line)
            elif '- **总错误数**' in line or '- **总警告数**' in line:
                print(line)
        
        print("=" * 60)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="项目验证系统")
    parser.add_argument("--project-root", default="/Users/zhoujiong/Documents/UGit/DetectiveSandbox/detective",
                       help="项目根目录")
    parser.add_argument("--case", help="指定检查的案件名称")
    parser.add_argument("--output", help="输出报告文件路径")
    parser.add_argument("--agent", choices=['data', 'logic', 'asset', 'flow', 'director', 'all'],
                       default='all', help="指定运行的agent")
    parser.add_argument("--quiet", action="store_true",
                       help="安静模式，只输出错误")
    
    args = parser.parse_args()
    
    runner = ValidationRunner(args.project_root)
    
    # 运行指定的检查
    if args.agent == 'data':
        report = runner.run_data_consistency_check(args.case)
    elif args.agent == 'logic':
        report = runner.run_narrative_logic_check(args.case)
    elif args.agent == 'asset':
        report = runner.run_asset_consistency_check(args.case)
    elif args.agent == 'flow':
        report = runner.run_flow_correctness_check(args.case)
    elif args.agent == 'director':
        report = runner.run_director_check(args.case)
    else:
        report = runner.run_all_checks(args.case)
    
    # 保存报告
    if args.output:
        runner.save_report(report, args.output)
    else:
        runner.save_report(report)
    
    # 打印摘要
    if not args.quiet:
        runner.print_summary(report)
        print("\n完整报告请查看: data/validation/validation_report.md")


if __name__ == "__main__":
    main()
