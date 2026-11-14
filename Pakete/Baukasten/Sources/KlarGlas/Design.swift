// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// DIE zentrale Stelle für das Aussehen (Design-Umbau 09.11.2026).
// Hier stehen Farben, Abstandsstufen, Eckenstufen und die drei Regler. Ändert man hier einen Wert, ändert er sich überall,
// wo er benutzt wird. Die Voreinstellung ergibt exakt das bisherige Aussehen (Regler = 1,0).
// App-spezifische Zahlen (z. B. Brettgrößen) gehören NICHT hierher, sondern bleiben im Spiel (`// design:spielinhalt`).

/// `Design` unter einem Namen, der auch in Erweiterungen von `Font` eindeutig ist: dort meint `Design` sonst `Font.Design`
/// (`design: KlarGlasDesign.zahlDesign`). Das Umstell-Skript `design_farben_umstellen.py` setzt in solchen Dateien diesen Namen ein.
public typealias KlarGlasDesign = Design

public enum Design {

    // MARK: Farben

    /// Die Farben der Hülle (Partie). Ein Hex-Wert ändern = überall geändert.
    public enum Farbe {
        /// Akzent der Hülle im hellen Modus (Design-SOLL 1658D8).
        public static let akzentHell: UInt32 = 0x1658D8
        /// Akzent der Hülle im dunklen Modus.
        public static let akzentDunkel: UInt32 = 0x6FA8FF
    }

    // MARK: Regler (Voreinstellung 1,0 = heutiges Aussehen; gespeichert, wirkt ab der nächsten Ansicht)

    public enum Regler {
        public static let abstandKey = "design.regler.abstand"
        public static let eckenKey = "design.regler.ecken"
        public static let schriftKey = "design.regler.schrift"

        /// Faktor für alle Standardabstände (0,75 … 1,5).
        public static var abstand: Double {
            get { lesen(abstandKey) }
            set { schreiben(abstandKey, newValue) }
        }
        /// Faktor für alle Standardecken (0 … 1,5).
        public static var ecken: Double {
            get { lesen(eckenKey, bereich: 0...1.5) }
            set { schreiben(eckenKey, newValue, bereich: 0...1.5) }
        }
        /// Faktor für die Schriftgrößen der festen Titel (0,85 … 1,25).
        public static var schrift: Double {
            get { lesen(schriftKey, bereich: 0.85...1.25) }
            set { schreiben(schriftKey, newValue, bereich: 0.85...1.25) }
        }
        public static func zuruecksetzen() {
            for k in [abstandKey, eckenKey, schriftKey] { UserDefaults.standard.removeObject(forKey: k) }
        }

        static func lesen(_ key: String, bereich: ClosedRange<Double> = 0.75...1.5) -> Double {
            guard let w = UserDefaults.standard.object(forKey: key) as? Double else { return 1 }
            return min(max(w, bereich.lowerBound), bereich.upperBound)
        }
        static func schreiben(_ key: String, _ wert: Double, bereich: ClosedRange<Double> = 0.75...1.5) {
            UserDefaults.standard.set(min(max(wert, bereich.lowerBound), bereich.upperBound), forKey: key)
        }
    }

    // MARK: Abstandsstufen (Grundwerte im 4-pt-Raster, mal Regler)

    public enum Abstand {
        public static var xs: CGFloat { 4 * f }
        public static var s: CGFloat { 8 * f }
        public static var m: CGFloat { 12 * f }
        public static var l: CGFloat { 16 * f }
        public static var xl: CGFloat { 24 * f }
        /// Seitenrand je Design (klar 16, Tinte 20, Salon 22), mal Regler.
        public static var seite: CGFloat { Design.werte.seitenRand * f }
        private static var f: CGFloat { CGFloat(Regler.abstand) }
    }

    // MARK: Eckenstufen (mal Regler)

    public enum Ecke {
        // Grundwerte je Design aus `DesignWerte` (klar 8/12/20/28/32, Tinte 4/4/0/0/16, Salon 2/2/0/0/0).
        public static var klein: CGFloat { Design.werte.eckeKlein * f }
        public static var feld: CGFloat { Design.werte.eckeFeld * f }
        public static var karte: CGFloat { Design.werte.eckeKarte * f }
        public static var leiste: CGFloat { Design.werte.eckeLeiste * f }
        public static var sheet: CGFloat { Design.werte.eckeSheet * f }
        private static var f: CGFloat { CGFloat(Regler.ecken) }
    }

    // MARK: Schrift (Rollen je Design; nur Apple-Schriften: SF und New York = Serifenschrift des Systems)

    public enum Schrift {
        /// Größe der großen Startseiten-Überschrift (klar 56 pt fett, Tinte 46 medium, Salon 72 fett), mal Regler.
        public static var titel: CGFloat { Design.werte.titelGroesse * CGFloat(Regler.schrift) }
        /// Laufweite des Titels in Punkt bei der Größe `groesse`.
        public static func titelLaufweite(_ groesse: CGFloat) -> CGFloat { Design.werte.titelLaufweite * groesse }
        /// Schrift des Start-Titels in der (schon skalierten) Größe.
        public static func titelSchrift(_ groesse: CGFloat) -> Font {
            let w = Design.werte
            return .system(size: groesse, weight: w.titelGewicht, design: w.serif ? .serif : .default)
        }

