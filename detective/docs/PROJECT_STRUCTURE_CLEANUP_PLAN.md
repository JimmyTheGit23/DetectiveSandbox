# 项目数据结构整理方案

> 审计时间：2026-06-14 00:26
> 执行时间：2026-06-14 00:37

## 执行记录

| 操作 | 状态 | 说明 |
|------|------|------|
| 删除 `_compiled/` 中间目录 | ✅ 完成 | |
| 删除 `docs/_backup_outdated/` | ✅ 完成 | 38个过时文档 |
| 删除根目录 `AGENT_*.md/txt` | ✅ 完成 | 4个文件 |
| 添加 `data/cases/prologue_ferry/README.md` | ✅ 完成 | 标注JSON为编译产物 |
| 创建 `tools/compile_all.py` | ✅ 完成 | 一键编译脚本 |
| 确认手写JSON已被CSV覆盖 | ✅ 完成 | 见下方关键发现 |

## 关键发现

**游戏引擎运行时100%从CSV直接编译数据**（CaseTableLoader.gd），**不读取 `data/cases/` 下的任何JSON文件**。

- `data/cases/prologue_ferry/` 下的JSON仅供离线工具（TTS、验证）使用
- 改CSV后不需要跑编译器，游戏即时生效
- 需要同步JSON时用：`python3 tools/compile_all.py prologue_ferry`

---

## 一、当前问题诊断

### 问题1：数据双源——CSV和JSON并存，容易不同步

```
data/case_tables/prologue_ferry/*.csv    ← 手工编辑的源文件
         ↓ compile_case.py
data/case_tables/prologue_ferry/_compiled/*.json  ← Python编译输出（预览）
data/cases/prologue_ferry/*.json          ← 运行时数据（--write-runtime 写入）
```

**但是**：
- `CaseTableLoader.gd` 在运行时**也从CSV直接编译**（第700行 `_compile_confrontation`）
- 所以同样的数据存在**三份**：CSV源 → Python编译JSON → GD运行时编译
- 如果改了CSV忘记跑 `--write-runtime`，Python编译的JSON和GD运行时的结果不同
- `data/cases/prologue_ferry/` 下还有**手写的JSON**（`prologue.json`、`bgm_config.json`、`npcs.json`、`manifest.json`），不由CSV驱动

### 问题2：`data/cases/` 里混合了编译产物和手写源

| 文件 | 来源 | 问题 |
|------|------|------|
| `case.json` | CSV编译 | 每次改CSV需重新编译 |
| `evidence.json` | CSV编译 | 同上 |
| `prologue.json` | **手写JSON** | 不在CSV体系中 |
| `bgm_config.json` | **手写JSON** | 不在CSV体系中 |
| `npcs.json` | **手写JSON** + CSV编译merge | 基础数据手写，CSV补充 |
| `manifest.json` | CSV编译 | 同上 |

### 问题3：备份和过时文档散落

- `BACKUP/` 目录：89个PNG + 47个MD + 各种旧文件
- `docs/_backup_outdated/`：8个过时的分析/设计文档
- 根目录有5个 `AGENT_*.md`/`AGENT_*.txt` 文件

### 问题4：翻译文件膨胀

`data/case_tables/prologue_ferry/` 下有 **~300个 `.translation` 文件**（每个CSV列自动生成一个），加上 `.csv.import` 文件，共422个文件中CSV源文件只占~44个。

---

## 二、整理方案

### 方案A：明确"CSV是唯一真相"（推荐）

**原则**：所有游戏数据的**唯一编辑入口**是CSV，JSON都是编译产物。

**具体步骤**：

#### 1. 消灭手写JSON——把 `prologue.json`、`bgm_config.json` 等迁入CSV体系

| 手写JSON | 迁入的CSV | 说明 |
|----------|----------|------|
| `prologue.json` | 已有 `prologue_nodes.csv` + `prologue_lines.csv` | 已在CSV体系 |
| `bgm_config.json` | 已有 `json_docs.csv` (doc_id=bgm_config) | 已在CSV体系 |
| `npcs.json` | 已有 `characters.csv` | 需确认是否完整覆盖 |
| `key_info.json` | 已有 `json_docs.csv` (doc_id=key_info) | 已在CSV体系 |

**行动**：检查这些JSON是否还被直接手动编辑。如果编译器已经从CSV完整生成它们，就把手写版删掉，只保留编译产物。

#### 2. 统一编译流程——一个命令搞定所有

