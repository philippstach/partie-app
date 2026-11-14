// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/solitaer.md. Nicht von Hand ändern.
enum RegelWissenText_solitaer {
    static let quelle = #"""
## Überblick und Spielwahl
Stichwörter: Patience, allein, welche Spiele, auswählen, Ziel, Zielstapel
Solitär spielst du allein. Es gibt sieben Spiele: Klondike (1 oder 3 Karten), Spider (1, 2 oder 4 Farben), FreeCell, Pyramide, TriPeaks, Golf und Yukon. Du wählst vor dem Start auf der Spielseite oder im Startblatt. In Klondike, FreeCell und Yukon legst du alle Karten von Ass bis König nach Farben auf vier Zielstapel. Im Spider räumst du Reihen von König bis Ass ab. Bei Pyramide, TriPeaks und Golf räumst du den Tisch ab. Tippe eine Karte an, sie springt an den besten Platz, oder ziehe sie mit dem Finger. Die Wisch-Anleitung erklärt nur Klondike.

## Klondike
Stichwörter: Patience, Klassiker, sieben Spalten, drei Karten, König, Stapel
Sieben Spalten mit 1, 2, 3 bis 7 Karten, nur die oberste ist offen, die anderen liegen verdeckt (28 Karten). Der Stapel hat 24 Karten. Du legst absteigend und abwechselnd rot und schwarz an, zum Beispiel Herz 9 auf Pik 10. Ganze passende Reihen darfst du gemeinsam verschieben. In eine leere Spalte darf nur ein König (mit seiner Reihe). Ein Ziel baut je Farbe von Ass bis König auf. Du darfst Karten vom Ziel zurück in eine Spalte legen. Verdeckte Karten werden aufgedeckt, wenn sie frei liegen. Antippen des Stapels deckt 1 oder 3 Karten auf; nur die oberste Ablagekarte ist spielbar. Ist der Stapel leer, wird die Ablage wieder zum Stapel. Gewonnen, wenn alle vier Ziele bis zum König reichen.

## Klondike Wertung
Stichwörter: Punkte, Vegas, streng, Zeitbonus, Minus, zählen
Standard: Ablage → Spalte +5, Karte aufs Ziel +10, Karte aufgedeckt +5, vom Ziel zurück −15, Stapel umdrehen −100 (bei 3 Karten −20). Die Punkte fallen nie unter 0. Beim Sieg gibt es einen Zeitbonus von 700.000 ÷ Sekunden (ganzzahlig), wenn die Partie mindestens 30 Sekunden gedauert hat. Beispiel: Sieg nach 350 Sekunden = 2.000 Bonus. Streng (im Code Vegas): Start bei −52, jede Karte aufs Ziel +5, jede Karte vom Ziel zurück −5; nach dem Sieg stehen also −52 + 52 × 5 = 208. Mit 1 Karte gibt es 1 Durchgang durch den Stapel (kein Umdrehen), mit 3 Karten 3 Durchgänge. Dann erscheint „Keine Durchgänge mehr“. Streng fortlaufend addiert die Punkte über alle Partien. Aus: keine Punkte. Tagesspiel und Tagesziele zählen immer Standard.

## Spider
Stichwörter: Spinne, Farben, Reihe abräumen, Stapel austeilen, 104 Karten
Zwei Blätter (104 Karten) in 10 Spalten: vier Spalten mit 6 Karten, sechs mit 5, nur die oberste offen (54 Karten). Der Stapel hat 50 Karten. Mit 1 Farbe sind alle Karten Pik, mit 2 Farben Pik und Herz, mit 4 Farben alle. Lege eine Karte auf eine um eins höhere, egal welche Farbe. Verschieben darfst du nur Reihen in einer Farbe. Eine leere Spalte nimmt jede Karte oder Reihe. Tippe auf den Stapel: Er legt auf jede Spalte eine Karte, aber nur, wenn keine Spalte leer ist und noch 10 Karten im Stapel sind (5 Mal möglich). Eine Reihe König bis Ass in einer Farbe wandert automatisch ab. Gewonnen mit 8 abgeräumten Reihen. Punkte: Start 500, jeder Zug und jedes Austeilen −1, jede fertige Reihe +100, nie unter 0.

## FreeCell
Stichwörter: Freizelle, Zellen, Supermove, mehrere Karten, Nummer
Alle 52 Karten liegen offen in 8 Spalten (vier mit 7, vier mit 6 Karten). Oben links sind 4 freie Zellen, jede parkt eine Karte, oben rechts 4 Ziele (Ass bis König je Farbe). Du legst absteigend und abwechselnd rot und schwarz an. Mehrere Karten gehen auf einmal, höchstens (freie Zellen + 1) × 2 hoch (leere Spalten), eine leere Zielspalte zählt nicht mit. Beispiel: 4 freie Zellen, keine leere Spalte: 5 Karten. 2 freie Zellen und 1 leere andere Spalte: 3 × 2 = 6 Karten. In eine leere Spalte darf jede Karte oder Reihe. Vom Ziel zurück geht nicht. Es gibt keine Punkte. Die Partie-Nummern sind die Microsoft-Nummern (1 bis 32000). Gewonnen, wenn alle Ziele bis zum König reichen.

## Pyramide
Stichwörter: Summe 13, Paare, Dame, Bube, Pyramide abräumen
28 Karten liegen in 7 Reihen (1 bis 7 Karten) als Pyramide, der Stapel hat 24 Karten. Eine Karte ist frei, wenn keine andere auf ihr liegt. Entferne Paare, die zusammen 13 ergeben: Ass = 1, Bube = 11, Dame = 12, König = 13. Die Paare sind Ass + Dame, 2 + Bube, 3 + 10, 4 + 9, 5 + 8, 6 + 7. Ein König geht allein. Beide Karten müssen frei sein, eine davon darf die oberste Ablagekarte sein. Tippe eine Karte an, dann ihren Partner. Gibt es nur einen Partner, verschwindet das Paar sofort. Der Stapel deckt die nächste Ablagekarte auf. Ist er leer, darfst du die Ablage zweimal umdrehen (3 Durchgänge). Gewonnen, wenn die Pyramide leer ist. Keine Punkte.

## TriPeaks
Stichwörter: Gipfel, drei Spitzen, Kette, Bonus, Nachbar
Drei Gipfel mit zusammen 28 Karten (Reihen mit 3, 6, 9 und 10 Karten), eine Karte liegt auf der Ablage, 23 Karten im Stapel. Eine freie Karte darf auf die Ablage, wenn sie genau einen Wert höher oder niedriger ist. König und Ass zählen als Nachbarn (rundum). Der Stapel deckt eine Karte auf die Ablage auf, nur einmal durch, kein Umdrehen. Punkte: Jede abgelegte Karte bringt die Länge deiner Kette (1, 2, 3 …). Ziehen vom Stapel setzt die Kette auf 0. Wer einen Gipfel räumt, bekommt +15, der letzte Gipfel +30. Beispiel: Eine Kette von 4 Karten = 1 + 2 + 3 + 4 = 10 Punkte. Gewonnen, wenn alle 28 Karten der Gipfel weg sind.

## Golf
Stichwörter: Spalten, Ablage, Sackgasse, Stapel übrig
Sieben Spalten mit je 5 offenen Karten (35 Karten). Eine Karte liegt auf der Ablage, 16 im Stapel. Nur die oberste Karte jeder Spalte darf auf die Ablage, wenn sie genau einen Wert höher oder niedriger ist. Ass und König sind keine Nachbarn, und auf einen König geht nichts. Dann hilft nur der Stapel: Er deckt eine Karte auf, geht einmal durch, kein Umdrehen. Gewonnen, wenn alle Spalten leer sind. Die Punkte sind die Zahl der Karten, die beim Sieg im Stapel übrig sind. Beispiel: 4 Karten übrig = 4 Punkte. Es gibt keine Punkte, solange du nicht gewonnen hast.

## Yukon
Stichwörter: offene Karten mitnehmen, Spalten, ohne Stapel
Sieben Spalten, alle 52 Karten liegen von Anfang an in den Spalten, es gibt keinen Stapel. Spalte 1 hat 1 offene Karte, jede der Spalten 2 bis 7 hat 5 offene Karten und 1, 2 bis 6 verdeckte darunter. Du legst absteigend und abwechselnd rot und schwarz an. Jede offene Karte darfst du samt allem, was darauf liegt, verschieben. Die Karten darüber müssen keine Reihe bilden, nur die unterste bewegte Karte muss passen. In eine leere Spalte darf nur ein König. Ziele: Ass bis König je Farbe, auch Karten vom Ziel zurück sind erlaubt. Punkte wie Klondike Standard: aufs Ziel +10, aufgedeckt +5, vom Ziel zurück −15, nie unter 0.

## Tipp, Zurück, Tagesspiel
Stichwörter: Hinweis, rückgängig, lösbar, schwierig, automatisch ablegen, Tagesziel, Kalender, einstellen
„Tipp“ zeigt einen Zug. „Zurück“ nimmt Züge zurück, gedrückt halten spult schnell. „Fertig spielen“ gibt es, sobald alles aufgedeckt ist. „Karten ablegen“ steht standardmäßig auf „Selbst“; „Automatisch“ legt sichere Karten selbst aufs Ziel (Klondike, FreeCell, Yukon). Lösbare Partien hat ein Computer vorab bis zum Sieg gespielt. Die Schwierigkeit gilt für sie. Bei „Zufällige Partien“ ist nicht jede lösbar. Jeden Tag gibt es ein Tagesspiel mit Kalender. Das Tagesziel ist je Spiel zum Beispiel: gewinnen, ohne Zurück, ohne Tipp, in unter 4 bis 12 Minuten oder in höchstens ⌈1,4 × Lösung⌉ Zügen (Klondike, Spider). Gewonnene Partien zählen für Serien, Erfolge und Wochenziele.

## Was die App anders macht als die übliche Regel
Stichwörter: abweichen, anders, üblich, Unterschied
Karten legst du standardmäßig selbst ab, nicht automatisch. Standard sind lösbare Partien. Im Klondike gibt es unbegrenzt viele Durchgänge durch den Stapel, außer bei „Streng“. „Streng“ ist die Vegas-Wertung, aber mit 1 Durchgang (1 Karte) oder 3 Durchgängen (3 Karten) und +5 je Karte. In TriPeaks wird nicht umgedreht und es zählt die Kette. Golf punktet nur nach dem Sieg. Yukon wird wie üblich gespielt, mit offenen Reihen, die du beliebig mitnimmst. Das Tagesspiel ist immer Standard-Wertung. Spider hat die Punkte 500 − Züge + 100 je Reihe.
"""#
}
