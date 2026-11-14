// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/mogeln.md. Nicht von Hand ändern.
enum RegelWissenText_mogeln {
    static let quelle = #"""
## Ziel und Karten
Stichwörter: Spielerzahl, Karten, Blatt, austeilen, 32 Karten, verteilen, Ziel, Haufen
Mogeln spielst du mit 3 bis 6 Spielern. Es gibt 32 Karten: 7, 8, 9, 10, Bube, Dame, König und Ass in vier Farben, keine Joker. Alle Karten werden reihum verteilt. Bei 4 Spielern hat jeder 8 Karten, bei 3 Spielern 11, 11 und 10. Ziel: Du wirst als Erster alle Karten los, ohne beim Mogeln erwischt zu werden. In der Mitte liegt der Haufen. Oben auf dem Tisch steht, welcher Rang gerade „gefordert“ ist. Die Farben spielen keine Rolle, nur der Rang zählt.

## Ablauf eines Zugs
Stichwörter: legen, ablegen, verdeckt, behaupten, Rang, gefordert, Reihenfolge, passen, aussetzen, lügen, schwindeln, bluffen
Du legst 1 bis 4 Karten verdeckt auf den Haufen und behauptest damit, es seien Karten des geforderten Rangs. Passen gibt es nicht, du musst mindestens eine Karte legen. Den Rang suchst du nicht aus, er ist vorgegeben. Der Rang beginnt bei 7 und steigt mit jedem Zug: 7, 8, 9, 10, Bube, Dame, König, Ass, dann wieder 7. Du darfst lügen. Hast du den Rang nicht, legst du trotzdem eine Karte und tust so, als wäre sie richtig. Auch mit der Wahrheit darfst du weniger Karten legen, als du hast. Danach ist der nächste Spieler dran: Er muss sich entscheiden.

## Gelogen! oder Glauben
Stichwörter: anzweifeln, Gelogen rufen, glauben, aufdecken, Lügner, erwischt, Haufen nehmen, Zweifler
Der nächste Spieler hat zwei Möglichkeiten. „Glauben“: Der Haufen bleibt liegen, der Rang rückt weiter, und er legt selbst. „Gelogen!“: Die zuletzt gelegten Karten werden aufgedeckt (nicht der ganze Haufen). Gelogen war es, wenn mindestens eine dieser Karten nicht den geforderten Rang hat. Stimmte die Behauptung, nimmt der Zweifler den ganzen Haufen auf die Hand. Gelogen heißt: Der Lügner nimmt den ganzen Haufen. Wer den Haufen nimmt, legt als Nächster, und es gilt der nächste Rang. Nur der nächste Spieler darf anzweifeln, sonst niemand.

## Gewinnen und Sonderfälle
Stichwörter: gewinnen, letzte Karte, Sieger, Ende, Restkarten, Wertung, Sonderfall
Wer seine letzte Karte legt, hat noch nicht gewonnen. Erst muss der nächste Spieler entscheiden. Glaubt er, hat der Spieler gewonnen. Ruft er „Gelogen!“ und es stimmte, hat der Spieler ebenfalls gewonnen (der Zweifler nimmt den Haufen, aber das Spiel ist aus). War es gelogen, nimmt der Lügner den Haufen, und das Spiel geht weiter. Mehr als 4 Karten kannst du nie legen, denn es gibt nur 4 Karten je Rang. Nach dem Ende wird nach den Restkarten gewertet: Wer weniger Karten hat, steht weiter vorn. Beispiel: Der Haufen hat 5 Karten, du hast 3 Karten und wirst beim Lügen erwischt. Danach hast du 3 + 5 = 8 Karten.

## Optionen und Computer
Stichwörter: Option, einstellen, Variante, Computer, Stärke, leicht, mittel, schwer, Gegner, Regeln ändern
Mogeln hat keine Regelvarianten und keine Schalter für die Regeln. Du kannst nur die Stärke der Computer-Mitspieler einstellen (Menü „Mehr“, nur sichtbar, wenn ein Computer mitspielt): „Leicht“, „Mittel“ (Standard) oder „Schwer“. „Leicht“ ruft nach Gefühl, zufällig in etwa 3 von 10 Fällen, und kennt die Kartenzahl nicht. „Mittel“ und „Schwer“ rechnen mit den eigenen Karten: Behauptet jemand mehr Karten eines Rangs, als es außerhalb der eigenen Hand noch geben kann, zweifelt er an. „Schwer“ zweifelt gezielter. Der Computer legt ehrlich, was er hat, und lügt nur mit einer einzigen Karte.

## Begriffe, Beispiel und Bedienung
Stichwörter: Begriffe, Beispiel, Bedienung, Tipp, Wahrscheinlichkeit, Knopf, antippen, ablegen
Haufen: die verdeckten Karten in der Mitte. „Gefordert“: der Rang, den alle behaupten müssen. Mogeln oder lügen: eine falsche Behauptung. Ein Beispiel mit 4 Spielern: Rang 7, A legt 7♣, B glaubt. Rang 8: B legt 2 Karten (9♠, 10♦) als Achter, C ruft „Gelogen!“. Es war gelogen, also nimmt B den Haufen mit 3 Karten und legt als Nächster bei Rang 9. Hatte B vorher 8 Karten, hat er jetzt 9. Bedienung: Tippe 1 bis 4 Karten an und dann auf den Knopf „… Karte(n) als … ablegen“. Beim Entscheiden zeigt die Anzeige, wie viele Karten behauptet wurden. Der „Tipp“ nennt die Wahrscheinlichkeit in Prozent, dass die Ansage stimmt (unter 30 % lohnt sich Anzweifeln, bei 0 % kann es nicht stimmen). Der Tipp ist eine Schätzung.

## Was die App anders macht
Stichwörter: anders, Abweichung, Unterschied, Joker, Rang automatisch, üblich
Es gibt keine Joker. Der Rang steigt in der App immer automatisch um eins, auch nach „Gelogen!“. Wer den Haufen nimmt, legt als Nächster weiter, es ändert sich also die Reihenfolge am Tisch. Gewinn gibt es erst, wenn die letzte Legung nicht überführt wurde. Aufgedeckt werden nur die zuletzt gelegten Karten. Wertung nach dem Ende: Restkarten, die wenigsten vorn.
"""#
}
