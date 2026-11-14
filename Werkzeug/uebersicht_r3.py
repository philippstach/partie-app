#!/usr/bin/env python3
"""Übersicht Runde 3: python3 uebersicht_r3.py <Ordner> <Szene> [<Name>] -> uebersicht-<Name>.png (Tinte/Salon, hell oben, dunkel unten)."""
import sys, os
from PIL import Image
o, s = sys.argv[1], sys.argv[2]; n = sys.argv[3] if len(sys.argv) > 3 else s
W = 420
ims = [[Image.open(f"{o}/{d}-{m}-spiel-{s}.png").convert("RGB") for d in ("tinte", "salon")] for m in ("hell", "dunkel")]
ims = [[i.resize((W, round(i.height * W / i.width))) for i in z] for z in ims]
h = max(i.height for z in ims for i in z)
b = Image.new("RGB", (2 * W + 30, 2 * h + 30), (128, 128, 128))
for r, z in enumerate(ims):
    for c, i in enumerate(z): b.paste(i, (10 + c * (W + 10), 10 + r * (h + 10)))
b.save(f"{o}/uebersicht-{n}.png")
