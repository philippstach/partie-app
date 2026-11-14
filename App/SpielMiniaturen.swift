// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SpieleKern
import KlarGlas

/// Welche Miniatur (gezeichnetes Spielmaterial) ein Spiel auf der Startseite zeigt. Fehlt ein Eintrag, gilt die Miniatur der Spielart.
/// Neue Spiele tragen hier eine Zeile ein, wenn die Spielart-Vorgabe nicht passt (Schlüssel = `SpielModul.id`).
@MainActor
enum SpielMiniaturen {
    static func art(_ modul: any SpielModul) -> Miniatur { tabelle[modul.id] ?? modul.gattung.miniatur }

    static let tabelle: [String: Miniatur] = [
        // Karten
        "solitaer-neu": .kartenstapel, "farbwechsel": .kartenstapel, "stufenstapel": .kartenstapel, "crazyeights": .kartenstapel,
        "kartenduell": .kartenstapel, "paarsuche": .paare, "pechvogel": .paare, "flinkhand": .paare,
        "mahjongpaare": .paare,
        // K-010: Solitär (Stapel), Mau-Mau (Fächer, Vorgabe), Elfer raus (Reihen) und Schwimmen (Paare) sehen verschieden aus
        "elferraus-neu": .zahlenkarten, "schwimmen-neu": .paare,   // Große Tinte-Runde 14e: nicht mehr das Sudoku-Bild; eigene Miniatur mit Zahlenkarten 10-11-12 braucht einen KlarGlas-Patch (Miniatur.zahlenkarten)
        // Würfel
        "schocken-neu": .becher, "maexchen": .becher, "luegenwuerfel": .becher, "perudo": .becher,
        // Brett
        "schach": .schach, "dame": .brett, "muehle": .ludo, "wendespiel": .brett, "halma": .brett, "fuchsjagd-neu": .brett,
        "rauswurf-neu": .ludo, "himmelsleiter": .ludo, "patolli": .ludo, "backgammon": .ludo, "aceydeucey": .ludo,
        "kalaha": .mulden, "oware": .mulden, "sechseck": .sechseck, "viererreihe-neu": .bildgitter, "domino": .domino, "dominocubano": .domino,
        "koenigsweg": .ludo,
        // Rätsel
        "sudoku-neu": .zahlengitter, "kakuro": .zahlengitter, "ungleichung": .zahlengitter, "zahlenfusion": .bloecke, "schiebepuzzle": .bloecke,
        "nonogramm": .bildgitter, "lichteraus": .bildgitter, "farbraetsel": .bildgitter, "farbcode": .bildgitter, "lagerplatz": .bildgitter,
        "minensuche": .minen, "schiffeversenken": .minen, "bruecken": .minen, "hanoi": .turm, "irrgang": .labyrinth, "hoelzchen": .bloecke,
        "farbflut": .bildgitter, "kreuzwurf": .zahlengitter,
        "kaestchenjagd": .bildgitter, "steckspiel": .bildgitter,
        // Wort
        "wortpfeil": .pfeilraetsel, "galgenmaennchen-neu": .buchstaben, "stadtlandfluss": .buchstaben,   // B12-S2-024: Buchstabenfelder statt der Figur mit Kreuz (sah wie das Venus-Zeichen aus)
        // Arcade
        "mauerbrecher": .ziegel, "steinfall": .bloecke, "dauerlauf": .laeufer, "wolkenhuepfer": .laeufer, "ballwechsel": .schlaeger,
    ]
}
