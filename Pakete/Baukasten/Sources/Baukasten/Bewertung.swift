// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import StoreKit

/// Wann darf die App um eine Bewertung bitten? Reine Logik, ohne UI, ohne Netz.
public struct BewertungsRegel: Sendable {
    public var mindestStarts = 5
    public var mindestTage = 7
    public var mindestErfolge = 3          // z. B. beendete Partien, seit der letzten Anfrage
    public var abstandTage = 120
    public var hoechstensProJahr = 3       // Apple zeigt den Dialog ohnehin höchstens 3-mal in 365 Tagen
    public init() {}
}

public final class BewertungsZaehler {
    enum Schluessel {
        static let starts = "baukasten.bew.starts"
        static let erster = "baukasten.bew.erster"
        static let erfolge = "baukasten.bew.erfolge"
        static let anfragen = "baukasten.bew.anfragen"   // [Double] Zeitstempel
        static let version = "baukasten.bew.version"
    }

    private let speicher: WerteSpeicher
    private let regel: BewertungsRegel
    private let version: String
    private let jetzt: () -> Date

    public init(speicher: WerteSpeicher = UserDefaults.standard, regel: BewertungsRegel = .init(),
                version: String = AppInfo.version, jetzt: @escaping () -> Date = Date.init) {
        self.speicher = speicher; self.regel = regel; self.version = version; self.jetzt = jetzt
    }

    private func zahl(_ k: String) -> Int { speicher.object(forKey: k) as? Int ?? 0 }
    private var anfragen: [Date] { (speicher.object(forKey: Schluessel.anfragen) as? [Double] ?? []).map { Date(timeIntervalSince1970: $0) } }

    /// Beim Start der App aufrufen.
    public func appGestartet() {
        speicher.set(zahl(Schluessel.starts) + 1, forKey: Schluessel.starts)
        if speicher.object(forKey: Schluessel.erster) == nil { speicher.set(jetzt().timeIntervalSince1970, forKey: Schluessel.erster) }
    }

    /// Nach einem positiven Moment aufrufen (Partie beendet, Rätsel gelöst).
    public func erfolgVerbuchen() { speicher.set(zahl(Schluessel.erfolge) + 1, forKey: Schluessel.erfolge) }

    public func sollFragen() -> Bool {
        let jetzt = self.jetzt()
        guard zahl(Schluessel.starts) >= regel.mindestStarts, zahl(Schluessel.erfolge) >= regel.mindestErfolge else { return false }
        guard let erster = (speicher.object(forKey: Schluessel.erster) as? Double).map(Date.init(timeIntervalSince1970:)),
              jetzt.timeIntervalSince(erster) >= Double(regel.mindestTage) * 86_400 else { return false }
        if speicher.object(forKey: Schluessel.version) as? String == version { return false }   // höchstens einmal je Version
        let bisher = anfragen
        if let letzte = bisher.max(), jetzt.timeIntervalSince(letzte) < Double(regel.abstandTage) * 86_400 { return false }
        if bisher.filter({ jetzt.timeIntervalSince($0) < 365 * 86_400 }).count >= regel.hoechstensProJahr { return false }
        return true
    }

    /// Direkt nach `requestReview()` aufrufen.
    public func angefragtVerbuchen() {
        speicher.set(anfragen.map(\.timeIntervalSince1970) + [jetzt().timeIntervalSince1970], forKey: Schluessel.anfragen)
        speicher.set(version, forKey: Schluessel.version)
        speicher.set(0, forKey: Schluessel.erfolge)
    }
}

public extension View {
    /// Fragt über den System-Dialog nach einer Bewertung, wenn `ausloeser` auf true springt (z. B. Sieger-Bildschirm
    /// erscheint) und die Regel es erlaubt. Keine eigene Vorab-Frage. In Kinder-Apps nicht verwenden.
    func bewertungAnfragen(zaehler: BewertungsZaehler, ausloeser: Bool) -> some View {
        modifier(BewertungsAnfrage(zaehler: zaehler, ausloeser: ausloeser))
    }
}

private struct BewertungsAnfrage: ViewModifier {
    @Environment(\.requestReview) private var requestReview
    let zaehler: BewertungsZaehler
    let ausloeser: Bool

    func body(content: Content) -> some View {
        content.task(id: ausloeser) {
            guard ausloeser, zaehler.sollFragen() else { return }
            try? await Task.sleep(for: .seconds(2))     // erst den Erfolg wirken lassen
            guard !Task.isCancelled else { return }
            requestReview()
            zaehler.angefragtVerbuchen()
        }
    }
}
