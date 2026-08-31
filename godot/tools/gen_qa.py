#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Quality tooling for generated pirate-cats art.

Two modes:

1) contact sheet
   python3 tools/gen_qa.py sheet --screen 08_transport
   Builds a labeled grid PNG of the generated images for a screen for manual QA.

2) cut QA (background-removed PNGs)
   python3 tools/gen_qa.py cut --screen 08_transport
   Prints transparent%/opaque%/partial%, bbox and edge-color stats per cut.

Reads from assets/art/generated/<screen>/.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEN = os.path.join(BASE, "assets", "art", "generated")


def list_cuts(screen):
    d = os.path.join(GEN, screen)
    if not os.path.isdir(d):
        return []
    return sorted(
        f for f in os.listdir(d)
        if f.endswith(".png") and os.path.getsize(os.path.join(d, f)) > 1000
    )


def contact_sheet(screen, cols=4, cell=300):
    files = list_cuts(screen)
    if not files:
        sys.exit(f"no images in {screen}")
    rows = (len(files) + cols - 1) // cols
    pad = 14
    label_h = 34
    w = cols * cell + (cols + 1) * pad
    h = rows * (cell + label_h) + (rows + 1) * pad
    sheet = Image.new("RGB", (w, h), (40, 40, 48))
    draw = ImageDraw.Draw(sheet)
    for i, f in enumerate(files):
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad)
        y = pad + r * (cell + label_h + pad)
        try:
            im = Image.open(os.path.join(GEN, screen, f)).convert("RGBA")
            bg = Image.new("RGBA", im.size, (180, 220, 255))
            im = Image.alpha_composite(bg, im).convert("RGB")
            im.thumbnail((cell, cell))
        except Exception:  # noqa: BLE001
            im = Image.new("RGB", (cell, cell), (255, 0, 0))
        sheet.paste(im, (x, y))
        draw.text((x + 2, y + cell + 6), f.replace(".png", ""), fill=(255, 255, 255))
    out = os.path.join(GEN, f"{screen}_sheet.png")
    sheet.save(out)
    print(f"sheet: {out} ({len(files)} imgs)")


def cut_qa(screen):
    files = list_cuts(screen)
    if not files:
        sys.exit(f"no images in {screen}")
    for f in files:
        path = os.path.join(GEN, screen, f)
        im = Image.open(path).convert("RGBA")
        a = im.split()[3]
        total = a.size
        hist = a.histogram()
        transparent = 100 * (sum(hist[0:10]) + sum(hist[10:32])) / total
        opaque = 100 * sum(hist[224:256]) / total
        partial = 100 * sum(hist[33:223]) / total
        print(f"{f:20s} transparent={transparent:5.1f}% opaque={opaque:5.1f}% partial={partial:5.2f}%")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["sheet", "cut"])
    ap.add_argument("--screen", required=True)
    ap.add_argument("--cols", type=int, default=4)
    args = ap.parse_args()
    if args.mode == "sheet":
        contact_sheet(args.screen, args.cols)
    else:
        cut_qa(args.screen)


if __name__ == "__main__":
    main()
