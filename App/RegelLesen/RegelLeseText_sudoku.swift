// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/sudoku/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_sudoku {
    static let quelle = #"""
## Worum es geht

Sudoku ist ein Zahlenrätsel für dich allein. Fülle das Gitter so, dass **jede Zahl in jeder Zeile, jeder Spalte und jedem Kästchen genau einmal** steht. Rechnen musst du dabei nicht, nur logisch denken. Jedes Rätsel hat genau eine Lösung.

Die Zahlen, die schon zu Beginn im Gitter stehen, sind fest. Du kannst sie nicht ändern.

## Drei Spielarten

@form C
| Spielart | Gitter | Zahlen | Kästchen | Besonderheit |
|---|---|---|---|---|
|**Klassisch** | 9 × 9 | 1 bis 9 | 3 × 3 Felder | – |
|**Kinder** | 6 × 6 | 1 bis 6 | 3 breit, 2 hoch | ideal zum Einstieg |
|**X-Sudoku** | 9 × 9 | 1 bis 9 | 3 × 3 Felder | Auch die beiden Diagonalen enthalten jede Zahl einmal. |

Statt „Kästchen“ sagt die App manchmal „Box“. Beides meint dasselbe.

## Stufen

Für das klassische Sudoku gibt es vier Stufen. Sie richten sich danach, welche Lösetricks du brauchst:

- **Leicht:** nur einfache Einzelzahlen.
- **Mittel:** dazu Paare und Linien-Tricks.
- **Schwer:** dazu Tripel und X-Wing.
- **Experte:** braucht mehr als die üblichen Tricks.

Kinder- und X-Sudoku haben Leicht, Mittel und Schwer. Je schwerer, desto weniger Zahlen stehen am Anfang.

**Freischalten:** Leicht ist immer offen. Die nächste Stufe öffnet sich, wenn du auf der Stufe davor 3 klassische Rätsel ohne Tipp gelöst hast. Gesperrte Stufen haben ein Schloss. Tagesrätsel, Übungen und eigene Rätsel zählen dafür nicht.

## So trägst du ein

- Tippe ein leeres Feld an, dann unten die Zahl.
- Tippst du dieselbe Zahl noch einmal, wird sie gelöscht. Die Löschtaste geht auch.
- Neben jeder Zahl unten siehst du, wie oft sie noch fehlt.
- **Rückgängig** nimmt den letzten Schritt zurück.

## Notizen

Schalte **„Notizen“** ein. Dann schreibst du kleine Merkzahlen in ein leeres Feld: Zahlen, die dort noch in Frage kommen. Tippe dieselbe Zahl noch einmal, um sie wieder zu entfernen.

Setzt du später eine echte Zahl, streicht die App sie aus den Notizen aller Nachbarfelder in Zeile, Spalte und Kästchen (beim X-Sudoku auch in der Diagonale). Das lässt sich unter „Mehr“ → „Notizen automatisch streichen“ ausschalten.

„Mehr“ → „Notizen füllen“ trägt in alle leeren Felder die noch möglichen Zahlen ein.

## Fehler

Eine Zahl, die nicht zur Lösung passt, ist ein **Fehler**. Das gilt auch, wenn sie im Moment keine Regel verletzt. Oben steht „Fehler 1 von 3“.

Nach dem **dritten Fehler** fragt die App:
- **Zurücksetzen:** Die App geht zurück bis zum letzten Stand ohne falsche Zahl. Der Fehlerzähler beginnt wieder bei 0.
- **Weiterspielen:** Du spielst einfach weiter. Die Frage kommt nicht noch einmal.

Verlieren kannst du nicht.

**Rot:** Mit „Fehler sofort zeigen“ (Standard) wird eine falsche oder doppelte Zahl sofort rot. Schaltest du es unter „Mehr“ aus, siehst du nur doppelte Zahlen rot.

**Gleiche Zahlen hervorheben** (Standard an): Tippst du ein Feld mit einer 5 an, leuchten alle anderen 5en auf.

## Tipp

Der **Tipp** erklärt dir den nächsten Schritt.

- Steht irgendwo eine falsche Zahl, zeigt er dir zuerst diese.
- Sonst zeigt er ein Feld und erklärt, warum dort eine bestimmte Zahl hingehört. Beim klassischen Sudoku nennt er auch den Trick, zum Beispiel „Einzige Möglichkeit“ oder „Nacktes Paar“.
- Mit **„Nur zeigen“** schaust du nur. Mit **„Eintragen“** setzt die App die Zahl.

Jeder Tipp wird gezählt. Mit Tipp gibt es keine Bestzeit und keinen Fortschritt beim Freischalten.

## Tagesrätsel

Jeden Tag gibt es ein klassisches Rätsel der Stufe Mittel, für alle gleich. Löst du es Tag für Tag, wächst deine **Serie**. Einen einzelnen verpassten Tag verzeiht die App als Ruhetag. Verpasst du zwei Tage hintereinander, beginnt die Serie von vorn.

## Lernweg

Im Lernweg übst du die Tricks der Profis Schritt für Schritt: 12 Techniken in vier Stufen, je 6 Übungen. Von „Einzige Möglichkeit“ und „Einzige Stelle“ über Paare bis zu X-Wing, Schwertfisch, XY-Flügel und Färben. Jede Übung zeigt ein Gitter mit Notizen und sagt dir, was du finden sollst. Fehler zählen hier nicht.

## Eigenes Rätsel

Du hast ein Sudoku aus der Zeitung oder einem Buch? Tippe es ab. Mit „Prüfen“ schaut die App, ob es genau eine Lösung hat. Dann kannst du es mit Notizen und Tipps spielen. Eigene Rätsel zählen nicht für Bestzeit und Freischalten.

## Rätsel teilen

Ist „Rätsel per Link teilen“ eingeschaltet, kannst du ein Rätsel als Link schicken. Wer den Link öffnet, bekommt dasselbe Rätsel.

## Zeit und Bestzeit

Die Zeit läuft nur, solange die App offen ist. Am Ende siehst du Zeit, Fehler und Tipps. Für jede Spielart und Stufe merkt sich die App deine **Bestzeit**, nur für Rätsel ohne Tipp. Tagesrätsel, Übungen und eigene Rätsel zählen nicht.

## So startest du

Auf der Spielseite wählst du:
- **Tagesrätsel** mit Datum und Serie,
- **Neues Rätsel** mit Spielart und Stufe,
- **Lernweg**,
- **Eigenes Rätsel**.

Verlässt du ein Rätsel, kannst du später weitermachen.

## Kleine Tipps

- Fang mit Zahlen an, die schon oft im Gitter stehen. Für sie bleiben wenige Plätze.
- Such in einem Kästchen: Wo kann die 7 überhaupt noch hin? Oft gibt es nur eine Stelle.
- Notizen helfen ab der Stufe Mittel sehr.

## Begriffe

- **Kästchen (Box):** ein Block aus 3 × 3 Feldern (beim Kinder-Sudoku 3 × 2).
- **Vorgabe:** eine Zahl, die von Anfang an da ist.
- **Notiz:** kleine Merkzahl in einem Feld.
- **Einzige Möglichkeit:** In ein Feld passt nur noch eine Zahl.
- **Einzige Stelle:** Eine Zahl passt in einer Reihe, Spalte oder einem Kästchen nur an eine Stelle.
"""#
}
