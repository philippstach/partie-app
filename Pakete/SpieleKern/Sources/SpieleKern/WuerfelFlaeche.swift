// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

// Designwechsel D.3: Würfel in Tinte und Salon an einer Stelle. In „Klar & Glas“ zeichnen die Spiele ihre Würfel wie bisher.
// Runde 5, KS: `WuerfelSatz` wählt das Würfelbild (Vorgabe `.wieDesign`), noch ohne Auswahl in den Einstellungen.
// Die Farbwerte stehen in der Design-Ebene des Baukastens (`DesignWerte.wuerfel`).

/// Welches Würfelbild gezeichnet wird. `.wieDesign` (Vorgabe) folgt dem Design wie bisher. Gespeichert unter `"wuerfelSatz"`.
public enum WuerfelSatz: String, CaseIterable, Sendable {
    case wieDesign, tinte, klar, salon
    public static let schluessel = "wuerfelSatz"
    public static var aktuell: WuerfelSatz { UserDefaults.standard.string(forKey: schluessel).flatMap(WuerfelSatz.init(rawValue:)) ?? .wieDesign }
    /// Hat jemand einen Würfelsatz gewählt? Ohne Wahl zeichnen alle Stellen wie bisher.
    public static var istGewaehlt: Bool { aktuell != .wieDesign }
    /// Sätze, die zur Wahl stehen (ohne `.wieDesign`).
    public static var wahl: [WuerfelSatz] { [.tinte, .salon] }
    /// Name des Satzes (wie das Design heißt, nicht übersetzt); `.wieDesign` hat keinen eigenen Namen.
    public var name: String? {
        switch self { case .wieDesign: nil; case .tinte: "Tinte"; case .klar: "Klar & Glas"; case .salon: "Salon" }
    }
    public func bild(design: DesignArt) -> DesignArt {
        switch self { case .wieDesign: design; case .tinte: .tinte; case .klar: .klar; case .salon: .salon }
    }
}

/// Würfel im gewählten Design (Tinte, Salon); in „Klar & Glas“ zeichnen die Spiele ihre Würfel wie bisher.
/// Tinte: weißer Würfel mit 1,5-pt-Tinte-Rand, Ecke 8, Augen in Tinte; gehalten = schwarz mit Papier-Augen.
/// Salon: Creme-Würfel ohne Rand, Ecke 4, Augen Espresso (gedacht auf einem Farbband in der Spielart-Farbe);
/// gehalten = Espresso mit Creme-Augen. `augen: nil` zeigt einen noch nicht geworfenen Würfel.
public struct WuerfelFlaeche: View {
    let augen: Int?
    let gehalten: Bool
    let groesse: CGFloat
    /// true = der Würfel liegt auf einem Farbband in der Spielart-Farbe; sonst bekommt der Salon-Würfel eine feine Linie,
    /// weil Creme auf Creme (und Espresso auf Espresso im Dunkeln) sonst nicht zu sehen wäre.
    let aufBand: Bool
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    @AppStorage(WuerfelSatz.schluessel) private var satzGewaehlt = ""   // KS: zeichnet beim Wechsel des Würfelsatzes neu
    @Environment(\.accessibilityReduceMotion) private var wenigerBewegung
    /// Design-Runde 3: kurzer Wurf, wenn sich die Augen ändern (nur Tinte). `kipp` in Grad, `hub` 0…1.
    @State private var kipp: Double = 0
    @State private var hub: CGFloat = 0

    /// Vorschau in der Wahlseite: zeichnet den Satz `satz` statt des gewählten.
    let vorschau: WuerfelSatz?

    public init(augen: Int?, gehalten: Bool = false, groesse: CGFloat = 52, aufBand: Bool = false, vorschau: WuerfelSatz? = nil) {
        self.augen = augen; self.gehalten = gehalten; self.groesse = groesse; self.aufBand = aufBand; self.vorschau = vorschau
    }

    /// Eckenradius des Würfels der Kantenlänge `groesse` (Tinte 8, Salon 4, bezogen auf 52 pt).
    public static func ecke(_ groesse: CGFloat) -> CGFloat { (WuerfelSatz.aktuell.bild(design: Design.werte.art) == .salon ? 4 : 8) * groesse / 52 }

    /// Farbe der Augen des gehaltenen Würfels (für ein Schloss-Symbol und Ähnliches auf dem gehaltenen Würfel).
    public static var augeGehalten: Color { Design.werte.wuerfel?.augeGehalten.color ?? Color.schrift }

