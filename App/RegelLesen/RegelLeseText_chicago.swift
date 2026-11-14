// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/chicago/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_chicago {
    static let quelle = #"""
## Worum es geht

Chicago ist ein schnelles Würfelspiel mit zwei Würfeln. Es gibt 11 Runden, und jede Runde hat eine eigene **Zielzahl**: Runde 1 die 2, Runde 2 die 3 und so weiter bis Runde 11 mit der 12. Du versuchst, mit der Summe deiner zwei Würfel genau die Zielzahl zu treffen. Wer am Ende die meisten Punkte hat, gewinnt.

Es spielen 1 bis 6 Personen. Jeder Platz kann ein Mensch oder der Computer sein. Allein spielst du auf möglichst viele Punkte.

## So läuft eine Runde

Alle sind in jeder Runde einmal dran, immer in der Reihenfolge der Spielerliste.

1. Tippe auf „Würfeln“ (oder schüttle das Gerät).
2. Ist die Summe gleich der Zielzahl, ist das ein **Treffer**. Du bekommst Punkte, und dein Zug ist sofort vorbei.
3. Sonst darfst du noch einmal würfeln. Du hast höchstens **3 Würfe**.
4. Triffst du nach 3 Würfen nicht, gibt es in dieser Runde 0 Punkte.
5. Mit „Weiter“ ist die nächste Person dran.

Oben steht immer „Runde … von 11 · Zielzahl …“.

## Punkte

Ein Treffer bringt so viele Punkte wie die Zielzahl. Ein **Pasch** (zwei gleiche Würfel) zählt doppelt.

*Beispiele:*
- Zielzahl 7, du wirfst 3 und 4: 7 Punkte.
- Zielzahl 8, du wirfst 4 und 4: 16 Punkte (Pasch).
- Zielzahl 2, du wirfst 1 und 1: 4 Punkte (Pasch).

Ein Pasch geht nur bei geraden Zielzahlen. Es gibt keine Minuspunkte, und ein Treffer im ersten Wurf zählt genauso viel wie im dritten. Höchstens sind 119 Punkte möglich.

## Deine Chance

Bist du dran, zeigt die App die Chance, die Zielzahl im nächsten Wurf zu treffen. Die 7 ist am leichtesten (17 %), die 2 und die 12 am schwersten (3 %).

## Wer gewinnt

Nach Runde 11 tippst du auf „Ergebnis“. Es gewinnt, wer die meisten Punkte hat. Bei gleichen Punkten teilen sich die Personen den Platz.

## Würfel und Computer

- Im Blatt „Neues Spiel“ wählst du unter „Würfel“: **Virtuell** (die App würfelt) oder **Echt** (ihr würfelt am Tisch und tippt bei „Eintragen“ die zwei Augenzahlen ein).
- Der Computer würfelt immer selbst und macht danach von allein weiter. Er hat keine Stärke, er würfelt einfach.

## In der App

- Im Aussehen „Tinte“ zeigt eine Tafel die Zielzahlen 2 bis 12. Gespielte Zahlen sind blass, die aktuelle ist hervorgehoben.
- **Neue Partie** (unter „Mehr“): Läuft schon eine Partie, fragt die App nach und beginnt dann neu.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- Das Ergebnis zeigt, wer wie oft getroffen hat, und ein Bild aller Zielzahlen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Was hier anders ist als anderswo

Chicago wird in vielen Familien anders gespielt. Die App kennt eine feste Fassung: 11 Runden, Zielzahlen 2 bis 12 der Reihe nach, bis zu 3 Würfe, Pasch doppelt. Hausregeln gibt es nicht.
"""#
}
