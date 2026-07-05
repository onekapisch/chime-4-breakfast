#!/usr/bin/env python3
"""Synthesize the 14 built-in alert sounds from scratch.

Every sound is generated procedurally with the Python standard library only
(no samples, no third-party audio). The output is original work dedicated to
the public domain under CC0 1.0, so the whole app ships license-clean. Run:

    python3 scripts/gen-sounds.py

to regenerate Sources/Chime4BreakfastApp/Resources/Sounds/*.wav. Output format
matches what the app expects: 16-bit mono PCM WAV at 44.1 kHz.
"""
import math
import os
import struct
import wave

SR = 44100
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Sources", "Chime4BreakfastApp", "Resources", "Sounds",
)

TAU = 2 * math.pi


# --------------------------------------------------------------- buffer helpers
def buf(seconds):
    return [0.0] * int(SR * seconds)


def dur(b):
    return len(b) / SR


def add(b, start, samples):
    """Mix `samples` into buffer `b` starting at time `start` (seconds)."""
    i0 = int(start * SR)
    for i, v in enumerate(samples):
        j = i0 + i
        if 0 <= j < len(b):
            b[j] += v


# ------------------------------------------------------------------ envelopes
def env_ad(n, attack, decay, curve=2.5):
    """Attack then exponential-ish decay over n samples."""
    a = max(1, int(attack * SR))
    out = []
    for i in range(n):
        if i < a:
            e = i / a
        else:
            t = (i - a) / max(1, n - a)
            e = math.exp(-curve * t) * (1 - t)  # decay to 0 at the tail
        out.append(e)
    return out


def env_perc(n, k=5.0):
    """Instant attack, exponential decay (percussive)."""
    return [math.exp(-k * (i / n)) for i in range(n)]


# ------------------------------------------------------------------ oscillators
def tone(freq, seconds, env=None, harmonics=(1.0,), detune=0.0, phase=0.0):
    n = int(seconds * SR)
    out = [0.0] * n
    for hi, amp in enumerate(harmonics, start=1):
        if amp == 0:
            continue
        f = freq * hi * (1 + detune * hi)
        w = TAU * f / SR
        for i in range(n):
            out[i] += amp * math.sin(w * i + phase)
    if env is None:
        env = env_ad(n, 0.005, seconds)
    return [out[i] * env[i] for i in range(n)]


def sweep(f0, f1, seconds, env=None, curve="exp"):
    """Glide from f0 to f1."""
    n = int(seconds * SR)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / n
        f = f0 * (f1 / f0) ** t if curve == "exp" else f0 + (f1 - f0) * t
        phase += TAU * f / SR
        out[i] = math.sin(phase)
    if env is None:
        env = env_ad(n, 0.005, seconds)
    return [out[i] * env[i] for i in range(n)]


# deterministic pseudo-noise (no Random module needed, reproducible)
def noise_seq(n, seed=1):
    x = seed & 0xFFFFFFFF
    out = []
    for _ in range(n):
        x = (1103515245 * x + 12345) & 0x7FFFFFFF
        out.append((x / 0x3FFFFFFF) - 1.0)
    return out


def noise(seconds, env=None, seed=1, lp=0.0):
    n = int(seconds * SR)
    s = noise_seq(n, seed)
    if lp > 0:  # simple one-pole low-pass, lp in [0,1)
        for i in range(1, n):
            s[i] = s[i - 1] * lp + s[i] * (1 - lp)
    if env is None:
        env = env_perc(n, 6)
    return [s[i] * env[i] for i in range(n)]


# ------------------------------------------------------------------ the sounds
def s_tick():
    b = buf(0.09)
    add(b, 0.0, noise(0.02, env_perc(int(0.02 * SR), 40), seed=7, lp=0.2))
    add(b, 0.0, [0.5 * v for v in tone(2100, 0.05, env_perc(int(0.05 * SR), 30))])
    return b


def s_beep():
    b = buf(0.22)
    add(b, 0.0, tone(880, 0.2, env_ad(int(0.2 * SR), 0.008, 0.2, 2.0)))
    return b


def s_horn():
    # two stacked detuned saw-ish tones, a friendly car-horn fifth
    b = buf(0.55)
    h = (1.0, 0.6, 0.4, 0.28, 0.18, 0.12)
    e = env_ad(int(0.5 * SR), 0.02, 0.5, 1.6)
    add(b, 0.02, tone(392, 0.5, e, harmonics=h))          # G4
    add(b, 0.02, [0.8 * v for v in tone(587, 0.5, e, harmonics=h)])  # D5
    return b


def s_wave():
    # soft rolling swell, gentle vibrato
    b = buf(0.9)
    n = int(0.85 * SR)
    e = env_ad(n, 0.14, 0.85, 1.4)
    out = [0.0] * n
    for i in range(n):
        vib = 1 + 0.006 * math.sin(TAU * 5 * i / SR)
        out[i] = (math.sin(TAU * 320 * vib * i / SR)
                  + 0.5 * math.sin(TAU * 480 * vib * i / SR)) * e[i]
    add(b, 0.0, out)
    return b


def s_coin():
    # classic pickup: quick blip then a higher sustained blip
    b = buf(0.42)
    sq = (1.0, 0.0, 0.5, 0.0, 0.33, 0.0, 0.22)  # odd harmonics -> square-ish
    add(b, 0.0, [0.7 * v for v in tone(988, 0.06, env_perc(int(0.06 * SR), 12), harmonics=sq)])
    add(b, 0.06, [0.7 * v for v in tone(1319, 0.3, env_ad(int(0.3 * SR), 0.004, 0.3, 3.0), harmonics=sq)])
    return b