    /// Mittelpunkte der Augen im Einheitsquadrat (0…1) je Augenzahl; alle liegen mit Abstand zum Rand. Die eine Tabelle für alle
    /// Würfel-Darstellungen (vorher je eine Kopie in Schocken, Rauswurf, Yacht und 10k).
    public static let punkte: [Int: [CGPoint]] = [
        1: [.init(x: 0.5, y: 0.5)],
        2: [.init(x: 0.28, y: 0.28), .init(x: 0.72, y: 0.72)],
        3: [.init(x: 0.28, y: 0.28), .init(x: 0.5, y: 0.5), .init(x: 0.72, y: 0.72)],
        4: [.init(x: 0.28, y: 0.28), .init(x: 0.72, y: 0.28), .init(x: 0.28, y: 0.72), .init(x: 0.72, y: 0.72)],
        5: [.init(x: 0.28, y: 0.28), .init(x: 0.72, y: 0.28), .init(x: 0.5, y: 0.5), .init(x: 0.28, y: 0.72), .init(x: 0.72, y: 0.72)],
        6: [.init(x: 0.28, y: 0.25), .init(x: 0.72, y: 0.25), .init(x: 0.28, y: 0.5), .init(x: 0.72, y: 0.5), .init(x: 0.28, y: 0.75), .init(x: 0.72, y: 0.75)],
    ]

    public var body: some View {
        let bild = (vorschau ?? WuerfelSatz.aktuell).bild(design: art)
        let w = DesignWerte.fuer(bild).wuerfel
        let salon = bild == .salon
        let flaeche = (gehalten ? w?.gehalten : w?.flaeche)?.color ?? Color.kartenGrund
        let auge = (gehalten ? w?.augeGehalten : w?.auge)?.color ?? Color.schrift
        let form = RoundedRectangle(cornerRadius: (salon ? 4 : 8) * groesse / 52)
        // Design-Runde 3: In Tinte ist der Würfel Material: Elfenbein mit leichtem Verlauf und Schatten; gehalten dunkel mit hellen Augen.
        let tinte = bild == .tinte
        let augenFarbe: Color = tinte ? (gehalten ? Tisch.elfenbein : Tisch.auge) : auge
        ZStack {
            if tinte {
                form.fill(LinearGradient(colors: gehalten ? [Tisch.dunkel, Tisch.dunkelTief] : [Tisch.elfenbein, Tisch.elfenbeinTief],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                form.strokeBorder(gehalten ? Color.white.opacity(0.35) : Color.black.opacity(0.18), lineWidth: 1)
            } else {
                form.fill(flaeche)
                if !salon { form.strokeBorder(w?.rand?.color ?? Color.linieStark, lineWidth: 1.5) }
                else if !aufBand && !gehalten { form.strokeBorder(Color.linie, lineWidth: 1) }
            }
            if let augen, let p = Self.punkte[min(max(augen, 1), 6)] {
                ForEach(Array(p.enumerated()), id: \.offset) { _, punkt in
                    Circle().fill(augenFarbe).frame(width: groesse * 0.17, height: groesse * 0.17)
                        .position(x: punkt.x * groesse, y: punkt.y * groesse)
                }
            } else {
                Image(systemName: "questionmark").font(.system(size: groesse * 0.35, weight: .semibold)).foregroundStyle(augenFarbe.opacity(0.65))   // M-020: Platzhalter im Dunkeln lesbar; design:spielinhalt (skaliert mit dem Würfel)
            }
        }
        .frame(width: groesse, height: groesse)
        .shadow(color: Color.black.opacity(tinte ? 0.30 : 0), radius: tinte ? groesse * 0.07 : 0, x: 0, y: tinte ? groesse * 0.05 : 0)
        .rotationEffect(.degrees(kipp))
        .scaleEffect(1 + 0.12 * hub)
        .offset(y: -groesse * 0.18 * hub)
        .onChange(of: augen) { _, neu in
            guard tinte, neu != nil, !wenigerBewegung else { return }
            // Wurf: kurz anheben und kippen, dann federnd zurück auf den Tisch
            let richtung: Double = Bool.random() ? 1 : -1
            withAnimation(.easeOut(duration: 0.09)) { kipp = richtung * Double.random(in: 9...18); hub = 1 }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 90_000_000)
                withAnimation(.spring(response: 0.34, dampingFraction: 0.5)) { kipp = 0; hub = 0 }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Kleine Plakette mit Schloss für gehaltene oder herausgelegte Würfel in Tinte und Salon. Sie sitzt an der Würfelecke und überdeckt keine Augen.
/// `groesse` = Kantenlänge des Würfels. Beispiel: `.overlay(alignment: .topTrailing) { WuerfelSchloss(groesse: size).offset(x: size * 0.1, y: -size * 0.1) }`.
public struct WuerfelSchloss: View {
    let groesse: CGFloat
    public init(groesse: CGFloat) { self.groesse = groesse }
    public var body: some View {
        let d = max(16, groesse * 0.34)
        Image(systemName: "lock.fill").font(.system(size: d * 0.5, weight: .bold)).foregroundStyle(Color.schrift)   // design:spielinhalt (skaliert mit dem Würfel)
            .frame(width: d, height: d)
            .background(Circle().fill(Color.seitenGrund))
            .overlay(Circle().strokeBorder(Color.schrift, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}
#endif
