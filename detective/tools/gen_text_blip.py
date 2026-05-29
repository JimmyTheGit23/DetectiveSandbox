"""Generate 16-bit style text blip WAV files for typewriter effect."""
import wave
import struct
import math
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'cn', 'sfx')
SAMPLE_RATE = 44100

def gen_blip(filename, freq, volume, length=0.035):
    """Generate a single 16-bit soft blip (30% duty cycle square + triangle blend)."""
    num_samples = int(SAMPLE_RATE * length)
    attack = int(SAMPLE_RATE * 0.002)  # 2ms attack (softer)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        norm_t = t / length
        # 30% duty cycle square wave — much softer than 50%
        cycle_pos = (t * freq) % 1.0
        duty_square = 1.0 if cycle_pos < 0.30 else -1.0
        # Triangle wave for warmth
        triangle = 2.0 * abs(2.0 * cycle_pos - 1.0) - 1.0
        # Blend: 50% soft square + 50% triangle = warm 16-bit tone
        wave_mix = 0.5 * duty_square + 0.5 * triangle
        # Envelope: 2ms attack + gradual decay
        if num_samples <= attack:
            env = 1.0
        elif i < attack:
            env = i / attack
        else:
            env = max(0.0, 1.0 - 0.8 * ((i - attack) / (num_samples - attack)))
        amp = env * volume
        # Gentle low-pass fade at tail
        s = amp * wave_mix * (1.0 - 0.2 * norm_t)
        samples.append(int(max(-32768, min(32767, s * 32767))))

    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    wf = wave.open(path, 'w')
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
    wf.close()
    print(f'[OK] {path} ({len(samples)} samples, {freq}Hz)')


def gen_blip_profile(profile_name, variants):
    """Generate a set of blip variants for a character profile.
    variants: list of (filename_suffix, freq, volume) tuples
    """
    for suffix, freq, vol in variants:
        filename = f'blip_{profile_name}_{suffix}.wav'
        gen_blip(filename, freq, vol)


if __name__ == '__main__':
    # ─── 默认（主角/叙述） ───
    gen_blip_profile('default', [
        ('1', 340, 0.22),
        ('2', 380, 0.20),
        ('3', 300, 0.18),
    ])
    # 旧版兼容
    gen_blip_profile('default_compat', [
        ('', 340, 0.22),
    ])
    # 旧版 text_blip 文件保持兼容
    import shutil
    src = os.path.join(OUT_DIR, 'blip_default_1.wav')
    dst = os.path.join(OUT_DIR, 'text_blip.wav')
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f'[CP] {dst} (from {src})')

    # ─── 男青年（书生/公子）：清亮较高 ───
    gen_blip_profile('male_young', [
        ('1', 420, 0.20),
        ('2', 450, 0.18),
        ('3', 390, 0.16),
    ])

    # ─── 男中年（官员/捕头）：稳重 ───
    gen_blip_profile('male_middle', [
        ('1', 300, 0.24),
        ('2', 320, 0.22),
        ('3', 280, 0.20),
    ])

    # ─── 男粗犷（武人/捕快）：低沉有力 + 微噪 ───
    gen_blip_profile('male_rough', [
        ('1', 220, 0.28),
        ('2', 240, 0.26),
        ('3', 200, 0.24),
    ])

    # ─── 男老者（僧人/老吏）：低沉缓慢 ───
    gen_blip_profile('male_elder', [
        ('1', 200, 0.18),
        ('2', 210, 0.16),
        ('3', 180, 0.15),
    ])

    # ─── 女青年（温柔/花魁）：柔和较高 ───
    gen_blip_profile('female_young', [
        ('1', 500, 0.16),
        ('2', 530, 0.14),
        ('3', 470, 0.13),
    ])

    # ─── 女中年（掌柜/比丘尼）：沉稳 ───
    gen_blip_profile('female_middle', [
        ('1', 380, 0.18),
        ('2', 400, 0.16),
        ('3', 360, 0.15),
    ])

    # ─── 女老者：低沉庄重 ───
    gen_blip_profile('female_elder', [
        ('1', 280, 0.16),
        ('2', 300, 0.14),
        ('3', 260, 0.13),
    ])

    # ─── 年少（小厮/少年）：明亮活泼 ───
    gen_blip_profile('youth', [
        ('1', 520, 0.18),
        ('2', 560, 0.16),
        ('3', 490, 0.15),
    ])

    print('\n=== All character blip profiles generated! ===')
    # 列出所有生成的文件
    for f in sorted(os.listdir(OUT_DIR)):
        if f.startswith('blip_') or f.startswith('text_blip'):
            size = os.path.getsize(os.path.join(OUT_DIR, f))
            print(f'  {f} ({size} bytes)')
