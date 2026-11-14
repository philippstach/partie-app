// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/maexchen.md. Nicht von Hand ändern.
enum RegelWissenText_maexchen {
    static let quelle = #"""
## Ziel und Material
Stichwörter: Ziel, gewinnen, Leben, Spieler, Würfel, Bluff, Mäxchen, Material
Mäxchen ist ein Bluffspiel für 2 bis 8 Personen mit 2 Würfeln. Jede Person hat am Anfang 3 Leben. Du würfelst verdeckt, sagst einen Wert an, den du ehrlich oder gelogen nennst, und gibst die Ansage weiter. Wer zweifelt und falsch liegt, verliert ein Leben. Wer ein Leben verliert, beginnt die nächste Runde. Wer keine Leben mehr hat, ist raus. Wer als Letzter noch Leben hat, gewinnt. Mit der Option „Leben“ wählst du 1 Leben (K. o.), 3 oder 5. Die App merkt sich die Wahl für die nächsten Partien.

## Rangfolge der Ansagen
Stichwörter: Rangfolge, höher, Reihenfolge, Pasch, Mäxchen, 21, 31, 65, was schlägt was
Es gibt 21 mögliche Ansagen, vom niedrigsten zum höchsten:
- 31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65. Die größere Augenzahl steht vorn. „31“ sind eine 3 und eine 1. 65 ist die höchste dieser Zahlen.
- Pasch 1 (1-1), Pasch 2, Pasch 3, Pasch 4, Pasch 5, Pasch 6. Alle Pasche sind höher als die Zahlen. Pasch 6 ist der höchste Pasch.
- Mäxchen (2 und 1) ist am höchsten.
Die 21 Ansagen heißen in der App: 31 bis 65, Pasch 1 bis Pasch 6 und Mäxchen. „21“ gibt es nicht, 2 und 1 heißt immer Mäxchen.

## Ablauf einer Runde
Stichwörter: Ablauf, Runde, würfeln, ansagen, glauben, anzweifeln, lügen, Becher, weitergeben
1. Du würfelst beide Würfel verdeckt („Verdeckt würfeln“). Nur du siehst das Ergebnis.
2. Du sagst einen Wert an. Er muss höher sein als die letzte Ansage. Die erste Ansage nach einem Aufdecken darf beliebig sein.
3. Du gibst weiter. Die nächste Person entscheidet: glauben oder anzweifeln.
4. Glaubt sie, würfelt sie selbst verdeckt, mit neuen Würfeln, und muss einen höheren Wert als die letzte Ansage nennen. Sie darf dabei lügen, wenn ihr eigener Wurf nicht reicht. Sie darf auch niedriger ansagen als sie geworfen hat, solange die Ansage höher als die letzte Ansage ist.
5. Zweifelt sie an, wird der verdeckte Wurf des Ansagers aufgedeckt. Dann verliert jemand Leben (siehe nächster Abschnitt).
Nach dem Aufdecken beginnt eine neue Runde ohne Ansage. Wer die erste Runde beginnt, wählst du vor dem Start: „Reihum“ (Standard, jede neue Partie beginnt die nächste Person) oder eine feste Person.

## Aufdecken und Leben verlieren
Stichwörter: aufdecken, zweifeln, Leben verlieren, gelogen, ehrlich, Mäxchen zwei Leben, Verlierer, wer verliert
Beim Anzweifeln vergleicht die App den echten Wurf mit der Ansage. War der echte Wurf mindestens so hoch wie die Ansage, war die Ansage nicht gelogen. Dann verliert die Person, die gezweifelt hat, ein Leben. War der echte Wurf niedriger als die Ansage, war es gelogen. Dann verliert der Ansager ein Leben.
Ein höherer Wurf als angesagt zählt also auch als ehrlich. Die Ansage muss nicht genau stimmen.
Besonderheit Mäxchen: Wurde Mäxchen angesagt und es war wirklich Mäxchen, verliert der Zweifler 2 Leben. War es gelogen, verliert der Ansager 1 Leben. Auf eine Ansage „Mäxchen“ kannst du nicht glauben, denn nichts ist höher: Du musst aufdecken. Der Knopf „Glauben“ fehlt dann.
Wer ein Leben verliert, beginnt die nächste Runde. Ist er raus, beginnt die nächste Person nach ihm.
Beispiel: Anna sagt 54 an, ihr echter Wurf war 61. Ben zweifelt. 61 ist höher als 54, also ehrlich, Ben verliert 1 Leben.

## Computer, Tipp und Bedienung
Stichwörter: Computer, Stufe, Tipp, Bedienung, Knopf, echte Würfel, Sichtschutz, eintippen
Zuerst „Verdeckt würfeln“ (oder schütteln), dann im Rad die Ansage wählen und „Ansagen und weitergeben“ tippen. Bei mehreren Menschen zeigt die App erst eine Sichtschutz-Karte mit dem Namen, damit niemand fremde Würfel sieht. Bei „Echte Würfel“ tippst du die Augen über „Würfel eintragen“ ein.
Der Tipp beim Entscheiden nennt die Wahrscheinlichkeit, dass ein ehrlicher Wurf so hoch oder höher ist. Unter 30 % schreibt er „anzweifeln lohnt sich“. Auf Mäxchen schreibt er „Auf Mäxchen musst du aufdecken“.
Computer: Leicht sagt zufällig einen erlaubten Wert an und zweifelt in der Hälfte der Fälle. Mittel sagt die Wahrheit, wenn sein Wurf hoch genug ist; sonst lügt er 1 bis 3 Stufen über der letzten Ansage, und er zweifelt umso eher, je höher die Ansage ist. Schwer sagt ebenfalls die Wahrheit, wenn der Wurf reicht; sonst lügt er meist so klein wie möglich (manchmal eine Stufe höher) und merkt sich, wie oft ein Gegner beim Lügen erwischt wurde. Auf Mäxchen deckt jeder Computer immer auf.

## Wahrscheinlichkeiten und Beispiele
Stichwörter: Wahrscheinlichkeit, Chance, Prozent, Beispiel, wie wahrscheinlich
Mit 2 Würfeln gibt es 36 Würfe. Jede Zahl mit zwei verschiedenen Augen (zum Beispiel 31) kommt 2-mal vor, ein Pasch 1-mal, Mäxchen 2-mal (2-1 und 1-2).
Chance, mindestens diesen Wert zu würfeln: 31 oder höher 100 %. 51 oder höher 26 von 36 (72 %). 61 oder höher 18 von 36 (50 %). 65 oder höher 10 von 36 (28 %). Pasch 1 oder höher 8 von 36 (22 %). Pasch 6 oder höher 3 von 36 (8 %). Mäxchen 2 von 36 (6 %).
Beispiel: Ben sagt 65 an. Die Chance ist 28 %, Zweifeln lohnt sich oft.
Beispiel: Cem sagt Mäxchen an und hat gelogen (echter Wurf 43). Dina muss aufdecken und Cem verliert 1 Leben. Hätte Cem Mäxchen echt geworfen, verlöre Dina 2 Leben.

## Ende der Partie
Stichwörter: Ende, Sieger, Platz, Ergebnis, neue Partie
Wer als Letzter noch Leben hat, gewinnt. Die Ergebnisliste zeigt den Gewinner auf Platz 1. Alle anderen teilen sich Platz 2, egal wie lange sie durchgehalten haben. Die Leben stehen als Herzen am Namen. Im Menü „Neue Partie“ startet neu (mit Rückfrage, wenn schon gespielt wurde).

## Begriffe
Stichwörter: Begriff, bluffen, was heißt, Ansage
Ansage: der Wert, den du nennst. Pasch: zwei gleiche Würfel. Mäxchen: 2 und 1, der höchste Wurf. Anzweifeln oder aufdecken: den verdeckten Wurf prüfen. Glauben: die Ansage hinnehmen und selbst würfeln. Lügen oder bluffen: einen höheren Wert ansagen als gewürfelt. K. o.: die Option mit nur einem Leben.

## Was die App anders macht als die übliche Regel
Stichwörter: anders, Abweichung, üblich, Unterschied, Hausregel
Wer glaubt, würfelt bei der App immer selbst neu und sagt einen höheren Wert als die letzte Ansage; die Würfel werden nicht weitergereicht. Ein höherer Wurf als angesagt gilt als ehrlich. Echtes Mäxchen kostet den Zweifler 2 Leben, sonst gibt es immer 1 Leben Verlust. Auf Mäxchen gibt es kein Glauben. Es gibt keine weiteren Hausregeln außer der Zahl der Leben (1, 3 oder 5).
"""#
}
