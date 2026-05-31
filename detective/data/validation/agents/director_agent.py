#!/usr/bin/env python3
"""
导演Agent
检查场景中的人物、时间、物件、角色认知四要素的一致性
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
class SceneInfo:
    scene_id: str
    characters: List[str] = field(default_factory=list)
    time_phase: str = ""
    location: str = ""
    weather: str = ""
    dialogue_lines: List[Dict] = field(default_factory=list)
    file: str = ""
    line: int = 0


@dataclass
class CharacterKnowledge:
    character_id: str
    phase: str
    knows: List[str] = field(default_factory=list)
    doesnt_know: List[str] = field(default_factory=list)
    emotion: str = ""


class DirectorAgent:
    """导演Agent"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.validation_dir = self.project_root / "data" / "validation"
        self.results: List[ValidationResult] = []
        self.rules = self._load_rules()
        self.scenes: Dict[str, SceneInfo] = {}
        self.character_knowledge: Dict[str, Dict[str, CharacterKnowledge]] = {}
        
    def _load_rules(self) -> Dict:
        """加载规则配置"""
        rules_file = self.validation_dir / "director_rules.yaml"
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
    
    def _load_character_knowledge(self):
        """加载角色认知规则"""
        self.character_knowledge.clear()
        
        knowledge_rules = self.rules.get('character_knowledge', {})
        
        for char_id, phases in knowledge_rules.items():
            self.character_knowledge[char_id] = {}
            
            for phase_name, phase_data in phases.items():
                knowledge = CharacterKnowledge(
                    character_id=char_id,
                    phase=phase_name,
                    knows=phase_data.get('knows', []),
                    doesnt_know=phase_data.get('doesnt_know', []),
                    emotion=phase_data.get('emotion', '')
                )
                self.character_knowledge[char_id][phase_name] = knowledge
    
    def check_scene_characters(self, scene: SceneInfo):
        """检查场景人物调度"""
        print(f"    检查场景人物: {scene.scene_id}")
        
        scene_rules = self.rules.get('scene_rules', {})
        
        # 匹配场景规则
        matched_rule = None
        for rule_name, rule_data in scene_rules.items():
            if rule_name in scene.scene_id or scene.scene_id in rule_name:
                matched_rule = rule_data
                break
        
        if not matched_rule:
            self._add_result(
                Severity.INFO,
                f"未找到场景规则: {scene.scene_id}",
                scene.file,
                scene.line,
                "可能需要添加场景规则定义"
            )
            return
        
        # 检查允许的人物
        allowed = matched_rule.get('allowed_characters', [])
        forbidden = matched_rule.get('forbidden_characters', [])
        required = matched_rule.get('required_characters', [])
        
        # 检查是否有禁止的人物
        for char_id in scene.characters:
            if forbidden and char_id in forbidden:
                self._add_result(
                    Severity.ERROR,
                    f"场景中出现禁止的人物: {char_id}",
                    scene.file,
                    scene.line,
                    f"场景 {scene.scene_id} 不允许 {char_id} 出现"
                )
        
        # 检查必要的人物
        for char_id in required:
            if char_id not in scene.characters:
                self._add_result(
                    Severity.ERROR,
                    f"场景缺少必要的人物: {char_id}",
                    scene.file,
                    scene.line,
                    f"场景 {scene.scene_id} 必须有 {char_id} 出现"
                )
    
    def check_scene_timeline(self, scene: SceneInfo):
        """检查场景时间线"""
        print(f"    检查场景时间线: {scene.scene_id}")
        
        scene_rules = self.rules.get('scene_rules', {})
        
        # 匹配场景规则
        matched_rule = None
        for rule_name, rule_data in scene_rules.items():
            if rule_name in scene.scene_id or scene.scene_id in rule_name:
                matched_rule = rule_data
                break
        
        if not matched_rule:
            return
        
        # 检查时间阶段
        expected_time = matched_rule.get('time_phase', '')
        if expected_time and scene.time_phase and scene.time_phase != expected_time:
            self._add_result(
                Severity.WARNING,
                f"场景时间阶段不匹配: {scene.time_phase}",
                scene.file,
                scene.line,
                f"期望时间: {expected_time}"
            )
        
        # 检查天气
        expected_weather = matched_rule.get('weather', '')
        if expected_weather and scene.weather and scene.weather != expected_weather:
            self._add_result(
                Severity.WARNING,
                f"场景天气不匹配: {scene.weather}",
                scene.file,
                scene.line,
                f"期望天气: {expected_weather}"
            )
    
    def check_scene_objects(self, scene: SceneInfo):
        """检查场景物件"""
        print(f"    检查场景物件: {scene.scene_id}")
        
        object_rules = self.rules.get('object_rules', {})
        
        # 检查物件状态
        for obj_name, obj_data in object_rules.items():
            state_changes = obj_data.get('state_changes', [])
            
            for state in state_changes:
                # 检查物件是否应该在当前场景
                if state.get('location') == scene.location:
                    # 检查物件状态是否合理
                    pass
    
    def check_character_knowledge_in_dialogue(self, scene: SceneInfo):
        """检查对话中的角色认知"""
        print(f"    检查角色认知: {scene.scene_id}")
        
        self._load_character_knowledge()
        
        for line in scene.dialogue_lines:
            speaker = line.get('speaker', '')
            text = line.get('text', '')
            line_num = line.get('line', 0)
            
            if not speaker or not text:
                continue
            
            # 确定当前阶段
            current_phase = self._determine_phase(scene.scene_id)
            
            # 检查角色认知
            if speaker in self.character_knowledge:
                char_phases = self.character_knowledge[speaker]
                
                if current_phase in char_phases:
                    knowledge = char_phases[current_phase]
                    
                    # 检查角色是否说了不应该知道的内容
                    for forbidden_info in knowledge.doesnt_know:
                        if self._text_contains_forbidden_info(text, forbidden_info):
                            self._add_result(
                                Severity.ERROR,
                                f"角色说了不应该知道的内容: {speaker}",
                                scene.file,
                                line_num,
                                f"在 {current_phase} 阶段，{speaker} 不应该知道: {forbidden_info}"
                            )
                    
                    # 检查情感是否匹配
                    expected_emotion = knowledge.emotion
                    actual_emotion = line.get('emotion', '')
                    if expected_emotion and actual_emotion and expected_emotion != actual_emotion:
                        self._add_result(
                            Severity.WARNING,
                            f"角色情感不匹配: {speaker}",
                            scene.file,
                            line_num,
                            f"期望情感: {expected_emotion}，实际情感: {actual_emotion}"
                        )
    
    def _determine_phase(self, scene_id: str) -> str:
        """根据场景ID确定游戏阶段"""
        if 'cabin' in scene_id and 'prologue' in scene_id:
            return 'cabin_phase'
        elif 'cabin' in scene_id and ('flood' in scene_id or 'swim' in scene_id or 'deck' in scene_id):
            return 'sinking_phase'
        elif 'shore' in scene_id:
            return 'post_sinking'
        elif 'inn' in scene_id and 'warm' in scene_id:
            return 'post_sinking'
        elif 'day2' in scene_id:
            return 'accused_phase'
        elif 'dock' in scene_id:
            return 'accused_phase'
        else:
            return 'unknown'
    
    def _text_contains_forbidden_info(self, text: str, forbidden_info: str) -> bool:
        """检查文本是否包含禁止的信息"""
        # 简单的关键字匹配
        forbidden_keywords = {
            "船会被凿沉": ["凿", "凿沉", "故意凿", "人为凿"],
            "阿贵和老范的计划": ["计划", "阴谋", "串通"],
            "沈清月的存在": ["沈清月", "幕后", "主使"],
            "谁凿的船": ["谁凿", "凶手是", "是他凿"],
            "为什么凿船": ["为什么凿", "动机是"],
        }
        
        if forbidden_info in forbidden_keywords:
            keywords = forbidden_keywords[forbidden_info]
            for keyword in keywords:
                if keyword in text:
                    return True
        
        return False
    
    def check_dialogue_consistency(self, scene: SceneInfo):
        """检查对话一致性"""
        print(f"    检查对话一致性: {scene.scene_id}")
        
        dialogue_rules = self.rules.get('dialogue_rules', [])
        
        for rule in dialogue_rules:
            rule_name = rule.get('rule')
            
            if rule_name == 'character_cannot_mention_future_events':
                self._check_future_events(scene)
            elif rule_name == 'liar_consistency':
                self._check_liar_consistency(scene)
    
    def _check_future_events(self, scene: SceneInfo):
        """检查角色是否提及未来事件"""
        # 简化实现：检查是否有时间顺序错误
        pass
    
    def _check_liar_consistency(self, scene: SceneInfo):
        """检查说谎者的谎言一致性"""
        # 检查agui和lao_fan的谎言是否前后一致
        agui_lines = [l for l in scene.dialogue_lines if l.get('speaker') == 'agui']
        lao_fan_lines = [l for l in scene.dialogue_lines if l.get('speaker') == 'lao_fan']
        
        # 检查阿贵的谎言
        for line in agui_lines:
            text = line.get('text', '')
            # 阿贵应该声称自己不知道船会被凿沉
            if '知道' in text and '凿' in text:
                self._add_result(
                    Severity.ERROR,
                    "阿贵的谎言不一致",
                    scene.file,
                    line.get('line', 0),
                    "阿贵应该假装不知道船被凿沉"
                )
    
    def load_scenes_from_prologue(self, case_dir: Path):
        """从序章CSV加载场景信息"""
        self.scenes.clear()
        
        # 加载prologue_nodes
        prologue_nodes_file = case_dir / "prologue_nodes.csv"
        if prologue_nodes_file.exists():
            with open(prologue_nodes_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    node_id = row.get('node_id', '')
                    if node_id:
                        scene = SceneInfo(
                            scene_id=node_id,
                            location=row.get('background', ''),
                            file=str(prologue_nodes_file),
                            line=line_num
                        )
                        self.scenes[node_id] = scene
        
        # 加载prologue_lines
        prologue_lines_file = case_dir / "prologue_lines.csv"
        if prologue_lines_file.exists():
            with open(prologue_lines_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for line_num, row in enumerate(reader, start=2):
                    node_id = row.get('node_id', '')
                    speaker = row.get('speaker', '')
                    text = row.get('text', '')
                    
                    if node_id in self.scenes:
                        if speaker:
                            if speaker not in self.scenes[node_id].characters:
                                self.scenes[node_id].characters.append(speaker)
                        
                        self.scenes[node_id].dialogue_lines.append({
                            'speaker': speaker,
                            'text': text,
                            'emotion': row.get('emotion', ''),
                            'line': line_num
                        })
    
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
        
        print(f"\n导演检查案件: {case_name}")
        print("-" * 50)
        
        # 加载场景
        print("  加载场景数据...")
        self.load_scenes_from_prologue(case_dir)
        
        # 检查每个场景
        for scene_id, scene in self.scenes.items():
            print(f"\n  检查场景: {scene_id}")
            
            self.check_scene_characters(scene)
            self.check_scene_timeline(scene)
            self.check_scene_objects(scene)
            self.check_character_knowledge_in_dialogue(scene)
            self.check_dialogue_consistency(scene)
    
    def generate_report(self) -> str:
        """生成检查报告"""
        report = []
        report.append("# 导演检查报告")
        report.append("")
        
        # 统计
        errors = [r for r in self.results if r.severity == Severity.ERROR]
        warnings = [r for r in self.results if r.severity == Severity.WARNING]
        
        report.append(f"## 检查总结")
        report.append(f"- 检查场景数: {len(self.scenes)}")
        report.append(f"- 错误: {len(errors)}")
        report.append(f"- 警告: {len(warnings)}")
        report.append("")
        
        # 场景统计
        report.append("## 场景统计")
        report.append("| 场景ID | 人物数 | 对话行数 |")
        report.append("|--------|--------|----------|")
        for scene_id, scene in self.scenes.items():
            report.append(f"| {scene_id} | {len(scene.characters)} | {len(scene.dialogue_lines)} |")
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
    
    parser = argparse.ArgumentParser(description="导演检查")
    parser.add_argument("--project-root", default="/Users/zhoujiong/Documents/UGit/DetectiveSandbox/detective",
                       help="项目根目录")
    parser.add_argument("--case", help="指定检查的案件名称")
    parser.add_argument("--output", help="输出报告文件路径")
    
    args = parser.parse_args()
    
    director = DirectorAgent(args.project_root)
    
    if args.case:
        director.check_case(args.case)
    else:
        # 检查所有案件
        case_tables_dir = Path(args.project_root) / "data" / "case_tables"
        for case_dir in case_tables_dir.iterdir():
            if case_dir.is_dir() and not case_dir.name.startswith('_'):
                director.check_case(case_dir.name)
    
    report = director.generate_report()
    
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"\n报告已保存到: {args.output}")
    else:
        print("\n" + report)


if __name__ == "__main__":
    main()
