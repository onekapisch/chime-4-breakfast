#!/usr/bin/env python3
"""Render a visual "audition sheet" of the 14 built-in sounds for the README.

Reads the real .wav files and draws each waveform into a labelled card, so the
gallery reflects the actual audio. Writes .github/assets/sounds.png.
"""
import array
import os
import wave

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOUNDS = os.path.join(ROOT, "Sources", "Chime4BreakfastApp", "Resources", "Sounds")
ASSETS = os.path.join(ROOT, ".github", "assets")
os.makedirs(ASSETS, exist_ok=True)

# id, label, one-line character. Order matches SoundOption.catalog.
CARDS = [
    ("tick", "Tick", "crisp click"),
    ("beep", "Beep", "clean single tone"),
    ("horn", "Horn", "warm two-note fanfare"),
    ("wave", "Wave", "soft rolling swell"),
    ("coin", "Coin", "arcade pickup blip"),
    ("glass", "Glass", "bright glassy ping"),
    ("ping", "Ping", "quick high ping"),
    ("chime", "Chime", "three-note bell"),
    ("pulse", "Pulse", "three soft pulses"),
    ("bloom", "Bloom", "slow opening swell"),
    ("spark", "Spark", "shimmer burst"),
    ("knock", "Knock", "low woody knock"),
    ("drift", "Drift", "airy low pad"),
    ("flare", "Flare", "rising bright sweep"),
]

# a cohesive, lively palette cycled across the grid
PALETTE = [
    (0x4F, 0x7B, 0xFF), (0xF0, 0x62, 0x3A), (0x3D, 0xB9, 0x78),
    (0x8B, 0x5C, 0xF6), (0x2A, 0xB8, 0xC8), (0xF2, 0xA0, 0x3B),
    (0xE5, 0x5A, 0x8A),
]

COLS, ROWS = 7, 2
CARD_W, CARD_H = 214, 176
GAP = 16
PAD = 34
TOP = 96
W = PAD * 2 + COLS * CARD_W + (COLS - 1) * GAP
H = TOP + PAD + ROWS * CARD_H + (ROWS - 1) * GAP


def font(size, bold=False):
    paths = ([("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0)] if bold
             else [("/System/Library/Fonts/SFNS.ttf", 0),
                   ("/System/Library/Fonts/Supplemental/Arial.ttf", 0)])
    for p, i in paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size, index=i)
            except Exception:
                pass
    return ImageFont.load_default()


def vgrad(size, top, bottom):
    w, h = size
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        col.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return col.resize((w, h))


def envelope(path, cols):
    """Return (mins, maxs, seconds) normalized to [-1, 1] over `cols` buckets."""
    with wave.open(path, "rb") as w:
        n = w.getnframes()
        sr = w.getframerate()
        raw = w.readframes(n)
    s = array.array("h")
    s.frombytes(raw)
    if not len(s):
        return [0] * cols, [0] * cols, 0.0
    peak = max(1, max(abs(v) for v in s))
    mins, maxs = [], []
    step = len(s) / cols
    for c in range(cols):
        a = int(c * step)
        b = max(a + 1, int((c + 1) * step))
        chunk = s[a:b]
        mins.append(min(chunk) / peak)
        maxs.append(max(chunk) / peak)
    return mins, maxs, n / sr


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def build():
    img = vgrad((W, H), (22, 22, 31), (10, 10, 15)).convert("RGBA")
    d = ImageDraw.Draw(img)
    d.text((PAD, 40), "14 sounds, each previewable in one click",
           font=font(30, bold=True), fill=(236, 238, 245))
    d.text((PAD, 78), "Synthesized from scratch, dedicated to the public domain (CC0)",
           font=font(16), fill=(150, 155, 170))

    for idx, (sid, label, desc) in enumerate(CARDS):
        r, c = divmod(idx, COLS)
        x = PAD + c * (CARD_W + GAP)
        y = TOP + PAD + r * (CARD_H + GAP)
        color = PALETTE[idx % len(PALETTE)]

        # card background
        card = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
        cd = ImageDraw.Draw(card)
        cd.rounded_rectangle([0, 0, CARD_W - 1, CARD_H - 1], radius=18,
                             fill=(255, 255, 255, 12), outline=(255, 255, 255, 26), width=1)

        # waveform
        wf_x0, wf_x1 = 18, CARD_W - 18
        wf_cy, wf_h = 96, 58
        cols = wf_x1 - wf_x0
        mins, maxs, secs = envelope(os.path.join(SOUNDS, f"{sid}.wav"), cols)
        for i in range(cols):
            xx = wf_x0 + i
            y0 = wf_cy - maxs[i] * wf_h
            y1 = wf_cy - mins[i] * wf_h
            if y1 - y0 < 1:
                y0, y1 = wf_cy - 0.5, wf_cy + 0.5
            cd.line([(xx, y0), (xx, y1)], fill=color + (235,), width=1)
        cd.line([(wf_x0, wf_cy), (wf_x1, wf_cy)], fill=(255, 255, 255, 22), width=1)

        # labels
        cd.ellipse([18, 22, 30, 34], fill=color + (255,))
        cd.text((38, 20), label, font=font(19, bold=True), fill=(240, 242, 248))
        cd.text((18, 48), desc, font=font(13), fill=(158, 163, 178))
        cd.text((CARD_W - 18, 150), f"{secs:.2f}s", font=font(12),
                fill=(140, 145, 160), anchor="rm")

        card.putalpha(Image.composite(card.getchannel("A"),
                                      Image.new("L", card.size, 0),
                                      rounded_mask(card.size, 18)))
        img.alpha_composite(card, (x, y))

    img.convert("RGB").save(os.path.join(ASSETS, "sounds.png"))
    print("wrote sounds.png", f"({W}x{H})")


if __name__ == "__main__":
    build()
