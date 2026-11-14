// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/schocken/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_schocken {
    static let quelle = #"""
## Worum es geht

Schocken ist ein Kneipenspiel aus Deutschland. Ihr würfelt reihum mit drei Würfeln. Wer in einer Runde den schlechtesten Wurf hat, bekommt **Deckel**. Deckel sind Strafmarken, die will niemand haben.

Wer am Ende einer Hälfte alle Deckel hat, verliert diese Hälfte. Wer die Partie verliert, hängt von den Hälften ab (siehe „Hälften und Finale“). Es geht also nicht ums Gewinnen, sondern darum, **nicht zu verlieren**.

## Was du brauchst

- **Spieler:** 2 bis 6. Jeder Platz kann ein Mensch oder der Computer sein.
- **Würfel:** drei Würfel im Becher. Du kannst auch mit echten Würfeln am Tisch spielen und die Ergebnisse eintippen.
- **Deckel:** 13 im Stock (mit der Hausregel 15).

## Wer beginnt

In der ersten Hälfte lost die App aus, wer anfängt. Danach beginnt jede Runde, wer die letzte Runde verloren hat. Eine neue Hälfte und das Finale beginnt, wer die letzte Hälfte verloren hat.

## Eine Runde

Alle würfeln der Reihe nach, jeder einmal. Wer dran ist, hat **bis zu drei Würfe**.

1. Du wirfst alle drei Würfel.
2. Gefällt dir das Ergebnis, tippst du **„Stehen lassen“**. Dein Zug ist zu Ende.
3. Sonst tippst du **„Weiter würfeln“**. Vorher darfst du Würfel herauslegen (siehe unten). Die herausgelegten bleiben liegen und zählen am Ende mit. Die anderen wirfst du neu.
4. Nach dem letzten erlaubten Wurf ist dein Zug automatisch zu Ende.

**Der Vorleger bestimmt die Würfe.** Wer die Runde beginnt, ist der Vorleger. So viele Würfe er braucht, so viele dürfen alle anderen höchstens machen. Lässt er nach dem ersten Wurf stehen, haben alle anderen auch nur einen Wurf.

Haben alle gewürfelt, vergleicht die App die Würfe. Der schlechteste verliert die Runde.

## Herauslegen

Nach einem Wurf darfst du Würfel beiseitelegen und nur die übrigen neu werfen.

- Im Standard („Nur Einsen“) darfst du **nur Einsen** herauslegen.
- Mit der Hausregel „Beliebig“ darfst du jeden Würfel herauslegen.
- Du musst nichts herauslegen. Dann wirfst du alle drei neu.
- Mindestens **ein Würfel** muss immer neu geworfen werden.

Tippe einen Würfel an, um ihn herauszulegen. Er wandert dann von „Im Becher“ nach „Draußen“.

## Sechsen umdrehen

Hast du **zwei Sechsen** geworfen, darfst du eine davon zur Eins umdrehen. Bei **drei Sechsen** darfst du bis zu zwei umdrehen. Eine einzelne Sechs darfst du nicht umdrehen.

Die umgedrehten Würfel liegen dann als Einsen draußen, die übrigen wirfst du neu. Dafür gibt es den Knopf **„Sechsen umdrehen“**. Er zeigt, wie viele du umdrehst, zum Beispiel „1 von 2“. Tippst du ihn noch einmal an, ändert sich die Zahl.

Mit der Hausregel „Sechsen umdrehen: aus“ geht das nicht.

## Die Würfe vom besten zum schlechtesten

@form C
| Wurf | Beispiel | Deckel | Was gilt |
|---|---|---|---|
|**Schock aus** | 1-1-1 | alle | Der Verlierer bekommt sofort alle Deckel (siehe unten). |
|**Jule** | 4-2-1 | 7 | Nur mit der Hausregel „Jule“. Sonst ist 4-2-1 eine Zahl. |
|**Schock** | 1-1-6 bis 1-1-2 | so viele wie der dritte Würfel | Zwei Einsen und eine andere Zahl. Schock 6 ist der beste, Schock 2 der schwächste. |
|**General** | 6-6-6 bis 2-2-2 | 3 | Drei gleiche Zahlen (außer drei Einsen). |
|**Straße** | 4-5-6, 3-4-5, 2-3-4, 1-2-3 | 2 | Drei Zahlen hintereinander. |
|**Zahl** | 6-5-3 | 1 | Alles andere. Die Würfel werden von groß nach klein gelesen: 6-5-3 ist „653“. |

