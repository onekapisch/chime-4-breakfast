#!/usr/bin/env python3
"""Render an animated GIF of the screen-edge glow for the README.

Faithfully reproduces GlowBorderView: edge bands that fade inward (0.9 -> 0.32
-> clear), a soft rounded halo plus a crisp border line, a near-instant snap-in,
a steady hold for completions and a pulse for attention. Two scenes:
Claude finishing (warm, steady) then Codex needing you (blue, pulsing).

Writes .github/assets/glow.gif.
"""
import os

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, ".github", "assets")
os.makedirs(ASSETS, exist_ok=True)

W, H = 900, 560
CLAUDE = (240, 98, 58)
CODEX = (74, 108, 255)   # #3025FF reads too dark on black; lift slightly for GIF
FPS = 18
FRAME_MS = int(1000 / FPS)


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


# ---- static desktop backdrop with a mock chat window -----------------------
def make_backdrop(app_name, accent, caption, sub):
    img = vgrad((W, H), (26, 27, 34), (12, 12, 17)).convert("RGBA")
    d = ImageDraw.Draw(img)

    # centered app window
    win_w, win_h = 520, 300
    x0 = (W - win_w) // 2
    y0 = (H - win_h) // 2 - 20
    # shadow
    sh = Image.new("L", img.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle([x0, y0 + 14, x0 + win_w, y0 + win_h + 14], radius=18, fill=120)
    sh = sh.filter(ImageFilter.GaussianBlur(30))
    blk = Image.new("RGBA", img.size, (0, 0, 0, 255)); blk.putalpha(sh)
    img.alpha_composite(blk)

    d.rounded_rectangle([x0, y0, x0 + win_w, y0 + win_h], radius=18,
                        fill=(22, 23, 29, 255), outline=(255, 255, 255, 24), width=1)
    # title bar
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse([x0 + 20 + i * 20, y0 + 18, x0 + 32 + i * 20, y0 + 30], fill=c)
    d.text((x0 + win_w / 2, y0 + 24), app_name, font=font(14, bold=True),
           fill=(210, 214, 224), anchor="mm")

    # a few chat bubbles
    d.rounded_rectangle([x0 + 30, y0 + 66, x0 + 300, y0 + 96], radius=10, fill=(255, 255, 255, 16))
    d.rounded_rectangle([x0 + 30, y0 + 106, x0 + 250, y0 + 136], radius=10, fill=(255, 255, 255, 12))
    d.rounded_rectangle([x0 + win_w - 300, y0 + 152, x0 + win_w - 30, y0 + 182], radius=10,
                        fill=accent + (54,))
    d.rounded_rectangle([x0 + 30, y0 + 198, x0 + 210, y0 + 228], radius=10, fill=(255, 255, 255, 12))

    # "finished" chip
    chip_y = y0 + 250
    d.ellipse([x0 + 30, chip_y, x0 + 44, chip_y + 14], fill=accent + (255,))
    d.text((x0 + 52, chip_y + 7), f"{app_name} responded", font=font(13),
           fill=(180, 185, 198), anchor="lm")

    # caption band
    d.text((W / 2, H - 62), caption, font=font(24, bold=True), fill=(238, 240, 247), anchor="mm")
    d.text((W / 2, H - 34), sub, font=font(15), fill=(150, 155, 170), anchor="mm")
    return img.convert("RGB")


# ---- the glow overlay at a given strength -----------------------------------
def glow_layer(accent, strength):
    """Return an RGBA glow matching GlowBorderView, scaled by `strength` (0..1)."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    if strength <= 0:
        return layer
    bw = int(min(W, H) * 0.14)

    # edge bands: alpha 0.9 at the very edge -> ~0.32 -> 0 across the band.
    def band_alpha(t):  # t: 0 at edge, 1 at inner
        return max(0.0, 0.9 * (1 - t) ** 1.7)

    edge = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ed = ImageDraw.Draw(edge)
    for i in range(bw):
        a = int(255 * band_alpha(i / bw) * strength)
        if a <= 0:
            continue
        col = accent + (a,)
        ed.line([(0, i), (W, i)], fill=col)                 # top
        ed.line([(0, H - 1 - i), (W, H - 1 - i)], fill=col)  # bottom
        ed.line([(i, 0), (i, H)], fill=col)                 # left
        ed.line([(W - 1 - i, 0), (W - 1 - i, H)], fill=col)  # right
    layer.alpha_composite(edge)

    # soft rounded halo + crisp inner border line
    radius = int(min(W, H) * 0.05)
    halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.rounded_rectangle([10, 10, W - 10, H - 10], radius=radius,
                         outline=accent + (int(180 * strength),), width=16)
    halo = halo.filter(ImageFilter.GaussianBlur(16))
    layer.alpha_composite(halo)

    line = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line)
    ld.rounded_rectangle([10, 10, W - 10, H - 10], radius=radius,
                         outline=accent + (int(235 * strength),), width=3)
    line = line.filter(ImageFilter.GaussianBlur(1.2))
    layer.alpha_composite(line)
    return layer


def compose(backdrop, accent, strength):
    frame = backdrop.convert("RGBA")
    frame.alpha_composite(glow_layer(accent, strength))
    return frame.convert("RGB")


# ---- timeline ---------------------------------------------------------------
def build():
    claude_bg = make_backdrop("Claude", CLAUDE,
                              "Claude just finished", "you stepped away, so the edge lights up warm")
    codex_bg = make_backdrop("Codex", CODEX,
                             "Codex needs you", "a question or blocker pulses a stronger blue")

    frames, durations = [], []

    def hold(bg, accent, strength, n, ms=FRAME_MS):
        f = compose(bg, accent, strength)
        for _ in range(n):
            frames.append(f)
            durations.append(ms)

    def ramp(bg, accent, a, b, n):
        for k in range(n):
            s = a + (b - a) * (k + 1) / n
            frames.append(compose(bg, accent, s))
            durations.append(FRAME_MS)

    # Scene 1 - Claude completion: snap in, steady hold, fade out
    hold(claude_bg, CLAUDE, 0.0, 3, ms=260)   # rest
    ramp(claude_bg, CLAUDE, 0.0, 0.95, 2)     # near-instant snap-in
    hold(claude_bg, CLAUDE, 0.95, 8)          # steady dwell (~1 s)
    ramp(claude_bg, CLAUDE, 0.95, 0.0, 5)     # ease out

    # Scene 2 - Codex attention: snap in, pulse a few times, clear
    hold(codex_bg, CODEX, 0.0, 3, ms=240)
    ramp(codex_bg, CODEX, 0.0, 1.0, 2)
    for _ in range(2):                         # two attention pulses
        ramp(codex_bg, CODEX, 1.0, 0.5, 3)
        ramp(codex_bg, CODEX, 0.5, 1.0, 3)
    ramp(codex_bg, CODEX, 1.0, 0.0, 5)
    hold(codex_bg, CODEX, 0.0, 2, ms=500)      # breath before the loop

    out = os.path.join(ASSETS, "glow.gif")
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=durations,
                   loop=0, optimize=True, disposal=2)
    size_kb = os.path.getsize(out) / 1024
    print(f"wrote glow.gif  ({len(frames)} frames, {size_kb:.0f} KB)")


if __name__ == "__main__":
    build()
