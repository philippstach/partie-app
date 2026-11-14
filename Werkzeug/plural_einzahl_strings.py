#!/usr/bin/env python3
"""T-5: Einzahl-Formen. Legt für die Schlüssel aus plural-kandidaten-de.txt String-Catalog-Mehrzahl-Einträge (one/other) an, de/en/es/fr.
Je Sprache wird jedes „%lld <Nomen>“, dessen Nomen in der Tabelle steht, zu einer Substitution mit Einzahl und Mehrzahl.
Aufruf: python3 Werkzeug/plural_einzahl_strings.py App/Ressourcen/Localizable.xcstrings /mnt/project-files/plural-kandidaten-de.txt"""
import json, re, sys
EIN = {
 'de': dict(Runden='Runde', Punkte='Punkt', Karten='Karte', Siege='Sieg', Niederlagen='Niederlage', Felder='Feld', Partien='Partie',
            Personen='Person', Steine='Stein', Tage='Tag', Würfe='Wurf', Züge='Zug', Wochen='Woche', Versuche='Versuch', Fotos='Foto'),
 'en': dict(rounds='round', games='game', tries='try', points='point', cards='card', wins='win', losses='loss', squares='square', people='person', days='day',
            rolls='roll', moves='move', mistakes='mistake', weeks='week', photos='photo', draws='draw', turns='turn', stones='stone', discs='disc'),
 'es': dict(rondas='ronda', puntos='punto', cartas='carta', victorias='victoria', derrotas='derrota', casillas='casilla', partidas='partida',
            empates='empate', personas='persona', días='día', tiradas='tirada', movimientos='movimiento', errores='error', semanas='semana',
            piedras='piedra', intentos='intento', turnos='turno', lanzamientos='lanzamiento', fichas='ficha', fotos='foto', metros='metro', vidas='vida'),
 'fr': dict(manches='manche', points='point', cartes='carte', victoires='victoire', défaites='défaite', cases='case', parties='partie',
            nuls='nul', personnes='personne', jours='jour', lancers='lancer', coups='coup', erreurs='erreur', nulles='nulle', graines='graine',
            essais='essai', tours='tour', pions='pion', photos='photo', mètres='mètre', vies='vie'),
}
SPEC = re.compile(r'%(?:(\d+)\$)?(lld|@|d|ld|f|lf)')
LLD = re.compile(r'%(?:(\d+)\$)?lld(\s+)([^\s,.·:–)/]+)')

def einzahl(text, sprache):
    """-> (äußerer Text mit %#@vN@, {name: (argNum, one, other)}) oder None"""
    tab = EIN[sprache]
    ersetzt, subs, ordinal = [], {}, 0
    pos = 0; out = ''
    for m in SPEC.finditer(text):
        ordinal += 1
        k = int(m.group(1)) if m.group(1) else ordinal
        out += text[pos:m.start()]; pos = m.end()
        rest = text[m.end():]
        w = re.match(r'(\s+)([^\s,.·:–)/]+)', rest)
        if m.group(2) == 'lld' and w and w.group(2) in tab:
            wort = w.group(2); name = f'v{k}'
            subs[name] = (k, f'%arg {tab[wort]}', f'%arg {wort}')
            out += f'%#@{name}@'; pos = m.end() + w.end()   # Nomen steht in der Substitution
        else:
            out += m.group(0)
    out += text[pos:]
    return (out, subs) if subs else None

def main(katalog, liste):
    d = json.load(open(katalog)); strings = d['strings']
    keys = [l.split(' => ')[0] for l in open(liste).read().splitlines() if l.strip()]
    geaendert = 0; offen = []
    for k in keys:
        e = strings.get(k)
        if not e: offen.append((k, 'Schlüssel fehlt')); continue
        loc = e.setdefault('localizations', {})
        if 'de' not in loc: loc['de'] = {'stringUnit': {'state': 'translated', 'value': k}}
        for sp in ('de', 'en', 'es', 'fr'):
            x = loc.get(sp)
            if not x or 'stringUnit' not in x: continue
            r = einzahl(x['stringUnit']['value'], sp)
            if not r:
                if sp in ('de', 'en'): offen.append((k, f'{sp}: kein bekanntes Nomen'))
                continue
            outer, subs = r
            loc[sp] = {'stringUnit': {'state': 'translated', 'value': outer}, 'substitutions': {
                n: {'argNum': a, 'formatSpecifier': 'lld', 'variations': {'plural': {
                    'one': {'stringUnit': {'state': 'translated', 'value': one}},
                    'other': {'stringUnit': {'state': 'translated', 'value': other}}}}}
                for n, (a, one, other) in subs.items()}}
            geaendert += 1
    open(katalog, 'w').write(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
    print('geändert:', geaendert, 'Sprachfassungen'); print('offen:', *offen, sep='\n  ')

if __name__ == '__main__': main(*sys.argv[1:3])
