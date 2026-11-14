// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/maumau/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_maumau {
    static let quelle = #"""
## Worum es geht

Mau-Mau ist eines der bekanntesten Kartenspiele in Deutschland. Alle haben ein paar Karten auf der Hand und legen sie reihum auf einen gemeinsamen Ablagestapel. Wer als Erste oder Erster keine Karten mehr hat, gewinnt.

Klingt einfach, und das ist es auch. Spannend wird es durch die Sonderkarten: Mit einer 7 lässt du die nächste Person Karten ziehen, mit einer 8 lässt du sie aussetzen, und mit einem Buben bestimmst du, welche Farbe als Nächstes gelegt werden muss.

## Was du brauchst

- **Spieler:** 2 bis 6 Personen. Mitspielen können Menschen und der Computer, auch gemischt.
- **Karten:** ein Skatblatt mit 32 Karten. Es gibt vier Farben: Kreuz ♣, Pik ♠, Herz ♥ und Karo ♦. Jede Farbe hat die Werte 7, 8, 9, 10, Bube, Dame, König und Ass.
- **Ab 5 Personen** spielt die App mit zwei Blättern, also mit 64 Karten. Dann gibt es jede Karte zweimal.

## Vorbereitung

Die App mischt und teilt aus. Jede Person bekommt 5 Karten. Unter „Hausregeln“ kannst du stattdessen 6 oder 7 Karten einstellen.

Eine Karte wird offen hingelegt. Das ist die **Ablage**. Die übrigen Karten liegen verdeckt daneben. Das ist der **Stapel**, von dem gezogen wird.

Die erste Karte auf der Ablage ist nie eine Sonderkarte: kein Bube, keine 7, keine 8 und nicht die Karte, die aussetzen lässt (zum Beispiel das Ass, wenn du „Mit dem Ass“ gewählt hast). Ist „9 wechselt die Richtung“ an, ist sie auch keine 9.

**Wer beginnt:** Wer beginnt, wählst du vor dem Start: „Reihum“ (Standard, jede neue Partie beginnt die nächste Person) oder eine feste Person. Spielt ihr mehrere Runden mit Punkten, beginnt jede neue Runde die nächste Person.

## So läuft dein Zug

Gespielt wird reihum. Wenn du dran bist, hast du zwei Möglichkeiten:

1. **Eine Karte legen.** Sie muss zur obersten Karte der Ablage passen: gleiche **Farbe** oder gleicher **Wert**.
   *Beispiel:* Oben liegt Herz 9. Du darfst jede Herz-Karte legen (Herz 7, Herz König …) oder jede andere 9 (Pik 9, Kreuz 9 …). Einen Buben darfst du fast immer legen (siehe „Der Bube“).
2. **Eine Karte ziehen.** Du nimmst genau 1 Karte vom Stapel. Danach ist die nächste Person dran.

Du darfst auch ziehen, wenn du eine passende Karte hättest. Manchmal ist es klug, eine gute Karte aufzuheben.

Du legst immer nur eine Karte pro Zug.

## Die 7: Ziehen lassen

Legst du eine 7, muss die nächste Person **2 Karten ziehen**.

Hat sie selbst eine 7, darf sie diese drauflegen. Dann muss die Person danach **4 Karten** ziehen. Mit jeder weiteren 7 kommen 2 Karten dazu: 6, 8 und so weiter. Die Farbe der 7 ist dabei egal.

Solange gezogen werden muss, darfst du **nur eine 7** legen, sonst nichts, auch keinen Buben. Wer keine 7 hat (oder keine legen will), tippt auf „2 Karten ziehen“ (oder „4 Karten ziehen“ …), nimmt alle Karten auf einmal und ist danach nicht mehr dran.

## Die 8: Aussetzen

Legst du eine 8, muss die nächste Person **aussetzen**. Sie legt nichts und zieht nichts.

Hat sie selbst eine 8, kann sie diese drauflegen und das Aussetzen weitergeben. Dann setzt die Person danach aus. Die Farbe der 8 ist dabei egal. Sonst tippt sie auf „Aussetzen“.

Zu zweit bedeutet das: Nach deiner 8 bist du gleich noch einmal dran.

Unter „Hausregeln“ kannst du statt der 8 **das Ass** aussetzen lassen. Dann ist die 8 eine ganz normale Karte. Oder du wählst „Niemand setzt aus“.

## Der Bube: Farbe wünschen

Der Bube passt auf fast jede Karte, egal welche Farbe oben liegt. Wenn du ihn legst, **wünschst du dir eine Farbe**. Dafür erscheint eine Leiste mit den vier Farben.