**Wichtig bei General und Straße:** Sie zählen nur, wenn **alle drei Würfel im selben Wurf** gefallen sind. Hast du vorher etwas herausgelegt, ist es nur eine Zahl. Beispiel: Du legst eine Eins heraus und wirfst dann 2 und 3. Das ist keine Straße, sondern die Zahl 321.

Beim **Schock** ist es egal, wie die Einsen zustande kamen. Herausgelegte und umgedrehte Einsen zählen mit.

**Innerhalb einer Art** gewinnt der höhere Wurf: General 6 schlägt General 5, Straße 4-5-6 schlägt Straße 1-2-3, die Zahl 653 schlägt 643.

**Gleicher Wurf:** Wer weniger Würfe gebraucht hat, ist besser. Ist auch das gleich, ist besser, wer früher in der Runde dran war.

## Deckel verteilen

Der Verlierer der Runde bekommt so viele Deckel, wie der **beste** Wurf der Runde wert ist. Hat der Beste einen General geworfen, bekommt der Schlechteste 3 Deckel.

**Erste Phase, solange Deckel im Stock liegen:** Der Verlierer nimmt die Deckel aus dem Stock. Liegen dort weniger, nimmt er nur den Rest.

**Zweite Phase, wenn der Stock leer ist:** Jetzt gibt der Gewinner der Runde seine Deckel an den Verlierer ab. Er gibt höchstens so viele, wie er selbst hat.

**Ausscheiden:** Ist der Stock leer und hat jemand nach einer Runde keine Deckel, ist er für den Rest dieser Hälfte raus. Er hat die Hälfte sicher nicht verloren.

Die Hälfte endet, wenn **einer alle Deckel** hat (13 oder 15). Er hat diese Hälfte verloren.

## Schock aus

Drei Einsen sind der beste Wurf. Im Standard gilt: Wer in dieser Runde verliert, bekommt **sofort alle Deckel**, auch die, die andere schon haben. Die Hälfte ist damit zu Ende, er hat sie verloren.

Mit der Hausregel „Schock aus beendet die Hälfte: aus“ zählt Schock aus wie ein Wurf mit 13 Deckeln (bzw. 15). Dann wird ganz normal verteilt, erst aus dem Stock, dann vom Gewinner, und die Hälfte geht weiter.

## Hälften und Finale

Eine Partie hat zwei Hälften und vielleicht ein Finale.

1. **Hälfte 1:** Alle spielen, bis einer alle Deckel hat.
2. **Hälfte 2:** Wieder alle, mit vollem Stock.
3. Hat **dieselbe Person beide Hälften** verloren, hat sie die Partie verloren. Es gibt kein Finale.
4. Sonst spielen die **beiden Verlierer der Hälften** ein **Finale** gegeneinander, nur die zwei. Wer das Finale verliert, verliert die Partie.

Mit der Hausregel „Nur eine Hälfte“ ist nach der ersten Hälfte Schluss. Wer sie verliert, verliert die Partie.

**Ergebnis:** Wer die Partie verloren hat, steht ganz unten. Alle anderen stehen nach der Zahl ihrer verlorenen Hälften, weniger ist besser. Bei gleicher Zahl teilen sie sich den Platz.

## Hausregeln

Unter „Mehr“ → „Hausregeln ändern“ stellst du ein, wie ihr spielt. Das geht nur, solange in der Partie noch nicht gewürfelt wurde. Die App merkt sich die Einstellung für die nächsten Partien.

@form B
| Hausregel | Standard | Auswahl |
|---|---|---|
|Herauslegen | Nur Einsen | Nur Einsen oder Beliebig |
|Sechsen umdrehen | an | an oder aus |
|Jule 4-2-1 | aus | an oder aus |
|Deckel | 13 | 13 oder 15 |
|Spiellänge | Partie mit Finale | Partie mit Finale oder Nur eine Hälfte |
|Schock aus beendet die Hälfte | an | an oder aus |

**Vorlagen:** „Kneipe“ ist streng: nur Einsen herauslegen, Jule an. „Familie“ ist locker: Jule aus, beliebige Würfel herauslegen. „Auf Standard zurücksetzen“ stellt alles wieder auf den Anfang.

## Gegen den Computer

