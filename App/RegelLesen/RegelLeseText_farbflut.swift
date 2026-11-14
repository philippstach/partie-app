// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/farbflut/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_farbflut {
    static let quelle = #"""
## Worum es geht

Das Feld besteht aus bunten Quadraten. Oben links beginnt die **Flut**: das Eckfeld und alle angrenzenden Felder in derselben Farbe. Mit jedem Zug gibst du der Flut eine neue Farbe, und sie wächst. Färbe das ganze Feld in einer einzigen Farbe, bevor deine Züge aufgebraucht sind.

Du spielst allein. Die Zeit spielt keine Rolle, nur die Zahl der Züge.

## So läuft ein Zug

Tippe unten einen der runden Farbknöpfe an. Die ganze Flut nimmt diese Farbe an und schluckt dabei alle angrenzenden Felder in dieser Farbe. Die Felder der Flut erkennst du am weißen Innenrahmen.

Die Farbe, die die Flut gerade hat, ist abgeblendet. Sie noch einmal zu wählen, wäre kein Zug.

Jede Farbe hat auch ein Zeichen (Kreis, Quadrat, Dreieck, Raute, Stern, Sechseck). So kannst du sie auch ohne Farbsehen unterscheiden.

## Gewonnen oder verloren

Oben steht, wie viele Züge du noch hast. Ist das ganze Feld einfarbig, steht dort „Geschafft!“. Das gilt auch, wenn es genau mit dem letzten Zug klappt.

Sind alle Züge verbraucht und das Feld ist noch bunt, ist die Partie verloren.

Jedes Feld ist lösbar: Die App rechnet vorher einen Weg aus und gibt dir ein paar Züge mehr, als der braucht. Deshalb hat jedes Brett sein eigenes Limit.

## Schwierigkeit

@form C
| Stufe | Feld | Farben | Reservezüge |
|---|---|---|---|
|Leicht | 8 × 8 | 4 | 6 |
|Normal (Standard) | 12 × 12 | 6 | 5 |
|Schwer | 14 × 14 | 6 | 2 |

Leicht ist immer offen. **Normal** öffnet sich nach 3 Siegen ohne Tipp auf Leicht, **Schwer** nach 3 Siegen ohne Tipp auf Normal. Gesperrte Stufen zeigen ein Schloss. Im Kindermodus und mit „Alle Stufen offen“ in den Einstellungen ist alles offen.

## Punkte und Bestleistung

Geschafft gibt **100 Punkte plus 10 für jeden übrigen Zug**. *Beispiel:* Du hattest 25 Züge und warst nach 21 fertig. 4 Züge übrig ergibt 140 Punkte. Verloren gibt 0 Punkte.

Die App merkt sich je Stufe deine **Bestleistung**: die wenigsten Züge. Das gilt nur für Partien ohne Tipp.

## Tagesrätsel

Jeden Tag gibt es ein Brett, das alle bekommen: 12 × 12 mit 6 Farben. Du startest es über die Karte „Tagesrätsel heute“ auf der Spielseite. Löst du es, zählt der Tag für deine **Serie** (Tage in Folge). Das Tagesrätsel hat eine eigene Bestleistung pro Tag.

## Hilfen

- **Zurück:** nimmt Züge zurück, auch mehrere. Nach dem Ende geht das nicht mehr.
- **Tipp:** legt einen Ring um die Farbe, die gerade die meisten Felder dazubringt. Das ist ein guter, aber nicht immer der kürzeste Weg. Ein Tipp kostet nichts, aber die Partie zählt dann nicht für Bestleistung und Freischalten.
- **Neu beginnen** (unter „Mehr“): legt ein neues Brett. Hast du schon Züge gemacht und die Partie läuft noch, fragt die App vorher „Aktuelle Partie abbrechen?“.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps

- Arbeite dich zur Mitte vor. Von dort erreicht die Flut viele Felder auf einmal.
- Schau nicht nur auf die Farbe, die jetzt am meisten bringt, sondern auch auf den Zug danach.
"""#
}
