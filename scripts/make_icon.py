#!/usr/bin/env python3
"""Generate the simple_speed_reader icon set.

The mark is the app's own stage in miniature: the word "read" in white
monospace on the near-black stage, its ORP letter (the 'e', by the app's
own pivot law: 4 chars -> 2nd) in the accent red, with the red tick marks
above and below the pivot -- exactly the running-state frame.

Sizes >= 48 carry the full word; 32/24/16 simplify to a single 'r' with
the red ticks (four glyphs cannot survive 16 px).

Outputs:
  app/resources/speed_reader.ico   (256/128/64/48/32/24/16, per-size rendered)
  docs/images/icon-256.png         (README/docs raster)
Run from the repo root:  python3 scripts/make_icon.py
"""

from PIL import Image, ImageDraw, ImageFont

BG = (13, 13, 15, 255)          # stage near-black #0d0d0f
EDGE = (42, 42, 46, 255)        # faint rim for dark taskbars
INK = (232, 232, 234, 255)      # word white #e8e8ea
RED = (229, 72, 77, 255)        # pivot red #e5484d
FONT_PATH = r"C:\Windows\Fonts\consolab.ttf"   # Consolas Bold

SS = 4  # supersample factor for crisp small sizes


def rounded_stage(draw, w, r):
    draw.rounded_rectangle([0, 0, w - 1, w - 1], radius=r, fill=BG,
                           outline=EDGE, width=max(1, w // 128))


def glyph_box(font, text):
    l, t, r, b = font.getbbox(text)
    return l, t, r - l, b - t


def render(size):
    """One square icon layer at `size`, drawn at SSx and downsampled."""
    w = size * SS
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded_stage(d, w, int(w * 0.18))

    full = size >= 48
    text = "read" if full else "r"
    pivot_i = 1 if full else 0          # 'e' of read; the lone 'r' is its own pivot
    fsize = int(w * (0.30 if full else 0.62))
    font = ImageFont.truetype(FONT_PATH, fsize)

    l, t, tw, th = glyph_box(font, text)
    tx = (w - tw) // 2 - l
    ty = (w - th) // 2 - t

    # word: prefix white, pivot red, suffix white (advance-accurate, like the stage)
    x = tx
    for i, ch in enumerate(text):
        # small sizes keep the glyph white: red is spent on the ticks alone
        red_here = full and i == pivot_i
        d.text((x, ty), ch, font=font, fill=RED if red_here else INK)
        x += d.textlength(ch, font=font)

    # red ticks above/below the pivot glyph's center x
    pre = d.textlength(text[:pivot_i], font=font)
    piv_w = d.textlength(text[pivot_i], font=font)
    cx = tx + pre + piv_w / 2
    tick_w = max(SS, int(w * 0.045))
    tick_h = int(w * 0.14)
    gap = int(w * 0.075)
    top_y = (w - th) // 2 - gap - tick_h
    bot_y = (w + th) // 2 + gap
    for y0 in (top_y, bot_y):
        d.rectangle([cx - tick_w / 2, y0, cx + tick_w / 2, y0 + tick_h], fill=RED)

    return img.resize((size, size), Image.LANCZOS)


def main():
    sizes = [256, 128, 64, 48, 32, 24, 16]
    layers = {s: render(s) for s in sizes}

    import os
    os.makedirs("app/resources", exist_ok=True)
    os.makedirs("docs/images", exist_ok=True)

    layers[256].save("docs/images/icon-256.png")
    layers[256].save("app/resources/speed_reader.ico", format="ICO",
                     append_images=[layers[s] for s in sizes[1:]],
                     sizes=[(s, s) for s in sizes])

    ico = Image.open("app/resources/speed_reader.ico")
    print("ICO embedded sizes:", sorted(ico.info.get("sizes", []), reverse=True))
    print("Wrote app/resources/speed_reader.ico and docs/images/icon-256.png")


if __name__ == "__main__":
    main()
