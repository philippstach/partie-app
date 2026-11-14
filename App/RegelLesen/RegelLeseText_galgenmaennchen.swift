// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/galgenmaennchen/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_galgenmaennchen {
    static let quelle = #"""
## Worum es geht

Ein Wort ist gesucht. Du siehst nur Striche, für jeden Buchstaben einen. Rate Buchstaben, bis das Wort dasteht. Für jeden falschen Buchstaben platzt einer von **acht Ballons**. Platzt der letzte, ist das Wort verloren.

Das Spiel heißt auch Galgenraten oder Hangman. In der App platzen Ballons statt eines Galgens.

## So rätst du

- Tippe auf der Tastatur einen Buchstaben.
- Kommt er im Wort vor, erscheint er an **allen** Stellen.
- Kommt er nicht vor, platzt ein Ballon.
- Ein Buchstabe, den du schon getippt hast, kostet nichts mehr.
- Leerzeichen und Bindestriche stehen von Anfang an offen.
- Ä, Ö und Ü haben eigene Tasten. ß wird als ss geschrieben.

Stehen alle Buchstaben, hast du gewonnen.

## Das ganze Wort lösen

Mit **„Lösen“** rätst du das ganze Wort auf einmal. Groß- und Kleinschreibung ist egal.

- Richtig: Du hast sofort gewonnen.
- Falsch: Es platzen **2 Ballons**.
- Denselben falschen Versuch noch einmal zu wählen kostet nichts.

## Hinweise

Ein **Hinweis** deckt einen Buchstaben auf. Du wählst: einen beliebigen Buchstaben, den ersten Buchstaben oder einen Vokal.

- Du hast **2 Hinweise** je Wort, bei „Kinderleicht“ 4.
- Ein Hinweis kostet keinen Ballon.
- Er geht nur, solange noch mindestens zwei verschiedene Buchstaben fehlen. Den letzten Buchstaben musst du selbst finden.

## Allein spielen

**Freies Spiel:** Du wählst die Sprache der Wörter (Deutsch, Englisch, Spanisch oder Französisch), ein Thema oder „Alle“ und die Stufe Leicht, Mittel (Standard) oder Schwer. „Kinderleicht“ nimmt nur leichte Wörter und gibt 4 Hinweise. Wörter wiederholen sich nicht so schnell: Die letzten 200 je Sprache lässt die App aus, solange es neue gibt.

**Wort des Tages:** ein Wort pro Tag, für alle gleich, aus den Stufen Leicht und Mittel. Du hast einen Versuch pro Tag und Sprache. Gewinnst du mehrere Tage hintereinander, wächst deine Serie. Für die Serie zählt nur das erste Wort des Tages, auch wenn du danach eins in einer anderen Sprache spielst. Das Ergebnis kannst du teilen.

**Überleben:** Du startest mit **3 Leben** und rätst Wort für Wort. Jedes Wort hat 8 Ballons.
- Verlierst du ein Wort, verlierst du ein Leben.
- Löst du ein Wort mit höchstens 1 Fehler und ohne Hinweis, bekommst du ein Leben zurück, höchstens bis 5.
- Die ersten 3 Wörter sind leicht, die nächsten 4 mittel, danach nur noch schwer.
- Gezählt wird, wie viele Wörter du schaffst.

**Eigene Wörter:** Leg eine eigene Wortliste an, zum Beispiel für die Familie oder die Schule, gern mit einem Hinweis dazu. Die App zieht daraus ein Wort. Ein Wort braucht 3 bis 20 Buchstaben und darf nur Buchstaben, Leerzeichen und Bindestriche enthalten.

## Party mit 2 bis 4 Personen

Reihum rät eine Person. In Runde 1 rät Spieler 1, in Runde 2 Spieler 2 und so weiter.

- **Wörter selbst ausdenken** (Standard): Das Wort denkt sich die Person nach dem Rater aus, zu zweit also der andere. Der Rater schaut weg, das Gerät wird übergeben. Das Wort hat 3 bis 20 Buchstaben, dazu kommt ein kurzer Hinweis.
- **Wörter von der App:** mit Thema und Stufe.
- **Runden:** 1 bis 5 je Person, Standard 2. Zu dritt mit 2 Runden sind es also 6 Runden.

**Punkte:**
- Der Rater bekommt, wenn er das Wort schafft: 2 + übrige Ballons − benutzte Hinweise, mindestens 1 Punkt.
- Schafft er es nicht, bekommt er 0. Bei selbst ausgedachten Wörtern bekommt dann der Wortgeber 3 Punkte.
- Nach der letzten Runde gewinnt, wer die meisten Punkte hat. Gleich viele Punkte teilen sich den Platz.

*Beispiel:* Der Rater löst mit 2 Fehlern und 1 Hinweis: 2 + 6 − 1 = **7 Punkte**. Ohne Fehler und ohne Hinweis sind es 2 + 8 = **10**.

## So bedienst du das Spiel

- Buchstaben tippst du auf der Tastatur unten. Auf dem iPad mit Tastatur gehen auch die echten Tasten.
- Getippte Buchstaben werden auf der Tastatur markiert.
- **Hinweis** und **Lösen** sind eigene Knöpfe.
- Ein neues Spiel beginnst du über den Zurück-Knopf oben und die Spielseite.

## Kleine Tipps

- Fang mit häufigen Buchstaben an: E, N, R, I, S, T, A.
- Ein Vokal-Hinweis hilft bei kurzen Wörtern am meisten.
- Löse erst, wenn du dir sicher bist. Ein falsches Lösen kostet 2 Ballons.
"""#
}
