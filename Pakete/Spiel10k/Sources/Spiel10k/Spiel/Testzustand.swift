// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG
import SpieleKern
import Foundation

/// Nur Debug: Testzustand für `-testZustand`. Zwei Computer (gut) spielen mit festem Würfelzufall (Seed 8) über den Store, bis die Partie
/// steht; danach sind beide Plätze Menschen („Spieler 1/2“). ende: Partie zu Ende (Endkarte beim Öffnen).
/// kurzVorEnde: Beginn eines Zuges (vor dem Wurf), sobald ein Stand höchstens 1500 Punkte vor dem Ziel liegt.
public enum ZehnKTestzustand {
    private final class Zufall { var g = SplitMix64(seed: 8) }

    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let store = NeuAblage.neuerStore()
        for r in store.pausedGames { store.deleteGame(r.id) }
        let z = Zufall()
        store.roller = { Int.random(in: 1...6, using: &z.g) }
        var spieler = (1...2).map { Player(name: "Spieler \($0)", avatar: "\($0)", colorIndex: $0 - 1) }
        for i in spieler.indices { spieler[i].computer = .gut }
        var settings = GameSettings()
        settings.rules = NeuAblage.regeln()
        settings.diceMode = .digital
        settings.realEntry = .points
        store.startGame(players: spieler, settings: settings)
        var n = 0
        while let g = store.game, !g.finished, n < 30_000 {
            n += 1
            if art == .kurzVorEnde, !g.turn.hasRolled, g.offer == nil, (g.players.map(\.score).max() ?? 0) >= g.settings.goal - 1500 { break }
            store.nieteNotice = nil; store.tiebreakNotice = nil; store.nextPlayerNotice = nil
            store.computerSchritt()
        }
        if var g = store.game {
            for i in g.players.indices { g.players[i].computer = nil }
            store.game = g
        }
        if let gid = store.currentID { SpielStand.sichern(NeuAblage.Marker(spiel: gid), spiel: NeuAblage.id) }
        Testzustand.melden(kennung: NeuAblage.id, spieler: 2)
    }
}
#endif
