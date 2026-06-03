#!/usr/bin/env python3
"""Resolve merge conflicts in testimony_press_lines.csv."""
import sys
from pathlib import Path

FILE = Path(__file__).resolve().parent.parent / "data" / "case_tables" / "prologue_ferry" / "testimony_press_lines.csv"

with open(FILE, "r", encoding="utf-8-sig") as f:
    lines = f.readlines()

print(f"Input lines: {len(lines)}")
print(f"Input conflicts: {sum(1 for l in lines if l.strip().startswith('<<<<<<<'))}")

result = []
in_conflict = False
take_upstream = True
is_sf34 = False

i = 0
while i < len(lines):
    line = lines[i]
    stripped = line.strip()

    if stripped.startswith("<<<<<<< Updated upstream"):
        in_conflict = True
        take_upstream = True
        is_sf34 = False
        # Look ahead to check if this is the sf3_4 conflict
        j = i + 1
        while j < len(lines) and not lines[j].strip().startswith("======="):
            if "sf3_4,2" in lines[j]:
                is_sf34 = True
            j += 1
        i += 1
        continue

    if in_conflict and stripped.startswith("======="):
        if is_sf34:
            take_upstream = False  # Take stashed (correct毒囊 version)
        in_conflict = False
        i += 1
        continue

    if in_conflict and stripped.startswith(">>>>>>> Stashed changes"):
        in_conflict = False
        i += 1
        continue

    if in_conflict:
        if take_upstream:
            result.append(line)
        i += 1
        continue

    result.append(line)
    i += 1

content = "".join(result)
print(f"After conflict resolution lines: {len(result)}")

# Remove （插话） and fix 陆公子->大人 for Shen Qingyue
lines2 = content.split("\n")
new_lines = []
for line in lines2:
    if "（插话）" in line:
        line = line.replace("（插话）", "")
    parts = line.split(",", 4)
    if len(parts) >= 3 and parts[2].strip() == "沈清月":
        line = line.replace("陆公子", "大人")
    new_lines.append(line)

content = "\n".join(new_lines)

conflict_count = content.count("<<<<<<<")
cha_count = content.count("（插话）")
print(f"Conflicts remaining: {conflict_count}")
print(f"（插话） remaining: {cha_count}")

with open(FILE, "w", encoding="utf-8-sig", newline="") as f:
    f.write(content)

print("Done!")
