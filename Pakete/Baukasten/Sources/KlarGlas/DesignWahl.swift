// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import Observation

// Designwechsel (KlarGlas 2.17): Welches der drei Designs gilt. Die Auswahl liegt in `UserDefaults` („design.art“),
// der Halter `DesignWahl.geteilt` ist beobachtbar: jede Ansicht, die in `body` einen Design-Wert liest (Farbe, Ecke,
// Schrift), zeichnet sich beim Wechsel neu. Der Halter ist bewusst nicht an den MainActor gebunden, damit `swift test`
// auf dem Mac ohne Simulator läuft.

/// Die drei Designs. `klar` ist das bisherige Aussehen („Klar & Glas“) und die Voreinstellung.
public enum DesignArt: String, CaseIterable, Identifiable, Sendable {
    case klar, tinte, salon

    public var id: String { rawValue }

    /// Anzeigename in der Auswahl.
    public var name: String {
        switch self {
        case .klar: String(localized: "Klar & Glas", bundle: .module, comment: "Name des Designs Klar & Glas")
        case .tinte: String(localized: "Tinte", bundle: .module, comment: "Name des Designs Tinte")
        case .salon: String(localized: "Salon", bundle: .module, comment: "Name des Designs Salon")
        }
    }

    /// Eine Zeile Beschreibung unter dem Namen.
    public var kurztext: String {
        switch self {
        case .klar: String(localized: "Karten, Glas und kräftige Farben", bundle: .module, comment: "Kurztext Design Klar & Glas")
        case .tinte: String(localized: "Papier, feine Linien, Serifenschrift", bundle: .module, comment: "Kurztext Design Tinte")
        case .salon: String(localized: "Große Farbflächen wie im Magazin", bundle: .module, comment: "Kurztext Design Salon")
        }
    }
}

/// Hält die Auswahl. Beobachtbar über einen von Hand geführten `ObservationRegistrar` (mit Sperre, ohne MainActor).
public final class DesignWahl: Observable, @unchecked Sendable {
    public static let geteilt = DesignWahl()
    /// Schlüssel in `UserDefaults.standard` und (gespiegelt von der App) in der App Group.
    public static let schluessel = "design.art"

    private let registrar = ObservationRegistrar()
    private let sperre = NSLock()
    private let ablage: UserDefaults
    private var wert: DesignArt

    /// `ablage`: wo die Auswahl liegt (Tests geben eine eigene Ablage, damit sie die echte Einstellung nicht anfassen).
    public init(ablage: UserDefaults = .standard) {
        self.ablage = ablage
        self.wert = Self.gespeichert(in: ablage)
    }

    private static let voreinstellungSperre = NSLock()
    nonisolated(unsafe) private static var voreinstellungWert: DesignArt = .klar
    /// Das Design ohne gespeicherte Wahl. Im Baukasten `klar`; eine App setzt hier ihren Standard (Partie: Tinte) mit
    /// `DesignWahl.setzeVoreinstellung(_:)`, am besten als Erstes beim Start.
    public static var voreinstellung: DesignArt {
        voreinstellungSperre.lock(); defer { voreinstellungSperre.unlock() }
        return voreinstellungWert
    }

    /// Setzt die Voreinstellung. Liegt keine gespeicherte Wahl vor, gilt sie sofort (auch wenn `geteilt` schon gebaut ist).
    public static func setzeVoreinstellung(_ art: DesignArt) {
        voreinstellungSperre.lock(); voreinstellungWert = art; voreinstellungSperre.unlock()
        let g = geteilt
        g.sperre.lock(); let alt = g.wert; g.sperre.unlock()
        let neu = gespeichert(in: g.ablage)
        guard alt != neu else { return }
        g.registrar.withMutation(of: g, keyPath: \.art) { g.sperre.lock(); g.wert = neu; g.sperre.unlock() }
    }

    /// Die gespeicherte Auswahl; unbekannte oder fehlende Werte ergeben die Voreinstellung.
    /// `fallsLeer`: statt der Voreinstellung der App (Tests).
    public static func gespeichert(in ablage: UserDefaults = .standard, fallsLeer: DesignArt? = nil) -> DesignArt {
        ablage.string(forKey: schluessel).flatMap(DesignArt.init(rawValue:)) ?? fallsLeer ?? voreinstellung
    }

    private var breitWert = false
    /// Ob die Wurzel in der breiten Größenklasse steht (iPad ohne Split View). In Tinte und Salon werden die festen Schriften dann größer
    /// (`Design.Schrift.skaliert`). Beobachtbar wie `art`; `designWurzel()` setzt es.
    public var breit: Bool {
        get {
            registrar.access(self, keyPath: \.breit)
            sperre.lock(); defer { sperre.unlock() }
            return breitWert
        }
        set {
            sperre.lock(); let alt = breitWert; sperre.unlock()
            guard alt != newValue else { return }
            registrar.withMutation(of: self, keyPath: \.breit) {
                sperre.lock(); breitWert = newValue; sperre.unlock()
            }
        }
    }

