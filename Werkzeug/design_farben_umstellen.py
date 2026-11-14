#!/usr/bin/env python3
"""design_farben_umstellen.py: stellt Systemfarben und Zahlenschrift auf die Rollen der Design-Ebene um (Designwechsel A.4).

Ersetzt in App/ und Pakete/*/Sources (nie in .build, nie in Tests):
  Color(.systemGroupedBackground) | Color(uiColor: .systemGroupedBackground) | Color(UIColor.systemGroupedBackground)  -> Color.seitenGrund
  dieselben Formen von secondarySystemGroupedBackground                                                               -> Color.kartenGrund
  dieselben Formen von tertiarySystemGroupedBackground                                                                -> Color.feldGrund
  design: .rounded                                                                                                    -> design: Design.zahlDesign
                                                   (in Dateien mit `extension Font`: design: KlarGlasDesign.zahlDesign)

Wiederholbar und idempotent: ein zweiter Lauf ändert nichts. Der Integrator lässt das Skript nach dem Merge anderer
Branches erneut laufen. Dateien ohne `import KlarGlas` bekommen den Import nur, wenn ihr Paket KlarGlas schon als
Abhängigkeit hat; sonst bleibt die Stelle stehen und wird aufgelistet.
tertiarySystemFill, systemFill und systemGray* werden bewusst NICHT ersetzt (Entscheidung je Spiel, Stufe D).

Aufruf aus dem Projektordner:  python3 Werkzeug/design_farben_umstellen.py [--pruefen]
  --pruefen: nichts schreiben, nur zählen (Rückgabewert 1, wenn noch etwas zu tun wäre).
"""
import os, re, sys

WURZEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRUEFEN = '--pruefen' in sys.argv

def farbmuster(name):
    return re.compile(r'Color\(\s*(?:uiColor:\s*)?(?:UIColor)?\.' + name + r'\s*\)')

MUSTER = [
    ('systemGroupedBackground -> Color.seitenGrund', farbmuster('systemGroupedBackground'), 'Color.seitenGrund'),
    ('secondarySystemGroupedBackground -> Color.kartenGrund', farbmuster('secondarySystemGroupedBackground'), 'Color.kartenGrund'),
    ('tertiarySystemGroupedBackground -> Color.feldGrund', farbmuster('tertiarySystemGroupedBackground'), 'Color.feldGrund'),
    ('design: .rounded -> design: Design.zahlDesign', re.compile(r'design:\s*\.rounded\b'), 'design: Design.zahlDesign'),
]
# In Erweiterungen von `Font` meint `Design` den Typ `Font.Design`. Dateien mit `extension Font` bekommen deshalb den
# eindeutigen Namen `KlarGlasDesign` (Typalias im Baukasten); schon ersetzte Stellen werden dort nachgezogen.
FONT_ERWEITERUNG = re.compile(r'^\s*(?:public\s+|private\s+|fileprivate\s+|internal\s+)?extension\s+Font\b', re.M)
ZAHL_NAME = 'design: .rounded -> design: Design.zahlDesign'
ZAHL_FALSCH = re.compile(r'design:\s*(?<!KlarGlas)Design\.zahlDesign\b')
IMPORT = re.compile(r'^\s*(?:@testable\s+|@_exported\s+)?import\s+KlarGlas\b', re.M)
ERSTER_IMPORT = re.compile(r'^(?:@testable\s+|@_exported\s+)?import\s+\w+.*$', re.M)

def dateien():
    """Alle Swift-Quellen der App und der Pakete, ohne Bau-Ordner und ohne Tests."""
    for basis in ('App', 'Pakete'):
        for ordner, unter, namen in os.walk(os.path.join(WURZEL, basis)):
            unter[:] = [u for u in unter if u not in ('.build', '.swiftpm', 'Tests', 'build')]
            rel = os.path.relpath(ordner, WURZEL).split(os.sep)
            if basis == 'Pakete' and len(rel) >= 3 and rel[2] != 'Sources':
                continue   # in Paketen nur Sources (Tests, Shared, Skripte bleiben)
            for n in sorted(namen):
                if n.endswith('.swift'):
                    yield os.path.join(ordner, n)

_abhaengig = {}
def kennt_klarglas(pfad):
    """App: ja. Paket: nur, wenn Package.swift das Produkt KlarGlas nennt."""
    rel = os.path.relpath(pfad, WURZEL).split(os.sep)
    if rel[0] == 'App':
        return True
    paket = os.path.join(WURZEL, rel[0], rel[1])
    if paket not in _abhaengig:
        try:
            _abhaengig[paket] = 'KlarGlas' in open(os.path.join(paket, 'Package.swift'), encoding='utf-8').read()
        except OSError:
            _abhaengig[paket] = False
    return _abhaengig[paket]

def import_einfuegen(text):
    m = ERSTER_IMPORT.search(text)
    if m:   # hinter den ersten Import (bleibt in einem #if canImport(UIKit)-Block, wenn die Datei so beginnt)
        return text[:m.end()] + '\nimport KlarGlas' + text[m.end():]
    return 'import KlarGlas\n' + text

zahl = {name: 0 for name, _, _ in MUSTER}
geaendert, importe, ausgelassen = 0, 0, []
for pfad in dateien():
    text = open(pfad, encoding='utf-8').read()
    treffer = {name: len(m.findall(text)) for name, m, _ in MUSTER}
    in_font = bool(FONT_ERWEITERUNG.search(text))
    if in_font:
        treffer[ZAHL_NAME] += len(ZAHL_FALSCH.findall(text))
    if not any(treffer.values()):
        continue
    rel = os.path.relpath(pfad, WURZEL)
    hat_import = bool(IMPORT.search(text))
    if not hat_import and not kennt_klarglas(pfad):
        ausgelassen.append((rel, sum(treffer.values())))
        continue
    neu = text
    for name, m, ersatz in MUSTER:
        if name == ZAHL_NAME and in_font:
            ersatz = 'design: KlarGlasDesign.zahlDesign'
            neu = ZAHL_FALSCH.sub(ersatz, neu)
        neu = m.sub(ersatz, neu)
        zahl[name] += treffer[name]
    if not hat_import:
        neu = import_einfuegen(neu); importe += 1
    geaendert += 1
    if not PRUEFEN:
        open(pfad, 'w', encoding='utf-8').write(neu)

for name, _, _ in MUSTER:
    print(f'{zahl[name]:5d}  {name}')
print(f'{geaendert} Dateien {"wären zu ändern" if PRUEFEN else "geändert"}, {importe} Importe `import KlarGlas` ergänzt.')
if ausgelassen:
    print('Ausgelassen (Paket ohne KlarGlas-Abhängigkeit, Stellen bleiben stehen):')
    for rel, n in ausgelassen:
        print(f'  {rel}: {n}')
sys.exit(1 if PRUEFEN and geaendert else 0)
