#!/usr/bin/env python3
"""designwechsel_texte_fehlen.py: listet Textschlüssel aus Swift-Dateien, die im Katalog noch fehlen oder nicht in en/es/fr übersetzt sind.
Einfache Suche nach Text("…"), Button("…"), Label("…"), String(localized: "…"), LocalizedStringKey-Parametern in den genannten Dateien.
Aufruf: python3 Werkzeug/designwechsel_texte_fehlen.py <Katalog.xcstrings> <Datei.swift> …"""
import json, re, sys
kat = json.load(open(sys.argv[1], encoding='utf-8'))['strings']
muster = re.compile(r'"((?:[^"\\]|\\.)*)"')
aus = re.compile(r'verbatim:\s*$|systemImage:\s*$|systemName:\s*$|symbol:\s*$|forKey:\s*$|name:\s*$|id:\s*$|zeichen:\s*$|nummer:\s*$|format:\s*$|suiteName:\s*$')
def schluessel(s):
    # Swift-Interpolation -> Formatplatzhalter wie im Katalog (%@ für Texte, %lld für Zahlen ist nicht unterscheidbar: beide prüfen)
    s = s.replace('\\n', '\n').replace('\\"', '"')
    return s
for datei in sys.argv[2:]:
    text = open(datei, encoding='utf-8').read()
    for m in muster.finditer(text):
        davor = text[max(0, m.start() - 24):m.start()]
        s = m.group(1)
        if not s or aus.search(davor) or not re.search(r'[A-Za-zÄÖÜäöü]{2}', s): continue
        if re.fullmatch(r'[a-z0-9.\-_]+', s): continue          # Symbolnamen, Schlüssel
        k = schluessel(s)
        varianten = {k, re.sub(r'\\\([^)]*\)', '%@', k), re.sub(r'\\\([^)]*\)', '%lld', k)}
        treffer = [v for v in varianten if v in kat]
        fehlt = not treffer or any(sp not in kat[treffer[0]].get('localizations', {}) for sp in ('en', 'es', 'fr'))
        if fehlt and '\\(' not in s: print(f'{datei.split("/")[-1]}: {s!r}')
        elif fehlt: print(f'{datei.split("/")[-1]}: {s!r}   (mit Platzhalter, bitte prüfen)')
