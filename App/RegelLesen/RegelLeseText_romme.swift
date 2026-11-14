// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/romme/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_romme {
    static let quelle = #"""
## Worum es geht

Rommé ist ein klassisches Kartenspiel für 2 bis 4 Personen. Du sammelst Karten, die zusammenpassen, und legst sie als **Sätze** (gleiche Werte) oder **Folgen** (Reihen in einer Farbe) auf den Tisch. Wer als Erste oder Erster keine Karten mehr auf der Hand hat, gewinnt die Runde. Die anderen bekommen Strafpunkte für die Karten, die sie noch halten.

In jedem Zug ziehst du eine Karte, legst aus, wenn du kannst, und wirfst eine Karte ab. Spannend wird es durch die Joker und durch die Regel, dass deine erste Auslage mindestens 40 Augen haben muss.

## Was du brauchst

- **Spieler:** 2 bis 4. Jeder Platz kann ein Mensch oder der Computer sein.
- **Karten:** 110 Karten: zwei französische Blätter mit je 52 Karten (Kreuz ♣, Pik ♠, Herz ♥, Karo ♦; Ass, 2 bis 10, Bube, Dame, König) und 6 Joker (★).
- Jede Person bekommt **13 Karten**. Eine Karte liegt offen auf der **Ablage**, der Rest ist der **Stapel**.

## So läuft dein Zug

1. **Ziehen:** Nimm eine Karte vom Stapel („Vom Stapel ziehen“) oder die oberste Karte der Ablage („Ablage nehmen“). Die Ablagekarte musst du nicht verwenden.
2. **Auslegen, Anlegen, Joker tauschen:** Das darfst du jetzt, so oft du willst. Nichts davon ist Pflicht.
3. **Abwerfen:** Zum Schluss wirfst du genau eine Karte auf die Ablage. Dann ist die nächste Person dran.

Ist der Stapel leer, werden die Ablagekarten unter der obersten gemischt und bilden den neuen Stapel.

## Sätze und Folgen

**Satz:** 3 oder 4 Karten mit gleichem Wert in verschiedenen Farben.
*Beispiel:* K♠ K♥ K♦. Ein Satz hat höchstens 2 Joker. Mit 4 Karten ist er voll.

**Folge:** mindestens 3 Karten einer Farbe in einer Reihe, ohne Lücke und ohne doppelte Werte.
*Beispiel:* 5♥ 6♥ 7♥.
- Das Ass liegt unten (A-2-3) oder oben (D-K-A).
- „Um die Ecke“ geht nicht: K-A-2 ist keine Folge.
- Eine Folge hat höchstens 14 Karten (Ass bis König und wieder Ass).
- Joker dürfen beliebig viele drin sein, aber mindestens eine Karte muss echt sein.

**Joker (★)** ersetzen jede Karte. Sie füllen Lücken oder verlängern eine Folge.

## Die erste Auslage: 40 Augen

Bevor du zum ersten Mal auslegst, müssen deine Karten zusammen mindestens **40 Augen** haben. Du darfst dafür mehrere Sätze und Folgen auf einmal auslegen, ihre Augen werden zusammengezählt.

So zählen die Augen in einer Auslage:

| Karte | Augen |
|---|---|
|2 bis 10 | ihr Wert |
|Bube, Dame, König | 10 |
|Ass im Satz | 11 |
|Ass in der Folge unten (A-2-3) | 1 |
|Ass in der Folge oben (D-K-A) | 11 |
|Joker | so viel wie die Karte, die er ersetzt |

*Beispiele:*
- K♠ K♥ K♦ = 30 Augen. Das reicht allein nicht.
- 10♣ B♣ D♣ K♣ = 40 Augen. Das reicht.
- A♥ 2♥ 3♥ = 6 Augen. D♥ K♥ A♥ = 31 Augen.
- 8♥ 9♥ ★ B♥ (Joker als 10) = 37 Augen.

Beim Wählen zeigt die App, wie viele Augen du hast, zum Beispiel „Gewählte Auslage: 38 von 40 Augen – es fehlen noch 2.“

Nach der ersten Auslage darfst du weitere Auslagen ohne Mindestwert legen.

## Anlegen

