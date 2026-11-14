// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// `celebrating`: der Sieg-Moment im Spiel (winkt 3 ×, die Ballons ziehen das Männchen aus dem Bild).
/// `won` / `lost`: der ruhige Endzustand auf dem Ende-Bildschirm.
enum FigureOutcome: Sendable { case playing, celebrating, won, lost }

/// Das Ballon-Männchen. Die einzige Stelle, die die Figur kennt: wer sie tauscht, ändert nur diese Datei.
/// Gezeichnet in einer festen Fläche von 200 × 240 und auf den freien Platz skaliert, ganz ohne Bilddateien.
struct FigureView: View {
    let remaining: Int
    var total: Int = 8
    var outcome: FigureOutcome = .playing
    /// Auf dem Start schwebt die Figur leicht
    var floats = false
    /// Ende-Bildschirm (verloren): das sitzende Männchen groß zeigen statt winzig in einer leeren Fläche
    var zoomSeated = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bursts: [Burst] = []
    @State private var bob = false
    @State private var waveUp = false
    /// Sieg: Hochziehen aus dem Bild
    @State private var rise: CGFloat = 0
    /// Niederlage: Abstand der Landung (Männchen sinkt auf den Hügel)
    @State private var drop: CGFloat = 0
    @State private var dust: [Burst] = []

    private static let line = StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)

    private struct Burst: Identifiable { let id = UUID(); let point: CGPoint }

    // Entwurfsmaße (Punkte in der 200 × 240 großen Fläche)
    private static let size = CGSize(width: 200, height: 240)
    /// Platz über der Fläche, damit die oberste Ballonreihe (8 Ballons) nicht abgeschnitten wird
    private static let topMargin: CGFloat = 40
    private static let ground: CGFloat = 224
    private static let slots: [CGPoint] = [
        CGPoint(x: -38, y: 11), CGPoint(x: -13, y: 11), CGPoint(x: 13, y: 11), CGPoint(x: 38, y: 11),
        CGPoint(x: -25, y: -17), CGPoint(x: 0, y: -17), CGPoint(x: 25, y: -17), CGPoint(x: 0, y: -42),
    ]

    /// Höhe der Hände: weniger Ballons, tiefer über dem Boden
    private func handY(_ remaining: Int) -> CGFloat {
        146 - CGFloat(max(1, min(remaining, 8)) - 1) * 6.5
    }

    /// Gewonnen: Das Männchen steigt auf die oberste Höhe, egal wie viele Ballons übrig sind.
    private var hand: CGFloat { outcome == .won ? 124 : handY(remaining) }

    private func balloonCenter(_ index: Int, hand: CGFloat) -> CGPoint {
        let slot = Self.slots[index % Self.slots.count]
        return CGPoint(x: 100 + slot.x, y: hand - 66 + slot.y)
    }

    /// Das Männchen sinkt federnd, wenn ein Ballon platzt
    private var sink: Animation? { reduceMotion ? nil : .spring(duration: 0.6, bounce: 0.3) }
    /// Der Ballon wird kurz größer und ist weg
    private var pop: Animation? { reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.12) }

    private var lastBalloon: Bool { outcome == .playing && remaining == 1 }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Self.size.width, geo.size.height / (Self.size.height + Self.topMargin))
            ZStack(alignment: .topLeading) {
                Hill().stroke(Color(.separator), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                ZStack(alignment: .topLeading) {
                    if outcome == .lost {
                        SeatedMan().stroke(Color.primary, style: Self.line)
                            .offset(y: drop)
                    } else {
                        let waving = outcome == .won || outcome == .celebrating
                        FloatingMan(waving: waving, lookUp: lastBalloon).stroke(Color.primary, style: Self.line)
                            .offset(y: hand)
                            .animation(sink, value: hand)
                        if waving {
                            WavingArm().stroke(Color.primary, style: Self.line)
                                .rotationEffect(.degrees(waveUp ? 16 : -8), anchor: UnitPoint(x: 0.5, y: 38 / 240))
                                .offset(y: hand)
                        }
                        ForEach(0..<min(remaining, total), id: \.self) { i in
                            Balloon(index: i, hand: CGPoint(x: 100, y: hand),
                                    center: balloonCenter(i, hand: hand),
                                    pulsing: lastBalloon && !reduceMotion)
                                .animation(sink, value: hand)
                                .transition(.asymmetric(insertion: .identity,
                                                        removal: reduceMotion ? .opacity : .scale(scale: 1.15).combined(with: .opacity)))
                        }
                        .animation(pop, value: remaining)
                    }
                    ForEach(bursts) { b in BurstView(point: b.point) }
                    ForEach(dust) { d in DustView(point: d.point) }
                }
                .offset(y: rise + (floats && bob ? 2 : 0))
            }
            .frame(width: Self.size.width, height: Self.size.height)
            .frame(width: Self.size.width, height: Self.size.height + Self.topMargin, alignment: .bottom)
            .scaleEffect(zoomSeated && outcome == .lost ? 1.9 : 1, anchor: UnitPoint(x: 0.5, y: 0.94))
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onChange(of: remaining) { old, new in
            guard new < old, !reduceMotion else { return }
            // Platzen mehrere Ballons auf einmal (falsches Lösen), funken sie nacheinander (Abstand 0,25 s)
            for k in 0..<(old - new) {
                let burst = Burst(point: balloonCenter(old - 1 - k, hand: handY(old)))
                Task {
                    try? await Task.sleep(for: .seconds(Double(k) * 0.25))
                    bursts.append(burst)
                    try? await Task.sleep(for: .seconds(0.7))
                    bursts.removeAll { $0.id == burst.id }
                }
            }
        }
        .onChange(of: outcome) { _, new in enter(new) }
        .onAppear {
            guard !reduceMotion else { return }
            if floats { withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { bob = true } }
            if outcome == .won { startWaving() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(outcome == .lost ? Text("Alle Ballons geplatzt") : Text("Noch \(remaining) von \(total) Ballons"))
    }
}

extension FigureView {
    /// Übergang in einen neuen Zustand (nur wenn er sich im Spiel ändert, nicht beim ersten Zeigen)
    fileprivate func enter(_ new: FigureOutcome) {
        switch new {
        case .playing:
            rise = 0; waveUp = false
        case .celebrating, .won:
            startWaving()
            guard new == .celebrating, !reduceMotion else { return }
            // Die Ballons ziehen das Männchen hoch aus dem Bild (1,0 s, easeIn)
            withAnimation(.easeIn(duration: 1.0).delay(0.2)) { rise = -340 }
        case .lost:
            guard !reduceMotion else { return }
            drop = -30
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { drop = 0 }
            let cloud = Burst(point: CGPoint(x: 100, y: 222))
            Task {
                try? await Task.sleep(for: .seconds(0.2))   // Staub, sobald das Männchen aufsetzt
                dust.append(cloud)
                try? await Task.sleep(for: .seconds(0.6))
                dust.removeAll { $0.id == cloud.id }
            }
        }
    }

    /// Winken: im Spiel 3 Ausschläge in 0,9 s, auf dem Ende-Bildschirm dauerhaft (nicht bei „Bewegung reduzieren“)
    fileprivate func startWaving() {
        guard !reduceMotion else { return }
        if outcome == .celebrating {
            withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true)) { waveUp = true }
        } else {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { waveUp = true }
        }
    }
}

