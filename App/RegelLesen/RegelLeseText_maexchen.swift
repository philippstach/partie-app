// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/maexchen/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_maexchen {
    static let quelle = #"""
## Worum es geht

Mäxchen ist ein Bluffspiel mit zwei Würfeln. Du würfelst verdeckt, nur du siehst das Ergebnis. Dann sagst du an, was du gewürfelt hast, **ehrlich oder gelogen**. Der Nächste muss entscheiden: Glaubt er dir, oder deckt er auf?

Wer sich dabei irrt, verliert ein Leben. Wer als Letzter noch Leben hat, gewinnt.

## Was du brauchst

- **Spieler:** 2 bis 8, jeder Platz Mensch oder Computer.
- **Würfel:** zwei Würfel. Die App würfelt verdeckt für dich, oder ihr würfelt mit echten Würfeln unter einem Becher und tippt das Ergebnis ein.
- **Leben:** Jeder startet mit 3 Leben. Wählbar sind auch 1 (K. o.) oder 5.

## Die Würfe vom schwächsten zum besten

Die größere Zahl steht immer vorn. Eine 3 und eine 1 sind also „31“, nicht „13“.

| Wurf | Reihenfolge |
|---|---|
|**Zahlen** | 31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65 |
|**Pasch** | Pasch 1 (1 und 1), Pasch 2 … bis Pasch 6 |
|**Mäxchen** | 2 und 1, der höchste Wurf |

Jeder Pasch schlägt jede Zahl. Mäxchen schlägt alles. „21“ gibt es nicht, denn 2 und 1 ist immer Mäxchen.

Zusammen sind das 21 mögliche Ansagen.

## Eine Runde

1. **Würfeln:** Wer dran ist, würfelt verdeckt und schaut allein nach.
2. **Ansagen:** Er sagt einen Wert an. Der muss **höher** sein als die letzte Ansage. Ob er stimmt, ist egal. Du darfst auch weniger ansagen, als du hast, solange es höher ist als die letzte Ansage.
3. **Weitergeben:** Der Nächste ist dran und muss entscheiden:
   - **Glauben:** Er nimmt die Ansage hin. Dann würfelt er selbst neu und verdeckt und muss eine noch höhere Ansage machen.
   - **Anzweifeln:** Der Wurf wird aufgedeckt.

Zu Beginn einer Runde gibt es keine letzte Ansage. Dann ist jede Ansage erlaubt.

## Aufdecken

Beim Aufdecken vergleicht die App den echten Wurf mit der Ansage.

- **Der Wurf ist mindestens so hoch wie die Ansage:** Es war nicht gelogen. Wer gezweifelt hat, verliert ein Leben.
- **Der Wurf ist niedriger:** Es war gelogen. Wer angesagt hat, verliert ein Leben.

**Beispiel:** Anna sagt 54 an. Ihr echter Wurf ist 61. Ben zweifelt. 61 ist höher als 54, also hat Anna nicht gelogen. Ben verliert ein Leben.

## Mäxchen

Auf die Ansage „Mäxchen“ kann niemand mehr höher ansagen. Darum kannst du sie **nicht glauben**, du musst aufdecken. Der Knopf „Glauben“ fehlt dann.

- War es **wirklich Mäxchen**, verliert der Zweifler **2 Leben**.
- War es gelogen, verliert der Ansager 1 Leben.

## Nächste Runde und Ende

Wer ein Leben verloren hat, beginnt die nächste Runde. Ist er raus, beginnt die nächste Person nach ihm. Wer die erste Runde beginnt, wählst du vor dem Start: „Reihum“ (Standard, jede neue Partie beginnt die nächste Person) oder eine feste Person.

Wer keine Leben mehr hat, ist raus. Wer als **Letzter noch Leben** hat, gewinnt. Auf der Ergebnisseite steht der Gewinner auf Platz 1, alle anderen teilen sich Platz 2. Außerdem siehst du, wie viele Runden ihr gespielt habt, wie oft Mäxchen fiel und wie die Würfel gefallen sind.

## Leben einstellen

Unter „Mehr“ → „Leben“ wählst du 1 (K. o.), 3 oder 5. Das geht nur vor dem ersten Wurf. Die App merkt sich die Wahl für die nächsten Partien.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“, wenn ein Computer mitspielt:

- **Leicht:** sagt irgendeinen erlaubten Wert an und zweifelt wie beim Münzwurf.
- **Mittel** (Standard): sagt die Wahrheit, wenn sein Wurf reicht. Sonst lügt er knapp über der letzten Ansage. Je höher eine Ansage, desto eher zweifelt er.
- **Schwer:** lügt nur, wenn er muss, und dann so knapp wie möglich. Er merkt sich, wer oft beim Lügen erwischt wurde, und zweifelt bei dem eher.

Auf Mäxchen deckt jeder Computer auf, weil es nicht anders geht.

## Mit echten Würfeln

Wähle vor dem Start „Echte Würfel“. Würfle verdeckt unter dem Becher, schau allein nach und tippe auf „Würfel eintragen“. Den Rest macht die App.

## So bedienst du das Spiel

- **Verdeckt würfeln:** Knopf antippen oder das Gerät schütteln.
- **Ansagen:** Nach dem Wurf siehst du deine Würfel. Wähle im Rad deine Ansage und tippe „Ansagen und weitergeben“. Das Rad zeigt nur erlaubte Werte und steht zuerst auf dem niedrigsten, nicht auf deinem echten Wurf.
- **Glauben / Anzweifeln:** die zwei Knöpfe, wenn du dran bist.
- **Tipp:** Beim Entscheiden steht eine Zeile, wie wahrscheinlich ein so hoher Wurf ist, zum Beispiel „So hoch würfelt man nur zu etwa 17 % – anzweifeln lohnt sich.“
- **Sichtschutz:** Spielen mehrere Menschen an einem Gerät, erscheint vor jedem Zug eine Karte mit dem Namen. Gib das Gerät weiter, und erst dann tippt der Richtige darauf. So sieht niemand fremde Würfel.
- **Letzte Ansage:** steht in der Mitte, nach dem Aufdecken auch, was wirklich lag.
- **Herzen** am Namen zeigen die Leben.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

Einen Zug zurücknehmen kannst du nicht.

## Wie wahrscheinlich ist ein Wurf?

Von 36 möglichen Würfen sind:
- Mäxchen: 2 (etwa 6 %),
- jeder Pasch: 1 (etwa 3 %),
- jede Zahl: 2.

Eine 61 oder höher würfelt man in der Hälfte der Fälle, einen Pasch oder Mäxchen nur in etwa 22 von 100 Würfen. Je höher die Ansage, desto eher lohnt sich das Aufdecken.

## Kleine Tipps

- Lüg nicht zu hoch. Wer knapp über der letzten Ansage bleibt, macht es dem Nächsten schwer.
- Hast du einen guten Wurf, sag ruhig etwas weniger an. Dann hast du Luft nach oben, falls es zurückkommt.
- Merk dir, wer gern blufft.

## Begriffe

- **Ansage:** der Wert, den du nennst.
- **Pasch:** zwei gleiche Würfel.
- **Mäxchen:** 2 und 1, der höchste Wurf.
- **Anzweifeln (aufdecken):** den verdeckten Wurf prüfen.
- **Glauben:** die Ansage hinnehmen und selbst würfeln.
- **K. o.:** Spiel mit nur einem Leben.
"""#
}
