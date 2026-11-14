// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Metadaten je Spiel für Suche, Filter und die KI-Suche: Herkunftsland, Kurzbeschreibung der Regeln, Stichworte.
/// Neue Spiele tragen hier genau eine Zeile ein (Schlüssel = `SpielModul.id`).
struct SpielInfo {
    let land: String
    let kurz: String
    let stichworte: [String]
}

enum SpielMetadaten {
    static func info(_ id: String) -> SpielInfo { tabelle[id] ?? tabelle[SpielKatalog.kennung(id)] ?? SpielInfo(land: "", kurz: "", stichworte: []) }

    /// Kurzbeschreibung in der Sprache des Geräts (Schlüssel = deutscher Text im String-Katalog).
    static func kurzText(_ id: String) -> String {
        let k = info(id).kurz
        return k.isEmpty ? "" : NSLocalizedString(k, comment: "Kurzbeschreibung eines Spiels")
    }

    /// Herkunftsland in der Sprache des Geräts (Schlüssel = deutscher Name im String-Katalog).
    static func landText(_ land: String) -> String {
        land.isEmpty ? "" : NSLocalizedString(land, comment: "Herkunftsland eines Spiels")
    }

    /// Alle vorkommenden Länder, sortiert.
    static var laender: [String] { Array(Set(tabelle.values.map(\.land).filter { !$0.isEmpty })).sorted() }

