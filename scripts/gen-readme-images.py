#!/usr/bin/env python3
"""Generate README marketing images from the real app.

Composites the live popover screenshot (rendered by PopoverSnapshotTests to
/tmp/popover-snapshot.png) and the app icon into a branded hero, a framed
popover shot, and a screen-glow illustration — all written to .github/assets/.
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, ".github", "assets")
ICON = os.path.join(ROOT, "Sources/Chime4BreakfastApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png")
POPOVER = "/tmp/popover-snapshot.png"
os.makedirs(ASSETS, exist_ok=True)

CLAUDE = (240, 98, 58)      # #F0623A
CODEX = (48, 37, 255)       # #3025FF
BLUE = (79, 123, 255)
VIOLET = (139, 92, 246)


def font(size, bold=False):
    tries = (
        [("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0),
         ("/System/Library/Fonts/Helvetica.ttc", 1)]
        if bold else
        [("/System/Library/Fonts/SFNS.ttf", 0),
         ("/System/Library/Fonts/Helvetica.ttc", 0),
         ("/System/Library/Fonts/Supplemental/Arial.ttf", 0)]
    )
    for path, idx in tries:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size, index=idx)
            except Exception:
                continue
    return ImageFont.load_default()


def vgrad(size, top, bottom):
    w, h = size
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        col.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return col.resize((w, h))


def glow(canvas, center, diameter, color, max_alpha):
    base = ImageOps.invert(Image.radial_gradient("L")).resize((diameter, diameter))
    alpha = base.point(lambda v: int(v * max_alpha / 255))
    tint = Image.new("RGBA", (diameter, diameter), color + (0,))
    tint.putalpha(alpha)
    canvas.alpha_composite(tint, (center[0] - diameter // 2, center[1] - diameter // 2))


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def framed(img, radius=44, blur=46, offset=(0, 22), pad=90, shadow_alpha=150, border=(255, 255, 255, 46)):
    r = rounded(img, radius)
    w, h = r.size
    canvas = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    sh = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle(
        [pad + offset[0], pad + offset[1], pad + offset[0] + w, pad + offset[1] + h],
        radius=radius, fill=shadow_alpha)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    black = Image.new("RGBA", canvas.size, (0, 0, 0, 255))
    black.putalpha(sh)
    canvas.alpha_composite(black)
    canvas.alpha_composite(r, (pad, pad))
    ImageDraw.Draw(canvas).rounded_rectangle([pad, pad, pad + w - 1, pad + h - 1], radius=radius, outline=border, width=2)
    return canvas


def wrap(draw, text, fnt, max_w):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        trial = (cur + " " + wd).strip()
        if draw.textlength(trial, font=fnt) <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = wd
    if cur:
        lines.append(cur)
    return lines


def pill(draw, xy, text, fnt, dot=None):
    x, y = xy
    pad_x, h = 15, 34
    tw = draw.textlength(text, font=fnt)
    extra = 22 if dot else 0
    w = int(tw + pad_x * 2 + extra)
    draw.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=(255, 255, 255, 16),
                           outline=(255, 255, 255, 30), width=1)
    tx = x + pad_x
    if dot:
        cy = y + h // 2
        draw.ellipse([tx, cy - 4, tx + 8, cy + 4], fill=dot)
        tx += extra
    draw.text((tx, y + h / 2), text, font=fnt, fill=(220, 224, 235, 255), anchor="lm")
    return w


# ---------------------------------------------------------------- hero
def build_hero():
    W, H = 1680, 620
    img = vgrad((W, H), (20, 20, 29), (7, 7, 11)).convert("RGBA")
    glow(img, (300, 150), 900, BLUE, 46)
    glow(img, (830, 640), 1000, VIOLET, 30)
    glow(img, (1520, 90), 640, CLAUDE, 26)

    draw = ImageDraw.Draw(img)

    icon = Image.open(ICON).convert("RGBA").resize((188, 188), Image.LANCZOS)
    ishadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sh = Image.new("L", img.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle([96, 118, 96 + 188, 118 + 188], radius=42, fill=150)
    sh = sh.filter(ImageFilter.GaussianBlur(34))
    blk = Image.new("RGBA", img.size, (0, 0, 0, 255)); blk.putalpha(sh)
    img.alpha_composite(blk)
    img.alpha_composite(icon, (96, 118))

    x = 322
    draw.text((x, 150), "Chime 4 Breakfast", font=font(66, bold=True), fill=(255, 255, 255))
    draw.text((x, 236), "Walk away from your AI — it'll call you back.", font=font(30), fill=(196, 201, 214))
    for i, line in enumerate(wrap(draw,
            "A native macOS menu-bar watcher for Codex & Claude Desktop. A sound "
            "— and a screen-edge glow when you've stepped away — the moment a reply lands.",
            font(21), 640)):
        draw.text((x, 300 + i * 30), line, font=font(21), fill=(146, 151, 166))

    px = x
    py = 430
    fp = font(15, bold=True)
    px += pill(draw, (px, py), "100% local", fp, dot=(61, 185, 120)) + 10
    px += pill(draw, (px, py), "Screen glow", fp, dot=BLUE) + 10
    pill(draw, (px, py), "Codex & Claude", fp, dot=CLAUDE)

    if os.path.exists(POPOVER):
        pop = Image.open(POPOVER).convert("RGBA")
        scale = 520 / pop.height
        pop = pop.resize((int(pop.width * scale), 520), Image.LANCZOS)
        card = framed(pop, radius=34, blur=40, offset=(0, 20), pad=70)
        img.alpha_composite(card, (W - card.width - 60, (H - card.height) // 2))

    img.convert("RGB").save(os.path.join(ASSETS, "hero.png"))
    print("wrote hero.png")


# ---------------------------------------------------------------- popover
def build_popover():
    if not os.path.exists(POPOVER):
        return
    pop = Image.open(POPOVER).convert("RGBA")
    card = framed(pop, radius=42, blur=50, offset=(0, 24), pad=90)
    card.save(os.path.join(ASSETS, "popover.png"))
    print("wrote popover.png")


# ---------------------------------------------------------------- glow demo
def build_glow_demo():
    W, H = 1560, 600
    img = vgrad((W, H), (17, 17, 24), (6, 6, 9)).convert("RGBA")
    glow(img, (W // 2, H // 2), 1200, (30, 30, 40), 80)

    def screen(cx, color, app_name, caption):
        cx = int(cx)
        sw, sh = 560, 300
        x0, y0 = cx - sw // 2, 150
        # colored edge glow
        g = Image.new("RGBA", (sw + 260, sh + 260), (0, 0, 0, 0))
        gm = Image.new("L", g.size, 0)
        ImageDraw.Draw(gm).rounded_rectangle([120, 120, 120 + sw, 120 + sh], radius=26, outline=255, width=30)
        gm = gm.filter(ImageFilter.GaussianBlur(38))
        tint = Image.new("RGBA", g.size, color + (0,)); tint.putalpha(gm.point(lambda v: int(v * 0.95)))
        img.alpha_composite(tint, (x0 - 120, y0 - 120))
        # screen body
        d = ImageDraw.Draw(img)
        d.rounded_rectangle([x0, y0, x0 + sw, y0 + sh], radius=24, fill=(13, 13, 17, 255),
                            outline=color + (255,), width=3)
        # inner content hint
        d.rounded_rectangle([x0 + 34, y0 + 40, x0 + sw - 180, y0 + 66], radius=6, fill=(255, 255, 255, 18))
        d.rounded_rectangle([x0 + 34, y0 + 92, x0 + sw - 90, y0 + 118], radius=6, fill=(255, 255, 255, 12))
        d.rounded_rectangle([x0 + 34, y0 + 144, x0 + sw - 240, y0 + 170], radius=6, fill=(255, 255, 255, 12))
        d.ellipse([x0 + 30, y0 + sh - 58, x0 + 54, y0 + sh - 34], fill=color + (255,))
        d.text((x0 + 66, y0 + sh - 46), app_name, font=font(20, bold=True), fill=(235, 238, 245), anchor="lm")
        d.text((cx, y0 + sh + 52), caption, font=font(21), fill=(170, 175, 190), anchor="mm")

    screen(W * 0.28, CLAUDE, "Claude", "Claude finished — warm glow")
    screen(W * 0.72, CODEX, "Codex", "Codex finished — blue glow")
    ImageDraw.Draw(img).text((W // 2, 70),
                             "The edge lights up in the app's own color — so you know who's done, at a glance",
                             font=font(24, bold=True), fill=(225, 228, 238), anchor="mm")
    img.convert("RGB").save(os.path.join(ASSETS, "glow-demo.png"))
    print("wrote glow-demo.png")


build_hero()
build_popover()
build_glow_demo()
print("done")
