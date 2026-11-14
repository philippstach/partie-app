// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Ist der Regel-Chat hier nutzbar? Alles Apple-spezifische steht hinter `#if canImport(FoundationModels)`
/// und `#available(iOS 26)`; die App bleibt ab iOS 17.0. Bei `.hidden` zeigt die Oberfläche nichts an.
public enum RegelChatStatus: Equatable, Sendable {
    /// Bereit
    case available
    /// Das Modell wird noch geladen (Hinweis zeigen)
    case notReady
    /// Apple Intelligence ist in den Einstellungen aus (Hinweis zeigen)
    case notEnabled
    /// Gerät, iOS oder Sprache kann es nicht: kein Knopf, keine Eingabe
    case hidden

    /// Was das Betriebssystem über das Modell meldet, ohne Apple-Typen (damit die Logik ohne Modell testbar ist).
    public enum ModellZustand: Equatable, Sendable {
        case verfuegbar
        case laedt
        case appleIntelligenceAus
        case nichtUnterstuetzt
    }

    /// Reine Entscheidung. Der Chat spricht zuerst nur Deutsch (Regelwissen nur Deutsch): Ist die App in einer
    /// anderen Sprache, bleibt er verborgen (`nurDeutscheApp`). 10k prüft heute nur das Modell (`nurDeutscheApp: false`).
    public static func bestimmen(modell: ModellZustand, modellKannDeutsch: Bool, appSpracheDeutsch: Bool,
                                 nurDeutscheApp: Bool = true) -> RegelChatStatus {
        if nurDeutscheApp && !appSpracheDeutsch { return .hidden }
        switch modell {
        case .verfuegbar: return modellKannDeutsch ? .available : .hidden
        case .laedt: return .notReady
        case .appleIntelligenceAus: return .notEnabled
        case .nichtUnterstuetzt: return .hidden
        }
    }

    /// Ist die Sprache der App Deutsch?
    public static var appSpracheIstDeutsch: Bool {
        (Bundle.main.preferredLocalizations.first ?? Locale.current.identifier).hasPrefix("de")
    }

    /// Zustand des Systemmodells; vor iOS 26 oder ohne FoundationModels immer „nicht unterstützt“.
    public static func systemZustand() -> (zustand: ModellZustand, kannDeutsch: Bool) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            let model = SystemLanguageModel.default
            let deutsch = model.supportsLocale(Locale(identifier: "de_DE"))
            switch model.availability {
            case .available: return (.verfuegbar, deutsch)
            case .unavailable(.modelNotReady): return (.laedt, deutsch)
            case .unavailable(.appleIntelligenceNotEnabled): return (.appleIntelligenceAus, deutsch)
            case .unavailable: return (.nichtUnterstuetzt, deutsch)
            }
        }
        #endif
        return (.nichtUnterstuetzt, false)
    }

    /// Der Zustand jetzt. Hat ein Test oder die Attrappe (`RegelChatUmgebung`) einen Zustand vorgegeben, gilt der.
    public static func aktuell(nurDeutscheApp: Bool = true) -> RegelChatStatus {
        if let vorgabe = RegelChatUmgebung.statusVorgabe { return vorgabe }
        let system = systemZustand()
        return bestimmen(modell: system.zustand, modellKannDeutsch: system.kannDeutsch,
                         appSpracheDeutsch: appSpracheIstDeutsch, nurDeutscheApp: nurDeutscheApp)
    }

    public static var current: RegelChatStatus { aktuell() }

    /// Soll es überhaupt einen Einstieg geben (Knopf)? Bei „lädt“ und „aus“ mit Hinweis, bei „hidden“ nicht.
    public var zeigtEinstieg: Bool { self != .hidden }
    /// Kann jetzt gefragt werden?
    public var kannFragen: Bool { self == .available }
}

/// Umschalter für Tests und den Simulator (dort gibt es meist kein Apple-Intelligence-Modell).
public enum RegelChatUmgebung {
    private static let sperre = NSLock()
    nonisolated(unsafe) private static var vorgabe: RegelChatStatus?

    /// Test oder Attrappe: erzwingt einen Status. `nil` = das System entscheidet.
    public static var statusVorgabe: RegelChatStatus? {
        get {
            sperre.lock()
            defer { sperre.unlock() }
            if let v = vorgabe { return v }
            return attrappeAngefordert ? .available : nil
        }
        set {
            sperre.lock()
            vorgabe = newValue
            sperre.unlock()
        }
    }

    /// Nur in Debug-Bauten: Startargument `-PartieRegelChatAttrappe YES` schaltet im Simulator den Chat
    /// mit der Attrappe (feste Antworten, ohne Modell) frei. In Release-Bauten immer `false`.
    public static var attrappeAngefordert: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "PartieRegelChatAttrappe")
        #else
        return false
        #endif
    }

    /// Die Attrappe für den Simulator: antwortet immer gleich und nennt sich als Attrappe.
    public static func attrappe() -> RegelChatAttrappe {
        RegelChatAttrappe(standard: "Das ist eine Testantwort der Attrappe (kein Apple-Modell).")
    }
}
