#!/usr/bin/env python3
"""一键编译所有案件的CSV数据到JSON。

用法：
    python3 tools/compile_all.py                # 编译所有案件
    python3 tools/compile_all.py prologue_ferry  # 只编译指定案件
    python3 tools/compile_all.py --validate      # 编译后运行验证

注意：游戏引擎运行时直接从CSV编译，不读取JSON。
     此脚本仅用于离线工具（TTS、验证等）需要JSON时同步。
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COMPILER = ROOT / "tools" / "data_compiler" / "compile_case.py"
VALIDATOR = ROOT / "tools" / "data_compiler" / "validate_case_tables.py"
TABLES_ROOT = ROOT / "data" / "case_tables"


def find_cases():
    """列出所有有CSV文件的案件目录。"""
    cases = []
    for d in sorted(TABLES_ROOT.iterdir()):
        if d.is_dir() and not d.name.startswith(("_", ".")):
            csvs = list(d.glob("*.csv"))
            if csvs:
                cases.append(d.name)
    return cases


def compile_case(case_id: str, dry_run: bool = False) -> bool:
    """编译单个案件。"""
    cmd = [
        sys.executable,
        str(COMPILER),
        "--case", case_id,
        "--write-runtime",
    ]
    if dry_run:
        cmd.append("--dry-run")

    print(f"\n{'='*60}")
    print(f"  编译: {case_id}")
    print(f"{'='*60}")

    result = subprocess.run(cmd, cwd=str(ROOT))
    return result.returncode == 0


def validate_case(case_id: str) -> bool:
    """验证单个案件的CSV数据。"""
    if not VALIDATOR.exists():
        print(f"  [跳过验证] {VALIDATOR} 不存在")
        return True

    cmd = [sys.executable, str(VALIDATOR), "--case", case_id]
    print(f"  验证: {case_id}")
    result = subprocess.run(cmd, cwd=str(ROOT), capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  [验证失败] {case_id}")
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr)
        return False
    return True


def main():
    import argparse
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("case", nargs="?", help="指定案件ID（不指定则编译全部）")
    ap.add_argument("--validate", action="store_true", help="编译后运行验证")
    ap.add_argument("--dry-run", action="store_true", help="不实际写文件")
    ap.add_argument("--list", action="store_true", help="列出所有案件")
    args = ap.parse_args()

    if args.list:
        cases = find_cases()
        print(f"共 {len(cases)} 个案件:")
        for c in cases:
            print(f"  - {c}")
        return 0

    cases = [args.case] if args.case else find_cases()
    if not cases:
        print("未找到任何案件目录")
        return 1

    success = 0
    fail = 0
    for case_id in cases:
        if compile_case(case_id, args.dry_run):
            success += 1
            if args.validate:
                validate_case(case_id)
        else:
            fail += 1

    print(f"\n{'='*60}")
    print(f"  完成: {success} 成功, {fail} 失败")
    print(f"{'='*60}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
