#!/usr/bin/env python3
"""Render forge-screens/*.txt to PNGs matching the existing images.

by-file: whole .txt; by-screen: one PNG per ASCII box; menu-only: [Tool]/[Category] boxes.
Only writes images whose content changed, so untouched PNGs stay byte-identical.

Usage: tools/render_screens.py forge-screens 00-index,08-code HEAD
  arg 1: forge-screens directory
  arg 2: comma-separated screen stems to render
  arg 3: git revision to compare against (unchanged boxes are skipped)
"""
import os, sys, io
from PIL import Image, ImageDraw, ImageFont, ImageChops

FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 29.82,
                          layout_engine=ImageFont.Layout.RAQM)
BG, CARD, DOT, FG = (5, 7, 10), (13, 17, 23), (58, 68, 83), (201, 209, 217)
ADV, LH, OX, OY = 17.948, 42, 67, 127

def render(lines):
    n = max((len(l) for l in lines), default=0)
    W, H = round(n * ADV) + 134, LH * len(lines) + 176
    im = Image.new("RGB", (W, H), BG); d = ImageDraw.Draw(im)
    d.rounded_rectangle([2, 2, W - 3, H - 3], radius=18, fill=CARD)
    for cx in (69, 108, 148):
        d.ellipse([cx - 8, 52, cx + 8, 68], fill=DOT)
    for k, l in enumerate(lines):
        if l.strip():
            d.text((OX, OY + k * LH), l, font=FONT, fill=FG)
    return im

def boxes(lines):
    out, cur = [], None
    for l in lines:
        s = l.strip()
        if cur is None and s.startswith(".") and s.endswith(".") and "-" in s:
            cur = [l]
        elif cur is not None:
            cur.append(l)
            if s.startswith("'") and s.endswith("'"):
                out.append(cur); cur = None
    return out

def is_menu(b): return "[Tool]" in b[1] or "[Category]" in b[1]

def write(im, path, old_lines, new_lines):
    if old_lines == new_lines and os.path.exists(path):
        return False
    im.save(path, optimize=True); return True

if __name__ == "__main__":
    root, stems, oldrev = sys.argv[1], sys.argv[2].split(","), sys.argv[3]
    import subprocess
    for stem in stems:
        txt = os.path.join(root, stem + ".txt")
        new = open(txt).read().rstrip("\n").split("\n")
        old = subprocess.run(["git", "-C", root, "show", f"{oldrev}:forge-screens/{stem}.txt"],
                             capture_output=True, text=True).stdout.rstrip("\n").split("\n")
        changed = []
        if write(render(new), f"{root}/images-by-file/{stem}.png", old, new): changed.append(f"images-by-file/{stem}.png")
        ob, nb = boxes(old), boxes(new)
        for i, b in enumerate(nb, 1):
            name = f"{stem}-{i:02d}.png"; prev = ob[i - 1] if i <= len(ob) else None
            im = render(b)
            if write(im, f"{root}/images-by-screen/{name}", prev, b): changed.append("images-by-screen/" + name)
            if is_menu(b) and write(im, f"{root}/images-menu-only/{name}", prev, b): changed.append("images-menu-only/" + name)
        print(stem, len(nb), "boxes;", "written:", *changed, sep="\n  ")