// MARK: Teile

private struct Hill: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 228))
        p.addQuadCurve(to: CGPoint(x: 200, y: 228), control: CGPoint(x: 100, y: 214))
        return p
    }
}

/// Arme hoch zu den Schnüren, Körper, Beine. Gezeichnet ab der Handhöhe (y = 0).
private struct FloatingMan: Shape {
    var waving = false
    /// Letzter Ballon: Kopf 4 pt höher, Arme straffer
    var lookUp = false

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx: CGFloat = 100
        let elbow: CGFloat = lookUp ? 14 : 21
        p.addEllipse(in: CGRect(x: cx - 9, y: lookUp ? 9 : 13, width: 18, height: 18))
        p.move(to: CGPoint(x: cx - 6, y: 2)); p.addLine(to: CGPoint(x: cx - elbow, y: 24)); p.addLine(to: CGPoint(x: cx, y: 38))
        if !waving {
            p.move(to: CGPoint(x: cx + 6, y: 2)); p.addLine(to: CGPoint(x: cx + elbow, y: 24)); p.addLine(to: CGPoint(x: cx, y: 38))
        }
        p.move(to: CGPoint(x: cx, y: lookUp ? 27 : 31)); p.addLine(to: CGPoint(x: cx, y: 58))
        p.move(to: CGPoint(x: cx, y: 58)); p.addLine(to: CGPoint(x: cx - 9, y: 76))
        p.move(to: CGPoint(x: cx, y: 58)); p.addLine(to: CGPoint(x: cx + 9, y: 76))
        return p
    }
}

/// Der winkende rechte Arm: vom Körper nach außen und hoch. Gedreht wird um die Schulter (cx, 38).
private struct WavingArm: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 100, y: 38)); p.addLine(to: CGPoint(x: 120, y: 32)); p.addLine(to: CGPoint(x: 128, y: 10))
        return p
    }
}

