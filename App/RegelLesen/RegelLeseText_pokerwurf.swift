// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/pokerwurf/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_pokerwurf {
    static let quelle = #"""
## Worum es geht

Pokerwurf ist Poker mit Würfeln. Statt Karten hast du 5 Würfel und versuchst, daraus eine möglichst starke Hand zu würfeln: ein Paar, einen Drilling, eine Straße oder sogar fünf gleiche Würfel.

Jede Person hat pro Runde bis zu drei Würfe. Danach wird verglichen: Die beste Hand bekommt einen Punkt. Nach fünf Runden gewinnt, wer die meisten Punkte hat.

Ein schnelles Spiel mit Glück und ein bisschen Taktik: Welche Würfel hältst du fest, und wann hörst du auf?

## Was du brauchst

- **Spieler:** 2 bis 4. Jeder Platz kann ein Mensch oder der Computer sein.
- **Würfel:** 5 Würfel. Im Blatt „Neues Spiel“ wählst du unter „Würfel“: **Virtuell** (die App würfelt) oder **Echt** (ihr würfelt mit echten Würfeln und tippt die Augen ein).
- **Runden:** immer 5.

## Reihenfolge

In jeder Runde würfelt jede Person einmal, der Reihe nach wie in der Spielerliste. Wer beginnt, wählst du vor dem Start: „Reihum“ (Standard, jede neue Partie beginnt die nächste Person) oder eine feste Person. Innerhalb der Partie beginnt außerdem jede Runde die nächste Person.

## So läuft dein Zug

1. Tippe auf **„Würfeln“**. Beim ersten Wurf rollen alle 5 Würfel.
2. Schau dir an, was du hast. Tippe die Würfel an, die du **behalten** willst. Sie werden markiert. Nochmal antippen gibt sie wieder frei. Ab Build 25 bleiben gehaltene Würfel auch für den nächsten Wurf markiert, du musst sie nicht neu antippen (Schalter „Gehaltene Würfel bleiben liegen“ in den Einstellungen, Standard an).
3. Tippe wieder auf „Würfeln“. Jetzt rollen nur die Würfel, die du nicht hältst.
4. Das geht bis zu dreimal. Der Knopf zeigt, wie viele Würfe übrig sind, zum Beispiel „Würfeln (2 übrig)“.
5. Bist du zufrieden, tippst du auf **„Behalten“**. Das geht nach jedem Wurf, auch schon nach dem ersten. Nach dem dritten Wurf musst du behalten.

Bei virtuellen Würfeln kannst du statt zu tippen auch das Gerät schütteln.

## Die Hände

Von schwach nach stark:

@form C
| Hand | Was du brauchst | Beispiel |
|---|---|---|
|Nichts | keine gleichen Würfel, keine Straße | 6-5-3-2-1 |
|Ein Paar | 2 gleiche | 4-4-1-2-6 |
|Zwei Paare | 2 gleiche und noch 2 gleiche | 5-5-2-2-6 |
|Drilling | 3 gleiche | 3-3-3-1-6 |
|Kleine Straße | genau 1-2-3-4-5 | 1-2-3-4-5 |
|Große Straße | genau 2-3-4-5-6 | 2-3-4-5-6 |
|Full House | 3 gleiche und 2 gleiche | 4-4-4-2-2 |
|Vierling | 4 gleiche | 6-6-6-6-1 |
|Fünfling | 5 gleiche | 5-5-5-5-5 |

Wichtig: Es gibt nur diese zwei Straßen. 3-4-5-6 und dazu eine 1 oder eine weitere Zahl ist keine Straße.

Die App zeigt dir nach jedem Wurf, welche Hand du gerade hast.

## Gleiche Hand: wer gewinnt?

Haben zwei die gleiche Art von Hand, entscheiden die Augen:

