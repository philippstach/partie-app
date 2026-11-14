#!/usr/bin/env python3
"""Designwechsel D.4: ersetzt in den Spielpaketen die Abschnittsfläche
    .background(Color.kartenGrund, in: .rect(cornerRadius: R))
durch
    .designFlaeche(R)
(Baukasten KlarGlas 2.18: in klar genau dasselbe, in Tinte und Salon nur eine Haarlinie unten).
Wiederholbar und idempotent. Ändert nur Pakete/*/Sources, nie .build, nie Tests. Dateien ohne `import KlarGlas` werden ausgelassen und aufgelistet.
Aufruf im Projektordner: python3 Werkzeug/design_flaechen_umstellen.py
Nach dem Merge anderer Branches erneut laufen lassen (fängt neue Stellen)."""
import re, sys
from pathlib import Path

wurzel = Path(__file__).resolve().parent.parent
muster = re.compile(r"\.background\(Color\.kartenGrund, in: \.rect\(cornerRadius: ([^()]+(?:\([^()]*\))?[^()]*)\)\)")
geaendert, ausgelassen, stellen = [], [], 0
for datei in sorted((wurzel / "Pakete").glob("*/Sources/**/*.swift")):
    if ".build" in datei.parts:
        continue
    text = datei.read_text()
    treffer = muster.findall(text)
    if not treffer:
        continue
    if "import KlarGlas" not in text:
        ausgelassen.append(str(datei.relative_to(wurzel)))
        continue
    neu = muster.sub(lambda m: f".designFlaeche({m.group(1)})", text)
    datei.write_text(neu)
    geaendert.append(f"{datei.relative_to(wurzel)} ({len(treffer)})")
    stellen += len(treffer)
print(f"{stellen} Stellen in {len(geaendert)} Dateien ersetzt")
for g in geaendert:
    print("  ", g)
if ausgelassen:
    print("Ausgelassen (kein import KlarGlas):")
    for a in ausgelassen:
        print("  ", a)
