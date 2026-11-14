#!/usr/bin/env python3
"""uebersetzungen_aus_alten_apps.py: holt fehlende en/es/fr-Texte der Spiele aus den Katalogen der Einzel-Apps (10k, Schocken, VierGewinnt,
Sudoku, Minensuche, Kreuzwortraetsel, Ludo, Baukasten) in App/Ressourcen/Localizable.xcstrings.
Nimmt nur Texte, die ein Spiel in Partie wirklich benutzt (Quellen-Scan), überschreibt nie Vorhandenes und übernimmt nur Übersetzungen mit
gleicher Platzhalter-Folge. Aufruf aus dem Projektordner (Arcade/Haupt)."""
import re, json, glob, os, sys
KAT = 'App/Ressourcen/Localizable.xcstrings'
ALT = ['10k/TF/TenK', 'Schocken/Haupt/iOS/Schocken', 'VierGewinnt/Haupt/iOS/VierGewinnt', 'Sudoku/Haupt/iOS/Sudoku',
       'Minensuche/Haupt/Minensuche', 'Kreuzwortraetsel/Haupt/iOS/Kreuzwortraetsel', 'MenschAergereDich/Haupt/iOS/Ludo']
WURZEL = os.path.expanduser('~/Claude/App')
PH = re.compile(r'%[0-9\$]*(?:lld|@|d|lf|f)')
def norm(k): return PH.sub('§', k)
def folge(k): return [re.sub(r'[0-9\$]', '', m) for m in PH.findall(k)]

cat = json.load(open(KAT)); s = cat['strings']
quellen = {}
pfade = [os.path.join(WURZEL, a, 'Localizable.xcstrings') for a in ALT] + [os.path.join(WURZEL, 'Partie/_Gemeinsam/Baukasten/Sources/Baukasten/Resources/Localizable.xcstrings')]
for p in pfade:
    if not os.path.exists(p): continue
    for k, v in json.load(open(p))['strings'].items():
        loc = v.get('localizations', {})
        if all(l in loc and 'stringUnit' in loc[l] for l in ('en', 'es', 'fr')):
            quellen.setdefault(norm(k), []).append((k, loc))

# Texte, die Spiele wirklich benutzen
KONTEXT = re.compile(r'(Text\(|Button\(|Label\(|SectionLabel\(|Picker\(|Stepper\(|String\(localized: |untertitel: |regeln: |einzelText: |hinweis|navigationTitle|accessibilityLabel\(|accessibilityHint\(|accessibilityValue\(|Toggle\(|info: |mitte: |meldung|Section\(|LocalizedStringKey)')
benutzt = {}
for f in glob.glob('Pakete/Spiel*/Sources/**/*.swift', recursive=True):
    for z in open(f):
        if not KONTEXT.search(z) or 'verbatim:' in z or z.strip().startswith('//'): continue
        for l in re.findall(r'"((?:[^"\\]|\\.|\\\((?:[^()]|\([^()]*\))*\))*)"', z):
            k = re.sub(r'\\\((?:[^()]|\([^()]*\))*\)', '§', l).replace('\\"', '"').replace('\\n', '\n')
            if re.search(r'[A-Za-zÄÖÜäöü]{3,}', k): benutzt[k] = True

n = 0
for k_norm in benutzt:
    if k_norm not in quellen: continue
    ziele = [key for key in s if norm(key) == k_norm]
    quelle = quellen[k_norm][0]
    if not ziele:
        ziele = [quelle[0]]            # neuer Eintrag mit dem Schlüssel der alten App
        s[quelle[0]] = {"localizations": {}}
    for key in ziele:
        if folge(key) != folge(quelle[0]): continue
        loc = s[key].setdefault('localizations', {})
        for sp in ('en', 'es', 'fr'):
            if sp not in loc:
                v = quelle[1][sp]['stringUnit']['value']
                if folge(v) != folge(key) and PH.search(v): continue
                loc[sp] = {"stringUnit": {"state": "translated", "value": v}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
