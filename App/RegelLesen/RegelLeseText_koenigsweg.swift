// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/koenigsweg/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_koenigsweg {
    static let quelle = #"""
## Worum es geht

Königsweg ist ein Rennspiel für zwei. Es geht auf das **Königliche Spiel von Ur** zurück, eines der ältesten Brettspiele der Welt. Es ist über 4.500 Jahre alt und wurde in Königsgräbern im heutigen Irak gefunden.

Jeder hat **7 Steine**. Du bringst sie über einen Weg von 14 Feldern bis hinaus. Wer zuerst alle 7 Steine draußen hat, gewinnt. Statt mit einem Würfel wirfst du vier Münzen.

## Was du brauchst

- **Spieler:** genau 2. Ihr spielt zu zweit an einem Gerät oder du spielst gegen den Computer.
- **Steine:** 7 je Seite. Am Anfang liegen alle im **Vorrat**, neben dem Brett.
- **Münzen:** 4 Münzen. Die App wirft sie für dich, oder ihr werft echte Münzen und tippt das Ergebnis ein.

## Das Brett

Jeder hat seinen eigenen Weg mit den Feldern 1 bis 14. Danach kommt „draußen“, das Ziel.

- **Felder 1 bis 4:** dein Anfang. Hier stehen nur deine Steine.
- **Felder 5 bis 12:** der **gemeinsame Streifen** in der Mitte. Hier laufen beide Seiten auf denselben Feldern, und hier wird geschlagen.
- **Felder 13 und 14:** dein Ende. Auch hier stehen nur deine Steine.
- **Rosetten** (Blumen) liegen auf den Feldern **4, 8 und 14**.

Spieler 1 läuft unten, Spieler 2 oben, die Mitte teilt ihr euch.

## Wer beginnt

Wer beginnt, wählst du vor dem Start in der Karte „Wer beginnt“: „Abwechselnd“ (in der nächsten Partie beginnt der andere), der erste Spieler (gegen den Computer „Ich“) oder der zweite (der Computer). Standard ist der erste Spieler.

## Münzen werfen

Du wirfst 4 Münzen. Jede Münze mit Punkt zählt einen Schritt. Der Wurf ist also 0, 1, 2, 3 oder 4.

| Wurf | Wie oft |
|---|---|
|0 | selten (1 von 16) |
|1 | oft (4 von 16) |
|2 | am häufigsten (6 von 16) |
|3 | oft (4 von 16) |
|4 | selten (1 von 16) |

Bei einer **0** steht „Null – ausgesetzt“, und der Gegner ist dran.

## Ziehen

Mit deinem Wurf ziehst du **genau einen Stein** um genau so viele Felder weiter.

- **Neuer Stein:** Ein Stein aus dem Vorrat kommt auf das Feld mit der Nummer deines Wurfs. Bei einer 3 also auf Feld 3.
- **Stein auf dem Brett:** Tippe ihn an, er zieht weiter. Steine, die ziehen dürfen, sind dick umrandet.
- **Ziehen ist Pflicht.** Gibt es einen erlaubten Zug, musst du ihn machen.
- Gibt es keinen, steht „Kein Zug möglich“, und der Gegner ist dran.

**Nicht erlaubt:**
- Auf ein Feld, auf dem schon ein **eigener** Stein steht.
- Auf **Feld 8**, wenn dort ein Stein des Gegners steht.
- Über das Ziel hinaus.

## Hinaus ins Ziel

Raus kommst du nur mit der **genauen Zahl**. Von Feld 14 brauchst du eine 1, von Feld 13 eine 2, von Feld 12 eine 3. Ist der Wurf zu groß, kann dieser Stein nicht ziehen. Im Ziel dürfen beliebig viele eigene Steine liegen.

## Schlagen

Landest du im **gemeinsamen Streifen** (Felder 5 bis 12) auf einem Stein des Gegners, wird er geschlagen. Er geht zurück in den Vorrat und muss ganz von vorn beginnen. Die App meldet „Stein geschlagen!“.

Auf deinen eigenen Feldern (1 bis 4 und 13 bis 14) kann dich niemand schlagen.

**Beispiel:** Dein Stein steht auf Feld 5, ein Stein des Gegners auf Feld 7. Du wirfst 2. Du ziehst auf Feld 7, der Gegner muss zurück in den Vorrat.

## Rosetten

Landest du auf einer Rosette (Feld 4, 8 oder 14), darfst du **noch einmal werfen**. Die App meldet „Rosette – nochmal!“. Das gilt auch, wenn du dabei geschlagen hast. Schlagen allein gibt keinen Extrazug, und ins Ziel ziehen auch nicht.

Die Rosette in der Mitte, **Feld 8**, ist außerdem sicher: Steht dort ein Stein, kann der Gegner nicht darauf ziehen. Das macht Feld 8 zum wichtigsten Feld des Spiels.

**Beispiel:** Dein Stein steht auf Feld 2, du wirfst 2. Er kommt auf Feld 4, eine Rosette. Du wirfst sofort noch einmal.

## Wer gewinnt

Wer als Erster **alle 7 Steine draußen** hat, gewinnt sofort. Ein Unentschieden gibt es nicht.

Auf der Ergebnisseite siehst du, wie viele Steine jeder draußen hat, wie lange ihr gespielt habt, wie oft geschlagen wurde und wie die Münzen gefallen sind.

## Mit echten Münzen

Wähle vor dem Start „Echt“. Dann werft ihr die Münzen am Tisch. Die App fragt „Wie viele Münzen zeigen den Punkt?“, und du tippst 0 bis 4.

## Gegen den Computer

Die Stärke wählst du im Blatt „Neues Spiel“, wenn ein Computer mitspielt:

- **Leicht:** zieht irgendeinen erlaubten Stein.
- **Mittel** (Standard): bewertet jeden Zug, zieht gern auf Rosetten und schlägt, wenn es geht.
- **Schwer:** rechnet auch den nächsten Münzwurf und die beste Antwort von dir mit ein.

## So bedienst du das Spiel

- **Münzen werfen:** der große Knopf. Danach siehst du die Münzen und „N Felder ziehen“.
- **Neuer Stein:** setzt einen Stein aus dem Vorrat ein, wenn das geht.
- **Stein antippen:** zieht ihn weiter.
- **Tipp:** Ein gelber Ring zeigt den Zug, den der starke Computer wählen würde.
- **Zug zurück:** nimmt deinen letzten Zug zurück, solange noch nicht neu geworfen wurde. Den Wurf selbst kannst du nicht zurücknehmen.
- **Oben** steht bei jedem Spieler „Vorrat“ und „draußen“.
- **Gegenüber:** Spielt ihr zu zweit ohne Computer, liegt das Brett zwischen euch, und jeder hat seinen Knopf auf seiner Seite.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps

- Besetze Feld 8. Dort bist du sicher und blockierst den Gegner.
- Bleib im gemeinsamen Streifen nicht ein bis vier Felder vor einem gegnerischen Stein stehen. Dort trifft er dich leicht.
- Eine 2 kommt am häufigsten. Plane mit ihr.
- Lass nicht alle Steine im Vorrat. Mehrere Steine auf dem Brett geben dir mehr Wahl.

## Begriffe

- **Vorrat:** Steine, die noch nicht auf dem Brett sind, auch geschlagene.
- **Draußen:** Steine, die das Ziel erreicht haben.
- **Rosette:** Blumenfeld 4, 8 oder 14. Dort darfst du noch einmal werfen.
- **Gemeinsamer Streifen:** die Felder 5 bis 12, wo geschlagen wird.
"""#
}
