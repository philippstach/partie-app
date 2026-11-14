// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/wortpfeil/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_wortpfeil {
    static let quelle = #"""
## So funktioniert es

Dieses Kreuzworträtsel ist ein **Schwedenrätsel**: Es gibt keine Nummern und keine Liste mit Fragen. Die Fragen stehen in Feldern mitten im Gitter. Ein **Pfeil** zeigt, wohin das Wort läuft, nach rechts oder nach unten. Das Wort beginnt direkt hinter dem Pfeil und endet vor dem nächsten Fragefeld oder am Rand.

*Beispiel:* „Großmutter“ mit Pfeil nach rechts ergibt OMA. „Gefrorenes Wasser“ mit Pfeil nach unten ergibt EIS.

Ein Fragefeld kann zwei Fragen enthalten. Die meisten Buchstabenfelder gehören zu einem Wort nach rechts und einem nach unten.

Fülle alle Buchstabenfelder richtig aus. Es gibt keinen Zeitdruck und keine Strafen.

## Eintragen

- Tippe ein Feld oder eine Frage an. Das Wort wird markiert, die ganze Frage steht unten in der Leiste, dazu wie viele Buchstaben schon stehen (zum Beispiel 3/7).
- Tippst du dasselbe Feld noch einmal, wechselt die Richtung.
- Mit den Pfeilen neben der Leiste oder per Wischen springst du zur nächsten oder vorigen Frage.
- Nach jedem Buchstaben springt die Markierung ins nächste leere Feld.
- Mit dem **Bleistift** schreibst du Buchstaben, bei denen du unsicher bist. Das zählt nicht als Hilfe.

## Umlaute

Wie in der Zeitschrift: ein Feld, ein Buchstabe. Ä wird AE, Ö wird OE, Ü wird UE, ß wird SS. Die Tasten Ä, Ö und Ü tragen zwei Felder auf einmal ein. ß bekommst du, wenn du lange auf S drückst.

Alle Rätsel und Fragen sind auf Deutsch.

## Das Lösungswort

Manche Felder tragen kleine Nummern. Die Buchstaben in diesen Feldern ergeben der Reihe nach das **Lösungswort**. Es steht unten im Streifen. Tippst du dort ein Feld an, springst du an seine Stelle im Gitter.

## Hilfen und Stern

- **Aufdecken:** zeigt den Buchstaben im markierten Feld. Langes Drücken (oder „Mehr“ → „Wort aufdecken“) zeigt das ganze Wort.
- **Wort prüfen** und **Alles prüfen:** färben falsche Buchstaben rot.

Jede dieser Hilfen zählt, auch ein Prüfen ohne Fehler. Oben siehst du, wie viele Hilfen du genommen hast. Wer das Rätsel **ganz ohne Hilfe** löst, bekommt einen **Stern**.

Diese Einstellungen helfen, zählen aber nicht als Hilfe:
- **Fehler sofort zeigen:** Falsche Buchstaben werden gleich rot.
- **Richtige Wörter zeigen:** Ein richtig gelöstes Wort leuchtet kurz auf.
- **Starthilfe:** Der erste Buchstabe jedes Wortes steht schon drin. Im allerersten Rätsel ist das immer so.

## Rätsel und Stufen

@form A
| Stufe | Gitter | Rätsel |
|---|---|---|
|Leicht | 7 × 9 | 300 |
|Mittel | 9 × 12 | 300 |
|Schwer | 11 × 15 | 150 |

Dazu kommen **Themenrätsel** in 8 Themen (zum Beispiel Tiere, Musik, Geschichte) mit je 30 Rätseln. „Neues Rätsel“ gibt dir das nächste ungelöste Rätsel der Stufe.

Löst du drei Rätsel hintereinander ohne Hilfe, schlägt dir die App die nächste Stufe vor. Brauchst du oft viele Hilfen, schlägt sie eine leichtere vor. Das kannst du in den Einstellungen abschalten.

## Rätsel des Tages

Jeden Tag gibt es ein neues Rätsel, für alle gleich. Löst du es an Tagen hintereinander, wächst deine **Serie**. Vergangene Tage spielst du unter „Archiv und Zeiten“ im Kalender nach, sie zählen aber nicht zur Serie. Auf Wunsch erinnert dich die App jeden Tag daran.

## Zeit und Pause

Die Zeit läuft nur, solange das Rätsel offen ist. Mit „Mehr“ → „Pause“ wird das Gitter verdeckt und die Zeit hält an. Für jede Stufe merkt sich die App deine Bestzeit. Es gibt außerdem 14 Erfolge zu sammeln.

Einen Knopf zum Zurücknehmen gibt es nicht. Du überschreibst oder löschst einfach.

## Wenn etwas nicht passt

Sind alle Felder voll, aber noch nicht alles richtig, sagt dir die App „Noch nicht ganz richtig“. Prüfe dann einzelne Wörter. Eine Frage, die dir komisch vorkommt, kannst du unter „Mehr“ → „Frage merken“ notieren.
"""#
}
