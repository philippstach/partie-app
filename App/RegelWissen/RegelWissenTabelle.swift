// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py. Nicht von Hand ändern.
enum RegelWissenTabelle {
    /// Grund-ID → (Name in der App, Regeltext in Abschnitten, drei Beispielfragen). Zehntausend fehlt (KI-2: eigener Chat).
    static let eintraege: [String: (name: String, quelle: String, fragen: [String])] = [
        "solitaer": ("Solitär", RegelWissenText_solitaer.quelle, ["Wie viele Karten decke ich vom Stapel auf?", "Was darf ich beim Klondike in eine leere Spalte legen?", "Welche Karten ergeben bei der Pyramide zusammen 13?"]),
        "maumau": ("Mau-Mau", RegelWissenText_maumau.quelle, ["Was passiert bei einer 7 auf eine 7?", "Darf ich ziehen, obwohl ich eine Karte legen könnte?", "Was ist die Vorlage Wild?"]),
        "schwimmen": ("Schwimmen", RegelWissenText_schwimmen.quelle, ["Was darf ich in meinem Zug machen?", "Wie viel ist ein Ass, ein König und eine 9 wert?", "Darf ich schon im ersten Zug klopfen?"]),
        "elferraus": ("Elfer raus", RegelWissenText_elferraus.quelle, ["Wie viele Karten bekommt jeder am Anfang?", "Muss ich eine Karte legen, wenn eine passt?", "Alle haben nacheinander gepasst. Wie geht es weiter?"]),
        "romme": ("Rommé", RegelWissenText_romme.quelle, ["Wie viele Karten bekomme ich, und wie viele Joker gibt es?", "Darf ich K-A-2 als Folge legen?", "Wie viele Joker darf ein Satz haben?"]),
        "mogeln": ("Mogeln", RegelWissenText_mogeln.quelle, ["Wer darf „Gelogen!“ rufen?", "Wann gilt ein Zug als gelogen?", "Wie wird am Ende gewertet?"]),
        "siebzehnundvier": ("Siebzehn und Vier", RegelWissenText_siebzehnundvier.quelle, ["Was ist das Ziel von Siebzehn und Vier?", "Die Bank hat Ass und 6. Zieht sie noch?", "Welche Start-Chips kann ich wählen?"]),
        "herzensjagd": ("Herzensjagd", RegelWissenText_herzensjagd.quelle, ["Wer beginnt die Runde?", "Wie viele Punkte zählen Herz und Pik-Dame?", "Wann sind Herzen zum Ausspielen offen?"]),
        "yacht": ("Yacht", RegelWissenText_yacht.quelle, ["Wie läuft ein Zug bei Yacht ab?", "Ich habe 3-3-3-5-5 geworfen. Was bringt Full House?", "Wann ist das Spiel zu Ende?"]),
        "schocken": ("Schocken", RegelWissenText_schocken.quelle, ["Wie viele Würfel und wie viele Würfe hat man bei Schocken?", "Ich habe 1-1-6 geworfen. Wie viele Deckel ist das wert?", "Darf ich alle drei Würfel herauslegen?"]),
        "maexchen": ("Mäxchen", RegelWissenText_maexchen.quelle, ["Wie läuft eine Runde ab?", "Wie ist die Rangfolge der Würfe?", "Darf ich weniger ansagen, als ich gewürfelt habe?"]),
        "chicago": ("Chicago", RegelWissenText_chicago.quelle, ["Wie viele Runden hat Chicago?", "Zielzahl ist 7 und ich würfle 3 und 4. Wie viele Punkte?", "Welche Zielzahl gilt in der ersten Runde?"]),
        "pokerwurf": ("Pokerwurf", RegelWissenText_pokerwurf.quelle, ["Welche Hand ist die stärkste?", "Schlägt ein Full House eine große Straße?", "Mit wie vielen Würfeln und wie oft darf ich würfeln?"]),
        "koenigsweg": ("Königsweg", RegelWissenText_koenigsweg.quelle, ["Was ist das Ziel von Königsweg?", "Muss ich ziehen oder darf ich passen?", "Was ist, wenn ich nicht ziehen kann?"]),
        "sudoku": ("Sudoku", RegelWissenText_sudoku.quelle, ["Wie funktioniert Sudoku?", "Wie viele Fehler darf ich machen, bis ich verloren habe?", "Was bringt mir der Tipp?"]),
        "minensuche": ("Minensuche", RegelWissenText_minensuche.quelle, ["Wie funktioniert Minensuche?", "Kann der erste Zug schon eine Mine treffen?", "Was passiert, wenn ich eine Mine treffe?"]),
        "kakuro": ("Kakuro", RegelWissenText_kakuro.quelle, ["Wie funktioniert Kakuro?", "Welche Hinweiszahl gilt waagrecht und welche senkrecht?", "Welche Ziffern ergeben 16 über zwei Feldern?"]),
        "schiebepuzzle": ("Schiebepuzzle", RegelWissenText_schiebepuzzle.quelle, ["Was muss ich beim Schiebepuzzle erreichen?", "Wie bewege ich eine Kachel?", "Wonach wird beim Schiebepuzzle gewertet?"]),
        "irrgang": ("Labyrinth", RegelWissenText_irrgang.quelle, ["Was ist das Ziel im Labyrinth?", "Wie bewege ich den Läufer?", "Ich wische gegen eine Wand. Was passiert?"]),
        "farbflut": ("Farbfüller", RegelWissenText_farbflut.quelle, ["Was ist das Ziel bei Farbfüller?", "Wo beginnt die Flut?", "Was zeigt mir der Tipp?"]),
        "viererreihe": ("Viererreihe", RegelWissenText_viererreihe.quelle, ["Wie groß ist das Brett?", "Gilt auch eine Diagonale?", "Wo stelle ich die Stärke des Computers ein?"]),
        "rauswurf": ("Rauswurf", RegelWissenText_rauswurf.quelle, ["Wie bekomme ich eine Figur aus dem Haus?", "Was passiert, wenn ich auf eine fremde Figur lande?", "Was ändert die Spielart Kinder?"]),
        "muehle": ("Mühle", RegelWissenText_muehle.quelle, ["Wie viele Steine hat jeder Spieler?", "Was ist eine Mühle?", "Gilt Stellungswiederholung als Remis?"]),
        "galgenmaennchen": ("Galgenmännchen", RegelWissenText_galgenmaennchen.quelle, ["Wie viele Fehler darf ich machen?", "Was kostet ein falscher Lösungsversuch?", "Zählt ß als eigener Buchstabe?"]),
        "wortpfeil": ("Kreuzworträtsel", RegelWissenText_wortpfeil.quelle, ["Wie funktioniert ein Kreuzworträtsel mit Pfeilen hier?", "Wann ist das Rätsel gelöst?", "Wann bekomme ich den Stern?"]),
    ]
}
