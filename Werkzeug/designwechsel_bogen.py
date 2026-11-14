#!/usr/bin/env python3
"""designwechsel_bogen.py: setzt die Einzelbilder aus Partie/DesignWechsel/Bilder zu Übersichtsbögen zusammen.
  bogen-<design>.png          alle Szenen eines Designs (oben hell, unten dunkel)
  vergleich-<szene>.png       eine Szene in allen Designs nebeneinander (oben hell, unten dunkel)
Aufruf im Projektordner: python3 Werkzeug/designwechsel_bogen.py [Ordner]   (braucht Pillow)"""
import os, sys, glob
from PIL import Image, ImageDraw
ordner = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '..', 'Bilder')
designs = ['klar', 'tinte', 'salon']
bilder = {}
for p in glob.glob(os.path.join(ordner, '*.png')):
    n = os.path.basename(p)[:-4]
    t = n.split('-', 2)
    if len(t) == 3 and t[0] in designs and t[1] in ('hell', 'dunkel'): bilder[(t[0], t[1], t[2])] = p
szenen = sorted({k[2] for k in bilder})
B = 260   # Breite je Bild im Bogen
def klein(p):
    im = Image.open(p).convert('RGB'); return im.resize((B, round(im.height * B / im.width)))
def bogen(zellen, datei, titel):
    """zellen: Liste von Zeilen, jede Zeile eine Liste von (Beschriftung, Pfad oder None)."""
    zeilen = [[(b, klein(p) if p else None) for b, p in z] for z in zellen]
    hoehen = [max([im.height for _, im in z if im] or [0]) + 22 for z in zeilen]
    breite = max(len(z) for z in zeilen) * (B + 10) + 10
    aus = Image.new('RGB', (breite, sum(hoehen) + 34), (255, 255, 255)); d = ImageDraw.Draw(aus)
    d.text((10, 8), titel, fill=(0, 0, 0))
    y = 30
    for z, h in zip(zeilen, hoehen):
        x = 10
        for b, im in z:
            d.text((x, y), b, fill=(90, 90, 90))
            if im: aus.paste(im, (x, y + 16)); d.rectangle((x - 1, y + 15, x + B, y + 16 + im.height), outline=(200, 200, 200))
            x += B + 10
        y += h
    aus.save(os.path.join(ordner, datei)); return datei
gemacht = []
for de in designs:
    sz = [s for s in szenen if (de, 'hell', s) in bilder]
    if sz: gemacht.append(bogen([[(s, bilder.get((de, m, s))) for s in sz] for m in ('hell', 'dunkel')], f'bogen-{de}.png', f'{de}: oben hell, unten dunkel'))
for s in szenen:
    gemacht.append(bogen([[(f'{de} {m}', bilder.get((de, m, s))) for de in designs] for m in ('hell', 'dunkel')], f'vergleich-{s}.png', f'{s}: klar, tinte, salon'))
print(len(gemacht), 'Bögen:', ', '.join(gemacht))
