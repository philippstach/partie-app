// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation
import SwiftUI

/// Würfel per Sprache ansagen (KI-9). Der Kern kennt weder Mikrofon noch `WuerfelScan`: Die App setzt die Haken beim Start
/// (`AnsageEinsetzen`). Ohne Haken oder ohne Spracherkennung auf dem Gerät erscheint kein Knopf.
public enum WuerfelAnsageHaken {
    public enum Ausgang: Equatable, Sendable { case beendet, verweigert, nichtVerfuegbar }
    /// Hört zu, meldet laufend die bisher verstandenen Augen (höchstens `hoechstens`) und kehrt zurück, sobald die Ansage zu Ende ist.
    public typealias Hoeren = @MainActor (_ hoechstens: Int, _ laufend: @escaping @MainActor ([Int]) -> Void) async -> Ausgang

    /// Ob dieses Gerät Ansagen in der App-Sprache auf dem Gerät erkennen darf und kann (nicht im Kinder-Modus).
    nonisolated(unsafe) public static var verfuegbar: (@MainActor () -> Bool)?
    nonisolated(unsafe) public static var hoeren: Hoeren?
    /// Beendet das Zuhören von Hand („Fertig“, Blatt geht zu).
    nonisolated(unsafe) public static var stoppen: (@MainActor () -> Void)?

    @MainActor public static var angeboten: Bool { hoeren != nil && (verfuegbar?() ?? false) }
}

/// Regel „Die Ansage füllt nur leere Felder“ (Philipp 13.11. 11:56): Merkt sich beim Start, welche Plätze leer waren;
/// die angesagten Augen kommen der Reihe nach nur dorthin. Was schon steht, bleibt. Reine Logik, ohne Mikrofon testbar.
public struct AnsageFuellung: Equatable, Sendable {
    /// Positionen, die beim Start leer waren.
    public let leer: [Int]
    public init(plaetze: [Int?]) { leer = plaetze.indices.filter { plaetze[$0] == nil } }
    /// So viele Augen können noch angesagt werden.
    public var anzahl: Int { leer.count }

    /// Legt `augen` (nur 1…6) der Reihe nach auf die ursprünglich leeren Plätze. Plätze ohne passendes Auge werden wieder leer.
    public func anwenden(augen: [Int], auf plaetze: [Int?]) -> [Int?] {
        var neu = plaetze
        for (i, platz) in leer.enumerated() where neu.indices.contains(platz) {
            neu[platz] = augen.indices.contains(i) && (1...6).contains(augen[i]) ? augen[i] : nil
        }
        return neu
    }
}

/// Steuert eine Ansage für eine Reihe von Plätzen (`Binding<[Int?]>`). Zeigt „Ich höre zu“ und die Hinweise nach dem Ende.
/// Texte sind dieselben wie im Yacht-Eingabeblatt (schon übersetzt).
@MainActor @Observable
public final class AnsageSteuerung {
    public private(set) var hoert = false
    public private(set) var hinweis: String?
    /// Hat die Ansage in dieser Steuerung mindestens ein Auge eingetragen? (Für das Merken der Eingabeart: ein ganz von Hand getippter Wurf vergisst sie.)
    public private(set) var hatEingetragen = false
    private var aufgabe: Task<Void, Never>?

    public init() {}

    public var angeboten: Bool { WuerfelAnsageHaken.angeboten }

    /// Hört zu und legt die verstandenen Augen in die leeren Plätze. Ohne leeren Platz oder ohne Haken passiert nichts.
    public func starten(plaetze: Binding<[Int?]>) {
        guard !hoert, let hoeren = WuerfelAnsageHaken.hoeren else { return }
        let fuellung = AnsageFuellung(plaetze: plaetze.wrappedValue)
        guard fuellung.anzahl > 0 else { return }
        hinweis = nil
        hoert = true
        aufgabe = Task { [weak self] in
            var verstanden = 0
            let ausgang = await hoeren(fuellung.anzahl) { augen in
                verstanden = augen.count
                if !augen.isEmpty { self?.hatEingetragen = true }
                plaetze.wrappedValue = fuellung.anwenden(augen: augen, auf: plaetze.wrappedValue)
            }
            guard let self else { return }
            self.hoert = false
            self.hinweis = Self.hinweis(ausgang, verstanden: verstanden, erwartet: fuellung.anzahl)
            self.aufgabe = nil
        }
    }

    /// Nach einem übernommenen Wurf: Der nächste Wurf zählt wieder von vorn (für das Merken der Eingabeart).
    public func vergesseEintrag() { hatEingetragen = false }

    /// „Fertig“ oder Blatt schließt: Zuhören beenden. Der Hinweis nach dem Ende kommt von selbst.
    public func stoppen() {
        guard hoert else { return }
        WuerfelAnsageHaken.stoppen?()
    }

    /// Blatt geht weg: Zuhören beenden, ohne noch etwas anzuzeigen.
    public func abbrechen() {
        WuerfelAnsageHaken.stoppen?()
        aufgabe?.cancel()
        aufgabe = nil
        hoert = false
    }

    nonisolated static func hinweis(_ ausgang: WuerfelAnsageHaken.Ausgang, verstanden: Int, erwartet: Int) -> String? {
        switch ausgang {
        case .verweigert:
            return String(localized: "Kein Zugriff auf Mikrofon oder Spracherkennung. Erlaube beides in den iOS-Einstellungen unter Partie.")
        case .nichtVerfuegbar:
            return String(localized: "Die Ansage ist auf diesem Gerät gerade nicht verfügbar. Tippe die Augen ein.")
        case .beendet:
            if verstanden == 0 { return String(localized: "Nichts verstanden. Sag die Augen einzeln und deutlich, oder tippe sie ein.") }
            if verstanden < erwartet { return String(localized: "Nicht alle Würfel verstanden. Ergänze die fehlenden mit den Zifferntasten.") }
            return String(localized: "Bitte prüfe die Augen, bevor du den Wurf übernimmst.")
        }
    }
}

/// Welche Eingabeart für echte Würfel zuletzt benutzt wurde (Philipp 13.11.: „für den nächsten Wurf schon gespeichert“).
/// Das Eingabeblatt öffnet beim nächsten Wurf gleich damit (Kamera, Scanner oder Ansage), sofern sie dann verfügbar ist.
/// Tippen ändert nichts daran. Gilt für alle Würfelspiele zusammen und bleibt auf dem Gerät.
public enum WuerfelEingabeArt: String, CaseIterable, Sendable {
    case kamera, scanner, ansage

    static let schluessel = "partie.wuerfel.eingabeart"

    public static func gemerkt(in speicher: UserDefaults = .standard) -> WuerfelEingabeArt? {
        speicher.string(forKey: schluessel).flatMap(WuerfelEingabeArt.init(rawValue:))
    }

    /// Merkt die Art; `nil` vergisst sie.
    public static func merke(_ art: WuerfelEingabeArt?, in speicher: UserDefaults = .standard) {
        if let art { speicher.set(art.rawValue, forKey: schluessel) } else { speicher.removeObject(forKey: schluessel) }
    }
}
