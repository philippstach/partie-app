// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/rauswurf/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_rauswurf {
    static let quelle = #"""
## Worum es geht

Rauswurf kennst du vielleicht als „Mensch ärgere dich nicht“. Jede Person hat Figuren, die einmal um das ganze Brett laufen und dann ins eigene Ziel müssen. Gewürfelt wird mit einem Würfel.

Das Besondere: Landest du auf einer fremden Figur, wird sie **rausgeworfen** und muss zurück an den Anfang. Darum heißt das Spiel so, und darum kann sich das Blatt bis zum Schluss wenden.

## Was du brauchst

- **Spieler:** 2 bis 4. Jeder Platz kann ein Mensch oder der Computer sein.
- **Figuren:** 4 pro Person (in den Hausregeln auch 3 oder 2).
- **Würfel:** einer. Im Blatt „Neues Spiel“ wählst du, ob die App würfelt oder ihr mit einem echten Würfel spielt.

## Das Brett

- Jede Person hat ein **Haus**, in dem die Figuren am Anfang warten.
- Davor liegt ihr **Startfeld**. Dort kommen die Figuren auf die Laufbahn.
- Die **Laufbahn** hat 40 Felder und führt einmal rund ums Brett. Die Startfelder liegen je 10 Felder auseinander.
- Kurz vor dem eigenen Startfeld biegt die Bahn in das eigene **Ziel** ab. Es hat 4 Felder.

Zu zweit sitzt ihr euch gegenüber.

## Wer beginnt

Wer anfängt, lost die App aus. Das passiert bei jeder neuen Partie.

## So läuft dein Zug

1. **Würfeln:** Tippe auf den Würfel oder „Würfeln“. Du kannst das Gerät auch schütteln.
2. **Figur wählen:** Die Figuren, die ziehen können, leuchten. Tippe eine davon an. Sie zieht genau so viele Felder vorwärts, wie der Würfel zeigt. Hältst du eine Figur gedrückt, siehst du vorher, wo sie landen würde.
3. Gibt es nur einen möglichen Zug, zieht die App von selbst.
4. Gibt es gar keinen Zug, verfällt der Wurf. Dann ist die nächste Person dran.

Über Figuren springen darfst du auf der Laufbahn immer, auch über fremde. Du darfst aber nicht auf einem Feld landen, auf dem schon eine eigene Figur steht.

## Die 6

- **Raus:** Aus dem Haus kommt eine Figur nur mit einer 6. Sie steht dann auf deinem Startfeld.
- **Nochmal:** Nach einer 6 darfst du noch einmal würfeln, auch nach dem Rauskommen. Das gilt nur, wenn du mit der 6 auch ziehen konntest.

## Drei Versuche

Kannst du mit keiner Zahl von 1 bis 5 ziehen, zum Beispiel weil alle Figuren im Haus sind, darfst du bis zu dreimal würfeln, um eine 6 zu bekommen. Klappt es nicht, ist die nächste Person dran. Die Hinweiszeile zeigt dir, wie viele Versuche du noch hast.

## Rauswerfen

Landest du genau auf einem Feld mit einer fremden Figur, wird sie rausgeworfen und muss zurück in ihr Haus. Das gilt auch, wenn sie auf ihrem eigenen Startfeld steht. Im Ziel wird nicht geworfen, dort stehen nur eigene Figuren.

## Pflichten

Manchmal musst du einen bestimmten Zug machen. Die App zeigt das in der Hinweiszeile an. Die Pflichten gelten in dieser Reihenfolge:

1. **Mit 6 raus:** Würfelst du eine 6 und hast noch Figuren im Haus, musst du eine herausholen, wenn das Startfeld frei ist.
2. **Startfeld räumen:** Steht eine eigene Figur auf deinem Startfeld und warten noch Figuren im Haus, muss diese Figur zuerst weiterziehen, wenn sie kann. So machst du Platz für die nächste.
3. **Schlagpflicht** (nur wenn eingeschaltet): Kannst du jemanden rauswerfen, musst du es tun.

## Ins Ziel

Deine Figur läuft einmal um das Brett und biegt dann in dein Ziel ab. Von deinem Startfeld bis ins erste Zielfeld sind es 40 Felder.

Du darfst nicht über das letzte Zielfeld hinaus ziehen. Jedes freie Zielfeld davor ist erlaubt. *Beispiel:* Deine Figur steht auf dem letzten Feld vor deinem Ziel. Mit einer 1 kommt sie aufs erste Zielfeld, mit einer 4 aufs vierte. Eine 5 oder 6 geht mit ihr nicht.

Im Ziel darfst du über deine eigenen Figuren springen (außer bei der Hausregel „Im Ziel überspringen“ aus).

## Wer gewinnt

Wer zuerst alle Figuren im Ziel hat, gewinnt. Damit endet die Partie („Erster Sieger“).

Mit dem Spielende „Ganze Reihenfolge“ wird weitergespielt, bis alle außer einer Person fertig sind. So gibt es einen 2., 3. und 4. Platz. Wer fertig ist, setzt aus.

## Teams (2 gegen 2)

