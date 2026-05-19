#!/usr/bin/env python3
"""批量生成凌瑶（助手）的 TTS 语音文件。

使用 MiniMax CLI (mmx) 生成，音色为 female-shaonv-jingpin，语速 1.05。

用法:
  python3 tools/generate_companion_voices.py [--case linchuan_inn|xunyang_pavilion|all] [--delay 2] [--skip-existing]
"""

import json
import os
import subprocess
import sys
import time
import argparse

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data", "cases")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "cn", "voices", "actor_tomboy_courier")

# TTS 参数
VOICE = "female-shaonv-jingpin"
MODEL = "speech-2.8-hd"
SPEED = 1.05
SAMPLE_RATE = 24000
FORMAT = "wav"

CASES = ["linchuan_inn", "xunyang_pavilion"]


def find_mmx():
    """查找 mmx CLI 路径"""
    # 尝试 PATH 中的 mmx
    try:
        result = subprocess.run(["which", "mmx"], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    except:
        pass
    
    # 尝试 node 路径
    node_bin = os.path.expanduser("~/.workbuddy/binaries/node/versions/20.18.0/bin")
    mmx_path = os.path.join(node_bin, "mmx")
    if os.path.exists(mmx_path):
        return mmx_path
    
    # 也检查 npx
    try:
        result = subprocess.run(["npx", "--yes", "mmx", "--version"], capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return "npx --yes mmx"
    except:
        pass
    
    return None


def extract_lingyao_lines(data, rule_id_prefix=""):
    """从 banter/discussion JSON 中提取凌瑶的台词。
    
    返回: [(id, text), ...]
    """
    lines = []
    
    def process_lines_item(item, rule_id, idx):
        if isinstance(item, str):
            # 独白 - 就是凌瑶说的
            line_id = f"{rule_id}_{idx}"
            lines.append((line_id, item))
        elif isinstance(item, list):
            # 多人对话 - 只提取凌瑶的部分
            for turn_idx, turn in enumerate(item):
                if isinstance(turn, dict) and turn.get("speaker") == "凌瑶":
                    line_id = f"{rule_id}_{idx}_{turn_idx}"
                    lines.append((line_id, turn["text"]))
    
    if "rules" in data:
        for rule_idx, rule in enumerate(data["rules"]):
            rule_id = rule.get("id", f"rule_{rule_idx}")
            if rule_id_prefix:
                rule_id = f"{rule_id_prefix}_{rule_id}"
            
            if "lines" in rule:
                for idx, item in enumerate(rule["lines"]):
                    process_lines_item(item, rule_id, idx)
    
    # discussions 格式: { topic: { rules: [...] } }
    for key in data:
        if key.startswith("_"):
            continue
        if key == "rules":
            continue
        section = data[key]
        if isinstance(section, dict) and "rules" in section:
            for rule_idx, rule in enumerate(section["rules"]):
                rule_id = rule.get("id", f"{key}_rule_{rule_idx}")
                if rule_id_prefix:
                    rule_id = f"{rule_id_prefix}_{rule_id}"
                
                if "lines" in rule:
                    for idx, item in enumerate(rule["lines"]):
                        process_lines_item(item, rule_id, idx)
        
        # chitchat pool 格式: { pool: [{ lines: [...] }] }
        if isinstance(section, dict) and "pool" in section:
            for pool_idx, pool_item in enumerate(section["pool"]):
                rule_id = f"{key}_pool_{pool_idx}"
                if rule_id_prefix:
                    rule_id = f"{rule_id_prefix}_{rule_id}"
                
                if "lines" in pool_item:
                    for idx, item in enumerate(pool_item["lines"]):
                        process_lines_item(item, rule_id, idx)
    
    return lines


def sanitize_filename(text, max_len=30):
    """将文本转为安全文件名片段"""
    # 去掉标点和空格，取前几个字
    import re
    cleaned = re.sub(r'[^\w\u4e00-\u9fff]', '', text)
    return cleaned[:max_len]


def generate_tts(mmx_cmd, text, output_path):
    """调用 mmx CLI 生成 TTS"""
    cmd = [
        mmx_cmd, "speech", "generate",
        "--text", text,
        "--voice", VOICE,
        "--model", MODEL,
        "--format", FORMAT,
        "--sample-rate", str(SAMPLE_RATE),
        "--speed", str(SPEED),
        "--language", "Chinese",
        "--out", output_path,
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    return result.returncode == 0, result.stdout + result.stderr


def main():
    parser = argparse.ArgumentParser(description="批量生成凌瑶 TTS 语音")
    parser.add_argument("--case", choices=["linchuan_inn", "xunyang_pavilion", "all"], default="all")
    parser.add_argument("--delay", type=float, default=2.0, help="每条语音间隔秒数")
    parser.add_argument("--skip-existing", action="store_true", help="跳过已存在的文件")
    parser.add_argument("--dry-run", action="store_true", help="只列出要生成的台词，不实际生成")
    args = parser.parse_args()
    
    # 查找 mmx
    mmx_cmd = find_mmx()
    if not mmx_cmd and not args.dry_run:
        print("错误: 找不到 mmx CLI。请确保已安装 MiniMax CLI。")
        sys.exit(1)
    
    print(f"使用 mmx: {mmx_cmd}")
    print(f"音色: {VOICE}, 模型: {MODEL}, 语速: {SPEED}")
    print()
    
    cases = CASES if args.case == "all" else [args.case]
    all_lines = []
    
    for case_id in cases:
        case_dir = os.path.join(DATA_DIR, case_id)
        companion_dir = os.path.join(case_dir, "companion")
        
        if not os.path.isdir(companion_dir):
            print(f"⚠ 跳过 {case_id}: companion 目录不存在")
            continue
        
        # 处理 banter.json
        banter_path = os.path.join(companion_dir, "banter.json")
        if os.path.exists(banter_path):
            with open(banter_path, "r", encoding="utf-8") as f:
                banter_data = json.load(f)
            lines = extract_lingyao_lines(banter_data, case_id)
            print(f"📖 {case_id}/banter.json: 提取 {len(lines)} 条凌瑶台词")
            all_lines.extend(lines)
        
        # 处理 discussions.json
        discussions_path = os.path.join(companion_dir, "discussions.json")
        if os.path.exists(discussions_path):
            with open(discussions_path, "r", encoding="utf-8") as f:
                discussions_data = json.load(f)
            lines = extract_lingyao_lines(discussions_data, case_id)
            print(f"📖 {case_id}/discussions.json: 提取 {len(lines)} 条凌瑶台词")
            all_lines.extend(lines)
    
    print(f"\n共 {len(all_lines)} 条台词需要生成")
    
    if args.dry_run:
        print("\n--- DRY RUN ---")
        for line_id, text in all_lines:
            print(f"  [{line_id}] {text}")
        return
    
    # 创建输出目录
    for case_id in cases:
        os.makedirs(os.path.join(OUTPUT_DIR, case_id), exist_ok=True)
    
    # 逐条生成
    success = 0
    failed = 0
    skipped = 0
    
    for i, (line_id, text) in enumerate(all_lines):
        # 从 line_id 推断 case
        case_id = line_id.split("_")[0] if "_" in line_id else "linchuan_inn"
        # 修正: linchuan_inn 和 xunyang_pavilion
        if line_id.startswith("linchuan"):
            case_id = "linchuan_inn"
        elif line_id.startswith("xunyang"):
            case_id = "xunyang_pavilion"
        
        filename = f"{line_id}.wav"
        output_path = os.path.join(OUTPUT_DIR, case_id, filename)
        
        if args.skip_existing and os.path.exists(output_path):
            skipped += 1
            continue
        
        print(f"[{i+1}/{len(all_lines)}] {line_id}: {text[:40]}...")
        
        ok, output = generate_tts(mmx_cmd, text, output_path)
        if ok:
            success += 1
            # 解析时长
            try:
                info = json.loads(output[output.index("{"):])
                duration = info.get("duration_ms", 0) / 1000
                print(f"  ✓ {duration:.1f}s")
            except:
                print(f"  ✓ 已生成")
        else:
            failed += 1
            print(f"  ✗ 失败: {output[:200]}")
        
        if args.delay > 0 and i < len(all_lines) - 1:
            time.sleep(args.delay)
    
    print(f"\n=== 完成 ===")
    print(f"成功: {success}, 失败: {failed}, 跳过: {skipped}")


if __name__ == "__main__":
    main()