        /// Größe der Sieger-Schlagzeile (klar largeTitle = 34, Tinte 54, Salon 84), mal Regler.
        public static var schlagzeile: CGFloat { Design.werte.schlagzeileGroesse * CGFloat(Regler.schrift) }
        /// Schrift der Schlagzeile. Ohne Größe: die Rollengröße, mit Dynamic Type (höchstens × 1,25).
        public static func schlagzeileSchrift(_ groesse: CGFloat? = nil) -> Font {
            let w = Design.werte
            guard w.art != .klar else {
                return groesse.map { .system(size: $0, weight: .bold) } ?? .system(.largeTitle, design: .default).weight(.bold)
            }
            return .system(size: groesse ?? skaliert(schlagzeile, .largeTitle, hoechstens: 1.25), weight: w.schlagzeileGewicht, design: .serif)
        }

        /// Spielname in Listen (klar title3 fett, Tinte New York 21 medium, Salon New York 24 halbfett).
        public static var name: Font {
            let w = Design.werte
            guard w.art != .klar else { return .title3.weight(.bold) }
            return .system(size: skaliert(w.nameGroesse, .title3), weight: w.nameGewicht, design: .serif)
        }
        /// Nebenzeile unter Titeln (klar title3, Tinte New York 18 kursiv, Salon New York 20 leicht kursiv). Farbe: `schriftZweit`.
        public static var neben: Font {
            let w = Design.werte
            guard w.art != .klar else { return .title3 }
            return .system(size: skaliert(w.nebenGroesse, .title3), weight: w.art == .salon ? .light : .regular, design: .serif).italic()
        }
        /// Abschnitts-Label (klar caption halbfett, sonst SF 11 fett; immer in Großbuchstaben setzen).
        public static var label: Font {
            guard Design.werte.art != .klar else { return .caption.weight(.semibold) }
            return .system(size: skaliert(11, .caption, hoechstens: 2.2), weight: .bold)   // 2.34 N-020: wächst bei großer Schrift mit
        }
        /// Sperrung des Labels in Punkt (klar 0, Tinte 0,12 em, Salon 0,14 em).
        public static var labelSperrung: CGFloat { Design.werte.labelSperrung * 11 }
        /// Zahlen (klar SF Rounded, Tinte New York mit Tabellenziffern, Salon New York fett).
        public static func zahl(_ stil: Font.TextStyle = .body) -> Font {
            switch Design.werte.art {
            case .klar: .system(stil, design: .rounded)
            case .tinte: .system(stil, design: .serif).monospacedDigit()
            case .salon: .system(stil, design: .serif).weight(.bold)
            }
        }
        /// Serifenschrift (New York) in fester Größe, die mit Dynamic Type mitwächst. In `klar` die Systemschrift.
        public static func serif(_ groesse: CGFloat, gewicht: Font.Weight = .regular, relativ stil: Font.TextStyle = .body,
                                 kursiv: Bool = false, hoechstens: CGFloat = 1.35) -> Font {
            let f = Font.system(size: skaliert(groesse, stil, hoechstens: hoechstens), weight: gewicht,
                                design: Design.werte.serif ? .serif : .default)
            return kursiv ? f.italic() : f
        }
        /// Systemschrift (SF) in fester Größe, die mit Dynamic Type mitwächst (Labels, Knopfschrift der neuen Designs).
        public static func text(_ groesse: CGFloat, gewicht: Font.Weight = .regular, relativ stil: Font.TextStyle = .body,
                                hoechstens: CGFloat = 1.35) -> Font {
            .system(size: skaliert(groesse, stil, hoechstens: hoechstens), weight: gewicht)
        }

        /// Tinte und Salon in der breiten Größenklasse (iPad): feste Schriften um ein Fünftel größer; sonst 1.
        static var breitFaktor: CGFloat { Design.art != .klar && DesignWahl.geteilt.breit ? 1.2 : 1 }

        /// Größe mit der Schriftgröße des Geräts skaliert (Dynamic Type), nach oben begrenzt wie `StartTitel` (Faktor `hoechstens`).
        public static func skaliert(_ groesse: CGFloat, _ stil: Font.TextStyle = .body, hoechstens: CGFloat = 1.35) -> CGFloat {
            #if canImport(UIKit)
            let ui: UIFont.TextStyle
            switch stil {
            case .largeTitle: ui = .largeTitle
            case .title: ui = .title1
            case .title2: ui = .title2
            case .title3: ui = .title3
            case .headline: ui = .headline
            case .subheadline: ui = .subheadline
            case .callout: ui = .callout
            case .footnote: ui = .footnote
            case .caption: ui = .caption1
            case .caption2: ui = .caption2
            default: ui = .body
            }
            return min(UIFontMetrics(forTextStyle: ui).scaledValue(for: groesse), groesse * hoechstens) * breitFaktor
            #else
            return groesse
            #endif
        }
    }

    /// Schriftdesign für Zahlen: `.rounded` (klar) bzw. `.serif` (Tinte, Salon). Ersetzt `design: .rounded` in Spielen.
    public static var zahlDesign: Font.Design { Design.werte.zahlDesign }

    // MARK: Größen von Bedienelementen

    public enum Masse {
        public static let tippflaeche: CGFloat = 44
        public static let rundKnopf: CGFloat = 44
        public static let rundKnopfKlein: CGFloat = 36
        public static let hauptKnopfHoehe: CGFloat = 54
        public static let chipHoehe: CGFloat = 28
        public static let breiteSpalte: CGFloat = 640
    }

    // MARK: Knopfstile (zentral austauschbar)

    /// Hilfsschrift fürs Hero-Symbol (Anleitung, leere Zustände); heute 64 pt.
    public static var heldSymbolGroesse: CGFloat { 64 * CGFloat(Regler.schrift) }
}

