// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

extension ComputerTempo {
    /// Pause, wenn ein Computer-Zug endet und der letzte Wurf stehen bleibt (SPEZIFIKATION 15.1)
    var zugEndePause: Duration {
        switch self {
        case .langsam: .milliseconds(2000)
        case .normal: .milliseconds(1500)
        case .schnell: .milliseconds(800)
        }
    }
}

/// Aussehen der Würfel (der goldene Akzent der Oberfläche bleibt).
enum WuerfelStil: String, CaseIterable, Codable {
    case klassisch, gold, nacht, elfenbein
}

/// App-weite Einstellungen, in UserDefaults gesichert. Die Hausregeln gelten ab der nächsten Partie.
@Observable
final class AppPreferences {
    var reduceAnimations: Bool { didSet { defaults.set(reduceAnimations, forKey: "reduceAnimations") } }
    var tempo: ComputerTempo { didSet { defaults.set(tempo.rawValue, forKey: "tempo") } }
    /// Schütteln würfelt (bei VoiceOver immer aus)
    var schuetteln: Bool { didSet { defaults.set(schuetteln, forKey: "schuetteln") } }
    /// Chance zu schlagen, Perzentil und Tipp-Knopf
    var hilfen: Bool { didSet { defaults.set(hilfen, forKey: "hilfen") } }
    /// Kurze Hinweise in der ersten Partie
    var hinweise: Bool { didSet { defaults.set(hinweise, forKey: "hinweise") } }
    /// Hinweise der geführten Partie, die schon gezeigt wurden
    var gezeigteHinweise: Set<String> { didSet { defaults.set(Array(gezeigteHinweise), forKey: "gezeigteHinweise") } }
    var gefuehrtGestartet: Bool { didSet { defaults.set(gefuehrtGestartet, forKey: "gefuehrtGestartet") } }
    /// Neue Menschen starten mit echten Würfeln (statt App-Würfeln)
    var echteWuerfel: Bool { didSet { defaults.set(echteWuerfel, forKey: "echteWuerfel") } }
    /// Bei echten Würfeln jeden Wurf eintippen statt nur das Endergebnis
    var echtWurfFuerWurf: Bool { didSet { defaults.set(echtWurfFuerWurf, forKey: "echtWurfFuerWurf") } }
    var wuerfelStil: WuerfelStil { didSet { defaults.set(wuerfelStil.rawValue, forKey: "wuerfelStil") } }
    var hausregeln: Optionen {
        didSet { if let daten = try? JSONEncoder().encode(hausregeln) { defaults.set(daten, forKey: "hausregeln") } }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func flag(_ key: String, _ fallback: Bool) -> Bool {
            defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
        }
        reduceAnimations = flag("reduceAnimations", false)
        tempo = defaults.string(forKey: "tempo").flatMap(ComputerTempo.init) ?? .normal
        schuetteln = flag("schuetteln", true)
        hilfen = flag("hilfen", true)
        hinweise = flag("hinweise", true)
        gezeigteHinweise = Set(defaults.stringArray(forKey: "gezeigteHinweise") ?? [])
        gefuehrtGestartet = flag("gefuehrtGestartet", false)
        echteWuerfel = flag("echteWuerfel", false)
        echtWurfFuerWurf = flag("echtWurfFuerWurf", false)
        wuerfelStil = defaults.string(forKey: "wuerfelStil").flatMap(WuerfelStil.init) ?? .klassisch
        hausregeln = defaults.data(forKey: "hausregeln").flatMap { try? JSONDecoder().decode(Optionen.self, from: $0) } ?? .standard
    }
}