Nur zu viert: Wer sich gegenübersitzt, spielt zusammen, also Platz 1 und 3 gegen Platz 2 und 4.

- Den Partner schlägst du nicht. Ein Feld mit seiner Figur ist für dich gesperrt wie ein eigenes.
- Wer fertig ist, setzt aus, der Partner spielt weiter.
- Das Team gewinnt, sobald beide alle Figuren im Ziel haben.

## Spielarten

Im Blatt „Neues Spiel“ wählst du unter „Spielart“ eine fertige Zusammenstellung:

- **Familie** (Standard): so, wie die meisten zu Hause spielen. Alle Regeln oben gelten, Schlagpflicht ist aus.
- **Offiziell:** nach der offiziellen Anleitung. Eine Figur steht schon draußen, dafür gibt es keine drei Versuche.
- **Kinder:** Niemand fliegt raus. Auf ein Feld mit einer fremden Figur darfst du dann nicht.
- **Schnell:** nur 2 Figuren, eine steht schon draußen. In etwa 10 Minuten durch.
- **Streng:** Schlagpflicht, und im Ziel wird nicht gesprungen.

## Hausregeln

Unter „Hausregeln“ kannst du jeden Schalter einzeln ändern. Dann spielst du „Eigene Regeln“.

@form B
| Hausregel | Standard | Was sie macht |
|---|---|---|
|Mit 6 raus | an | Bei einer 6 musst du eine Figur aus dem Haus holen, wenn das geht. |
|Startfeld räumen | an | Die Figur auf dem Startfeld muss zuerst weiter, solange noch Figuren im Haus warten. |
|Schlagpflicht | aus | Wer schlagen kann, muss schlagen. |
|Drei Versuche | an | Dreimal würfeln, wenn du ohne 6 nicht ziehen kannst. |
|Nochmal nach 6 | an | Nach einer 6 noch einmal würfeln. |
|Im Ziel überspringen | an | Im Ziel über eigene Figuren springen. |
|Start mit einer Figur draußen | aus | Zu Beginn steht schon eine Figur auf deinem Startfeld. |
|Rauswerfen | an | Aus: Niemand fliegt raus. |
|Teams (2 gegen 2) | aus | Nur zu viert, siehe oben. |
|Figuren je Spieler | 4 | auch 3 oder 2 |
|Spielende | Erster Sieger | oder „Ganze Reihenfolge“ |

Die Hausregeln gelten ab der nächsten Partie. „Auf Standard zurücksetzen“ stellt alles wieder auf „Familie“.

## Gegen den Computer

Im Blatt „Neues Spiel“ wählst du die Stärke des Computers:

- **Leicht:** wirft raus, wenn er kann, holt sonst Figuren aus dem Haus und zieht sonst ohne Plan.
- **Mittel** (Standard) und **Schwer:** spielen gleich gut. Der Computer wirft am liebsten raus, bringt dann Figuren ins Ziel, holt neue heraus und stellt sich gern auf sichere Felder.

Mit dem Schalter **„Computer lässt Menschen gewinnen“** wirft er Menschen nur raus, wenn es gar nicht anders geht. Gut für Kinder.

Der Computer würfelt immer in der App, mit demselben Würfel wie alle. Er bekommt keine besseren Zahlen.

## Mit echtem Würfel

Hast du „Echt“ gewählt, würfelst du am Tisch. Die App fragt dann „Was hast du gewürfelt?“, und du tippst die Zahl an. Drei Sekunden lang kannst du sie noch ändern.

## Hilfen in der App

- **Hinweiszeile:** sagt dir, was gerade zu tun ist, zum Beispiel „Eine 6 – du musst rauskommen“ oder „Mach dein Startfeld frei“.
- **Tipp:** schlägt dir einen Zug vor, zum Beispiel „Figur 2 auf Feld 14 ziehen – wirft raus!“.
- **Rückgängig:** nimmt deine letzten Entscheidungen zurück, gegen den Computer auch seine Züge danach. Den Wurf bekommst du dabei nicht neu: Es kommt wieder dieselbe Zahl.
- **Würfelstatistik:** zeigt, wie oft jede Zahl gefallen ist und wie lange jemand auf eine 6 warten musste.
- **Weitergeben:** Spielen mehrere Menschen an einem Gerät, sagt die App, wem du das Gerät geben sollst.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Bring nicht nur eine Figur nach vorn. Mehrere Figuren draußen geben dir mehr Auswahl.
- Bleib nicht direkt vor einer fremden Figur stehen. 1 bis 6 Felder dahinter bist du in Gefahr.
- Eine Figur kurz vor dem Ziel ist wertvoll. Bring sie in Sicherheit, wenn du kannst.

## Begriffe

- **Haus:** dort warten die Figuren, die noch nicht im Spiel sind.
- **Startfeld:** das Feld, auf dem eine Figur aus dem Haus ankommt.
- **Ziel:** die 4 eigenen Felder am Ende des Wegs.
- **Rauswerfen (Schlagen):** eine fremde Figur zurück ins Haus schicken.
- **Raus / Rauskommen:** mit einer 6 eine Figur aus dem Haus holen.
"""#
}
