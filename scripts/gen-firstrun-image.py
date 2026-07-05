#!/usr/bin/env python3
"""Render the first-run onboarding flow for the README.

Three steps: drag to Applications, enable in Accessibility (one time), watching.
Writes .github/assets/first-run.png.
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, ".github", "assets")
ICON = os.path.join(ROOT, "Sources/Chime4BreakfastApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png")
os.makedirs(ASSETS, exist_ok=True)

GREEN = (61, 185, 120)
BLUE = (79, 123, 255)

W, H = 1500, 440
PAD = 40
GAP = 30
CARD_W = (W - 2 * PAD - 2 * GAP) // 3
CARD_H = 320
CARD_Y = 96


def font(size, bold=False, weight=None):
    if weight is None:
        weight = "Bold" if bold else "Regular"
    for p in (f"/Library/Fonts/SF-Pro-Text-{weight}.otf",
              f"/Library/Fonts/SF-Pro-Display-{weight}.otf",
              "/System/Library/Fonts/SFNS.ttf",
              "/System/Library/Fonts/Supplemental/Arial.ttf"):
        if os.path.exists(p):
            try:
                from PIL import ImageFont
                return ImageFont.truetype(p, size)
            except Exception:
                continue
    from PIL import ImageFont
    return ImageFont.load_default()


def vgrad(size, top, bottom):
    w, h = size
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        col.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return col.resize((w, h))


def rounded_icon(size):
    icon = Image.open(ICON).convert("RGBA").resize((size, size), Image.LANCZOS)
    return icon


def card(img, idx):
    x = PAD + idx * (CARD_W + GAP)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x, CARD_Y, x + CARD_W, CARD_Y + CARD_H], radius=22,
                        fill=(30, 32, 42), outline=(56, 58, 70), width=1)
    return x


def step_number(d, x, n, tint):
    cx, cy = x + 34, CARD_Y + 34
    d.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=tint + (255,))
    d.text((cx, cy), str(n), font=font(18, bold=True), fill=(12, 12, 16), anchor="mm")


def build():
    img = vgrad((W, H), (22, 22, 31), (11, 11, 16)).convert("RGBA")
    d = ImageDraw.Draw(img)

    d.text((PAD, 34), "Up and running in three steps",
           font=font(30, weight="Bold"), fill=(236, 238, 245))

    # ---- Step 1: drag to Applications ----
    x = card(img, 0)
    step_number(d, x, 1, BLUE)
    cxc = x + CARD_W // 2
    icon = rounded_icon(96)
    img.alpha_composite(icon, (int(cxc - 120), CARD_Y + 96))
    # arrow
    d.line([(cxc - 8, CARD_Y + 144), (cxc + 40, CARD_Y + 144)], fill=(150, 155, 170), width=4)
    for dx in range(10):
        d.line([(cxc + 40 - dx, CARD_Y + 144 - dx), (cxc + 40 - dx, CARD_Y + 144 + dx)], fill=(150, 155, 170), width=1)
    # applications folder glyph
    fx, fy = cxc + 60, CARD_Y + 108
    d.rounded_rectangle([fx, fy, fx + 74, fy + 62], radius=10, fill=(70, 120, 210, 255))
    d.rounded_rectangle([fx, fy - 8, fx + 34, fy + 14], radius=6, fill=(70, 120, 210, 255))
    d.text((cxc, CARD_Y + 214), "Drag into Applications", font=font(21, weight="Semibold"),
           fill=(224, 227, 236), anchor="mm")
    d.text((cxc, CARD_Y + 250), "from the downloaded DMG", font=font(16),
           fill=(150, 155, 170), anchor="mm")

    # ---- Step 2: enable in Accessibility (macOS toggle row) ----
    x = card(img, 1)
    step_number(d, x, 2, GREEN)
    row_x0, row_y0 = x + 26, CARD_Y + 104
    row_w, row_h = CARD_W - 52, 64
    d.rounded_rectangle([row_x0, row_y0, row_x0 + row_w, row_y0 + row_h], radius=14,
                        fill=(46, 48, 58))
    ic = rounded_icon(40)
    img.alpha_composite(ic, (row_x0 + 14, row_y0 + 12))
    d.text((row_x0 + 66, row_y0 + row_h // 2), "Chime 4 Breakfast",
           font=font(17, weight="Semibold"), fill=(240, 242, 248), anchor="lm")
    # green macOS toggle (on)
    tw, th = 46, 28
    tx = row_x0 + row_w - tw - 16
    ty = row_y0 + (row_h - th) // 2
    d.rounded_rectangle([tx, ty, tx + tw, ty + th], radius=th // 2, fill=GREEN + (255,))
    d.ellipse([tx + tw - th + 3, ty + 3, tx + tw - 3, ty + th - 3], fill=(255, 255, 255, 255))
    cxc = x + CARD_W // 2
    d.text((cxc, CARD_Y + 214), "Enable in Accessibility", font=font(21, weight="Semibold"),
           fill=(224, 227, 236), anchor="mm")
    d.text((cxc, CARD_Y + 250), "one time, System Settings, Privacy", font=font(16),
           fill=(150, 155, 170), anchor="mm")

    # ---- Step 3: watching ----
    x = card(img, 2)
    step_number(d, x, 3, BLUE)
    cxc = x + CARD_W // 2
    icon = rounded_icon(88)
    img.alpha_composite(icon, (int(cxc - 44), CARD_Y + 92))
    # watching pill
    pill = "Watching"
    pf = font(16, weight="Semibold")
    pw = int(d.textlength(pill, font=pf)) + 46
    px = cxc - pw // 2
    py = CARD_Y + 196
    d.rounded_rectangle([px, py, px + pw, py + 34], radius=17, fill=(16, 18, 26, 200),
                        outline=GREEN + (200,), width=2)
    d.ellipse([px + 14, py + 13, px + 22, py + 21], fill=GREEN + (255,))
    d.text((px + 30, py + 17), pill, font=pf, fill=(240, 242, 248), anchor="lm")
    d.text((cxc, CARD_Y + 256), "Move on. It pings you when a reply lands.",
           font=font(16), fill=(150, 155, 170), anchor="mm")

    img.convert("RGB").save(os.path.join(ASSETS, "first-run.png"))
    print("wrote first-run.png", f"({W}x{H})")


if __name__ == "__main__":
    build()
