// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/chicago.md. Nicht von Hand ändern.
enum RegelWissenText_chicago {
    static let quelle = #"""
## Ziel und Überblick
Stichwörter: Spielziel, gewinnen, Sieger, wie viele Runden, wie viele Spieler, allein spielen, Zielsumme
Chicago ist ein Würfelspiel mit zwei Würfeln. Es gibt genau 11 Runden. In jeder Runde gilt eine andere Zielzahl: Runde 1 hat die Zielzahl 2, Runde 2 die 3 und so weiter bis Runde 11 mit der Zielzahl 12. Du willst mit der Augensumme deiner zwei Würfel die Zielzahl treffen. Für jeden Treffer bekommst du Punkte. Nach 11 Runden gewinnt, wer die meisten Punkte hat. Es spielen 1 bis 6 Personen, jeder Platz kann ein Mensch oder der Computer sein. Allein spielst du auf Punkte, es gibt dann keinen Sieg. Die App zeigt oben „Runde x von 11 · Zielzahl y“.

## Ablauf einer Runde
Stichwörter: Würfeln, wer ist dran, drei Versuche, Wurf, nochmal werfen, Zug, weiter, daneben, Reihenfolge
Alle Spieler sind in jeder Runde einmal dran, immer in der gleichen Reihenfolge wie in der Spielerliste. Wer dran ist, würfelt beide Würfel und bildet die Summe. Ist die Summe gleich der Zielzahl, ist es ein Treffer: Du bekommst Punkte und dein Zug endet sofort. Ist sie anders, darfst du nochmal würfeln. Du hast höchstens 3 Würfe pro Runde („Versuch 1 von 3“). Triffst du nach 3 Würfen nicht, steht „Leider verfehlt.“ und du bekommst 0 Punkte in dieser Runde. Danach tippst du auf „Weiter“, der nächste Spieler ist dran. Nach dem letzten Spieler beginnt die nächste Runde mit der nächsten Zielzahl. Du kannst nicht freiwillig aufhören und nicht nach einem Treffer weiterwürfeln.

## Punkte und Pasch
Stichwörter: Punkte, Wertung, zählen, doppelt, Doppelpasch, Treffer, Summe, Höchstpunktzahl, Maximum, Minuspunkte
Bei einem Treffer bekommst du so viele Punkte wie die Zielzahl. Ein Pasch zählt doppelt. Ein Pasch sind zwei gleiche Würfel. Beispiele: Zielzahl 7 und du wirfst 3 und 4: 7 Punkte. Zielzahl 8 und du wirfst 3 und 5: 8 Punkte. Zielzahl 8 und du wirfst 4 und 4: 16 Punkte, weil Pasch. Zielzahl 2 und du wirfst 1 und 1: 4 Punkte. Ein Pasch ist nur bei geraden Zielzahlen möglich (2, 4, 6, 8, 10, 12), bei ungeraden Zielzahlen (3, 5, 7, 9, 11) kann die Summe kein Pasch sein. Die Pasch-Punkte sind 4, 8, 12, 16, 20 und 24. Der Höchstwert über alle 11 Runden ist 119 Punkte: 77 (die Summe der Zielzahlen 2 bis 12) plus 42 für die sechs Pasch-Runden. Ohne Treffer gibt es keine Punkte, es gibt keine Minuspunkte.

## Chancen
Stichwörter: Wahrscheinlichkeit, Prozent, Glück, Quote, wie wahrscheinlich, Anzeige
Die App zeigt dir, wenn du dran bist, die Chance auf die Zielzahl im nächsten Wurf in Prozent, gerundet auf ganze Prozent: Zielzahl 7 hat 17 %, 6 und 8 haben je 14 %, 5 und 9 je 11 %, 4 und 10 je 8 %, 3 und 11 je 6 %, 2 und 12 je 3 %. Das ist die Zahl der Würfelkombinationen von 36 (7: 6 Kombinationen, 2: nur 1+1). Für alle 3 Würfe zusammen gilt zum Beispiel: Zielzahl 7 etwa 42 %, Zielzahl 2 oder 12 etwa 8 %. Diese Gesamtchance rechnet das Spiel aus, zeigt sie aber nicht an. Beim Computer wird die Chance nicht angezeigt.

## Würfel: virtuell oder echt
Stichwörter: echte Würfel, eintippen, eintragen, schütteln, Computer würfelt, Tempo
Im Neues-Spiel-Blatt wählst du „Virtuell“ oder „Echt“. Bei Virtuell würfelt die App, du tippst auf „Würfeln“ oder schüttelst das Gerät. Bei Echt würfelst du zwei echte Würfel am Tisch, tippst auf „Eintragen“ und wählst im Blatt „Was hast du gewürfelt?“ die zwei Augenzahlen. Der Computer würfelt immer selbst in der App, auch bei Echt. Würfelt der Computer, steht „… würfelt …“ und er geht von allein weiter. Das Tempo des Computers folgt der Einstellung der Sammlung.

## Ende, Gleichstand, Neue Partie
Stichwörter: Ende, Ergebnis, Unentschieden, gleich viele Punkte, Platz, neu starten, abbrechen, fortsetzen
Nach Runde 11 erscheint der Knopf „Ergebnis“. Die Spieler werden nach Punkten sortiert. Bei Gleichstand bekommen alle Gleichen denselben Platz, die nächsten Plätze werden entsprechend übersprungen. Allein zählt das Ergebnis als „x Punkte“, ohne Sieg. Im Menü „Mehr“ gibt es „Neue Partie“: Läuft schon eine Partie, fragt die App nach, die laufende Partie wird dann verworfen und neu begonnen. Außerdem „Spiel beenden“. Eine angefangene Partie wird gemerkt und kann fortgesetzt werden.

## Begriffe und Sonderfälle
Stichwörter: Begriffe, Bedeutung, was heißt, verfehlt, Zielzahl, Bonus, Sonderregel
Zielzahl: die Summe, die du in dieser Runde treffen musst. Treffer: Augensumme gleich Zielzahl. Verfehlt: 3 Würfe ohne Treffer. Pasch: zwei gleiche Würfel. Es gibt keine Rangfolge von Würfen, keine Wiederholung nach Pasch und keinen Bonus für schnelle Treffer: Ein Treffer im ersten Wurf zählt genauso viel wie im dritten. Es gibt in der App keine Varianten, keine Hausregeln und keine Stärke des Computers.

## Was die App anders macht als die übliche Regel
Stichwörter: Hausregel, Variante, anders, üblich, Unterschied, Einstellungen
Chicago gibt es in vielen Hausregel-Fassungen. Die App kennt nur eine feste Fassung. Es gilt nur: 11 Runden, Zielzahlen 2 bis 12 in dieser Reihenfolge, 2 Würfel, bis zu 3 Würfe, Punkte gleich Zielzahl, Pasch doppelt, Zug endet nach Treffer. Die Zielzahl der Runde ist immer fest. Mehr gibt es nicht.
"""#
}
