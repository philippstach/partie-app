// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern


private struct StartSeiteKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    /// Wahr innerhalb der Startseite (z. B. damit Kacheln wissen, dass sie eingebettet sind)
    var startSeite: Bool { get { self[StartSeiteKey.self] } set { self[StartSeiteKey.self] = newValue } }
}

/// Texte der Startseite
enum StartText {
    /// „Klondike · 1 Karte“, bei neuer Partie dazu „· Leicht“
    static func modus(_ mode: GameMode, difficulty: Int?, solvable: Bool) -> String {
        var teile = [mode.kind.title]
        switch mode.kind {
        case .klondike: teile.append(mode.option == 3 ? String(localized: "3 Karten") : String(localized: "1 Karte"))
        case .spider: teile.append(mode.option == 1 ? String(localized: "1 Farbe") : String(localized: "\(mode.option) Farben"))
        case .freecell, .pyramid, .tripeaks, .golf, .yukon: break
        }
        if let difficulty, solvable, DealCatalog.shared.hasLevels(mode) {
            let namen = [String(localized: "Gemischt"), String(localized: "Leicht"), String(localized: "Mittel"), String(localized: "Schwer")]
            if namen.indices.contains(difficulty) { teile.append(namen[difficulty]) }
        }
        return teile.joined(separator: " · ")
    }

    /// Stufe einer lösbaren Partie („Leicht“ …), sonst nil
    static func stufe(_ deal: DealInfo) -> String? {
        guard deal.kind == .solvable, let level = DealCatalog.shared.level(mode: deal.mode, seed: deal.seed) else { return nil }
        switch level {
        case 1: return String(localized: "Leicht")
        case 2: return String(localized: "Mittel")
        case 3: return String(localized: "Schwer")
        default: return nil
        }
    }
}
