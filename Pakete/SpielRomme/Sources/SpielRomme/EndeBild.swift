// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Rommé (Blatt 22, Paket EB-1, Schritt 1). Nicht syntaxgeprüft.
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import RommeKern

/// Bild vom Ende: die Auslagen auf dem Tisch (alle, das Spiel merkt sich nicht, wer sie ausgelegt hat), höchstens drei Reihen, dann „+2 weitere“.
/// Nimmt nur Werte (Karten), keine Bindungen und keine Gesten.
enum RommeEndeBild {
    /// `nil`, wenn nichts ausliegt. Kennt das Spiel den Besitzer (`von`) und hat der Sieger Auslagen gelegt, zeigt das Bild nur seine
    /// („Spieler 1 hat ausgelegt“); sonst alle Auslagen wie in Schritt 1.
    static func bild(tisch: [[RKarte]], von: [Int]?, sieger: Int, siegerName: String) -> EndeBild? {
        guard !tisch.isEmpty else { return nil }
        var titel: Text? = nil
        var reihen = tisch
        if let von, von.count == tisch.count {
            let eigene = tisch.indices.filter { von[$0] == sieger }.map { tisch[$0] }
            if !eigene.isEmpty { reihen = eigene; titel = Text("\(siegerName) hat ausgelegt") }
        }
        let gezeigt = reihen
        return EndeBild(Text("Auslagen auf dem Tisch"), hoehe: 150) { groesse in
            let sichtbar = Array(gezeigt.prefix(3))
            let breitste = max(sichtbar.map(\.count).max() ?? 1, 1)
            let breite = max(14, min(30, (groesse.width - CGFloat(breitste - 1) * 2) / CGFloat(breitste)))
            VStack(alignment: .leading, spacing: 6) {
                if let titel { titel.font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Tisch.hinweis) } else { EndeBildTitel("Auf dem Tisch") }
                ForEach(sichtbar.indices, id: \.self) { m in
                    HStack(spacing: 2) { ForEach(sichtbar[m], id: \.self) { RBild(karte: $0, klein: true, breite: breite) } }
                }
                if gezeigt.count > 3 { Text("+\(gezeigt.count - 3) weitere").font(.system(size: 12, weight: .semibold)).foregroundStyle(Tisch.hinweis) }
            }
            .frame(width: groesse.width, height: groesse.height, alignment: .center)
        }
    }
}
#endif
