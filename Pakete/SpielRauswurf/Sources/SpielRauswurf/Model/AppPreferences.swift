// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SpieleKern
import Foundation
import KlarGlas
import Observation

/// App-weite Einstellungen, in UserDefaults gesichert. Die Hausregeln gelten ab der nächsten Partie.
@MainActor
@Observable
final class AppPreferences {
    var animationen: Bool { didSet { defaults.set(animationen, forKey: "animationen") } }
    var autoZug: Bool { didSet { defaults.set(autoZug, forKey: "autoZug") } }
    /// Würfelart, die neue menschliche Spieler bekommen
    /// Würfelart aus der gemeinsamen Wahl auf dem Spielstart (Karte „Würfel“), sonst der alte Standard.
    var wuerfelWahl: Wuerfelart { WuerfelWahl.quelle("rauswurf", vorgabe: wuerfelStandard == .echt ? .echt : .app) == .echt ? .echt : .app }
    var wuerfelStandard: Wuerfelart { didSet { defaults.set(wuerfelStandard.rawValue, forKey: "wuerfelStandard") } }
    /// Hinweis „Gib das iPhone an …“, wenn nach einem Menschen ein anderer Mensch dran ist
    var weitergeben: Bool { didSet { defaults.set(weitergeben, forKey: "weitergeben") } }
    /// Optik des Bretts ("Klar" oder "Warm")
    var brett: BrettThemaArt { didSet { defaults.set(brett.rawValue, forKey: "brett") } }
    var theme: BrettTheme { BrettTheme.thema(brett) }
    var tempo: ComputerTempo { didSet { defaults.set(tempo.rawValue, forKey: "tempo") } }
    var hausregeln: Optionen {
        didSet { if let daten = try? JSONEncoder().encode(hausregeln) { defaults.set(daten, forKey: "hausregeln") } }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func flag(_ key: String, _ fallback: Bool) -> Bool {
            defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
        }
        animationen = flag("animationen", true)
        autoZug = flag("autoZug", true)
        brett = defaults.string(forKey: "brett").flatMap(BrettThemaArt.init) ?? .klar
        weitergeben = flag("weitergeben", true)
        wuerfelStandard = defaults.string(forKey: "wuerfelStandard").flatMap(Wuerfelart.init) ?? .app
        tempo = defaults.string(forKey: "tempo").flatMap(ComputerTempo.init) ?? .normal
        hausregeln = defaults.data(forKey: "hausregeln").flatMap { try? JSONDecoder().decode(Optionen.self, from: $0) } ?? .standard
    }
}