def s_glass():
    # bright inharmonic ping, glassy overtones
    b = buf(0.8)
    partials = [(1.0, 1.0), (2.76, 0.5), (5.40, 0.28), (8.93, 0.16)]
    for mult, amp in partials:
        n = int(0.75 * SR)
        add(b, 0.0, [amp * v for v in tone(1400 * mult / 1.0, 0.75,
             env_perc(n, 4.0 + mult))])
    return b


def s_ping():
    b = buf(0.4)
    add(b, 0.0, tone(1568, 0.36, env_perc(int(0.36 * SR), 7), harmonics=(1.0, 0.25)))
    return b


def s_chime():
    # three-note ascending bell (major triad)
    b = buf(1.1)
    notes = [(523.25, 0.0), (659.25, 0.09), (783.99, 0.18)]  # C5 E5 G5
    h = (1.0, 0.6, 0.25, 0.12, 0.06)
    for f, t in notes:
        n = int(0.85 * SR)
        add(b, t, [0.8 * v for v in tone(f, 0.85, env_perc(n, 4.5), harmonics=h)])
    return b


def s_pulse():
    # three soft rhythmic pulses at one pitch
    b = buf(0.6)
    for k in range(3):
        add(b, k * 0.13, [0.9 * v for v in tone(660, 0.1,
            env_ad(int(0.1 * SR), 0.006, 0.1, 4.0), harmonics=(1.0, 0.4))])
    return b


def s_bloom():
    # slow upward swell that opens up in brightness
    b = buf(1.0)
    n = int(0.95 * SR)
    e = env_ad(n, 0.3, 0.95, 1.2)
    out = [0.0] * n
    for i in range(n):
        t = i / n
        bright = 0.3 + 0.7 * t
        out[i] = (math.sin(TAU * 440 * i / SR)
                  + bright * 0.5 * math.sin(TAU * 880 * i / SR)
                  + bright * 0.25 * math.sin(TAU * 1320 * i / SR)) * e[i]
    add(b, 0.0, out)
    return b


def s_spark():
    # bright noisy transient + high shimmer
    b = buf(0.3)
    add(b, 0.0, [0.6 * v for v in noise(0.12, env_perc(int(0.12 * SR), 22), seed=13, lp=0.05)])
    add(b, 0.0, [0.5 * v for v in sweep(2600, 3600, 0.14, env_perc(int(0.14 * SR), 16))])
    return b


def s_knock():
    # low woody double knock
    b = buf(0.45)
    for t in (0.0, 0.14):
        n = int(0.12 * SR)
        add(b, t, [0.9 * v for v in tone(180, 0.12, env_perc(n, 30), harmonics=(1.0, 0.5, 0.3))])
        add(b, t, [0.4 * v for v in noise(0.03, env_perc(int(0.03 * SR), 40), seed=21, lp=0.5)])
    return b


def s_drift():
    # airy low pad with slow detuned beating
    b = buf(1.2)
    n = int(1.15 * SR)
    e = env_ad(n, 0.35, 1.15, 1.0)
    out = [0.0] * n
    for i in range(n):
        out[i] = (math.sin(TAU * 220 * i / SR)
                  + math.sin(TAU * 221.5 * i / SR)  # beating
                  + 0.4 * math.sin(TAU * 330 * i / SR)) * e[i]
    add(b, 0.0, out)
    return b


def s_flare():
    # fast bright rising sweep with a tail
    b = buf(0.6)
    add(b, 0.0, [0.9 * v for v in sweep(500, 2000, 0.35,
        env_ad(int(0.35 * SR), 0.01, 0.35, 2.2))])
    add(b, 0.28, [0.5 * v for v in tone(2000, 0.28, env_perc(int(0.28 * SR), 8),
        harmonics=(1.0, 0.4, 0.2))])
    return b


SOUNDS = {
    "tick": s_tick, "beep": s_beep, "horn": s_horn, "wave": s_wave,
    "coin": s_coin, "glass": s_glass, "ping": s_ping, "chime": s_chime,
    "pulse": s_pulse, "bloom": s_bloom, "spark": s_spark, "knock": s_knock,
    "drift": s_drift, "flare": s_flare,
}


# ------------------------------------------------------------------ write
def normalize(b, peak=0.89):
    m = max((abs(v) for v in b), default=1.0) or 1.0
    g = peak / m
    return [v * g for v in b]


def soft_fade(b, ms=6):
    # short fade in/out to avoid clicks
    f = int(SR * ms / 1000)
    n = len(b)
    for i in range(min(f, n)):
        b[i] *= i / f
        b[n - 1 - i] *= i / f
    return b


def write_wav(path, b):
    b = soft_fade(normalize(b))
    frames = bytearray()
    for v in b:
        s = max(-1.0, min(1.0, v))
        frames += struct.pack("<h", int(s * 32767))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SOUNDS.items():
        b = fn()
        path = os.path.join(OUT, f"{name}.wav")
        write_wav(path, b)
        print(f"wrote {name}.wav  ({dur(b):.2f}s)")
    print(f"\n{len(SOUNDS)} sounds written to {OUT}")


if __name__ == "__main__":
    main()
