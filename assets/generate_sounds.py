import wave
import math
import struct
import random
import os

SAMPLE_RATE = 44100

def save_wav(filename, samples):
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        for s in samples:
            wav_file.writeframesraw(struct.pack('<h', int(max(-32768, min(32767, s * 32767)))))

def generate_tone(freq, duration, volume=0.5, wave_type='sine'):
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = float(i) / SAMPLE_RATE
        if wave_type == 'sine':
            val = math.sin(2 * math.pi * freq * t)
        elif wave_type == 'square':
            val = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        elif wave_type == 'saw':
            val = 2.0 * (t * freq - math.floor(0.5 + t * freq))
        elif wave_type == 'noise':
            val = random.uniform(-1.0, 1.0)
        
        # Simple envelope (fade in/out) to prevent clicking
        env = 1.0
        if i < 441: env = i / 441.0
        elif i > num_samples - 441: env = (num_samples - i) / 441.0
            
        samples.append(val * volume * env)
    return samples

def append_silence(samples, duration):
    samples.extend([0.0] * int(SAMPLE_RATE * duration))
    return samples

# 1. Hover SE (Softer tone, lower volume and frequency)
hover = generate_tone(700, 0.04, 0.12, 'sine')
save_wav('se_hover.wav', hover)

# 2. Whoosh SE (Noise sweep)
whoosh = []
for i in range(int(SAMPLE_RATE * 0.3)):
    t = i / float(SAMPLE_RATE)
    freq = 1000 - (t * 2000) # Sweep down
    val = random.uniform(-1.0, 1.0) * max(0, (0.3 - t))
    whoosh.append(val * 0.5)
save_wav('se_whoosh.wav', whoosh)

# 3. Tension SE (Heartbeat pulse / tick)
tension = generate_tone(100, 0.1, 0.8, 'sine') + [0.0]*int(SAMPLE_RATE*0.1) + generate_tone(100, 0.1, 0.6, 'sine')
save_wav('se_tension.wav', tension)

# 4. Fanfare SE (Major triad arpeggio)
fanfare = generate_tone(440, 0.15, 0.5, 'square') + generate_tone(554, 0.15, 0.5, 'square') + generate_tone(659, 0.3, 0.5, 'square') + generate_tone(880, 0.5, 0.5, 'square')
save_wav('se_fanfare.wav', fanfare)

# 5. BGM Title (Relaxing slow sequence)
bgm_title = []
for _ in range(4):
    bgm_title.extend(generate_tone(261.63, 0.5, 0.2, 'sine')) # C4
    bgm_title.extend(generate_tone(329.63, 0.5, 0.2, 'sine')) # E4
    bgm_title.extend(generate_tone(392.00, 0.5, 0.2, 'sine')) # G4
    bgm_title.extend(generate_tone(523.25, 0.5, 0.2, 'sine')) # C5
save_wav('bgm_title.wav', bgm_title)

# 6. BGM Tense (Dark low pulse)
bgm_tense = []
for _ in range(8):
    bgm_tense.extend(generate_tone(65.41, 0.2, 0.4, 'saw')) # C2
    bgm_tense.extend([0.0] * int(SAMPLE_RATE * 0.3))
    bgm_tense.extend(generate_tone(65.41, 0.2, 0.3, 'saw'))
    bgm_tense.extend([0.0] * int(SAMPLE_RATE * 0.3))
save_wav('bgm_tense.wav', bgm_tense)

# 7. BGM Result (Happy fast melody)
bgm_result = []
for _ in range(4):
    bgm_result.extend(generate_tone(523.25, 0.1, 0.3, 'square'))
    bgm_result.extend(generate_tone(587.33, 0.1, 0.3, 'square'))
    bgm_result.extend(generate_tone(659.25, 0.1, 0.3, 'square'))
    bgm_result.extend(generate_tone(783.99, 0.3, 0.3, 'square'))
save_wav('bgm_result.wav', bgm_result)

print("Audio files generated successfully.")
