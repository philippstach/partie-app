// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/irrgang/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_irrgang {
    static let quelle = #"""
## Worum es geht

Du stehst in der Ecke links oben eines Labyrinths. Der Ausgang ist in der Ecke rechts unten. Finde den Weg hinaus, möglichst kurz, und sammle unterwegs **Funken**. Danach kommt das nächste, größere Labyrinth.

Du spielst allein auf Punkte. Es gibt keine Zeit und kein Verlieren. Der Lauf geht so lange, bis du ihn beendest.

## So läufst du

Wische in eine Richtung. Dein Läufer geht geradeaus und hält erst an, wenn
- eine Wand kommt,
- eine Abzweigung kommt,
- er einen Funken erreicht oder
- er am Ausgang ist.

Er biegt nie von allein ab. Wischen kannst du überall auf dem Bildschirm.

## Punkte

Am Ausgang bekommst du für die Stufe:
- **100 Punkte mal die Stufe** (Stufe 3 bringt also 300),
- **50 Punkte für jeden Funken**,
- einen **Wegbonus** bis zu 100 mal die Stufe. Den vollen Bonus gibt es für den kürzesten Weg. Je mehr Umwege, desto weniger.

Funken liegen nur in Sackgassen. Es lohnt sich also manchmal, einen Abstecher zu machen, auch wenn der Weg dadurch länger wird.

## Stufen

Mit jeder Stufe wird das Labyrinth größer: Stufe 1 hat 6 × 8 Felder, ab Stufe 14 sind es 19 × 21. Ab **Stufe 4** wird es dunkel: Du siehst nur noch einen Ausschnitt um deinen Läufer, und der wird auf höheren Stufen kleiner. Felder, auf denen du warst, bleiben schwach sichtbar.

Nach jedem Ausgang tippst du „Weiter zu Stufe …“.

## Lauf beenden

Unter „Mehr“ → „Lauf beenden“ endet dein Lauf. Gezählt werden alle Stufen, deren Ausgang du erreicht hast. Die App merkt sich deinen **Bestwert**.

## Tageslauf

Jeden Tag gibt es einen Tageslauf: Alle bekommen dieselben Labyrinthe, Stufe für Stufe. Du startest ihn über die Karte „Tageslauf heute“ auf der Spielseite. Schaffst du mindestens eine Stufe, zählt der Tag für deine Serie.

## Hilfen

- **Tipp:** zeigt die Richtung zum Ausgang, zum Beispiel „Tipp: nach oben ↑“. Jeder Tipp kostet 25 Punkte.
- **Zug zurück:** nimmt den letzten Wisch zurück. Die Schritte zählen trotzdem weiter.
- **Neue Partie** und **Tageslauf** (unter „Mehr“): beginnen einen neuen Lauf. Hast du im Lauf schon Schritte gemacht oder Punkte gesammelt, fragt die App vorher „Aktuelle Partie abbrechen?“.
- **Pause:** Verlässt du das Spiel, kannst du später weiterlaufen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps

- Folge einer Wand mit der Hand, dann findest du immer hinaus. Kürzer geht es, wenn du vorher schaust.
- Im Dunkeln helfen die schwach sichtbaren Felder: Dort warst du schon.
"""#
}