Nach deiner eigenen ersten Auslage darfst du einzelne Karten an Auslagen auf dem Tisch anlegen, auch an die der anderen. Die Auslage muss danach noch gültig sein. *Beispiel:* An 5♥ 6♥ 7♥ passt 4♥ oder 8♥.

So geht es: Wähle genau eine Karte und tippe dann die Auslage auf dem Tisch an.

## Joker tauschen

Liegt auf dem Tisch ein Joker, und du hast die echte Karte, die er ersetzt, darfst du tauschen: Deine Karte kommt an seine Stelle, der Joker kommt auf deine Hand. Auch das geht erst nach deiner ersten Auslage.

Den Joker darfst du danach auslegen, anlegen, abwerfen oder einfach behalten. Passt deine Karte sowohl zum Tauschen als auch zum Anlegen, fragt die App, was du willst.

## Ende der Runde

Hast du keine Karte mehr auf der Hand, gewinnst du die Runde. Das geht durch Abwerfen der letzten Karte, aber auch schon, wenn du mit Auslegen oder Anlegen die letzte Karte loswirst.

Alle anderen bekommen **Strafpunkte** für ihre Restkarten:

| Karte auf der Hand | Strafpunkte |
|---|---|
|Joker | 20 |
|Ass | 11 |
|Bube, Dame, König | 10 |
|2 bis 10 | ihr Wert |

*Beispiel:* K♠, 5♥, A♦ und ein Joker = 10 + 5 + 11 + 20 = 46 Strafpunkte. Wer gewinnt, bekommt 0.

## Mehrere Runden

Im Blatt „Neues Spiel“ wählst du unter „Runden“: **Eine Runde** (Standard), **3 Runden** oder **5 Runden**.

Bei mehreren Runden werden die Strafpunkte zusammengezählt. Nach jeder Runde zeigt die App den Stand, dann geht es mit „Nächste Runde“ weiter. Wer anfängt, rückt jede Runde einen Platz weiter. Nach der letzten Runde gewinnt, wer die **wenigsten** Strafpunkte hat. Bei Gleichstand steht vorn, wer die letzte Runde gewonnen hat.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“ → „Stärke des Computers“:

- **Leicht:** nimmt nie die Ablagekarte, tauscht keine Joker und wirft zufällig ab.
- **Mittel:** nimmt die Ablagekarte nur manchmal, tauscht Joker und wirft hohe Karten ab.
- **Schwer** (Standard): spielt am klügsten und behält Karten, die zu anderen passen.

Den Joker wirft der Computer nie ab.

## Hilfen in der App

- **Karten wählen:** Tippe Karten an, sie heben sich. „Auslegen“ geht ab 3 gewählten Karten, „Abwerfen“ mit genau einer.
- **Sortieren:** ordnet deine Hand „Wie gezogen“, „Nach Farbe“ oder „Nach Wert“. Joker stehen immer hinten.
- **Tipp:** schlägt vor, was ein starker Computer jetzt tun würde, und wählt die Karten schon aus.
- **Hinweiszeile:** erklärt, was gerade geht oder warum etwas nicht geht.
- **Spielerleiste:** zeigt für jede Person die Zahl der Karten und die Strafpunkte.
- **Sichtschutz:** Spielen mehrere Menschen an einem Gerät, ist die Hand verdeckt, bis die Person am Zug sie aufdeckt.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

Einen Zug zurücknehmen geht nicht. Überleg also vor dem Abwerfen.

## Kleine Tipps für den Anfang

- Sammle zuerst Karten für die 40 Augen. Hohe Karten (Bube bis Ass) helfen dabei.
- Wirf Karten ab, die zu nichts passen, am besten hohe, denn die kosten am Ende viele Strafpunkte.
- Schau, was die anderen von der Ablage nehmen. Dann weißt du, was sie sammeln, und wirfst ihnen das nicht hin.
- Behalte Joker. Sie sind am Ende 20 Strafpunkte wert, aber vorher deine beste Karte.

## Begriffe

- **Auslage:** ein Satz oder eine Folge auf dem Tisch.
- **Satz:** gleiche Werte, verschiedene Farben.
- **Folge:** Reihe in einer Farbe.
- **Augen:** der Punktwert einer Auslage.
- **Anlegen:** eine Karte an eine Auslage auf dem Tisch legen.
- **Strafpunkte:** die Punkte deiner Restkarten am Ende einer Runde.
"""#
}
