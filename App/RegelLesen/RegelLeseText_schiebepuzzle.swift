// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/schiebepuzzle/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_schiebepuzzle {
    static let quelle = #"""
## Worum es geht

Auf einem Brett liegen nummerierte Kacheln durcheinander. Ein Platz ist frei, die Lücke. Du schiebst die Kacheln in die Lücke, bis alle Zahlen der Reihe nach stehen: 1, 2, 3 … Zeile für Zeile, und die Lücke ist unten rechts.

Du spielst allein. Es geht darum, das Brett mit möglichst wenigen Zügen zu ordnen.

## So schiebst du

Tippe eine Kachel an, die in derselben Zeile oder Spalte wie die Lücke liegt. Sie rutscht in Richtung Lücke, und alle Kacheln dazwischen rutschen mit. Das zählt als **ein Zug**, egal wie viele Kacheln sich bewegen.

Kacheln, die nicht in der Zeile oder Spalte der Lücke liegen, bewegen sich nicht.

Kacheln, die schon am richtigen Platz sind, siehst du voll. Die anderen sind etwas blasser.

## Gelöst

Stehen alle Zahlen der Reihe nach und ist die Lücke unten rechts, ist das Puzzle gelöst. Die App zeigt dann, wie viele Züge und wie viele Sekunden du gebraucht hast.

Jedes Brett ist lösbar. Die App mischt es aus der fertigen Lösung heraus. Größere Bretter werden länger gemischt, damit sie genauso durcheinander sind.

## Größen

Es gibt 3 × 3 (8 Kacheln), 4 × 4 (15 Kacheln, Standard), 5 × 5 (24 Kacheln) und 6 × 6 (35 Kacheln). Die Größe wählst du vor dem Start auf der Spielseite oder während des Spiels unter „Mehr“ → „Größe“. Ein Wechsel mischt sofort neu.

## Tagesrätsel und Neu mischen

- **Tagesrätsel:** Alle bekommen am selben Tag in derselben Größe dasselbe Brett. So kannst du dich mit anderen vergleichen.
- **Neu mischen:** ein frisches Zufallsbrett in der gleichen Größe.

## Wertung

Es zählen die Züge, nicht die Zeit. Die App merkt sich je Größe deine **beste Zugzahl**. Du findest sie unter „Mehr“. Das Tagesrätsel hat eine eigene Bestleistung. Ist dein Ergebnis besser als bisher, steht „Neue Bestleistung!“ dabei.

Hast du einen Tipp benutzt, zählt die Partie nicht für die Bestleistung.

## Hilfen

- **Tipp:** zeigt mit einem gelben Rahmen die Kachel, die du als Nächstes schieben solltest. Ein Tipp kostet keinen Zug.
- **Rückgängig** (unter „Mehr“): nimmt Züge zurück. Der Zugzähler geht mit zurück.
- **Pause:** Verlässt du das Spiel, kannst du später weiterspielen. Die Zeit läuft nur, solange du spielst.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Ordne zuerst die oberste Zeile, dann die linke Spalte. Danach ist der Rest ein kleineres Puzzle.
- Rühre fertige Zeilen danach nicht mehr an.
- Die letzten beiden Kacheln einer Zeile bringst du am besten gemeinsam an ihren Platz.

## Was hier anders ist als anderswo

Meist darfst du nur die Kachel direkt neben der Lücke bewegen. Hier darfst du eine ganze Reihe auf einmal schieben, und das zählt nur als ein Zug.
"""#
}
