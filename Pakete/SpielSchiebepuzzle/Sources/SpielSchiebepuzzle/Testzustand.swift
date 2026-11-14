// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import SchiebepuzzleKern

/// Nur Debug: Testzustand für `-testZustand`. 3 × 3, gemischt mit festem Zufall aus dem gelösten Brett (95 s Spielzeit, ohne Tipps).
/// kurzVorEnde: acht Mischzüge vom Ziel entfernt. ende: ein Mischzug vom Ziel entfernt; die Ansicht spielt den letzten Zug nach dem Laden selbst.
public enum SchiebepuzzleTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var g = SplitMix64(seed: 9)
        var p = Schiebepuzzle(n: 3)
        p.mischen(zuege: art == .ende ? 1 : 8, mit: &g)
        Testzustand.ablegen(SchiebepuzzleStand(puzzle: p, sekunden: 95, tipps: 0, tag: false), kennung: "schiebepuzzle", spieler: 1)
    }
}
#endif
