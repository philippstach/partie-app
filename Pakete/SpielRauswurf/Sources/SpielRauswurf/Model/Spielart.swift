// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Fertige Regelsätze (SPEZIFIKATION 6.1). Ein Tipp setzt alle Schalter; wer danach einzeln etwas ändert, spielt „Eigene Regeln“.
enum Spielart: String, CaseIterable, Identifiable, Sendable {
    case familie, offiziell, kinder, schnell, streng

    var id: String { rawValue }

    var optionen: Optionen {
        var o = Optionen()
        switch self {
        case .familie: break
        case .offiziell: o.startMitFigur = true; o.dreiVersuche = false
        case .kinder: o.rauswerfen = false
        case .schnell: o.figuren = 2; o.startMitFigur = true
        case .streng: o.schlagpflicht = true; o.zielUeberspringen = false
        }
        return o
    }

    /// Welche Spielart die Optionen genau treffen, sonst nil („Eigene Regeln“).
    static func erkennen(_ o: Optionen) -> Spielart? {
        allCases.first { $0.optionen == o }
    }
}