/// Sitzt entspannt auf dem Hügel (verloren: freundlich, nicht tragisch).
private struct SeatedMan: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx: CGFloat = 100
        p.addEllipse(in: CGRect(x: cx - 9, y: 168, width: 18, height: 18))
        p.move(to: CGPoint(x: cx, y: 186)); p.addLine(to: CGPoint(x: cx, y: 210))          // Körper
        p.move(to: CGPoint(x: cx, y: 210)); p.addLine(to: CGPoint(x: cx + 20, y: 210))     // Oberschenkel
        p.addLine(to: CGPoint(x: cx + 20, y: 222))                                          // Unterschenkel
        p.move(to: CGPoint(x: cx, y: 210)); p.addLine(to: CGPoint(x: cx - 14, y: 212))
        p.addLine(to: CGPoint(x: cx - 14, y: 222))
        p.move(to: CGPoint(x: cx, y: 194)); p.addLine(to: CGPoint(x: cx + 14, y: 202)); p.addLine(to: CGPoint(x: cx + 20, y: 208)) // Arm auf dem Knie
        p.move(to: CGPoint(x: cx, y: 194)); p.addLine(to: CGPoint(x: cx - 12, y: 204))
        return p
    }
}

private struct Balloon: View {
    let index: Int
    let hand: CGPoint
    let center: CGPoint
    var pulsing = false
    @State private var pulse = false

    private var opacity: Double { [1.0, 0.85, 0.7][index % 3] }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: CGPoint(x: center.x, y: center.y + 19))
                p.addQuadCurve(to: hand, control: CGPoint(x: (center.x + hand.x) / 2, y: (center.y + hand.y) / 2 + 6))
            }
            .stroke(Color(.separator), lineWidth: 1)
            Path { p in    // Knoten
                p.move(to: CGPoint(x: center.x, y: center.y + 18))
                p.addLine(to: CGPoint(x: center.x - 4, y: center.y + 25))
                p.addLine(to: CGPoint(x: center.x + 4, y: center.y + 25))
                p.closeSubpath()
            }
            .fill(Color.appFlaeche.opacity(opacity))
            Ellipse().fill(Color.appFlaeche.opacity(opacity))
                .frame(width: 31, height: 39)
                .scaleEffect(pulse ? 1.06 : 1)
                .position(center)
            Ellipse().fill(.white.opacity(0.3))
                .frame(width: 7, height: 11)
                .position(x: center.x - 7, y: center.y - 9)
        }
        .onAppear { updatePulse() }
        .onChange(of: pulsing) { _, _ in updatePulse() }
    }

    /// Letzter Ballon: pulsiert ganz leicht (1,0 ↔ 1,06, 1,2 s je Takt)
    private func updatePulse() {
        if pulsing {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
        } else {
            withAnimation(.none) { pulse = false }
        }
    }
}

/// Sechs kleine App-Farben-Punkte fliegen auseinander.
private struct BurstView: View {
    let point: CGPoint
    @State private var out = false

    private static let radii: [Double] = [30, 38, 26, 40, 33, 24]

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let angle = Double(i) / 6 * 2 * .pi
                let r = Self.radii[i]
                Circle().fill(Color.appFlaeche)
                    .frame(width: 4, height: 4)
                    .offset(x: out ? cos(angle) * r : 0, y: out ? sin(angle) * r : 0)
                    .opacity(out ? 0 : 1)
            }
        }
        .position(point)
        .onAppear { withAnimation(.easeOut(duration: 0.35)) { out = true } }
        .allowsHitTesting(false)
    }
}

/// Staubwolke beim Aufsetzen: 5 graue Kreise wachsen und verblassen in 0,4 s.
private struct DustView: View {
    let point: CGPoint
    @State private var out = false

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                let x = Double(i - 2) * 11
                Circle().fill(Color(.systemGray3))
                    .frame(width: out ? 14 : 6, height: out ? 14 : 6)
                    .offset(x: out ? x * 1.6 : x * 0.3, y: out ? -8 - Double(i % 2) * 5 : 0)
                    .opacity(out ? 0 : 0.8)
            }
        }
        .position(point)
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { out = true } }
        .allowsHitTesting(false)
    }
}

#Preview("8 Ballons") { FigureView(remaining: 8).frame(height: 260).padding() }
#Preview("3 Ballons") { FigureView(remaining: 3).frame(height: 260).padding() }
#Preview("Letzter Ballon") { FigureView(remaining: 1).frame(height: 260).padding() }
#Preview("Gewonnen") { FigureView(remaining: 4, outcome: .won).frame(height: 260).padding() }
#Preview("Verloren") { FigureView(remaining: 0, outcome: .lost).frame(height: 260).padding() }
#endif