- **Paar, Drilling, Vierling, Fünfling:** Die höheren gleichen Würfel gewinnen. Sind die auch gleich, zählen die übrigen Würfel, der höchste zuerst.
- **Full House:** zuerst der Drilling, dann das Paar.
- **Zwei Paare:** zuerst das höhere Paar, dann das niedrigere, dann der einzelne Würfel.
- **Nichts:** alle 5 Würfel, vom höchsten abwärts.
- **Straßen:** Zwei gleiche Straßen sind gleich gut.

*Beispiele:*
- 4-4-4-1-1 schlägt 3-3-3-5-5 (Drilling aus Vieren gegen Drilling aus Dreien).
- 6-6-5-1-2 schlägt 6-6-4-3-2 (beide ein Sechser-Paar, dann 5 gegen 4).
- 5-5-3-3-1 schlägt 5-5-2-2-6 (zweites Paar 3 gegen 2).

## Wertung der Runde

Hat die letzte Person „Behalten“ getippt, vergleicht die App alle Hände. Die beste Hand bekommt **1 Punkt**.

Sind mehrere Hände genau gleich gut, bekommen alle Besten je 1 Punkt. Die App meldet dann „Unentschieden in dieser Runde“. Sonst steht da zum Beispiel „Anna gewinnt die Runde“.

Danach geht es mit „Nächste Runde“ weiter.

## Wer gewinnt

Nach der 5. Runde tippst du auf „Ergebnis“. Es gewinnt, wer die meisten Punkte hat. Mehr als 5 Punkte sind nicht möglich. Bei gleichen Punkten teilen sich die Personen den Platz.

## Mit echten Würfeln

Hast du „Echt“ gewählt, würfelst du mit deinen eigenen Würfeln. Vor jedem Wurf öffnet sich ein Feld: Tippe dort die Augen der Würfel ein, die du gerade neu geworfen hast. Beim ersten Wurf sind das alle 5, danach nur die, die du nicht hältst. Hältst du alle, kommt keine Eingabe. Der Computer würfelt immer selbst.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“ → „Stärke des Computers“:

- **Leicht:** hält oft einfach zufällig Würfel fest (etwa jeden zweiten Zug).
- **Mittel** (Standard): spielt meistens vernünftig.
- **Schwer:** spielt immer nach seinem besten Plan.

Der Computer hält Paare, Drillinge, fertige Straßen und Full Houses fest und sucht vier aufeinanderfolgende Zahlen für eine Straße. Ist er als Letzter dran und liegt schon vorn (mit mindestens einem Drilling), hört er ab „Mittel“ früher auf.

## Hilfen in der App

- **Zug zurück:** nimmt deine letzte Auswahl der gehaltenen Würfel oder dein „Behalten“ zurück. Einen Wurf kann man nie zurücknehmen.
- **Rangfolge:** Im Aussehen „Tinte“ zeigt eine Tafel die Hände von stark nach schwach, deine aktuelle Hand ist hervorgehoben.
- **Spielerleiste:** zeigt die Punkte und die Hand jeder Person in dieser Runde.
- **So fielen die Würfel:** Am Ende zeigt die Ergebnisseite, wie oft welche Zahl gefallen ist.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Halte nach dem ersten Wurf deine gleichen Würfel fest und würfle den Rest neu.
- Hast du vier aufeinanderfolgende Zahlen wie 2-3-4-5, fehlt dir nur eine 1 oder 6 für eine Straße.
- Bist du als Letzter dran, siehst du die Hände der anderen. Liegst du schon vorn, kannst du einfach „Behalten“ tippen.

## Was hier anders ist als anderswo

Pokerwurf wird oft mit Ansagen, Einsätzen oder Bluffen gespielt. In der App nicht: Alle würfeln offen, jeder hat drei Würfe, und die beste Hand der Runde bekommt einen Punkt. Es gibt keine Joker.

## Begriffe

- **Hand:** die fünf Würfel am Ende deines Zugs.
- **Halten / Behalten:** Würfel festhalten (nicht neu werfen) / den Zug beenden.
- **Pasch:** mehrere Würfel mit derselben Zahl.
- **Straße:** fünf aufeinanderfolgende Zahlen.
"""#
}
