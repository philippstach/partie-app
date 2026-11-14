// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/10k/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_10k {
    static let quelle = #"""
## Worum es geht

10k (Zehntausend) ist ein Würfelspiel, bei dem du dein Glück herausforderst. Du würfelst, legst Punkte-Würfel raus und entscheidest: aufhören und die Punkte sichern oder weiterwürfeln und mehr holen? Wer zu gierig ist, verliert mit einer **Niete** alles aus diesem Zug. Wer zuerst **10.000 Punkte** hat, gewinnt.

## Was du brauchst

- **Spieler:** 1 bis 8, jeder Platz Mensch oder Computer.
- **Würfel:** 5 (mit der Variante „6 Würfel“ sechs). Die App würfelt, oder ihr würfelt mit echten Würfeln und tippt das Ergebnis ein.

## Was Punkte bringt

| Würfel | Punkte |
|---|---|
|eine 1 | 100 |
|eine 5 | 50 |
|drei Einsen | 1.000 |
|drei gleiche andere | Augenzahl × 100 (drei Vieren = 400, drei Zweien = 200) |
|Straße 1-2-3-4-5 oder 2-3-4-5-6 | 1.000 |

Zweien, Dreien, Vieren und Sechsen bringen einzeln nichts.

**Vier oder fünf gleiche:** Es zählt der Drilling. Weitere Würfel zählen nur, wenn es Einsen oder Fünfen sind. Vier Vieren sind also nur 400, vier Einsen 1.000 + 100 = 1.100.

**Wichtig:** Gewertet wird nur, was **in einem Wurf** fällt. Einen Drilling oder eine Straße kannst du nicht über mehrere Würfe zusammensammeln. Eine Straße zählt nur, wenn alle Würfel gleichzeitig geworfen wurden.

## Dein Zug

1. Wirf alle Würfel.
2. Lege **mindestens einen** Würfel mit Punkten raus. Mehr darfst du, musst du aber nicht.
3. Entscheide:
   - **Aufhören:** Die Punkte dieses Zugs kommen auf dein Konto. Der Knopf zeigt sie an, zum Beispiel „Aufhören +500“.
   - **Weiterwürfeln:** Du wirfst die übrigen Würfel noch einmal.
4. Das geht so lange, bis du aufhörst oder eine Niete wirfst.

**Niete:** Bringt ein Wurf keinen einzigen Punkt, ist dein Zug vorbei, und **alle Punkte dieses Zugs sind weg**.

**Alle Würfel punkten:** Hast du alle Würfel rausgelegt, darfst du mit allen wieder neu würfeln. Die Punkte bleiben.

*Beispiel:* Du wirfst 1-5-3-3-6. Du legst die 1 raus (100) und würfelst mit vier Würfeln weiter: 4-4-4-2. Drei Vieren, 400. Du hast jetzt 500 in diesem Zug und noch einen Würfel. Hörst du auf, bekommst du 500. Würfelst du weiter und es kommt keine 1 oder 5, ist alles weg.

## Übernehmen

Hört jemand auf und lässt Würfel offen, darf die **nächste Person** diese Würfel samt Punkten übernehmen und weiterwürfeln. Sie kann auch ablehnen und neu anfangen.

- Hat der Vorgänger alle Würfel rausgelegt, übernimmst du mit allen Würfeln (abschaltbar).
- Beim ersten Wurf nach einer Übernahme zählt keine Straße.
- Wirfst du dabei eine Niete, sind die übernommenen Punkte auch weg.

## Strafe

Wer **3 Nieten hintereinander** hat, bekommt **500 Punkte abgezogen**. Danach zählt es von vorn. Der Punktestand kann dadurch unter 0 fallen.

## Wer gewinnt

Wer zuerst **10.000 Punkte** erreicht, gewinnt sofort. Geprüft wird am Ende jedes Zugs.

Mit einem Rundenlimit oder der fairen Schlussrunde gewinnt am Ende, wer vorne liegt. Bei Gleichstand gibt es ein **Stechen**: Jeder der Gleichauf-Liegenden hat noch einen Zug, und nur die Punkte dieses Zugs zählen. Im Stechen gibt es keine Strafe und keine Einstiegshürde. Ist es wieder gleich, folgt ein weiteres Stechen.

Allein spielst du gegen deine eigenen Rekorde.

## Regeln dieser Partie

Wie ihr spielt, stellst du **vor dem Start auf der Spielseite** ein, in der Karte „Regeln der Partie“ (dort auch „Eigene Regeln …“). Die App merkt sich die Wahl für die nächste Partie. Während der Partie lassen sich die Regeln nicht mehr ändern; unter „Mehr“ → „Regeln dieser Partie“ kannst du sie nur nachlesen.

**Vorlagen:**
- **Standard:** 10.000 Punkte, alle Drillinge zählen, Strafe 500.
- **Kurzes Spiel – 5.000:** Ziel 5.000, sonst wie Standard.
- **Nur Einsen und Fünfen:** Nur drei Einsen und drei Fünfen zählen als Drilling, je 500.
- **6 Würfel:** mit sechs Würfeln und 5er-Straße, sonst wie Standard.

**Einzelne Regeln:**

