#!/usr/bin/env python3
"""texte_extrahieren.py: sammelt lokalisierbare deutsche Texte der neuen Spiele (Spiel<Name>/Sources/Spiel<Name>/*.swift) als Katalogschlüssel
(Interpolationen → %lld / %@) und schreibt die fehlenden nach Werkzeug/texte_fehlen.json. Aufruf aus Partie/Haupt."""
import re,glob,json,sys
neu=["Klappbrett","Schiebepuzzle","Muehle","Schwimmen","LichterAus","Hanoi","Zahlenfusion","Kalaha","Wendespiel","Dame","Siebzehn","Maexchen","Schiffe","Schweinerei","MauMau","Nonogramm","Chicago","ElferRaus","Luegenwuerfel","Mogeln","Halma","StadtLandFluss","Schach","MahjongPaare","Bruecken","Kakuro","Backgammon","Romme"]
cat=json.load(open('App/Ressourcen/Localizable.xcstrings'))['strings']
STR=re.compile(r'"((?:[^"\\]|\\.|\\\((?:[^()]|\([^()]*\))*\))*)"')
def schluessel(roh):
    def ers(m):
        e=m.group(1)
        if re.search(r'name|\.text|joined|symbol|kurz|String\(|Text|nachricht|titel|\.first|ablage', e, re.I) and not re.search(r'\.count|Int\(', e): return '%@'
        return '%lld'
    return re.sub(r'\\\(((?:[^()]|\([^()]*\))*)\)', ers, roh)
KONTEXT=re.compile(r'(Text\(|Button\(|Label\(|SectionLabel\(|Picker\(|Stepper\(|String\(localized: |untertitel: |regeln: |hinweis|navigationTitle|accessibilityLabel\(|Toggle\(|info: String\(localized|mitte: |meldung = |Text\(|Section\()')
ausgabe={}
for n in neu:
    for f in glob.glob(f'Pakete/Spiel{n}/Sources/Spiel{n}/*.swift'):
        for z in open(f):
            if '.font(.system' in z and 'Text(' not in z: continue
            if not KONTEXT.search(z): continue
            for m in STR.findall(z):
                if 'verbatim' in z and re.search(r'verbatim: *"'+re.escape(m),z): continue
                k=schluessel(m).replace('\\"','"')
                if not any(c.isalpha() for c in k) or k.startswith('die.face') or re.fullmatch(r'[a-z.]+\.?[a-z.]*',k) and '.' in k: continue
                if k in ('verbatim','Haupt','Mehr') and False: continue
                ausgabe.setdefault(k,set()).add(n)
fehlt={k:sorted(v) for k,v in ausgabe.items() if k not in cat or 'en' not in cat[k].get('localizations',{})}
json.dump(fehlt,open('Werkzeug/texte_fehlen.json','w'),ensure_ascii=False,indent=1)
print(len(ausgabe),len(fehlt))
