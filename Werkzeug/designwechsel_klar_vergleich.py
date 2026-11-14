#!/usr/bin/env python3
"""Designwechsel: vergleicht die Bilder aus <Ordner>/alt und <Ordner>/neu Punkt für Punkt.

Aufruf: designwechsel_klar_vergleich.py <Ordner>     (wird von designwechsel_klar_vergleich.sh aufgerufen)
Schreibt <Ordner>/ERGEBNIS.txt und für jedes abweichende Paar ein Bild unterschied-<name>.png
(links alt, Mitte neu, rechts die abweichenden Punkte in Rot). Rückgabe 1, wenn etwas abweicht.
"""
import sys
from pathlib import Path
from PIL import Image, ImageChops

ordner = Path(sys.argv[1])
alt, neu = ordner / "alt", ordner / "neu"
for f in ordner.glob("unterschied-*.png"):
    f.unlink()
zeilen, abweichend = [], 0
namen = sorted({p.name for p in alt.glob("*.png")} | {p.name for p in neu.glob("*.png")})
for name in namen:
    a, n = alt / name, neu / name
    if not a.exists() or not n.exists():
        zeilen.append(f"FEHLT   {name} ({'alt' if not a.exists() else 'neu'} fehlt)")
        abweichend += 1
        continue
    ba, bn = Image.open(a).convert("RGB"), Image.open(n).convert("RGB")
    if ba.size != bn.size:
        zeilen.append(f"GRÖSSE  {name} alt {ba.size} neu {bn.size}")
        abweichend += 1
        continue
    diff = ImageChops.difference(ba, bn)
    kasten = diff.getbbox()
    if kasten is None:
        zeilen.append(f"gleich  {name}")
        continue
    grau = diff.convert("L")
    punkte = sum(1 for v in grau.getdata() if v > 0)
    staerke = max(grau.getdata())
    anteil = punkte / (ba.size[0] * ba.size[1])
    zeilen.append(f"ANDERS  {name}: {punkte} Punkte ({anteil:.4%}), größte Abweichung {staerke}/255, Bereich {kasten}")
    abweichend += 1
    maske = grau.point(lambda v: 255 if v > 0 else 0)
    rot = Image.composite(Image.new("RGB", ba.size, (255, 0, 0)), bn.point(lambda v: 200 + v // 5), maske)
    bogen = Image.new("RGB", (ba.size[0] * 3 + 40, ba.size[1]), "white")
    for i, b in enumerate((ba, bn, rot)):
        bogen.paste(b, (i * (ba.size[0] + 20), 0))
    bogen.save(ordner / f"unterschied-{name}")
kopf = f"{len(namen)} Bildpaare, {len(namen) - abweichend} gleich, {abweichend} abweichend"
(ordner / "ERGEBNIS.txt").write_text(kopf + "\n" + "\n".join(zeilen) + "\n")
print(kopf)
print("\n".join(z for z in zeilen if not z.startswith("gleich")))
sys.exit(1 if abweichend else 0)
