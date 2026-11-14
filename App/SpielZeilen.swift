// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Gemeinsame Hilfen der Sammlungs-Blätter: Spielzeile und Spielerzahl-Text für ein Modul, Gruppen nach Spielart.
@MainActor
enum SpielZeilen {
    /// Reihenfolge der Spielarten in Listen (wie die Chips auf dem Start).
    /// B12-S2-018: Nur Spielarten, zu denen es sichtbare Spiele gibt (ohne Entwicklermodus also kein leerer Arcade-Chip).
    static var spielarten: [Gattung] {
        let alle: [Gattung] = [.karten, .wuerfel, .brett, .raetsel, .wort, .arcade]
        let da = Set(SpielKatalog.sichtbar.map(\.gattung))
        return alle.filter { da.contains($0) }
    }

    static func spielerText(_ m: any SpielModul) -> String {
        let z = m.spielerzahl
        return z.lowerBound == z.upperBound ? String(localized: "\(z.lowerBound) Spieler") : String(localized: "\(z.lowerBound)–\(z.upperBound) Spieler")
    }

    /// Helle Spielzeile für Blätter: Spielart-Farbe, Miniatur, Name, Untertitel (Vorgabe: Spielart · Spieler).
    @MainActor
    static func zeile(_ m: any SpielModul, untertitel: Text? = nil, favorit: Bool = false, aktion: @escaping () -> Void) -> some View {
        SpielZeile(name: m.name, untertitel: untertitel ?? Text("\(m.gattung.anzeigeName) · \(spielerText(m))"),
                   farbe: m.gattung.farbe.color, miniatur: SpielMiniaturen.art(m), favorit: favorit, hell: true, aktion: aktion)
    }

    /// Spiele nach Spielart gruppiert, mit Überschrift je Gruppe (leere Gruppen entfallen).
    @MainActor
    static func gruppen(_ module: [any SpielModul], @ViewBuilder zeile: @escaping (any SpielModul) -> some View) -> some View {
        ForEach(spielarten, id: \.self) { g in
            let teil = module.filter { $0.gattung == g }
            if !teil.isEmpty {
                SpielartLabel(text: Text("\(g.anzeigeName) · \(teil.count)"), farbe: g.farbe.color).padding(.top, 8)
                ForEach(teil, id: \.id) { m in zeile(m) }
            }
        }
    }
}
