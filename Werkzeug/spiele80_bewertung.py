#!/usr/bin/env python3
"""spiele80_bewertung.py: Bewertung aller Spiele (ohne Arcade) für Doku/SPIELE-80.md. Aufruf aus dem Projektordner.
Gemessen wird aus dem Code, mit gemeinsamen Bausteinen (SpielRahmen, KartenFlaeche, WuerfelBild, SpielerLeiste ...) eingerechnet.
Nicht gemessen: Spielspaß, Regel-Richtigkeit, Layout. Das ist eine Näherung, kein Urteil."""
import os, re, glob, json
P = 'Pakete'
x = json.load(open('App/Ressourcen/Localizable.xcstrings'))['strings']
def trans(s):
    e = x.get(s)
    if not e: return 0
    l = e.get('localizations', {})
    return sum(1 for k in ('en', 'es', 'fr') if k in l) / 3
def lies(pattern):
    return ''.join(open(f).read() for f in glob.glob(pattern, recursive=True) if '/.build/' not in f)
ZUSTAENDIG = {
 **{g: 'Computergegner-Stufen' for g in ['kalaha', 'oware', 'halma', 'wendespiel', 'fuchsjagd', 'backgammon', 'nardy', 'chinchon', 'crazyeights', 'elferraus', 'escoba', 'hoelzchen', 'klappbrett', 'luegenwuerfel', 'patolli', 'schiffsfracht', 'schwimmen', 'truco']},
 'solitaer': 'Brett- und Kartenspiele', 'spitspeed': 'Brett- und Kartenspiele', 'dame': 'Brett- und Kartenspiele', 'schach': 'Brett- und Kartenspiele',
 'muehle': 'Brett- und Kartenspiele', 'maumau': 'Brett- und Kartenspiele',
 'sudoku': 'Rätsel und Wortspiele', 'kakuro': 'Rätsel und Wortspiele', 'bruecken': 'Rätsel und Wortspiele', 'nonogramm': 'Rätsel und Wortspiele', 'wortpfeil': 'Rätsel und Wortspiele',
}
# Reine Glücksspiele ohne Entscheidung: Tipp und Computer-Stufen entfallen. Siebzehn und Vier spielt nur gegen die Bank.
GLUECK = {'bunco', 'chicago', 'himmelsleiter', 'kartenduell', 'pechvogel'}
OHNE_COMPUTER = {'siebzehnundvier'}
GEM_A11Y = r'KartenFlaeche|SkatKartenBild|SpanischeKarteBild|WuerfelBild|SpielerLeiste|EchteWuerfel|echteWuerfelEingabe'
zeilen = []
for d in sorted(os.listdir(P)):
    if not d.startswith('Spiel') or d in ('SpielHilfen', 'SpieleKern'): continue
    ui = lies(f'{P}/{d}/Sources/Spiel*/**/*.swift')
    if 'SpielModul' not in ui: continue
    kern = lies(f'{P}/{d}/Sources/**/*.swift')
    pakete = [d] + (['MinensucheKern'] if d == 'SpielMinensuche' else [])
    tests = sum(len(re.findall(r'func test|@Test', lies(f'{P}/{p}/Tests/**/*.swift'))) for p in pakete)
    m = re.search(r"let id = \"(\w+)\"", ui) or re.search(r"id: \"(\w+)\"", ui); gid = m.group(1) if m else d.replace("Spiel", "").lower()
    g = re.search(r'Gattung\.(\w+)', ui).group(1)
    if g == 'arcade': continue
    gross = len(kern.splitlines()) > 2500
    regeln = bool(re.search(r'regeln:\s*"', ui)) or gross or 'RegelnView' in ui or bool(glob.glob(f'{P}/{d}/Sources/Spiel*/Regeln*.swift'))
    anleitung = 'mitAnleitung' in ui or 'AnleitungBlatt' in ui or bool(glob.glob(f'{P}/{d}/Sources/Spiel*/Anleitung*.swift'))
    tipp = bool(re.search(r'[Tt]ipp|hinweisGeben|Hinweis', ui))
    comp = bool(re.search(r'computerErlaubt: true|ComputerStufe', kern))
    stufe = 'ComputerStufe' in kern
    solo = gid in ('sudoku','kakuro','nonogramm','bruecken','lichteraus','schiebepuzzle','hanoi','zahlenfusion','mahjongpaare','minensuche','farbraetsel','solitaer','irrgang','ungleichung','steckspiel','farbflut','farbcode','lagerplatz','hoelzchen','10k','galgenmaennchen','wortpfeil','yacht') or re.search(r'spielerzahl = 1\.\.\.1', ui)
    undo = bool(re.search(r'verlauf|Rueckgaengig|undo|rueckgaengig', kern + ui, re.I))
    fortsetzen = bool(re.search(r'fortsetzbar\(|SpielStand\.|\.spielstand\(|OffenesSpiel', kern + ui))
    eigen = len(re.findall(r'accessibility', ui))
    gem = len(re.findall(GEM_A11Y, ui))
    a11y = min(1, (eigen + 2 * min(gem, 2)) / 5)
    skal = bool(re.search(r'dynamicTypeSize', ui)) * 0.5 + bool(re.search(r'weicheAnimation|reduceMotion|bewegungReduziert', ui)) * 0.25 + bool(re.search(r'spielHaptik|[Hh]aptik', ui)) * 0.25
    teile = []   # (Gewicht, Anteil, Name)
    teile.append((5, 1.0 if regeln else 0, 'Regeltext'))
    teile.append((5, 1.0 if anleitung or gross else 0, 'Anleitung'))
    # Testziel nach Größe der Spiellogik: mindestens 15 Tests, bis 25 für große Kerne (große Alt-Apps: 60)
    kernzeilen = len(lies(f'{P}/{d}/Sources/*Kern/**/*.swift').splitlines()) + len(lies(f'{P}/MinensucheKern/Sources/**/*.swift').splitlines()) * (d == 'SpielMinensuche')
    ziel = 60 if gross else min(25, max(15, kernzeilen // 10))
    teile.append((20, min(tests / ziel, 1), 'Tests'))
    teile.append((10, 1.0 if fortsetzen else 0, 'Weiterspielen'))
    teile.append((15, a11y, 'VoiceOver'))
    teile.append((5, skal, 'Schrift/Bewegung/Haptik'))
    if gid not in GLUECK: teile.append((10, 1.0 if tipp else 0, 'Tipp'))
    if gid not in GLUECK | OHNE_COMPUTER and (comp or g in ('karten', 'brett') and not solo): teile.append((10, (0.5 if comp else 0) + (0.5 if stufe else 0), 'Computer-Stufen'))
    if (g in ('raetsel', 'brett') and solo and gid not in ('minensuche', 'schiffeversenken', 'farbcode')) or gid in ('schach','dame','muehle','halma','sechseck','fuchsjagd','kalaha','oware','wendespiel'): teile.append((10, 1.0 if undo else 0, 'Rückgängig'))
    w = sum(t[0] for t in teile); s = sum(t[0] * t[1] for t in teile) / w * 100
    fehlt = sorted([(t[0] * (1 - t[1]), t[2]) for t in teile if t[1] < 0.99], reverse=True)
    zeilen.append(dict(id=gid, gattung=g, wert=round(s), tests=tests, fehlt=[f"{n}" for _, n in fehlt[:3]], zust=ZUSTAENDIG.get(gid, 'dieser Chat'), a11y=eigen, gem=gem))
zeilen.sort(key=lambda z: z['wert'])
n = len(zeilen); mittel = sum(z['wert'] for z in zeilen) / n
ab80 = sum(z['wert'] >= 80 for z in zeilen)
md = ['# Spiele auf 80 % (Bewertung)', '',
 f'Stand: Branch spiele-80, {n} Spiele ohne Arcade. Schnitt **{mittel:.0f} %**, **{ab80} von {n}** Spielen bei 80 % oder mehr.', '',
 'Gemessen aus dem Code (Skript `Werkzeug/spiele80_bewertung.py`), gemeinsame Bausteine eingerechnet. Gewichte: Regeltext 5, Anleitung 5, Tests 20, Weiterspielen 10, VoiceOver 15, Schrift/Bewegung/Haptik 5, Tipp 10, Computer-Stufen 10 (wo es Computergegner gibt), Rückgängig 10 (bei Rätsel- und Brettspielen). Nicht gemessen: Spielspaß, Regel-Richtigkeit, Layout, offene Fehler aus `Test/`-Berichten.', '',
 '| Spiel | Art | Wert | Tests | Größte Lücken | Zuständig |', '|---|---|---|---|---|---|']
for z in zeilen:
    md.append(f"| {z['id']} | {z['gattung']} | {z['wert']} % | {z['tests']} | {', '.join(z['fehlt']) or '–'} | {z['zust']} |")
open('Doku/SPIELE-80.md', 'w').write('\n'.join(md) + '\n')
print(n, round(mittel), ab80)
for z in zeilen[:30]: print(z['id'], z['wert'], z['tests'], z['fehlt'], z['zust'])