Danach muss die nächste Person eine Karte in der gewünschten Farbe legen. Der Wert zählt dann nicht mehr. Stattdessen darf sie auch wieder einen Buben legen und sich selbst eine Farbe wünschen.

Ausnahmen:
- Muss gerade jemand wegen einer 7 ziehen oder wegen einer 8 aussetzen, hilft der Bube nicht.
- Mit der Hausregel „Bube auf Bube erlaubt“ aus darf kein Bube auf einen Buben.
- Mit der Hausregel „Bube darf die letzte Karte sein“ aus kannst du mit einem Buben nicht gewinnen.

## Wenn der Stapel leer ist

Ist der Stapel aufgebraucht, nimmt die App alle Karten der Ablage außer der obersten, mischt sie und legt sie als neuen Stapel hin. Das Spiel geht einfach weiter.

## Wer gewinnt

Wer die letzte Karte ablegt, gewinnt sofort. Das gilt auch, wenn die letzte Karte eine 7 oder 8 ist.

Im Standard ist damit die Partie zu Ende. Die anderen werden danach sortiert, wie viele Karten sie noch auf der Hand haben: Wer weniger hat, steht weiter vorn.

## Mehrere Runden mit Punkten

Mit der Hausregel „Mehrere Runden mit Punkten“ wird über mehrere Runden gespielt.

Am Ende jeder Runde bekommt die Siegerin oder der Sieger **0 Punkte**. Alle anderen zählen die **Augen** ihrer Restkarten:

| Karte | Augen |
|---|---|
|Bube | 20 |
|Ass | 11 |
|Dame, König | je 10 |
|7, 8, 9, 10 | so viel, wie draufsteht |

*Beispiel:* Du hast noch Bube, Ass und 9. Das sind 20 + 11 + 9 = 40 Punkte.

Die Punkte werden über die Runden zusammengezählt. Sobald jemand die Zielsumme erreicht oder überschreitet, ist die Partie zu Ende. Die Zielsumme stellst du unter „Spielende bei“ ein: 50, 100 oder 150 Punkte (Standard 100).

**Gewonnen hat, wer am Ende die wenigsten Punkte hat.** Wer die Zielsumme zuerst erreicht, verliert also meistens. Haben zwei oder mehr gleich wenige Punkte, nennt die App keinen Sieger; die Partie endet unentschieden.

*Beispiel:* Ziel ist 100. Du hast 85 Punkte und bekommst in dieser Runde 20 dazu. Jetzt hast du 105, die Partie ist vorbei.

## Hausregeln

Bei Mau-Mau spielt fast jede Familie etwas anders. Darum kannst du die Regeln selbst zusammenstellen. Jeder Schalter wirkt für sich.

@form B
| Hausregel | Standard | Was sie macht |
|---|---|---|
|Karten auf der Hand | 5 | 5, 6 oder 7 Karten zu Beginn |
|7 lässt ziehen (stapelbar) | an | aus: Die 7 ist eine normale Karte. |
|Aussetzen | Mit der 8 | „Mit dem Ass“: das Ass lässt aussetzen, die 8 ist normal. „Niemand setzt aus“: keine Karte lässt aussetzen. |
|Bube darf die letzte Karte sein | an | aus: Mit einem Buben kannst du nicht gewinnen. |
|Bube auf Bube erlaubt | an | aus: Auf einen Buben darf kein Bube. |
|9 wechselt die Richtung (ab drei Personen) | aus | an: Eine 9 dreht die Spielrichtung um. Zu zweit hat das keine Wirkung. |
|„Mau“ sagen (sonst Strafkarte) | aus | an: Wer die vorletzte Karte legt, muss vorher „Mau sagen“ antippen. Sonst zieht er sofort 1 Strafkarte. |
|Gezogene Karte gleich legen | aus | an: Passt die eine gezogene Karte, darfst du sie sofort legen oder „Weitergeben“ tippen. Gilt nicht, wenn du wegen einer 7 ziehen musstest. |
|Mehrere Runden mit Punkten | aus | an: Wertung über mehrere Runden (siehe oben). |
|Spielende bei | 100 | nur mit mehreren Runden: 50, 100 oder 150 Punkte |

**Wo?** Vor dem Start im Blatt „Neues Spiel“ unter „Hausregeln“. In der laufenden Partie über „Mehr“ → „Hausregeln“.

**Wann?** Nur vor dem ersten Zug. Änderst du dann etwas, teilt die App neu aus. Danach sind die Regeln für diese Partie fest. Bei mehreren Runden gilt das nur für die erste Runde.

