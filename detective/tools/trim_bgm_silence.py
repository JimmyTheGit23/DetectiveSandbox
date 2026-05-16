"""
剪掉 Lyria 生成 BGM 开头的静音部分（音频未"暖起来"的几秒）。
保留尾部，重新封 WAV。
"""
from pathlib import Path
import wave
import struct

BGM_DIR = Path(__file__).resolve().parent.parent / "assets/cn/bgm"

# 静音判定：振幅 < 这个阈值视为静音
SILENCE_THRESHOLD = 200
# 至少要连续多少帧不静音才算"真正开始"
WINDOW_FRAMES = 4800  # ~0.1s at 48kHz


def find_audio_start(wav_path: Path) -> int:
    """返回第一个"足够响"的帧位置。"""
    w = wave.open(str(wav_path), "rb")
    rate = w.getframerate()
    channels = w.getnchannels()
    sampwidth = w.getsampwidth()
    nframes = w.getnframes()
    
    # 每 0.05 秒检查一次窗口
    step = int(rate * 0.05)
    pos = 0
    while pos + WINDOW_FRAMES < nframes:
        w.setpos(pos)
        raw = w.readframes(WINDOW_FRAMES)
        # 取每个采样的绝对值平均
        samples_per_frame = channels
        total = 0
        count = 0
        for i in range(0, len(raw), sampwidth):
            v = int.from_bytes(raw[i:i+sampwidth], "little", signed=True)
            total += abs(v)
            count += 1
            if count > 5000:
                break
        avg = total / max(count, 1)
        if avg >= SILENCE_THRESHOLD:
            w.close()
            return pos
        pos += step
    
    w.close()
    return 0


def trim_silence(wav_path: Path, extra_skip_seconds: float = 0.5) -> None:
    """剪掉开头的静音 + 额外多剪一点点（避免淡入起来还是静音）。"""
    w = wave.open(str(wav_path), "rb")
    rate = w.getframerate()
    channels = w.getnchannels()
    sampwidth = w.getsampwidth()
    nframes = w.getnframes()
    
    start = find_audio_start(wav_path)
    # 多剪 extra_skip_seconds 让淡入起来时已经是真正的音乐
    start = max(0, start + int(rate * extra_skip_seconds))
    if start <= 0:
        print(f"  {wav_path.name}: 没有需要剪的静音 (start={start})")
        w.close()
        return
    
    w.setpos(start)
    remaining_frames = nframes - start
    pcm = w.readframes(remaining_frames)
    w.close()
    
    # 重写 WAV
    out_path = wav_path  # 原地覆盖
    byte_rate = rate * channels * sampwidth
    block_align = channels * sampwidth
    data_size = len(pcm)
    riff_size = 36 + data_size
    
    with open(out_path, "wb") as f:
        f.write(b"RIFF")
        f.write(struct.pack("<I", riff_size))
        f.write(b"WAVE")
        f.write(b"fmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, channels, rate, byte_rate, block_align, sampwidth * 8))
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        f.write(pcm)
    
    print(f"  ✓ {wav_path.name}: 剪掉 {start/rate:.2f}s 开头静音 → 剩 {data_size/byte_rate:.1f}s")


def main():
    for wav_path in sorted(BGM_DIR.glob("*.wav")):
        trim_silence(wav_path)


if __name__ == "__main__":
    main()
