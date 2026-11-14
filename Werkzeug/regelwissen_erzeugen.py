#!/usr/bin/env python3
"""regelwissen_erzeugen.py (KI-3): macht aus den Regeltexten der Text-Pakete (plan/ki-regeltexte/<id>.md) Swift-Dateien
App/RegelWissen/RegelWissenText_<id>.swift und die Tabelle App/RegelWissen/RegelWissenTabelle.swift.
Die App liest /mnt/project-files nicht; der Text steht deshalb als Raw-String in der Datei. Nur der Teil ab der ersten
Zeile „## “ kommt hinein (Kopf mit Quellen und Optionen bleibt Dokumentation). Nicht von Hand ändern, sondern die .md
ändern und dies neu laufen lassen. Aufruf aus dem Projektordner:
    python3 Werkzeug/regelwissen_erzeugen.py /mnt/project-files/plan/ki-regeltexte"""
import re, sys, os

QUELLE = sys.argv[1] if len(sys.argv) > 1 else '/mnt/project-files/plan/ki-regeltexte'
ZIEL = 'App/RegelWissen'

# Name, wie ihn Spieler in der App lesen, und drei Beispielfragen für das leere Chat-Blatt (Blatt 12).
# Die Fragen stammen aus den Testfragen der Text-Pakete (dort mit geprüfter Antwort).
SPIELE = {
 'solitaer': ('Solitär', ['Wie viele Karten decke ich vom Stapel auf?', 'Was darf ich beim Klondike in eine leere Spalte legen?', 'Welche Karten ergeben bei der Pyramide zusammen 13?']),
 'maumau': ('Mau-Mau', ['Was passiert bei einer 7 auf eine 7?', 'Darf ich ziehen, obwohl ich eine Karte legen könnte?', 'Was ist die Vorlage Wild?']),
 'schwimmen': ('Schwimmen', ['Was darf ich in meinem Zug machen?', 'Wie viel ist ein Ass, ein König und eine 9 wert?', 'Darf ich schon im ersten Zug klopfen?']),
 'elferraus': ('Elfer raus', ['Wie viele Karten bekommt jeder am Anfang?', 'Muss ich eine Karte legen, wenn eine passt?', 'Alle haben nacheinander gepasst. Wie geht es weiter?']),
 'romme': ('Rommé', ['Wie viele Karten bekomme ich, und wie viele Joker gibt es?', 'Darf ich K-A-2 als Folge legen?', 'Wie viele Joker darf ein Satz haben?']),
 'mogeln': ('Mogeln', ['Wer darf „Gelogen!“ rufen?', 'Wann gilt ein Zug als gelogen?', 'Wie wird am Ende gewertet?']),
 'siebzehnundvier': ('Siebzehn und Vier', ['Was ist das Ziel von Siebzehn und Vier?', 'Die Bank hat Ass und 6. Zieht sie noch?', 'Welche Start-Chips kann ich wählen?']),
 'herzensjagd': ('Herzensjagd', ['Wer beginnt die Runde?', 'Wie viele Punkte zählen Herz und Pik-Dame?', 'Wann sind Herzen zum Ausspielen offen?']),
 'yacht': ('Yacht', ['Wie läuft ein Zug bei Yacht ab?', 'Ich habe 3-3-3-5-5 geworfen. Was bringt Full House?', 'Wann ist das Spiel zu Ende?']),
 'schocken': ('Schocken', ['Wie viele Würfel und wie viele Würfe hat man bei Schocken?', 'Ich habe 1-1-6 geworfen. Wie viele Deckel ist das wert?', 'Darf ich alle drei Würfel herauslegen?']),
 'maexchen': ('Mäxchen', ['Wie läuft eine Runde ab?', 'Wie ist die Rangfolge der Würfe?', 'Darf ich weniger ansagen, als ich gewürfelt habe?']),
 'chicago': ('Chicago', ['Wie viele Runden hat Chicago?', 'Zielzahl ist 7 und ich würfle 3 und 4. Wie viele Punkte?', 'Welche Zielzahl gilt in der ersten Runde?']),
 'pokerwurf': ('Pokerwurf', ['Welche Hand ist die stärkste?', 'Schlägt ein Full House eine große Straße?', 'Mit wie vielen Würfeln und wie oft darf ich würfeln?']),
 'koenigsweg': ('Königsweg', ['Was ist das Ziel von Königsweg?', 'Muss ich ziehen oder darf ich passen?', 'Was ist, wenn ich nicht ziehen kann?']),
 'sudoku': ('Sudoku', ['Wie funktioniert Sudoku?', 'Wie viele Fehler darf ich machen, bis ich verloren habe?', 'Was bringt mir der Tipp?']),
 'minensuche': ('Minensuche', ['Wie funktioniert Minensuche?', 'Kann der erste Zug schon eine Mine treffen?', 'Was passiert, wenn ich eine Mine treffe?']),
 'kakuro': ('Kakuro', ['Wie funktioniert Kakuro?', 'Welche Hinweiszahl gilt waagrecht und welche senkrecht?', 'Welche Ziffern ergeben 16 über zwei Feldern?']),
 'schiebepuzzle': ('Schiebepuzzle', ['Was muss ich beim Schiebepuzzle erreichen?', 'Wie bewege ich eine Kachel?', 'Wonach wird beim Schiebepuzzle gewertet?']),
 'irrgang': ('Labyrinth', ['Was ist das Ziel im Labyrinth?', 'Wie bewege ich den Läufer?', 'Ich wische gegen eine Wand. Was passiert?']),
 'farbflut': ('Farbfüller', ['Was ist das Ziel bei Farbfüller?', 'Wo beginnt die Flut?', 'Was zeigt mir der Tipp?']),
 'viererreihe': ('Viererreihe', ['Wie groß ist das Brett?', 'Gilt auch eine Diagonale?', 'Wo stelle ich die Stärke des Computers ein?']),
 'rauswurf': ('Rauswurf', ['Wie bekomme ich eine Figur aus dem Haus?', 'Was passiert, wenn ich auf eine fremde Figur lande?', 'Was ändert die Spielart Kinder?']),
 'muehle': ('Mühle', ['Wie viele Steine hat jeder Spieler?', 'Was ist eine Mühle?', 'Gilt Stellungswiederholung als Remis?']),
 'galgenmaennchen': ('Galgenmännchen', ['Wie viele Fehler darf ich machen?', 'Was kostet ein falscher Lösungsversuch?', 'Zählt ß als eigener Buchstabe?']),
 'wortpfeil': ('Kreuzworträtsel', ['Wie funktioniert ein Kreuzworträtsel mit Pfeilen hier?', 'Wann ist das Rätsel gelöst?', 'Wann bekomme ich den Stern?']),
}

