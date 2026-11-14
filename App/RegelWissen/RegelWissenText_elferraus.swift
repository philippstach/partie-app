// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/elferraus.md. Nicht von Hand ändern.
enum RegelWissenText_elferraus {
    static let quelle = #"""
## Ziel
Stichwörter: gewinnen, Minuspunkte, Spieler, Runde
Werde alle deine Karten los, bevor es die anderen schaffen. Wer als Erste oder Erster keine Karten mehr hat, gewinnt sofort. Es spielen 2 bis 6 Personen, auch mit Computer. Die übrigen Karten der anderen zählen als Minuspunkte, nur für die Rangfolge am Ende. Es gibt nur eine Runde, keine Punkte über mehrere Runden. Im Standard spielst du „Elfer raus“ mit 80 Karten. Daneben gibt es die Variante Kartendomino.

## Aufbau und Start
Stichwörter: austeilen, Kartenzahl, Stapel, anfangen, rote Elf, Farben
Es gibt vier Farben (Rot ●, Gelb ■, Grün ▲, Blau ◆), jede mit den Karten 1 bis 20, zusammen 80 Karten. Jede Person bekommt 10 Karten, der Rest ist der Stapel (bei 2 Personen 60 Karten, bei 3 Personen 50, bei 4 Personen 40, bei 5 Personen 30, bei 6 Personen 20). Die rote 11 eröffnet das Spiel. Hat jemand sie auf der Hand, beginnt diese Person und die 11 wird automatisch gelegt, die Person bleibt noch dran und darf weitere Karten anlegen. Liegt die rote 11 im Stapel, wird sie von dort auf den Tisch gelegt, und die erste Person beginnt.

## Anlegen
Stichwörter: legen, Reihe, nach oben, nach unten, Elf, passende Karte
Auf dem Tisch gibt es je Farbe eine Reihe. Jede Farbe beginnt mit ihrer 11. Die 11 einer neuen Farbe darfst du jederzeit legen. Danach wächst die Reihe nach oben und unten, immer um genau eine Zahl an einem Ende. Beispiel: Gelb liegt von 9 bis 13. Du darfst gelb 8 oder gelb 14 anlegen, aber nicht gelb 15 oder gelb 7. Die Reihe endet unten bei der 1 und oben bei der 20. Die App markiert die Karten in deiner Hand, die du jetzt anlegen darfst; du tippst die Karte oder ihren freien Platz an.

## Zug im Standard
Stichwörter: ziehen, passen, Zug beenden, mehrere Karten, festgefahren, Pflicht
Du musst mindestens eine Karte anlegen, wenn eine passt. Du darfst so viele Karten anlegen, wie du kannst und willst. Dann tippst du „Zug beenden“. Passt keine Karte, ziehst du genau 1 Karte vom Stapel. Passt sie, legst du sie an und bleibst dran, du kannst weitere anlegen. Passt sie nicht, ist der Nächste dran. Ziehen darfst du nur, wenn nichts passt und du in diesem Zug noch nichts gelegt hast. Ist der Stapel leer, passt du. Passen alle hintereinander (nichts geht mehr), endet die Runde: Es gewinnt, wer die kleinste Restsumme hat. Haben mehrere dieselbe kleinste Restsumme, nennt die App keinen Sieger (unentschieden).

## Wertung
Stichwörter: Punkte, Restkarten, Summe, Rangfolge, Sieger
Wer keine Karten mehr hat, gewinnt, sofort mitten im Zug. Die übrigen Karten zählen als Minuspunkte: die Summe der Kartenwerte. Im Standard zählt die Zahl auf der Karte. Beispiel: Restkarten 20, 3 und 7 sind 20 + 3 + 7 = 30 Minuspunkte. Die Rangfolge geht von der Siegerin oder dem Sieger zur kleinsten Restsumme; bei gleicher Summe teilen sich die Personen auf der Ergebnisseite den Platz; ist die kleinste Summe gleich, gibt es keinen Sieger. Die Anzeige am Ende zeigt die Minuspunkte. Wer leer ist, hat 0; nur beim Festfahren hat auch die Siegerin eine Restsumme.

## Variante Kartendomino
Stichwörter: Skatblatt, 32 Karten, Bube, Domino, Herz
Kartendomino (Skatblatt) ist die frühere Skat-Form. Gespielt wird mit 32 Karten, 7, 8, 9, 10, Bube, Dame, König und Ass in Kreuz, Pik, Herz und Karo. Alle Karten werden ausgeteilt (zu zweit je 16, zu dritt 11, 11 und 10, zu viert je 8), es gibt keinen Stapel. Die „11“ ist der Bube, die Reihe läuft also 7 8 9 10 Bube Dame König Ass. Der Herz-Bube eröffnet; wer ihn hat, legt ihn automatisch, dann ist die nächste Person dran. Du legst nur eine Karte je Zug. Passt keine, passt du. Es wird nicht gezogen. Minuspunkte: 7 bis 10 ihre Zahl, Bube 11, Dame 12, König 13, Ass 14. Beispiel: Rest Bube und Ass = 11 + 14 = 25.

## Variante wählen und Bedienung
Stichwörter: wechseln, Menü, Regeln, Tipp, Neue Partie, Einstellung
Die Variante wählst du in der Partie unter „Mehr“ → „Regeln“: „Elfer raus (1–20)“ oder „Kartendomino (Skatblatt)“. Die App merkt sich die Wahl für die nächsten Partien. Beim Wechsel wird neu ausgeteilt. Die Wahl ist möglich bis zum ersten eigenen Zug. Der automatisch gelegte Startzug zählt dabei nicht. Ein Wechsel teilt sofort neu aus, ohne Rückfrage. „Neue Partie“ mischt neu mit der gewählten Variante. „Tipp“ zeigt eine passende Karte. Bei mehreren Menschen verdeckt ein Sichtschutz die Hand. Auf dem iPad gibt es eine Seitenspalte mit dem Verlauf. Die Computer-Stärke wählst du unter „Mehr“.

## Begriffe
Stichwörter: was heißt, Fachwort, Bedeutung, Restsumme
Anlegen: eine Karte an das Ende der Reihe legen. Reihe: die Karten einer Farbe auf dem Tisch, die von der 11 aus wachsen. Passen: ohne Zug an die nächste Person weitergeben. Festgefahren: alle passen hintereinander, die Runde endet. Zug beenden: nach mindestens einer gelegten Karte die Runde an den Nächsten geben. Restsumme: die Summe der Karten, die du noch hältst. Minuspunkte: dasselbe, als Wertung am Ende.

## Was die App anders macht als die übliche Regel
Stichwörter: abweichen, anders, üblich, Unterschied
Im Standard (Elfer raus) gewinnt, wer zuerst leer ist; die Restkarten sind nur Minuspunkte für die Rangfolge, es gibt keine Punkte über mehrere Runden. Wer anlegen kann, muss mindestens eine Karte legen. Beim Ziehen gibt es genau eine Karte. Die Startkarte, die rote 11, wird automatisch gelegt, und die Person, die sie besitzt, beginnt. Die Variante Kartendomino ist eine eigene App-Variante mit dem Herz-Buben als Startkarte.
"""#
}
