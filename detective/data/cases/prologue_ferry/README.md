# ⚠️ 不要手动编辑此目录下的JSON文件

这些JSON文件全部由 CSV 编译生成，运行时引擎（CaseTableLoader.gd）**直接从CSV编译数据，不读取这些JSON**。

## 唯一编辑入口

```
data/case_tables/prologue_ferry/*.csv
```

## 何时需要重新编译JSON

仅当需要使用离线工具（TTS语音生成、验证脚本等）时：

```bash
python3 tools/data_compiler/compile_case.py --case prologue_ferry --write-runtime
```

## 文件来源

| 文件 | CSV源 |
|------|-------|
| case.json | confrontations.csv + testimony_*.csv + case_meta.csv |
| evidence.json | evidence_items.csv |
| npcs.json / casting.json | characters.csv |
| locations.json | locations.csv + location_links.csv + search_points.csv |
| dialogues/*.json | dialogue_nodes.csv + dialogue_lines.csv + dialogue_options.csv |
| day_events.json | day_events.csv + day_event_lines.csv |
| progression.json | progression_phases.csv + progression_unlocks.csv |
| companion/*.json | companion_*.csv |
| prologue.json | prologue_nodes.csv + prologue_lines.csv + prologue_choices.csv |
| bgm_config.json | json_docs.csv (doc_id=bgm_config) |
