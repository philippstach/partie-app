// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
// design:spielinhalt-datei

/// Der Würfel: **eine** View, Körper und Augen in einem `Canvas` (kein `ForEach`, keine Augen-Views).
/// Ein Wechsel der Augenzahl ist nur ein neuer Zeichendurchgang, ohne Übergang und ohne Animation.
/// Wackeln und Hüpfen kommen von außen (`WuerfelWackeln`), als endliche Animation je Wurf.
struct DieView: View {
    let wert: Int?
    var aktiv = false
    var gedimmt = false
    var size: CGFloat = 64
    /// Symbol, solange keine Augenzahl da ist (Hand = Eingabe des echten Würfels)
    var leerSymbol = "dice"

    /// Mittelpunkte der Augen je Augenzahl: die eine Tabelle aus dem Kern.
    static let augenPunkte = WuerfelFlaeche.punkte
    /// Augendurchmesser im Verhältnis zur Kante
    static let augenAnteil: CGFloat = 0.17

    @AppStorage(WuerfelSatz.schluessel) private var satzGewaehlt = ""   // KS: zeichnet beim Wechsel des Würfelsatzes neu

    var body: some View {
        // KS (Blatt 17): Hat jemand einen Würfelsatz gewählt, zeichnet der gemeinsame Würfel; sonst bleibt es beim eigenen Würfel unten.
        if WuerfelSatz.istGewaehlt, let wert {
            WuerfelFlaeche(augen: wert, gehalten: false, groesse: size)
                .overlay { if aktiv { RoundedRectangle(cornerRadius: size * 0.16, style: .continuous).strokeBorder(Color.appFlaeche, lineWidth: max(2, size * 0.05)) } }
                .opacity(gedimmt ? 0.4 : 1)
                .transaction { $0.animation = nil }
        } else { eigenerWuerfel }
    }

    private var eigenerWuerfel: some View {
        Canvas { ctx, s in
            let kante = min(s.width, s.height)
            let rect = CGRect(x: 0, y: 0, width: kante, height: kante)
            let radius = kante * 0.2
            let koerper = Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
            ctx.fill(koerper, with: .color(Color(.dieFace)))
            let rand = rect.insetBy(dx: aktiv ? kante * 0.025 : 0.6, dy: aktiv ? kante * 0.025 : 0.6)
            ctx.stroke(Path(roundedRect: rand, cornerRadius: radius, style: .continuous),
                       with: .color(aktiv ? Color.appFlaeche : Color.primary.opacity(0.18)),
                       lineWidth: aktiv ? max(2, kante * 0.05) : 1.2)
            if let wert, let punkte = Self.augenPunkte[wert] {
                let d = kante * Self.augenAnteil
                let farbe = Color.primary.opacity(gedimmt ? 0.25 : 1)
                for p in punkte {
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x * kante - d / 2, y: p.y * kante - d / 2, width: d, height: d)), with: .color(farbe))
                }
            } else if let symbol = ctx.resolveSymbol(id: 0) {
                ctx.draw(symbol, at: CGPoint(x: kante / 2, y: kante / 2))
            }
        } symbols: {
            Image(systemName: leerSymbol)
                .font(.system(size: size * 0.45, weight: .semibold))   // design:spielinhalt (Beschriftung auf dem Spielmaterial, skaliert mit der Zellgröße)
                .foregroundStyle(aktiv ? Color.appFlaeche : Color.secondary)
                .tag(0)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: size * 0.04, y: size * 0.02)
        .transaction { $0.animation = nil }          // Augenwechsel und Rahmen nie animieren
        .accessibilityHidden(true)
    }
}

/// Endliches Wackeln und Hüpfen des ganzen Würfels (450 ms) bei jedem Wurf. Der Zähler löst die Animation aus,
/// es gibt keine Endlosschleife. Ohne Bewegung (`aktiv == false`) bleibt der Würfel ruhig.
struct WuerfelWackeln: ViewModifier {
    let zaehler: Int
    let aktiv: Bool

    private struct Wert {
        var winkel: Double = 0
        var hub: CGFloat = 0
    }

    func body(content: Content) -> some View {
        if aktiv {
            content.keyframeAnimator(initialValue: Wert(), trigger: zaehler) { view, w in
                view.rotationEffect(.degrees(w.winkel)).offset(y: w.hub)
            } keyframes: { _ in
                KeyframeTrack(\.winkel) {
                    CubicKeyframe(14, duration: 0.09)
                    CubicKeyframe(-12, duration: 0.11)
                    CubicKeyframe(8, duration: 0.1)
                    CubicKeyframe(-4, duration: 0.09)
                    CubicKeyframe(0, duration: 0.06)
                }
                KeyframeTrack(\.hub) {
                    CubicKeyframe(-8, duration: 0.15)
                    CubicKeyframe(0, duration: 0.15)
                    CubicKeyframe(-3, duration: 0.08)
                    CubicKeyframe(0, duration: 0.07)
                }
            }
        } else {
            content
        }
    }
}

/// Kurzes „Plopp“ (1,0 → 1,12 → 1,0), wenn eine Zahl eingetippt wurde. Ohne Wackeln.
struct WuerfelPlopp: ViewModifier {
    let zaehler: Int
    let aktiv: Bool

    func body(content: Content) -> some View {
        if aktiv {
            content.keyframeAnimator(initialValue: CGFloat(1), trigger: zaehler) { view, s in
                view.scaleEffect(s)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(zaehler == 0 ? 1 : 1.12, duration: 0.1)
                    CubicKeyframe(1, duration: 0.14)
                }
            }
        } else {
            content
        }
    }
}

private extension UIColor {
    /// Würfelfläche: weiß, dunkel `#2C2C2E`
    static let dieFace = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1) : .white }
}