    public var art: DesignArt {
        get {
            registrar.access(self, keyPath: \.art)
            sperre.lock(); defer { sperre.unlock() }
            return wert
        }
        set {
            sperre.lock(); let alt = wert; sperre.unlock()
            guard alt != newValue else { return }
            registrar.withMutation(of: self, keyPath: \.art) {
                sperre.lock(); wert = newValue; sperre.unlock()
            }
            ablage.set(newValue.rawValue, forKey: Self.schluessel)   // immer ausdrücklich: eine Wahl überlebt jede Voreinstellung
            KlarGlasHaken.designGewechselt?(newValue)
        }
    }
}

public extension Design {
    /// Solange `false`, steht die Design-Auswahl nur im Abschnitt „Entwickler“ der Einstellungen.
    /// Bei `true` (seit 2.21) steht sie für alle in „Start und Aussehen“ direkt unter „Darstellung“.
    static let umschalterOeffentlich = true

    /// Das gewählte Design (lesen und schreiben). Lesen in `body` macht die Ansicht vom Design abhängig.
    static var art: DesignArt {
        get { DesignWahl.geteilt.art }
        set { DesignWahl.geteilt.art = newValue }
    }

    /// Alle Werte des gewählten Designs.
    static var werte: DesignWerte { DesignWerte.fuer(art) }

    static func ist(_ a: DesignArt) -> Bool { art == a }

    /// Ob das Design gefüllte Karten und Glas zeigt (nur `klar`); Tinte und Salon arbeiten mit Linien und Farbflächen.
    static var mitKarten: Bool { art == .klar }
}

private struct DesignArtSchluessel: EnvironmentKey {
    /// Ohne gesetzten Wert (Vorschau, eigenes Fenster) gilt die gespeicherte Auswahl.
    static var defaultValue: DesignArt { DesignWahl.geteilt.art }
}

public extension EnvironmentValues {
    /// Das Design für diesen Teilbaum. Die App setzt es an der Wurzel (`designWurzel()`); Bausteine lesen es, damit sie
    /// beim Wechsel garantiert neu zeichnen (auch Knopfstile).
    var designArt: DesignArt {
        get { self[DesignArtSchluessel.self] }
        set { self[DesignArtSchluessel.self] = newValue }
    }
}

#if canImport(UIKit)

/// Setzt das Design für einen Teilbaum: Umgebungswert und, in Tinte und Salon, die Schriftfarben als Vordergrund
/// (damit `.primary`, `.secondary`, `.tertiary` tintig bzw. warm werden). In `klar` wird kein Vordergrund gesetzt.
/// Der Vordergrund bleibt bis zum Neuaufbau der Ansicht stehen (kein Umbau mitten im offenen Blatt); die Hülle baut
/// die Wurzel nach einem Wechsel einmal neu auf.
public struct DesignWurzel: ViewModifier {
    @State private var fest = Design.art
    @Environment(\.horizontalSizeClass) private var klasse

    public init() {}

    public func body(content: Content) -> some View {
        Group {
            if fest == .klar {
                content
            } else if fest == .tinte {
                // 2.50 Blatt 24b (ST Stufe 2): In Tinte bekommt jeder blanke `Toggle` den gemeinsamen Schalter (an grün, aus grau,
                // gesperrt blass). Ein näherer Stil (`einstellungsSchalter()`, `BlattSchalterStil`) gewinnt weiter.
                content.foregroundStyle(Color.schrift, Color.schriftZweit, Color.schriftBlass)
                    .toggleStyle(SchalterStil())
            } else {
                content.foregroundStyle(Color.schrift, Color.schriftZweit, Color.schriftBlass)
            }
        }
        .environment(\.designArt, Design.art)
        .onChange(of: klasse, initial: true) { _, k in DesignWahl.geteilt.breit = k == .regular }
    }
}

public extension View {
    /// An die Wurzel der App und an eigene Blätter hängen: setzt `\.designArt` und den Vordergrund des Designs.
    func designWurzel() -> some View { modifier(DesignWurzel()) }
}

public extension Design {
    /// Navigationstitel in Serifenschrift (Tinte, Salon) bzw. Systemschrift (klar). Wirkt auf Leisten, die danach
    /// entstehen; die Hülle ruft es beim Start und bei jedem Wechsel auf.
    @MainActor static func navigationsleisteAnwenden() {
        let leiste = UINavigationBar.appearance()
        guard art != .klar else {
            leiste.titleTextAttributes = nil
            leiste.largeTitleTextAttributes = nil
            return
        }
        func serif(_ stil: UIFont.TextStyle, _ gewicht: UIFont.Weight) -> UIFont {
            let basis = UIFont.preferredFont(forTextStyle: stil)
            let beschreibung = UIFont.systemFont(ofSize: basis.pointSize, weight: gewicht).fontDescriptor.withDesign(.serif)
            return beschreibung.map { UIFont(descriptor: $0, size: basis.pointSize) } ?? basis
        }
        let farbe = UIColor(Color.schrift)
        leiste.titleTextAttributes = [.font: serif(.headline, .semibold), .foregroundColor: farbe]
        // 2.49: Großer Serifentitel (z. B. „Einstellungen“) wächst bei großer Schrift höchstens auf 34 pt, sonst wird er abgeschnitten.
        let gross = serif(.largeTitle, art == .salon ? .bold : .medium)
        let begrenzt = UIFont(descriptor: gross.fontDescriptor, size: min(gross.pointSize, 34))
        leiste.largeTitleTextAttributes = [.font: begrenzt, .foregroundColor: farbe]
    }
}

#endif
