#!/usr/bin/env python3
"""Extract remaining JSON text to CSV: dialogues_base, companion_config, manifest."""
import csv, json, pathlib

CASE_DIR = pathlib.Path(__file__).resolve().parent.parent / "data" / "case_tables" / "prologue_ferry"
JSON_DOCS = CASE_DIR / "json_docs.csv"

def read_docs():
    docs = {}
    with open(JSON_DOCS, "r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            docs[row["doc_id"]] = json.loads(row["json"])
    return docs

def write_csv(path, headers, rows):
    with open(path, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(headers)
        for r in rows:
            w.writerow(r)
    print(f"  {path.name}: {len(rows)} rows")

docs = read_docs()

# ─── 1. companion_config → companion_config.csv + companion_tutorial_hints.csv ─
print("--- companion_config ---")
cc = docs.get("companion_config", {})
# Tutorial hints
hints = cc.get("tutorial_hints", {})
hint_rows = []
for key, text in hints.items():
    hint_rows.append({"hint_key": key, "text": text})
write_csv(CASE_DIR / "companion_tutorial_hints.csv", ["hint_key", "text"], 
          [[r["hint_key"], r["text"]] for r in hint_rows])

# Config fields (non-text)
config_row = {
    "companion_id": cc.get("companion_id", ""),
    "role_name": cc.get("role_name", ""),
    "actor_id": cc.get("actor_id", ""),
    "available_topics": json.dumps(cc.get("available_topics", []), ensure_ascii=False),
    "limits": json.dumps(cc.get("limits", {}), ensure_ascii=False),
    "lock_on_final_day": str(cc.get("lock_on_final_day", False)).lower(),
    "banter_max_per_day": cc.get("banter_max_per_day", ""),
    "intro_hint": cc.get("intro_hint", ""),
    "tutorial_mode": str(cc.get("tutorial_mode", False)).lower(),
}
headers = list(config_row.keys())
write_csv(CASE_DIR / "companion_config.csv", headers, [[config_row[h] for h in headers]])

# ─── 2. manifest → case_info.csv ──────────────────────────────────────────────
print("--- manifest ---")
mf = docs.get("manifest", {})
info_row = {}
for key in ["id", "title", "subtitle", "order", "difficulty", "estimated_days", "max_days",
            "main_scene", "preview_image", "synopsis", "intro", "era", "locale", 
            "companion", "is_tutorial", "voice_status"]:
    v = mf.get(key, "")
    if isinstance(v, bool):
        v = str(v).lower()
    info_row[key] = str(v)
# scenes, files, directories, rewards → JSON
for key in ["scenes", "files", "directories", "rewards"]:
    if key in mf:
        info_row[key] = json.dumps(mf[key], ensure_ascii=False)
headers = list(info_row.keys())
write_csv(CASE_DIR / "case_info.csv", headers, [[info_row[h] for h in headers]])

# ─── 3. Remove dialogues_base, key_info, culprit_actions_base, case_base ──────
print("\n--- Updating json_docs.csv ---")
remaining = {}
# Keep bgm_config (audio config, no text to extract)
if "bgm_config" in docs:
    remaining["bgm_config"] = docs["bgm_config"]

with open(JSON_DOCS, "w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f)
    w.writerow(["doc_id", "json"])
    for doc_id, data in remaining.items():
        w.writerow([doc_id, json.dumps(data, ensure_ascii=False)])

print(f"\nRemaining docs: {list(remaining.keys())}")
print("Done! Only bgm_config remains in json_docs.csv")