Der Computer würfelt von selbst, mit einer kleinen Pause. Mit „Überspringen“ geht es schneller.

- **Leicht:** spielt einfach. Als Vorleger bleibt er ab der Zahl 650 stehen, sonst sobald er den bisher schlechtesten Wurf schlägt.
- **Mittel** (Standard): spielt etwa jeden zweiten Zug gut, sonst wie Leicht.
- **Schwer:** rechnet jedes Mal aus, ob Stehen oder Weiterwürfeln besser ist.

## Mit echten Würfeln

Ihr könnt am Tisch mit echten Würfeln spielen und die App zählt mit. Für jeden Spieler lässt sich einstellen, ob er echt oder in der App würfelt.

- **Schnelleingabe:** Du tippst nur das Endergebnis und die Zahl der Würfe ein. Bei Straße und General fragt die App, ob alle drei Würfel in einem Wurf gefallen sind.
- **Wurf für Wurf:** Du tippst jeden Wurf einzeln ein.

Mit „Ändern“ korrigierst du eine Eingabe.

## So bedienst du das Spiel

- **Würfeln:** startet deinen Zug.
- **Würfel antippen:** legt ihn heraus oder holt ihn zurück in den Becher.
- **Stehen lassen / Weiter würfeln:** nach jedem Wurf.
- **Sechsen umdrehen:** erscheint nur, wenn du zwei oder drei Sechsen hast.
- **Tipp:** Die Glühbirne zeigt dir, ob Stehen oder Weiterwürfeln besser ist. Nur, wenn die Hilfen eingeschaltet sind.
- **Weiter:** zum nächsten Spieler oder zur nächsten Runde.
- **Oben** steht, welche Hälfte und welche Runde läuft, zum Beispiel „Hälfte 1 · Runde 3“. Darunter siehst du jeden Spieler mit seinen Deckeln.
- **Verlauf:** Tippe auf die Spielerleiste oder wähle „Mehr“ → „Verlauf“. Dort steht Runde für Runde, wer was geworfen hat und wohin die Deckel gingen.
- **Euer Abend:** Statistik über mehrere Partien an einem Abend. Ab der zweiten Partie gibt es Auszeichnungen wie Schock-König, Pechvogel und Glückspilz.
- **Geführte Partie:** eine Hälfte mit Erklärungen zu jedem Schritt, gut zum Lernen.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

Einen Zug zurücknehmen kannst du bei Schocken nicht.

## Beispiel einer Runde

Anna ist Vorleger. Sie wirft 6-6-2. Sie dreht eine Sechs zur Eins um und wirft die anderen zwei neu: 1 und 4. Jetzt hat sie 1-1-4, einen **Schock 4**. Sie lässt nach zwei Würfen stehen.

Ben darf jetzt auch nur zweimal werfen. Er wirft 5-5-5, einen **General**. Ein General ist schwächer als ein Schock, also wirft er noch einmal alle drei: 6-4-2. Das ist nur die Zahl 642, und er hat keinen Wurf mehr.

Clara wirft 3-4-5, eine **Straße**, und lässt stehen.

Bester Wurf ist Annas Schock 4. Schlechtester ist Bens 642. Ben bekommt **4 Deckel**.

## Kleine Tipps für den Anfang

- Als Vorleger: Ein guter Wurf im ersten Versuch zwingt alle anderen, mit nur einem Wurf auszukommen.
- Einsen sind Gold. Mit zwei Einsen hast du schon einen Schock sicher.
- Du musst nicht den Besten schlagen. Es reicht, nicht der Schlechteste zu sein. Liegt schon ein schwacher Wurf vor, lass ruhig früher stehen.
- Im zweiten Teil einer Hälfte (Stock leer) kannst du durch einen guten Wurf Deckel loswerden.

## Begriffe

- **Deckel:** Strafmarke. Wer alle hat, verliert die Hälfte.
- **Stock:** Vorrat an Deckeln in der Mitte.
- **Vorleger:** wer die Runde beginnt. Er legt die Zahl der Würfe fest.
- **Herauslegen:** einen Würfel beiseitelegen, der nicht neu geworfen wird.
- **Schock:** zwei Einsen und eine andere Zahl.
- **Schock aus:** drei Einsen.
- **General:** drei gleiche Zahlen.
- **Jule:** 4-2-1, nur mit Hausregel.
- **Hälfte / Finale:** die Abschnitte einer Partie.
"""#
}
