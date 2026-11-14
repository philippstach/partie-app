// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/kakuro/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_kakuro {
    static let quelle = #"""
## Worum es geht

Kakuro ist ein Zahlen-Kreuzworträtsel. Statt Wörtern trägst du **Ziffern von 1 bis 9** in die weißen Felder ein. Die Zahlen in den dunklen Feldern sagen dir, welche Summe herauskommen muss. Du spielst allein und in Ruhe, ohne Gegner.

## Das Gitter

- **Weiße Felder:** Hier trägst du Ziffern ein.
- **Dunkle Felder:** Sie trennen die Reihen. Manche tragen eine **Hinweiszahl**.
- Die erste Zeile und die erste Spalte sind immer dunkel.

Eine Reihe weißer Felder zwischen zwei dunklen Feldern heißt **Lauf**. Jeder Lauf hat mindestens 2 Felder.

**Wo die Hinweiszahl steht:**
- Die Zahl **oben rechts** im dunklen Feld gilt für den Lauf **nach rechts**.
- Die Zahl **unten links** gilt für den Lauf **nach unten**.

## Die Regeln

1. Die Ziffern eines Laufs ergeben zusammen genau die Hinweiszahl.
2. In einem Lauf darf **keine Ziffer doppelt** vorkommen.
3. Jedes weiße Feld gehört zu einem Lauf nach rechts und meist auch zu einem nach unten. Es muss für beide passen.

Das Rätsel ist gelöst, wenn alle Läufe voll sind und jede Summe stimmt.

**Beispiel:** Die Hinweiszahl 7 über zwei Feldern lässt 1 + 6, 2 + 5 oder 3 + 4 zu. 8 über zwei Feldern: 1 + 7, 2 + 6 oder 3 + 5. 4 + 4 geht nicht, weil die 4 doppelt wäre.

**Feste Paare, die dir helfen:**
- 3 über zwei Feldern: nur 1 und 2.
- 4 über zwei Feldern: nur 1 und 3.
- 16 über zwei Feldern: nur 7 und 9.
- 17 über zwei Feldern: nur 8 und 9.
- 6 über drei Feldern: nur 1, 2 und 3.
- 24 über drei Feldern: nur 7, 8 und 9.

## Vorgegebene Ziffern

In manchen weißen Feldern steht schon von Anfang an eine Ziffer. Die App gibt sie vor, damit das Rätsel **genau eine Lösung** hat. Diese Ziffern kannst du nicht ändern und nicht löschen. Sie zählen in den Summen ganz normal mit.

## So trägst du ein

- Tippe ein weißes Feld an. Es wird hervorgehoben. Beim Start ist schon das erste freie Feld gewählt.
- Tippe unten eine Ziffer von 1 bis 9. Eine neue Ziffer ersetzt die alte.
- Mit der **Löschtaste** machst du das Feld wieder leer.
- **Zug zurück** nimmt deinen letzten Eintrag zurück, auch mehrmals.

## Hilfen

**Rot:** Steht in einem Lauf eine Ziffer doppelt, oder ist die Summe schon zu groß, werden die Felder rot. Eine zu kleine Summe wird nicht rot, solange der Lauf noch nicht voll ist.

**Möglich:** Unter dem Ziffernblock steht, welche Ziffern für das gewählte Feld noch in Frage kommen, zum Beispiel „Möglich: 1 2 5“. Die App rechnet das aus den Summen und den Ziffern aus, die schon stehen. Passt keine Ziffer mehr, steht dort „Hier passt keine Ziffer mehr – prüfe die anderen Felder.“

**Prüfen:** vergleicht deine Ziffern mit der Lösung. Die App meldet „Bisher alles richtig.“ oder „Falsche Felder: 2“ und färbt die falschen rot. Achtung: Eine Ziffer kann alle Regeln einhalten und trotzdem falsch sein. Prüfen kostet nichts.

**Tipp:** trägt die richtige Ziffer in das gewählte Feld ein. Ist es schon richtig, nimmt die App ein anderes leeres oder falsches Feld. Ein Tipp zählt mit: Mit Tipp gibt es keine Bestzeit und keinen Fortschritt beim Freischalten.

## Größen und Freischalten

Es gibt drei Größen: **5 × 5, 6 × 6 und 7 × 7**. Die erste Zeile und Spalte mit den Hinweisen zählen mit.

- 5 × 5 ist immer offen.
- 6 × 6 öffnet sich nach 3 gelösten Rätseln ohne Tipp auf 5 × 5.
- 7 × 7 öffnet sich nach 3 gelösten Rätseln ohne Tipp auf 6 × 6.
- Gesperrte Größen haben ein Schloss. Im Kindermodus und mit „Alle Stufen offen“ ist alles offen.

Die Größe wählst du auf der Spielseite vor dem Start oder im Spiel unter „Mehr“ → „Größe“. Im Spiel beginnt damit sofort ein neues Rätsel.

## Tagesrätsel

Jeden Tag gibt es ein Tagesrätsel, für alle gleich, in jeder Größe ein eigenes. Du startest es auf der Spielseite oder im Spiel unter „Mehr“ → „Tagesrätsel“. Es hat eine eigene Bestzeit, zählt aber nicht fürs Freischalten.

## Zeit und Bestzeit

Die Zeit läuft ab dem Start. Ist die App im Hintergrund, hält sie an. Am Tisch siehst du keine Uhr, die Zeit steht erst auf der Ergebnisseite.

Für jede Größe merkt sich die App deine **Bestzeit**, nur für Rätsel ohne Tipp. Sie steht im Menü „Mehr“ als „Bestzeit“, sobald es eine gibt.

## Neues Rätsel und Pause

- „Mehr“ → „Neue Partie“ gibt dir ein neues Rätsel. Hast du schon etwas eingetragen oder einen Tipp genutzt, fragt die App vorher „Aktuelle Partie abbrechen?“. Das gilt auch für „Tagesrätsel“ und einen Größenwechsel.
- Verlässt du das Spiel, kannst du später an derselben Stelle weitermachen, die Zeit läuft dann weiter.

## Begriffe

- **Lauf:** eine Reihe weißer Felder zwischen zwei dunklen Feldern.
- **Hinweiszahl:** die Summe, die ein Lauf ergeben muss.
- **Vorgabe:** eine Ziffer, die von Anfang an da ist und sich nicht ändern lässt.
"""#
}
