// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/mogeln/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_mogeln {
    static let quelle = #"""
## Worum es geht

Mogeln ist ein Kartenspiel, bei dem Lügen erlaubt ist. Ihr legt Karten verdeckt ab und behauptet, sie hätten einen bestimmten Rang. Ob das stimmt, weiß nur, wer gelegt hat. Wer als Erster alle Karten los ist, **ohne erwischt zu werden**, gewinnt.

## Was du brauchst

- **Spieler:** 3 bis 6, jeder Platz Mensch oder Computer.
- **Karten:** 32 Karten, von der 7 bis zum Ass in vier Farben. Joker gibt es nicht.
- Alle Karten werden reihum verteilt. Zu viert hat jeder 8 Karten, zu dritt 11, 11 und 10.

Die Farben spielen keine Rolle. Es zählt nur der Rang.

## Der geforderte Rang

In der Mitte steht groß, welcher Rang gerade **gefordert** ist. Er beginnt bei der 7 und steigt mit jedem Zug um eins:

7, 8, 9, 10, Bube, Dame, König, Ass, dann wieder 7.

Den Rang suchst du dir nicht aus. Er rückt immer weiter, auch nach einem „Gelogen!“.

## Dein Zug

1. Wähle **1 bis 4 Karten** aus deiner Hand.
2. Lege sie verdeckt auf den Haufen. Damit behauptest du: Das sind Karten des geforderten Rangs.
3. Passen gibt es nicht. Du musst mindestens eine Karte legen.

**Du darfst lügen.** Hast du keine Karte des Rangs, legst du trotzdem eine und tust so. Auch wenn du ehrlich bist, darfst du weniger Karten legen, als du hast.

## Glauben oder „Gelogen!“

Nur die **nächste Person** entscheidet:

- **Glauben:** Der Haufen bleibt liegen. Der Rang rückt weiter, und die Person legt selbst.
- **Gelogen!:** Die zuletzt gelegten Karten werden aufgedeckt, nicht der ganze Haufen.
  - Ist auch nur eine Karte nicht vom geforderten Rang, war es gelogen. Dann nimmt der **Lügner** den ganzen Haufen auf die Hand.
  - Stimmte alles, nimmt der **Zweifler** den ganzen Haufen.

Wer den Haufen nimmt, legt als Nächster, und es gilt der nächste Rang.

*Beispiel:* Rang 8. Ben legt 2 Karten und sagt „zwei Achter“. In Wahrheit sind es eine 9 und eine 10. Clara ruft „Gelogen!“. Ben nimmt den ganzen Haufen und legt danach bei Rang 9.

## Wer gewinnt

Wer seine **letzte Karte** legt, hat noch nicht sofort gewonnen. Erst entscheidet die nächste Person:

- Sie glaubt: gewonnen.
- Sie ruft „Gelogen!“ und es stimmte: auch gewonnen.
- Sie ruft „Gelogen!“ und es war gelogen: Der Lügner nimmt den Haufen, das Spiel geht weiter.

Danach werden die anderen nach ihren Restkarten gereiht: Wer weniger hat, steht weiter vorn.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“, wenn ein Computer mitspielt:

- **Leicht:** ruft „Gelogen!“ nach Gefühl, etwa in 3 von 10 Fällen.
- **Mittel** (Standard): rechnet mit seinen eigenen Karten. Werden mehr Karten eines Rangs behauptet, als es noch geben kann, zweifelt er.
- **Schwer:** rechnet genauer und zweifelt gezielter.

Der Computer legt ehrlich, was er hat. Lügen muss er nur, wenn er den Rang nicht hat, und dann mit einer einzigen Karte.

## So bedienst du das Spiel

- **Legen:** Tippe 1 bis 4 Karten an und dann auf „2 Karten als 8 ablegen“ (der Knopf nennt Zahl und Rang).
- **Entscheiden:** Oben steht, wer wie viele Karten gelegt hat. Darunter eine Tipp-Zeile: wie wahrscheinlich die Behauptung stimmt, zum Beispiel „Die Ansage ist nur zu etwa 20 % wahr – anzweifeln lohnt sich.“ Der Tipp rechnet nur mit deinen eigenen Karten, er ist eine Schätzung.
- Nach dem Aufdecken steht in der Mitte, was lag und wer den Haufen nimmt.
- **Sichtschutz:** Spielen mehrere Menschen an einem Gerät, erscheint vor deinem Zug eine Karte mit deinem Namen. Erst wenn du das Gerät hast, tippst du darauf.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

Einen Zug zurücknehmen kannst du nicht. Eine neue Partie startest du über die Spielseite.

## Kleine Tipps

- Merk dir, wie viele Karten eines Rangs du selbst hast. Hast du drei Damen und jemand legt „zwei Damen“, stimmt das sicher nicht.
- Lüg am besten mit einer Karte. Mehrere falsche Karten fallen eher auf.
- Kurz vor dem Ende wird öfter gezweifelt. Heb dir für die letzte Karte eine ehrliche auf.

## Begriffe

- **Haufen:** die verdeckten Karten in der Mitte.
- **Gefordert:** der Rang, den alle gerade behaupten müssen.
- **Mogeln, lügen, bluffen:** eine falsche Behauptung.
- **Gelogen!:** der Ruf, mit dem man aufdecken lässt.
"""#
}