Die App merkt sich deine Hausregeln für die nächsten Partien.

## Schnellwahl

Oben im Blatt „Hausregeln“ gibt es fertige Zusammenstellungen:

- **Standard (7 zieht, 8 setzt aus):** die Grundregeln wie oben beschrieben.
- **Ass setzt aus:** wie Standard, aber das Ass lässt aussetzen statt der 8.
- **Sieben Karten auf die Hand:** wie Standard, aber mit 7 Karten.
- **Schlicht (ohne 7 und 8):** Die 7 lässt nicht ziehen, niemand setzt aus. Gut für Kinder.
- **Streng (Bube nicht zuletzt):** Der Bube darf nicht die letzte Karte sein und nicht auf einen Buben.
- **Wild (9 dreht, Mau, sofort legen):** 9 wechselt die Richtung, „Mau“ sagen ist Pflicht, gezogene Karte gleich legen.

Eine Schnellwahl stellt alle Schalter neu ein. Nur „Mehrere Runden mit Punkten“ und „Spielende bei“ bleiben, wie sie waren. Danach kannst du jeden Schalter noch einzeln ändern.

## „Mau“ sagen

Diese Regel gilt nur, wenn „„Mau“ sagen (sonst Strafkarte)“ an ist.

Hast du 2 Karten und kannst eine davon legen, erscheint der Knopf **„Mau sagen“**. Tippe ihn an, bevor du die Karte legst. Dann zeigt er „Mau!“. Legst du die vorletzte Karte, ohne „Mau“ gesagt zu haben, ziehst du sofort 1 Strafkarte.

Der Computer vergisst „Mau“ nie, auch nicht auf der Stufe „Leicht“.

## Gegen den Computer

Du kannst einen oder mehrere Plätze mit dem Computer besetzen. Seine Stärke stellst du in der Partie über „Mehr“ ein:

- **Leicht:** Er legt oft eine zufällige passende Karte.
- **Mittel:** Er spielt meistens gut, ab und zu zufällig.
- **Schwer** (Standard): Er wählt immer die Karte, die er für die beste hält.

Der Computer legt immer, wenn er kann. Er zieht nur, wenn keine Karte passt.

## Hilfen in der App

- **Spielbare Karten** sind hell, alle anderen sind abgedunkelt. Tippe eine helle Karte an, um sie zu legen.
- **Tipp:** zeigt dir die Karte, die der Computer an deiner Stelle legen würde.
- **Anzeige über der Hand:** Dort steht, was gerade gilt: „Farbe oder Wert“, „+4 für Anna“, „Anna setzt aus“, „Wunsch: ♥ Herz“ oder „Richtung gedreht“. Darunter steht der letzte Zug.
- **Sichtschutz:** Spielen mehrere Menschen an einem Gerät, wird die Hand erst gezeigt, wenn die Person am Zug sie aufdeckt.
- **Neben den Namen** steht, wie viele Karten jede Person hat. Bei mehreren Runden steht dahinter der Punktestand.
- **iPad:** Im Querformat zeigt eine Seitenspalte den Verlauf und die Regeln dieser Partie.
- **Pause:** Verlässt du die Partie, kannst du sie später an derselben Stelle fortsetzen.
- **Frag nach den Regeln** und **Regeln ansagen** („Sag, wie ihr spielen wollt“): nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Hebe dir einen Buben für den Notfall auf. Er passt fast immer.
- Wünsch dir die Farbe, von der du selbst die meisten Karten hast.
- Hat die nächste Person nur noch 1 oder 2 Karten, ist eine 7 oder 8 besonders wertvoll.
- Bei mehreren Runden zählen Buben und Asse viele Punkte. Werde sie lieber früh los.

## Begriffe

- **Ablage:** der offene Stapel in der Mitte, auf den gelegt wird.
- **Stapel:** die verdeckten Karten, von denen gezogen wird.
- **Farbe:** Kreuz, Pik, Herz oder Karo.
- **Wert:** 7, 8, 9, 10, Bube, Dame, König oder Ass.
- **Wunschfarbe:** die Farbe, die sich jemand mit einem Buben gewünscht hat.
- **Aussetzen:** einmal nicht dran sein.
- **Augen:** die Punkte einer Karte bei mehreren Runden.
- **Strafkarte:** die Karte, die du ziehst, wenn du „Mau“ vergessen hast.
- **Hausregel:** ein Schalter, mit dem du die Grundregeln änderst.
"""#
}