def swift_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

os.makedirs(ZIEL, exist_ok=True)
zeilen = []
for sid, (name, fragen) in SPIELE.items():
    md = open(os.path.join(QUELLE, sid + '.md'), encoding='utf-8').read()
    i = md.find('\n## ')
    assert i >= 0, sid
    text = md[i + 1:].rstrip() + '\n'
    assert '"""#' not in text, sid
    datei = os.path.join(ZIEL, f'RegelWissenText_{sid}.swift')
    with open(datei, 'w', encoding='utf-8') as f:
        f.write(f'''// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/{sid}.md. Nicht von Hand ändern.
enum RegelWissenText_{sid} {{
    static let quelle = #"""
{text}"""#
}}
''')
    zeilen.append(f'        {swift_str(sid)}: ({swift_str(name)}, RegelWissenText_{sid}.quelle, [{", ".join(swift_str(q) for q in fragen)}]),')

with open(os.path.join(ZIEL, 'RegelWissenTabelle.swift'), 'w', encoding='utf-8') as f:
    f.write('''// Erzeugt von Werkzeug/regelwissen_erzeugen.py. Nicht von Hand ändern.
enum RegelWissenTabelle {
    /// Grund-ID → (Name in der App, Regeltext in Abschnitten, drei Beispielfragen). Zehntausend fehlt (KI-2: eigener Chat).
    static let eintraege: [String: (name: String, quelle: String, fragen: [String])] = [
''' + '\n'.join(zeilen) + '''
    ]
}
''')
print(len(SPIELE), 'Spiele')
