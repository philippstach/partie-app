// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG
import Foundation
import SpieleKern
import SpielSolitaer
import SpielMauMau
import SpielSchwimmen
import SpielElferRaus
import SpielRomme
import SpielMogeln
import SpielSiebzehn
import SpielHerzensjagd
import SpielYacht
import SpielSchocken
import Spiel10k
import SpielMaexchen
import SpielChicago
import SpielPokerwurf
import SpielKoenigsweg
import SpielSudoku
import SpielMinensuche
import SpielKakuro
import SpielSchiebepuzzle
import SpielIrrgang
import SpielFarbflut
import SpielViererreihe
import SpielRauswurf
import SpielMuehle
import SpielGalgenmaennchen
import SpielWortpfeil

/// Nur Debug-Bauten: Startargument `-testZustand kurzVorEnde|ende` zusammen mit `-startetMit <spiel-id>`.
/// Legt vor dem Öffnen des Spiels einen Spielstand ab, der über die normale Spiellogik (feste Zugfolge, festgelegter Zufall) kurz vor dem
/// Ende oder am Ende steht, und lässt den Rahmen das Spiel direkt weiterspielen. Liste je Spiel: TESTZUSTAENDE.md.
/// In Release-Bauten gibt es diese Datei nicht (`#if DEBUG`), ebenso wenig die Anbieter in den Spielpaketen.
@MainActor
enum Testzustaende {
    static func vorbereiten(_ id: String) {
        guard let art = Testzustand.art else { return }
        let grund = id.hasSuffix("-neu") ? String(id.dropLast(4)) : id
        switch grund {
        case "solitaer": SolitaerTestzustand.ablegen(art)
        case "maumau": MauMauTestzustand.ablegen(art)
        case "schwimmen": SchwimmenTestzustand.ablegen(art)
        case "elferraus": ElferRausTestzustand.ablegen(art)
        case "romme": RommeTestzustand.ablegen(art)
        case "mogeln": MogelnTestzustand.ablegen(art)
        case "siebzehnundvier": SiebzehnTestzustand.ablegen(art)
        case "herzensjagd": HerzensjagdTestzustand.ablegen(art)
        case "yacht": YachtTestzustand.ablegen(art)
        case "schocken": SchockenTestzustand.ablegen(art)
        case "10k": ZehnKTestzustand.ablegen(art)
        case "maexchen": MaexchenTestzustand.ablegen(art)
        case "chicago": ChicagoTestzustand.ablegen(art)
        case "pokerwurf": PokerwurfTestzustand.ablegen(art)
        case "koenigsweg": KoenigswegTestzustand.ablegen(art)
        case "sudoku": SudokuTestzustand.ablegen(art)
        case "minensuche": MinensucheTestzustand.ablegen(art)
        case "kakuro": KakuroTestzustand.ablegen(art)
        case "schiebepuzzle": SchiebepuzzleTestzustand.ablegen(art)
        case "irrgang": IrrgangTestzustand.ablegen(art)
        case "farbflut": FarbflutTestzustand.ablegen(art)
        case "viererreihe": ViererreiheTestzustand.ablegen(art)
        case "rauswurf": RauswurfTestzustand.ablegen(art)
        case "muehle": MuehleTestzustand.ablegen(art)
        case "galgenmaennchen": GalgenmaennchenTestzustand.ablegen(art)
        case "wortpfeil": WortpfeilTestzustand.ablegen(art)
        default: break
        }
    }
}
#endif
