// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/viererreihe.md. Nicht von Hand ändern.
enum RegelWissenText_viererreihe {
    static let quelle = #"""
## Ziel
Stichwörter: Vier gewinnt, Vierer, Reihe, Sieg, Remis, Unentschieden, Brett, Rot, Blau, Farbe
Du spielst auf einem senkrechten Brett mit 7 Spalten und 6 Zeilen (42 Felder). Rot (Spieler 1) und Blau (Spieler 2) werfen abwechselnd je einen Stein in eine Spalte. Wer zuerst 4 eigene Steine in einer Reihe hat, gewinnt. Die Reihe darf waagerecht, senkrecht oder schräg (beide Richtungen) liegen. Auch mehr als 4 Steine in einer Reihe zählen, es gewinnt mit dem Stein, der die Reihe vollendet. Sind alle 42 Felder voll und niemand hat 4 in einer Reihe, endet die Partie unentschieden (Remis). Gegen den Computer bist du immer Rot, der Computer ist Blau.

## Ablauf und Zug
Stichwörter: Stein einwerfen, Spalte, fallen lassen, passen, Tastatur, Zug, dran
Pro Zug wirfst du genau einen Stein ein. Passen musst du nie, denn du kannst immer werfen, solange das Brett nicht voll ist. Der Stein fällt bis ganz nach unten oder bleibt auf dem obersten Stein der Spalte liegen. Du wählst also nur die Spalte, nicht das Feld. Eine volle Spalte (6 Steine) ist gesperrt. Auf dem Handy legst du den Finger auf eine Spalte, der Stein schwebt darüber, beim Loslassen fällt er. Am iPad mit Tastatur wirfst du mit den Ziffern 1 bis 7 (1 ganz links). Gegen den Computer wirft er nach kurzer Denkpause selbst.

## Wer beginnt
Stichwörter: Anfang, erster, Startspieler, abwechselnd, Revanche, Seitenwechsel
Vor dem Start wählst du im Neues-Spiel-Blatt „Wer beginnt“: „Abwechselnd“, du (bzw. Spieler 1) oder Computer (bzw. Spieler 2). Standard ist: Spieler 1 beginnt immer. Bei „Abwechselnd“ beginnt in der Revanche der andere, auch nach Neues Spiel im Menü. Wer beginnt, wirft die Steine 1, 3, 5 … (ungerade Züge), der andere die geraden Züge. Beginnt der Computer, setzt er den ersten Stein selbst. Die Farben bleiben gleich: Rot ist immer Spieler 1, auch wenn Blau beginnt.

## Computerstufen
Stichwörter: Gegner, Schwierigkeit, Stärke, leicht, mittel, geübt, stark, KI, Fehler machen, Mitte
Gegen den Computer wählst du im Menü „Mehr“ (drei Punkte) die „Stärke des Computers“. Voreingestellt ist Mittel. Leicht: Er gewinnt, wenn er sofort kann, blockt eine sofortige Vier des Gegners, sonst wirft er zufällig. Mittel: Er rechnet 4 Halbzüge voraus (also seinen Zug und 3 weitere) und wählt unter gleich guten Zügen zufällig. Geübt: Er rechnet 6 Halbzüge voraus, spielt aber etwa jeden vierten Zug bewusst den zweitbesten Zug, nie wenn das einen sicheren Sieg verschenkt oder der zweite Zug sicher verliert. Stark: Er rechnet so tief, wie er in etwa 1 Sekunde schafft, und beginnt in der Mitte (Spalte 4). Auch Geübt beginnt in der Mitte. Eine geänderte Stufe gilt ab dem nächsten Computerzug.

## Zug zurück und Tipp
Stichwörter: zurücknehmen, rückgängig, Hilfe, Vorschlag, Undo, Hinweis
„Zug zurück“ nimmt gegen den Computer deinen letzten Zug samt der Antwort des Computers zurück, damit du wieder an der Reihe bist. Zu zweit geht nur der letzte Zug zurück. Nach Spielende und ohne eigenen Zug geht es nicht. Hat der Computer die Partie begonnen und du noch nicht gezogen, gibt es nichts zurückzunehmen. „Tipp“ zeigt dir eine Spalte, die der starke Computer (höchstens 0,6 Sekunden Rechenzeit) wählen würde. Tipp gibt es nur, wenn du am Zug bist. Tipp und Zug zurück ändern die Regeln nicht, sie sind reine Hilfen.

## Online mit Freund
Stichwörter: Game Center, Internet, Freund einladen, online spielen, Mitteilung
Im Neues-Spiel-Blatt gibt es die Karte „Online mit Freund“ (nur mit Game Center). Jeder spielt auf dem eigenen Gerät, abwechselnd. Wer dran ist, bekommt eine Mitteilung. Wer die Partie begonnen hat, ist Rot und wirft den ersten Stein; „Wer beginnt“ gilt hier nicht, Rot beginnt immer. Während der Freund am Zug ist, ist dein Brett gesperrt. Online gibt es weder Zug zurück noch Tipp noch Neues Spiel. Endet die Partie, wird sie in Game Center beendet. Ist ein Zug noch nicht angekommen, kannst du ihn erneut senden. Die Regeln für Gewinn und Remis sind dieselben.

## Beispiele
Stichwörter: Beispiel, Diagonale, waagerecht, Rechnung
Beispiel waagerecht: Rot hat Steine in Spalte 2, 3 und 4 ganz unten. Wirft Rot jetzt in Spalte 5 (unten), sind es 4 in einer Reihe, Rot gewinnt. Beispiel schräg: Rot hat Steine in Spalte 1 (Zeile 1), Spalte 2 (Zeile 2), Spalte 3 (Zeile 3) und wirft in Spalte 4 so, dass der Stein auf Zeile 4 landet: Das ist eine Diagonale mit 4 Steinen, Rot gewinnt. Beispiel Remis: Alle 42 Felder sind voll (21 Rot, 21 Blau), kein Vierer: unentschieden. Beispiel Zug zurück: Du (Rot) wirfst in Spalte 4, der Computer in Spalte 3. Du tippst „Zug zurück“: Beide Steine sind weg, du bist wieder dran, das Brett ist leer.

## Begriffe und Umgangssprache
Stichwörter: Vier in einer Reihe, Doppelte Drohung, blocken, Gewinnfeld, Zugzwang
„Vier gewinnt“ oder „Vier in einer Reihe“ heißt dasselbe Spiel, in der App Viererreihe. „Remis“ oder „Unentschieden“ gilt, wenn das Brett voll ist. „Zugzwang“ nennt man, wenn jeder mögliche Zug dem Gegner einen Vorteil gibt. „Doppelte Drohung“ heißt, dass du zwei Gewinnfelder zugleich bedrohst, der Gegner kann nur eins blocken. „Mitte“ ist Spalte 4: dort liegen die meisten möglichen Reihen. „Blocken“ ist, einen Stein auf das Feld zu setzen, das der Gegner zum Gewinnen braucht. Ein „Gewinnfeld“ ist ein leeres Feld, das mit dem nächsten Stein eine Vierer-Reihe vollenden würde.

## Was die App anders macht als die übliche Regel
Stichwörter: Variante, Regeländerung, Popout, Brettgröße, Unterschied
Wie üblich: 7 × 6, Vier in einer Reihe, volles Brett = unentschieden. Die App kennt keine Varianten (kein Popout, keine anderen Brettgrößen, kein „Fünf gewinnt“). Besonderheiten der App: Wer beginnt ist einstellbar und merkt sich die Wahl. Der Computer hat 4 Stufen. Es gibt „Zug zurück“ (ohne Begrenzung auf eine Anzahl) und „Tipp“. Offline wie online sind Rot = Spieler 1 und Blau = Spieler 2 feste Farben. Es gibt keine Punktewertung, nur Sieg, Niederlage oder Remis.
"""#
}