    static let tabelle: [String: SpielInfo] = [
        "yacht-neu": SpielInfo(land: "Kanada", kurz: "Würfle fünf Würfel bis zu dreimal und trage die Augen in eine Wertungstabelle ein (Paschs, Straßen, Full House, Yacht). Wählbar: Klassisch, Yatzy oder Original-Yacht.", stichworte: ["kniffel", "yahtzee", "yatzy", "würfeln", "kniffel", "pasch", "full house", "punkte"]),
        "schocken-neu": SpielInfo(land: "Deutschland", kurz: "Kneipenwürfelspiel mit drei Würfeln unter dem Deckel: Wer den schlechtesten Wurf hat, bekommt die Deckel.", stichworte: ["würfeln", "kneipe", "deckel", "bluffen", "schock"]),
        "rauswurf-neu": SpielInfo(land: "Deutschland", kurz: "Brettspiel für 2–4: Mit der Würfelzahl die Figuren einmal um das Brett ins Haus bringen und Gegner hinauswerfen.", stichworte: ["mensch ärgere dich nicht", "ludo", "würfeln", "brett", "figuren"]),
        "minensuche": SpielInfo(land: "USA", kurz: "Decke alle sicheren Felder auf, ohne eine Mine zu treffen; Zahlen zeigen die Minen in der Nachbarschaft.", stichworte: ["minesweeper", "rätsel", "logik", "minen"]),
        "farbraetsel": SpielInfo(land: "Deutschland", kurz: "Ordne Farbfelder so, dass sie einen sanften Farbverlauf ergeben.", stichworte: ["farben", "puzzle", "verlauf", "sortieren"]),
        "solitaer-neu": SpielInfo(land: "Frankreich", kurz: "Klassisches Kartenlegen allein: Klondike, Spider, FreeCell, Pyramide, TriPeaks, Golf, Yukon.", stichworte: ["karten", "patience", "klondike", "freecell", "spider", "allein", "neu"]),
        "wortpfeil": SpielInfo(land: "Deutschland", kurz: "Kreuzworträtsel mit Fragefeldern und Pfeilen im Gitter.", stichworte: ["kreuzworträtsel", "wörter", "rätsel", "pfeilrätsel"]),
        "sudoku-neu": SpielInfo(land: "Japan", kurz: "Fülle das Gitter so, dass jede Zahl in jeder Zeile, Spalte und Box genau einmal steht – klassisch, als Kinder-Sudoku 6 × 6 oder als X-Sudoku.", stichworte: ["zahlen", "logik", "rätsel", "gitter", "x-sudoku", "kinder", "tagesrätsel"]),
        "viererreihe-neu": SpielInfo(land: "USA", kurz: "Wirf abwechselnd Steine in ein senkrechtes Brett; wer zuerst vier in einer Reihe hat, gewinnt.", stichworte: ["vier gewinnt", "connect four", "brett", "zwei spieler", "strategie"]),
        "galgenmaennchen-neu": SpielInfo(land: "England", kurz: "Errate ein gesuchtes Wort Buchstabe für Buchstabe, bevor das Männchen am Galgen vollständig ist.", stichworte: ["hangman", "wörter", "buchstaben", "raten"]),
        "10k-neu": SpielInfo(land: "USA", kurz: "Würfle mit fünf oder sechs Würfeln Punkte zusammen und sei als Erster bei 10 000, ohne eine Niete zu würfeln.", stichworte: ["10k", "zehntausend", "farkle", "würfeln", "punkte", "risiko"]),
        "klappbrett": SpielInfo(land: "Frankreich", kurz: "Klappe die Zahlen 1 bis 9 passend zur Würfelsumme zu; wer am Ende die wenigsten offenen Zahlen hat, gewinnt.", stichworte: ["shut the box", "würfeln", "zahlen", "klappen"]),
        "schiebepuzzle": SpielInfo(land: "USA", kurz: "Schiebe nummerierte Kacheln in die Lücke, bis die Reihenfolge stimmt.", stichworte: ["15-puzzle", "schieben", "zahlen", "rätsel"]),
        "muehle": SpielInfo(land: "Antike (Ägypten, Rom)", kurz: "Setze neun Steine und schließe Mühlen aus drei in einer Reihe, um gegnerische Steine zu entfernen.", stichworte: ["nine men's morris", "brett", "zwei spieler", "strategie"]),
        "schwimmen-neu": SpielInfo(land: "Deutschland", kurz: "Drei Karten, möglichst nah an 31 Punkten in einer Farbe: tauschen, schieben oder klopfen.", stichworte: ["31", "karten", "schnauz", "knacken", "leben"]),
        "lichteraus": SpielInfo(land: "USA", kurz: "Ein Tipp schaltet ein Licht und seine Nachbarn um; bringe alle Lichter zum Erlöschen.", stichworte: ["lights out", "rätsel", "logik", "schalten"]),
        "hanoi": SpielInfo(land: "Frankreich", kurz: "Versetze einen Turm aus Scheiben von einem Stab auf einen anderen, nie eine größere auf eine kleinere.", stichworte: ["türme", "scheiben", "rätsel", "rekursion"]),
        "zahlenfusion": SpielInfo(land: "Italien", kurz: "Wische Zahlenkacheln, gleiche verschmelzen zu ihrer Summe, bis die 2048 erscheint.", stichworte: ["2048", "wischen", "zahlen", "rätsel"]),
        "kalaha": SpielInfo(land: "Afrika", kurz: "Säe Steine aus Mulden reihum und fülle dein Haus; endet der letzte Stein im Haus, bist du nochmal dran.", stichworte: ["mancala", "säen", "brett", "zwei spieler"]),
        "wendespiel": SpielInfo(land: "England", kurz: "Schließe gegnerische Steine zwischen deinen ein und wende sie; am Ende gewinnt, wer mehr Steine hat.", stichworte: ["reversi", "othello", "brett", "wenden", "zwei spieler"]),
        "dame": SpielInfo(land: "Frankreich", kurz: "Ziehe diagonal, springe und schlage Pflicht, erreiche die letzte Reihe und werde Dame.", stichworte: ["checkers", "brett", "schlagzwang", "zwei spieler"]),
        "siebzehnundvier": SpielInfo(land: "Spanien", kurz: "Komme mit Karten möglichst nah an 21, ohne darüber zu geraten, und schlage die Bank.", stichworte: ["blackjack", "21", "karten", "bank", "ziehen"]),
        "maexchen": SpielInfo(land: "Deutschland", kurz: "Würfle verdeckt, sage einen Wert an (auch gelogen) und lass den nächsten glauben oder anzweifeln.", stichworte: ["bluffen", "lügen", "würfeln", "becher", "kneipe"]),
        "schiffeversenken": SpielInfo(land: "Russland", kurz: "Verstecke Schiffe auf einem Gitter und errate die Felder der gegnerischen Flotte.", stichworte: ["battleship", "raten", "gitter", "zwei spieler", "flotte"]),
        "schweinerei": SpielInfo(land: "USA", kurz: "Würfle so oft du magst und sammle Punkte; bei einer 1 sind sie weg – sichere rechtzeitig.", stichworte: ["pig", "würfeln", "risiko", "einfach", "kinder"]),
        "maumau-neu": SpielInfo(land: "Deutschland", kurz: "Lege Karten gleicher Farbe oder gleichen Wertes ab; Tisch als Spielfeld, Hausregeln frei kombinierbar, auf Wunsch mit Mau und mehreren Runden.", stichworte: ["uno", "karten", "ablegen", "familie", "mau mau"]),
        "nonogramm": SpielInfo(land: "Japan", kurz: "Fülle Felder nach Zahlenhinweisen an den Rändern, bis ein Bild entsteht.", stichworte: ["picross", "griddlers", "bilderrätsel", "logik"]),
        "chicago": SpielInfo(land: "USA", kurz: "Elf Runden mit Zielzahlen 2 bis 12: Würfle die Zielsumme und sammle Punkte.", stichworte: ["würfeln", "zielzahl", "runden", "punkte"]),
        "elferraus-neu": SpielInfo(land: "Deutschland", kurz: "Lege Karten jeder Farbe von der Elf aus nach oben und unten an und werde als Erster alle los.", stichworte: ["karten", "anlegen", "familie", "sevens"]),
        "luegenwuerfel": SpielInfo(land: "Südamerika", kurz: "Verdeckte Würfel, steigende Gebote über alle Würfel am Tisch und das Anzweifeln des Vorgängers.", stichworte: ["liar's dice", "bluffen", "würfeln", "gebot", "kneipe"]),
        "mogeln": SpielInfo(land: "USA", kurz: "Lege Karten verdeckt ab und behaupte, es seien die verlangten; der Nächste darf „Gelogen!“ rufen.", stichworte: ["cheat", "bluffen", "karten", "lügen"]),
        "halma": SpielInfo(land: "USA", kurz: "Bringe alle Steine hüpfend und in Sprungketten in die gegenüberliegende Ecke.", stichworte: ["chinese checkers", "brett", "springen", "ecke"]),
        "stadtlandfluss": SpielInfo(land: "Deutschland", kurz: "Finde zu einem Buchstaben Stadt, Land, Fluss, Tier und mehr; seltene Antworten zählen doppelt.", stichworte: ["wörter", "buchstaben", "kategorien", "schreiben", "party"]),
        "schach": SpielInfo(land: "Indien", kurz: "Der Klassiker: Setze den gegnerischen König matt; mit Rochade, en passant und Umwandlung.", stichworte: ["chess", "könig", "matt", "brett", "strategie", "zwei spieler"]),
        "mahjongpaare": SpielInfo(land: "China", kurz: "Entferne paarweise gleiche freie Steine aus einer gestapelten Figur.", stichworte: ["mahjong solitaire", "paare", "steine", "allein"]),
        "bruecken": SpielInfo(land: "Japan", kurz: "Verbinde Inseln mit Brücken nach ihren Zahlen, ohne dass sich Brücken kreuzen.", stichworte: ["hashi", "bridges", "inseln", "logik", "rätsel"]),
        "kakuro": SpielInfo(land: "Japan", kurz: "Zahlenkreuzworträtsel: Ziffern 1–9 so eintragen, dass sie die Hinweissummen ergeben, ohne Wiederholung.", stichworte: ["kreuzzahlrätsel", "summen", "zahlen", "logik"]),
        "backgammon": SpielInfo(land: "Persien", kurz: "Würfle und ziehe 15 Steine um das Brett nach Hause, schlage Einzelsteine und trage zuerst alle ab.", stichworte: ["würfeln", "brett", "zwei spieler", "strategie", "tavla"]),
        "romme": SpielInfo(land: "Deutschland", kurz: "Lege Folgen und Sätze aus, mit Jokern; wer zuerst keine Karten mehr hat, gewinnt.", stichworte: ["rummy", "rami", "karten", "folgen", "sätze", "joker"]),
        "ballwechsel": SpielInfo(land: "Deutschland", kurz: "Schläger-Ball-Duell: Schlage den Ball zurück und lass ihn beim Gegner durch; erster bei sieben gewinnt.", stichworte: ["pong", "arcade", "ball", "zwei spieler", "reaktion"]),
        "steinfall": SpielInfo(land: "Deutschland", kurz: "Fallende Fünfer-Steine stapeln und Reihen auflösen, bevor das Feld überläuft.", stichworte: ["tetris", "arcade", "stapeln", "blöcke", "reaktion"]),
        "wolkenhuepfer": SpielInfo(land: "Deutschland", kurz: "Hüpfe von Wolke zu Wolke immer höher und steuere mit dem Finger.", stichworte: ["doodle jump", "arcade", "hüpfen", "plattformen", "reaktion"]),
        "dauerlauf": SpielInfo(land: "Deutschland", kurz: "Ein Läufer rennt von allein; springe über Hürden, ducke dich und sammle Perlen.", stichworte: ["endless runner", "arcade", "laufen", "springen", "reaktion"]),
        "mauerbrecher": SpielInfo(land: "Deutschland", kurz: "Brich mit Kugel und Schlagholz eine vorrückende Mauer, bevor sie dich erreicht.", stichworte: ["breakout", "arkanoid", "arcade", "ball", "steine", "reaktion"]),
        "paarsuche": SpielInfo(land: "Deutschland", kurz: "Decke Karten auf und finde gleiche Paare, wer sich mehr merkt, gewinnt.", stichworte: ["memory", "paare", "gedächtnis", "karten", "kinder"]),
        "farbflut": SpielInfo(land: "Deutschland", kurz: "Flute das Feld mit Farben und färbe es mit möglichst wenigen Zügen komplett ein.", stichworte: ["farbflut", "flood", "farben", "füllen", "rätsel"]),
        "schiffsfracht": SpielInfo(land: "Niederlande", kurz: "Lade Fracht geschickt auf die Schiffe, damit nichts übrig bleibt.", stichworte: ["schiffe", "fracht", "packen", "rätsel"]),
        "koenigsweg": SpielInfo(land: "Indien", kurz: "Bringe deinen König über das Brett zum Ziel, bevor es der Gegner schafft.", stichworte: ["könig", "brett", "weg", "taktik"]),
        "ungleichung": SpielInfo(land: "Japan", kurz: "Zahlenrätsel mit Größer-und-Kleiner-Zeichen: Fülle das Feld ohne Wiederholung.", stichworte: ["futoshiki", "zahlen", "ungleich", "logik", "rätsel"]),
        "crazyeights": SpielInfo(land: "USA", kurz: "Lege Karten gleicher Farbe oder Zahl ab, Achter sind Joker und bestimmen die Farbe.", stichworte: ["acht", "ablegen", "karten", "uno", "familie"]),
        "spitspeed": SpielInfo(land: "USA", kurz: "Schnelles Kartenduell: Beide legen gleichzeitig auf zwei Stapel, wer zuerst leer ist, gewinnt.", stichworte: ["spit", "speed", "schnell", "karten", "reaktion"]),
        "kaestchenjagd": SpielInfo(land: "Frankreich", kurz: "Ziehe Linien und schließe Kästchen, wer ein Kästchen schließt, darf nochmal.", stichworte: ["punkte", "kästchen", "linien", "dots and boxes"]),
        "steckspiel": SpielInfo(land: "Deutschland", kurz: "Lege Steine in die Reihe und erkenne die Muster, bevor der Gegner sie schließt.", stichworte: ["stecken", "reihen", "muster", "taktik"]),
        "esel": SpielInfo(land: "Deutschland", kurz: "Kartenspiel: Wer als Letzter nicht rechtzeitig zugreift, ist der Esel.", stichworte: ["reaktion", "karten", "esel", "schnell"]),
        "aceydeucey": SpielInfo(land: "Griechenland", kurz: "Backgammon-Variante: alle Steine starten auf der Bar, mit der Sonderregel für 1 und 2.", stichworte: ["backgammon", "tavla", "würfel", "bar"]),
        "perudo": SpielInfo(land: "Südamerika", kurz: "Würfel-Bluffspiel mit verdeckten Würfeln: Biete Mengen, zweifle an oder gib Calza.", stichworte: ["bluff", "würfel", "lügen", "liar", "dudo", "südamerika"]),
        "fuchsjagd-neu": SpielInfo(land: "Deutschland", kurz: "Jage den Fuchs auf dem Brett und schneide ihm den Weg ab.", stichworte: ["jagd", "fuchs", "brett", "taktik", "neu"]),
        "lagerplatz": SpielInfo(land: "Deutschland", kurz: "Baue Zelte so, dass die Zahlen am Rand stimmen.", stichworte: ["zelte", "bäume", "logik", "rätsel"]),
        "farbcode": SpielInfo(land: "Großbritannien", kurz: "Knacke den Farbcode des Gegners mit wenigen Versuchen.", stichworte: ["mastermind", "code", "farben", "logik"]),
        "sechseck": SpielInfo(land: "USA", kurz: "Verbinde auf dem Sechseckbrett deine beiden Seiten vor dem Gegner.", stichworte: ["hex", "verbinden", "brett", "taktik"]),
        "patolli": SpielInfo(land: "Mexiko", kurz: "Aztekisches Würfel-Brettspiel: Würfle und ziehe deine Steine einmal um das Kreuz.", stichworte: ["azteken", "würfel", "kreuz", "mexiko"]),
        "bunco": SpielInfo(land: "USA", kurz: "Würfelspiel in sechs Runden: Würfle die Zahl der Runde und sammle Punkte, drei Gleiche sind ein Bunco.", stichworte: ["würfel", "runden", "party", "glück"]),
        "dominocubano": SpielInfo(land: "Kuba", kurz: "Domino mit Doppel-Neun-Satz (55 Steine), zehn Steine je Spieler.", stichworte: ["domino", "kuba", "steine", "augen"]),
        "chinchon": SpielInfo(land: "Spanien", kurz: "Rommé-Spiel mit spanischem Blatt: Bilde Gruppen und Reihen und schließe aus.", stichworte: ["rommé", "spanisch", "karten", "gruppen", "reihen"]),
        "oware": SpielInfo(land: "Ghana", kurz: "Afrikanisches Säespiel: Verteile Samen in Mulden und erobere sie vom Gegner.", stichworte: ["mancala", "säen", "afrika", "kalaha", "samen"]),
        "pokerwurf": SpielInfo(land: "USA", kurz: "Würfelpoker: Würfle Paare, Drillinge und Straßen und schlage den Gegner.", stichworte: ["poker", "würfel", "kniffel", "kombination"]),
        "domino": SpielInfo(land: "China", kurz: "Lege Steine mit passenden Augen aneinander und werde zuerst deine los.", stichworte: ["steine", "augen", "anlegen", "klassiker"]),
        "brisca": SpielInfo(land: "Spanien", kurz: "Spanisches Stichspiel: Gewinne Stiche mit Trumpf und sammle die meisten Augen.", stichworte: ["stiche", "trumpf", "karten", "spanisch", "spanien"]),
        "truco": SpielInfo(land: "Argentinien", kurz: "Stichspiel mit Bluffen: Rufe Truco, erhöhe den Einsatz und täusche den Gegner.", stichworte: ["bluff", "stiche", "karten", "südamerika", "spanisch"]),
        "kartenduell": SpielInfo(land: "Deutschland", kurz: "Zwei treten mit Karten gegeneinander an, die höhere Karte sticht.", stichworte: ["krieg", "karten", "duell", "vergleichen"]),
        "flinkhand": SpielInfo(land: "Deutschland", kurz: "Wer zuerst das passende Tier erkennt, greift zu und gewinnt die Karte.", stichworte: ["reaktion", "schnell", "tiere", "karten", "kinder"]),
        "himmelsleiter": SpielInfo(land: "Indien", kurz: "Würfle dich über das Brett nach oben, Leitern helfen, Schlangen werfen zurück.", stichworte: ["leitern", "schlangen", "würfeln", "kinder", "brettspiel"]),
        "hoelzchen": SpielInfo(land: "China", kurz: "Nimm abwechselnd Hölzchen weg, wer das letzte nimmt, gewinnt oder verliert.", stichworte: ["nim", "streichhölzer", "taktik", "zahlen"]),
        "escoba": SpielInfo(land: "Spanien", kurz: "Nimm Karten vom Tisch, die zusammen 15 ergeben, und sammle Punkte für Escobas.", stichworte: ["fünfzehn", "karten", "spanien", "spanisch", "15"]),
        "pechvogel": SpielInfo(land: "Deutschland", kurz: "Sammle Tierpaare und lass dir nicht den Pechvogel zuschieben.", stichworte: ["schwarzer peter", "paare", "tiere", "karten", "kinder"]),
        "herzensjagd": SpielInfo(land: "USA", kurz: "Stichspiel für vier: Vermeide Herzen und die Pik-Dame, oder schieße den Mond.", stichworte: ["hearts", "herzen", "stiche", "karten", "pik dame"]),
        "stufenstapel": SpielInfo(land: "Deutschland", kurz: "Lege Karten in aufsteigender Reihenfolge auf Stapel und werde deine Karten los.", stichworte: ["stapel", "karten", "reihenfolge", "ablegen"]),
        "kreuzwurf": SpielInfo(land: "Deutschland", kurz: "Würfle und trage die Zahlen so ins Kreuz ein, dass möglichst viele Reihen zählen.", stichworte: ["würfel", "kreuz", "punkte", "kniffel"]),
        "irrgang": SpielInfo(land: "Griechenland", kurz: "Finde den Weg durch das Labyrinth, auf höheren Stufen im Nebel.", stichworte: ["irrgang", "labyrinth", "irrgarten", "maze", "weg", "nebel"]),
        "farbwechsel": SpielInfo(land: "USA", kurz: "Lege Karten gleicher Farbe oder Zahl ab und werde deine Hand zuerst los.", stichworte: ["uno", "ablegen", "karten", "farbe", "familie"]),
    ]
}
