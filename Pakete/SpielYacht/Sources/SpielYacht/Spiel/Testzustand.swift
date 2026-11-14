// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG
import KlarGlas
import SpieleKern
import Foundation

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen, Regeln wie zuletzt gewählt (Vorgabe Kniffel), App-Würfel aus festem Zufall;
/// jeder Zug würfelt einmal und trägt das Feld mit den meisten Punkten ein (normale Store-Aufrufe).
/// kurzVorEnde: Ein Feld fehlt noch, der Spieler ist vor dem Wurf. ende: Alle Felder sind belegt, die Endkarte erscheint beim Öffnen.
public enum YachtTestzustand {
    private final class Zufall { var g = SplitMix64(seed: 21) }

    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let store = NeuAblage.neuerStore()
        for r in store.pausedGames { store.deleteGame(r.id) }
        let z = Zufall()
        store.roller = { Int.random(in: 1...6, using: &z.g) }
        let spieler = (1...2).map { Player(name: "Spieler \($0)", avatar: Design.ist(.tinte) ? Spieler.abzeichen(name: "Spieler \($0)", zeichen: nil) : "\($0)", colorIndex: $0 - 1) }
        store.startGame(players: spieler, settings: GameSettings(rules: NeuAblage.regeln(), diceMode: .digital, dailyKey: nil))
        var schritte = 0
        while let g = store.game, !g.state.finished, schritte < 200 {
            let frei = g.state.players.reduce(0) { $0 + g.state.rules.variant.fields.count - $1.scores.count }
            if art == .kurzVorEnde, frei == 1 { break }
            guard store.roll(), let s = store.game?.state,
                  let feld = s.legalCategories.max(by: { s.potentialScore($0) < s.potentialScore($1) }) else { break }
            store.score(feld)
            schritte += 1
        }
        if let gid = store.game?.id { SpielStand.sichern(NeuAblage.Marker(spiel: gid), spiel: NeuAblage.id) }
        Testzustand.melden(kennung: NeuAblage.id, spieler: 2)
    }
}
#endif
