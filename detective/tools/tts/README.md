# 本地 TTS 生成

本目录用于开发期本地生成语音。游戏运行时**不依赖** Python / ChatTTS / torch；只依赖已经生成并提交的 `.wav` 文件。

## 目标

- 每个 `actor_id` 固定一个 `speaker_seed`，保证同一演员跨台词/案件声线一致。
- 输出路径完全符合运行时 `AssetResolver` 约定：
  - 对话：`assets/cn/voices/{actor_id}/{case_id}/{node_id}.wav`
  - 序章：`assets/cn/voices/_prologue/{case_id}/{node_id}.wav`
  - 事件：`assets/cn/voices/_events/{case_id}/{evt_id}_{idx}.wav`
- 生成完提交 `.wav` 后，其他机器（macOS/Windows/Linux/导出包）可直接播放。

## 当前 backend 状态

| backend | 命令参数 | 状态 | 用途 |
|---------|----------|------|------|
| ChatTTS | `--engine chattts` | 已接入；依赖已可安装；当前机器下载 HuggingFace 模型失败（网络 EOF/reset） | 推荐的快速本地测试方案 |
| macOS say | `--engine macos_say` | 已接入；仅 macOS 可用；效果差 | 仅用于验证路径/播放链路，不作为正式语音 |
| CosyVoice2 | `--engine cosyvoice` | 预留接口，未安装 | 后续正式中文配音优先方向 |

> 2026-05-17 试跑记录：`macos_say` 已验证播放链路，但声音机械，试听 wav 已删除；`ChatTTS` 卡在模型下载，不是代码问题。

## 安装 ChatTTS

### macOS / Linux

```bash
cd <project-root>
python3 -m venv .venv-tts
source .venv-tts/bin/activate
pip install --upgrade pip
pip install -r tools/tts/requirements-chattts.txt
```

### Windows PowerShell

```powershell
cd <project-root>
py -3 -m venv .venv-tts
.\.venv-tts\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r tools/tts/requirements-chattts.txt
```

如果 `torch` 安装失败，请先去 https://pytorch.org/get-started/locally/ 安装当前平台匹配版本，然后再安装：

```bash
pip install numpy soundfile
pip install git+https://github.com/2noise/ChatTTS.git
```

## ChatTTS 模型下载

默认会用 `huggingface_hub` 下载 `2Noise/ChatTTS`。网络不稳定时可尝试：

```bash
source .venv-tts/bin/activate
export HF_ENDPOINT=https://hf-mirror.com
python tools/generate_local_voices.py --case xunyang_pavilion --engine chattts --actor actor_wealthy_merchant --only-missing --limit 2
```

如果仍报 `EOF` / `connection reset` / `LocalEntryNotFoundError`，需要换网络/VPN，或手动把 `2Noise/ChatTTS` 下载到 HuggingFace cache。

## 声线配置

配置文件：`data/voices/actor_voice_profiles.json`

关键字段：

- `speaker_seed`：声线种子，绑定 `actor_id`。
- `speed`：ChatTTS 速度 token，建议 3~6。
- `temperature`：采样温度，0.25~0.45 较稳。
- `oral/laugh/break`：ChatTTS refine token。

注意：ChatTTS 不保证不同平台/不同 torch 版本生成结果 bit-perfect 一致。若要发布稳定版本，请提交生成好的 wav。

## 预演

只看会生成哪些文件，不实际跑模型：

```bash
python tools/generate_local_voices.py --case xunyang_pavilion --dry-run --limit 12
```

## 生成第二案缺失语音

先少量测试一个角色：

```bash
python tools/generate_local_voices.py --case xunyang_pavilion --engine chattts --actor actor_wealthy_merchant --only-missing --limit 2
python tools/audit_voices.py
```

确认效果后全量生成：

```bash
python tools/generate_local_voices.py --case xunyang_pavilion --engine chattts --only-missing
python tools/audit_voices.py
```

## macOS say debug（不推荐正式使用）

仅用于检查路径和游戏播放链路：

```bash
python tools/generate_local_voices.py --case xunyang_pavilion --engine macos_say --actor actor_wealthy_merchant --only-missing --limit 1
```

试听后若效果不满意，应删除对应 wav 并重跑：

```bash
rm assets/cn/voices/actor_wealthy_merchant/xunyang_pavilion/*.wav
python tools/audit_voices.py
```

## 常用过滤

```bash
# 只生成某个 NPC 的对话
python tools/generate_local_voices.py --case xunyang_pavilion --npc bu_zhang --only-missing

# 只生成序章
python tools/generate_local_voices.py --case xunyang_pavilion --kind prologue --only-missing

# 只生成事件叙述
python tools/generate_local_voices.py --case xunyang_pavilion --kind event --only-missing

# 覆盖重生成某个 actor
python tools/generate_local_voices.py --case xunyang_pavilion --actor actor_opera_performer --overwrite
```

## 生成后检查

```bash
python tools/audit_voices.py
python tools/regression/run_static.py
```

若第二案语音全部生成完，可把 `data/cases/xunyang_pavilion/manifest.json` 的 `voice_status` 从 `missing` 改为 `full`。