```bash
# 当前需要
python3 tools/data_compiler/compile_case.py --case prologue_ferry --write-runtime

# 建议改为
make compile  # 或 python3 tools/compile_all.py
```

**行动**：
- 写一个 `Makefile` 或 `tools/compile_all.py`，一键编译所有case
- 编译时自动验证（调用 `validate_case_tables.py`）
- 编译成功后自动写入 `data/cases/`
- **删除 `_compiled/` 中间目录**，直接写到 `data/cases/`

#### 3. 清理 `data/cases/` 目录——只放编译产物

```
data/cases/prologue_ferry/
  ├── .gitignore          ← 所有JSON都是生成物，不入git
  ├── case.json           ← 编译生成
  ├── evidence.json       ← 编译生成
  ├── ...
```

**或者**保留入git（因为Godot导出需要），但明确标记为"不要手动编辑"。

#### 4. 清理备份和过时文档

| 操作 | 目标 |
|------|------|
| 删除 | `BACKUP/` 整个目录（如果资产已在 `assets/` 中） |
| 删除 | `docs/_backup_outdated/` 整个目录 |
| 删除 | 根目录 `AGENT_*.md`、`AGENT_*.txt`（agent信息在 `.codebuddy/agents/` 中） |
| 保留 | `docs/CHARACTER_VOICE_GUIDE.md`（语言身份证） |
| 保留 | `docs/PROLOGUE_FULL_NARRATIVE.md`（叙事文档） |
| 保留 | `docs/REWRITE_PROGRESS_LOG.md`（重写日志） |
| 保留 | `docs/DATA_SCHEMA_REFERENCE.md`（数据格式参考） |
| 保留 | `docs/DATA_DRIVEN_AUTHORING_DESIGN.md`（数据驱动设计） |

#### 5. 解决GD运行时编译的冲突

`CaseTableLoader.gd` 在运行时也从CSV编译数据。这意味着：
- 编辑器里运行游戏 → 用GD从CSV实时编译（总是最新的）
- 导出游戏 → 用 `data/cases/*.json`（需要先编译）

**建议**：保持这种双路机制（开发时方便），但在编辑器中加一个 `EditorPlugin` 按钮"编译数据"，或者在每次 Play 前自动编译。

---

## 三、最终目标结构

```
data/
├── case_tables/              ← 唯一编辑入口
│   ├── case_index.csv
│   └── prologue_ferry/
│       ├── *.csv             ← 44个CSV源文件
│       └── (no _compiled/)   ← 不再需要中间目录
│
├── cases/                    ← 编译产物（只读）
│   ├── _index.json
│   └── prologue_ferry/
│       ├── *.json            ← 全部由CSV编译生成
│       └── companion/*.json
│       └── dialogues/*.json
│
├── actors/                   ← 独立配置（手工维护）
├── bgm/                     ← 独立配置
├── companions/              ← 独立配置
├── meta/                    ← 独立配置
├── scenes/                  ← 独立配置
└── voices/                  ← 独立配置

docs/
├── CHARACTER_VOICE_GUIDE.md  ← 语言身份证
├── DATA_SCHEMA_REFERENCE.md  ← 数据格式参考
├── DATA_DRIVEN_AUTHORING_DESIGN.md
├── PROLOGUE_FULL_NARRATIVE.md
├── REWRITE_PROGRESS_LOG.md
└── PROLOGUE_CHARACTER_ARCHIVE.md

tools/
├── data_compiler/            ← 编译器
│   ├── compile_case.py
│   ├── validate_case_tables.py
│   └── export_case_tables.py
├── remove_purple_bg.py       ← 图片工具
└── Makefile / compile_all.py  ← 一键编译（新增）
```

---

## 四、执行优先级

| 优先级 | 操作 | 影响范围 | 风险 |
|--------|------|---------|------|
| **P0** | 删除 `_compiled/` 中间目录 | 无风险 | 低 |
| **P0** | 删除 `docs/_backup_outdated/` | 无风险 | 低 |
| **P0** | 删除根目录的 `AGENT_*.md/txt` | 无风险 | 低 |
| **P1** | 确认手写JSON是否已被CSV覆盖 | 需逐文件检查 | 中 |
| **P1** | 写 `tools/compile_all.py` 一键编译 | 提升效率 | 低 |
| **P2** | 清理 `BACKUP/` 目录 | 需确认哪些资产还被引用 | 中 |
| **P2** | `.translation` 文件整理 | Godot自动生成，暂不管 | 低 |

