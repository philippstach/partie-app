// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Solitär (Blatt 22, Paket EB-1, Schritt 1). Nicht syntaxgeprüft.
import SwiftUI
import KlarGlas
import SpieleKern

/// Ergebnisseite: Werte und Bild vom Ende. Das Bild nimmt nur Werte entgegen (keine Bindungen, keine Gesten).
@MainActor
enum NeuEndeInhalt {
    /// Zwei bis drei Wertzeilen: Zeit, Züge, Punkte (nur wenn die Variante Punkte zählt).
    static func werte(_ s: any GameSession) -> [EndeWert] {
        var w = [EndeWert("Zeit", Zeitformat.text(s.elapsed)), EndeWert("Züge", "\(s.moves)")]
        if let p = s.displayScore { w.append(EndeWert("Punkte", "\(p)")) }
        return w
    }

    /// Die vollen Ablagestapel: oberste Karte je Stapel. Nach einem Sieg liegt auf jedem Stapel der König, deshalb zeigt das Bild
    /// vier Könige. Varianten ohne Ablagestapel (Spider, Golf, Pyramide, TriPeaks) bekommen kein Bild.
    static func bild(_ modus: GameMode, vierFarben: Bool) -> EndeBild? {
        guard [.klondike, .freecell, .yukon].contains(modus.kind) else { return nil }
        let karten = Suit.allCases.map { CardFace(rank: 13, suit: $0) }
        return EndeBild(Text("Ablagestapel am Ende"), hoehe: 150) { groesse in
            let luecke: CGFloat = 10
            let breite = min(max((groesse.width - 3 * luecke) / 4, 30), 74)
            HStack(spacing: luecke) {
                ForEach(karten, id: \.suit) { k in CardFaceView(face: k, width: breite, fourColor: vierFarben).frame(width: breite, height: breite * 1.4) }
            }
            .frame(width: groesse.width, height: groesse.height)
        }
    }
}
