// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/elferraus/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_elferraus {
    static let quelle = #"""
## Worum es geht

Elfer raus ist ein Anlegespiel. In der Mitte entstehen vier Reihen, eine pro Farbe. Jede Reihe beginnt mit der 11 und wächst nach oben und unten, immer um genau eine Zahl. Wer als Erste oder Erster alle Karten angelegt hat, gewinnt.

Das Spiel ist leicht zu lernen. Die Kunst ist, die eigenen Karten so zu legen, dass du den anderen keine Tür öffnest.

## Was du brauchst

- **Spieler:** 2 bis 6. Jeder Platz kann ein Mensch oder der Computer sein.
- **Karten:** 80 Karten in vier Farben: Rot ●, Gelb ■, Grün ▲ und Blau ◆, jede Farbe mit den Zahlen 1 bis 20.
- Jede Person bekommt **10 Karten**. Der Rest liegt als Stapel bereit.

## Der Anfang

Die **rote 11** eröffnet. Hat jemand sie auf der Hand, legt die App sie automatisch, und diese Person ist zuerst dran. Sie darf danach gleich weitere Karten anlegen. Liegt die rote 11 im Stapel, kommt sie von dort auf den Tisch, und Spieler 1 beginnt.

## Anlegen

- Jede Farbe beginnt mit ihrer 11. Die 11 einer neuen Farbe darfst du jederzeit legen.
- Danach wächst die Reihe an beiden Enden, immer um genau eins.
- *Beispiel:* Gelb liegt von 9 bis 13. Du darfst Gelb 8 oder Gelb 14 anlegen, aber nicht Gelb 7 oder Gelb 15.
- Die Reihe endet unten bei 1 und oben bei 20.

Die Karten, die du gerade anlegen kannst, sind in deiner Hand hervorgehoben. Tippe die Karte an oder ihren freien Platz auf dem Tisch.

## Dein Zug

- Passt eine Karte, **musst** du mindestens eine anlegen.
- Danach darfst du so viele anlegen, wie du kannst und willst. Dann tippst du „Zug beenden“.
- Passt keine Karte, tippst du „Karte ziehen“ und nimmst genau **eine** vom Stapel. Passt sie, darfst du sie anlegen und bleibst dran. Passt sie nicht, ist die nächste Person dran.
- Ziehen darfst du nur, wenn nichts passt und du in diesem Zug noch nichts gelegt hast.
- Ist der Stapel leer, tippst du „Passen“.

## Wer gewinnt

Wer die letzte Karte anlegt, gewinnt sofort, auch mitten im Zug.

Die anderen zählen ihre Restkarten als **Minuspunkte**: die Zahlen werden zusammengezählt. *Beispiel:* Restkarten 20, 3 und 7 sind 30 Minuspunkte. Wer weniger hat, steht weiter vorn. Bei gleicher Summe teilt ihr euch den Platz.

**Geht nichts mehr?** Passen alle nacheinander, endet die Runde. Dann gewinnt, wer die kleinste Restsumme hat. Haben mehrere dieselbe kleinste Summe, nennt die App keinen Sieger.

Es gibt nur eine Runde.

## Variante Kartendomino

Kartendomino ist die ältere Form mit dem Skatblatt (32 Karten: 7, 8, 9, 10, Bube, Dame, König, Ass in Kreuz, Pik, Herz und Karo). Der **Bube** spielt die Rolle der 11.

Unterschiede:
- Alle Karten werden ausgeteilt, es gibt keinen Stapel.
- Der **Herz-Bube** eröffnet. Wer ihn hat, legt ihn automatisch, dann ist die nächste Person dran.
- Du legst **genau eine Karte** pro Zug.
- Passt keine Karte, passt du. Gezogen wird nicht.
- Minuspunkte: 7 bis 10 ihre Zahl, Bube 11, Dame 12, König 13, Ass 14.

**Variante wählen:** in der Partie unter „Mehr“ → „Regeln“, bis du deinen ersten eigenen Zug gemacht hast. Ein Wechsel teilt sofort neu aus. Die App merkt sich deine Wahl für die nächsten Partien.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“ → „Stärke des Computers“:

- **Leicht:** legt oft eine zufällige passende Karte.
- **Mittel:** spielt meist gut, manchmal zufällig.
- **Schwer** (Standard): spielt immer seinen besten Zug. Er legt gern so, dass er dem Nächsten keine Karte möglich macht.

## Hilfen in der App

- **Tipp:** zeigt die Karte, die der Computer an deiner Stelle legen würde.
- **Statuszeile:** zeigt den letzten Zug, zum Beispiel „Anna legt Rot 11“, und wie viele Karten im Stapel sind.
- **Sichtschutz:** Spielen mehrere Menschen an einem Gerät, ist die Hand verdeckt, bis die Person am Zug sie aufdeckt.
- **Spielerleiste:** zeigt, wie viele Karten jede Person noch hat.
- **iPad:** Im Querformat zeigt eine Seitenspalte den Verlauf und die Regeln dieser Partie.
- **Neue Partie** (unter „Mehr“): teilt neu aus. Nach deinem ersten Zug fragt die App vorher nach.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Halte Karten zurück, mit denen der Nächste etwas anfangen könnte.
- Hast du viele Karten einer Farbe, öffne diese Farbe früh.
- Hohe und tiefe Karten (1, 2, 19, 20) kommen spät dran. Wer sie bis zum Schluss hat, zahlt viele Minuspunkte.

## Begriffe

- **Anlegen:** eine Karte an eine Reihe legen.
- **Reihe:** alle gelegten Karten einer Farbe.
- **Restsumme:** die Summe deiner Restkarten am Ende.
- **Passen:** nichts tun, die nächste Person ist dran.
"""#
}