@form B
| Regel | Standard | Auswahl |
|---|---|---|
|Zielpunkte | 10.000 | 1.000 bis 50.000 |
|Rundenlimit | keins | bis 50 Runden; danach gewinnt, wer vorne liegt |
|Stechen bei Gleichstand | an | nur mit Rundenlimit oder fairer Schlussrunde |
|Strafe bei 3 Nieten | 500 | 0 bis 2.000 |
|Drillinge | alle | alle oder nur Einsen und Fünfen |
|Übernahme mit allen Würfeln | an | an oder aus |
|Faire Schlussrunde | aus | an: Erreicht jemand das Ziel, spielen die anderen die Runde zu Ende |
|Einstiegshürde | aus | ab 350, 500 oder 1.000 |
|Vier bis sechs Gleiche | Drilling plus Einzelne | verdoppelt sich oder feste Werte |
|Würfel | 5 | 5 oder 6 |
|Straße mit 6 Würfeln | 5er-Straße (1.000) | oder große Straße 1–6 (1.500) |
|Drei Paare | aus | 1.500, nur mit 6 Würfeln |

**Was die Varianten bedeuten:**
- **Einstiegshürde:** Wer noch keine Punkte hat, darf erst aufhören, wenn der Zug mindestens so viel bringt.
- **Drilling verdoppelt sich:** Jeder weitere gleiche Würfel verdoppelt. Vier Vieren = 800, fünf Vieren = 1.600.
- **Feste Werte:** Vier gleiche = 1.000, fünf = 2.000, sechs = 3.000.
- **6 Würfel, 5er-Straße:** Straße 1–5 oder 2–6 = 1.000, der sechste Würfel zählt als 1 oder 5 dazu (1-2-3-4-5-5 = 1.050). Zwei Drillinge in einem Wurf zählen beide (2-2-2-4-4-4 = 600).
- **Große Straße 1–6:** nur mit allen sechs in einem Wurf, 1.500.
- **Drei Paare:** drei verschiedene Paare im Wurf mit allen 6 Würfeln, 1.500.
- **Faire Schlussrunde:** Wer das Ziel erreicht, gewinnt nicht sofort. Die anderen spielen die Runde zu Ende, dann gewinnt, wer vorne liegt.
- **Stechen:** Liegen am Ende mehrere gleichauf, hat jeder von ihnen noch einen Zug. Wer dabei mehr holt, gewinnt. Ohne Stechen gewinnen sie gemeinsam.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“, sie gilt ab der nächsten Partie.

- **Leicht:** hört ab 350 Punkten im Zug auf (bei nur noch ein oder zwei Würfeln schon ab 200).
- **Schwer:** rechnet bei jedem Wurf aus, ob Aufhören oder Weiterwürfeln mehr bringt.
- **Mittel:** mischt beides: mal spielt er wie Leicht, mal wie Schwer.

Spielt ein Computer mit, würfelt immer die App; echte Würfel gibt es dann nicht.

## Mit echten Würfeln

Auf der Spielseite wählst du „Würfel: Virtuell“ oder „Echt“. Mit echten Würfeln gibt es zwei Eingabearten (unter „Mehr“ → „Eingabe“, nur zwischen zwei Zügen umstellbar):

- **Würfel eintippen:** Du tippst die Augen der rausgelegten Würfel ein, die App rechnet. Danach „Weiterwürfeln mit n Würfeln“, „Aufhören +Punkte“ oder „Niete“.
- **Punkte eintippen:** Du tippst nur die Punkte des Zugs ein (Kacheln von 50 bis 1.000, die App zählt zusammen), oder „Niete“. Auch hier bekommt die nächste Person die Punkte zum Übernehmen angeboten, ohne Würfel.

## So bedienst du das Spiel

- Tippe die Würfel an, die du rauslegen willst. Die App zeigt, wie viele Punkte sie bringen.
- Unten stehen zwei Knöpfe: „Weiter (n)“ würfelt mit den übrigen Würfeln, „Aufhören +Punkte“ sichert den Zug. Hast du alle Würfel rausgelegt, heißt der linke Knopf „Alle 5 nochmal“.
- Unter „Mehr“ gibt es zwei Hilfen: „Punkte-Würfel vorauswählen“ (an) markiert nach dem Wurf die Würfel mit Punkten, „Tipp: beste Auswahl“ (aus) zeigt die Auswahl mit den meisten Punkten.
- **Rückgängig** nimmt bis zu 50 Schritte zurück: abgeschlossene Züge, Übernahme-Entscheidungen und eingetippte Würfe. Einen neuen Wurf der App nimmt es nicht zurück, sonst wäre es neu würfeln.
- Tippe auf die Spielerleiste für Punktestand und Verlauf, auf eine Person für ihre Werte. Die **Bestenliste** findest du auf der Spielseite.
- **Tisch-Modus** (nur iPad, 2 bis 4 Menschen am Gerät): Schalter auf der Spielseite. Jede Person bekommt am Rand ein zu ihr gedrehtes Namensschild, das Schild der Person am Zug leuchtet. Das Spiel selbst bleibt gleich.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps

- Mit nur einem oder zwei Würfeln ist eine Niete wahrscheinlich. Hör lieber auf.
- Mit allen fünf Würfeln ist eine Niete selten. Weiterwürfeln lohnt sich.
- Ein Angebot zum Übernehmen lohnt sich, wenn viele Punkte und mindestens drei Würfel offen sind.

## Begriffe

- **Rauslegen:** Punkte-Würfel beiseitelegen.
- **Aufhören:** die Punkte des Zugs sichern.
- **Niete:** ein Wurf ohne Punkte; der Zug ist verloren.
- **Übernehmen:** die offenen Würfel und Punkte des Vorgängers weiterspielen.
- **Drilling:** drei gleiche Würfel.
"""#
}
