// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Rechnet den Kartenwasserfall: Könige zuerst, dann jede Karte springt vom Ziel, fällt, hüpft am unteren Rand (Dämpfung 0,7)
/// und hinterlässt eine Spur aus Abdrücken, die nach 1,5 s ausblendet.
final class WaterfallSim {
    struct Flyer {
        var face: CardFace
        var pos: CGPoint
        var vel: CGVector
        var releaseAt: Double
        var lastStamp: CGPoint
        var done = false
    }
    struct Stamp { var face: CardFace; var pos: CGPoint; var time: Double }

    static let gravity: CGFloat = 1500
    static let damping: CGFloat = 0.7
    static let hold = 1.0, fade = 0.5   // Spur: 1 s voll, dann 0,5 s Ausblenden

    var flyers: [Flyer] = []
    var stamps: [Stamp] = []
    private(set) var time = 0.0
    private let bounds: CGSize
    private let cardSize: CGSize

    init(cards: [(face: CardFace, origin: CGPoint)], cardSize: CGSize, bounds: CGSize) {
        self.bounds = bounds
        self.cardSize = cardSize
        var rng = SplitMix64(seed: 2026)
        func unit() -> CGFloat { CGFloat(rng.next() % 10_000) / 10_000 }
        for (k, item) in cards.enumerated() {
            let dir: CGFloat = rng.next() % 2 == 0 ? 1 : -1
            flyers.append(Flyer(face: item.face, pos: item.origin,
                                vel: CGVector(dx: dir * (80 + unit() * 190), dy: -(120 + unit() * 380)),
                                releaseAt: Double(k) * 0.09, lastStamp: item.origin))
        }
    }

    /// Bis zur Zeit `t` (Sekunden seit Start) weiterrechnen, in festen Schritten.
    func advance(to t: Double) {
        let dt = 1.0 / 120
        while time + dt <= t {
            time += dt
            for i in flyers.indices where !flyers[i].done && time >= flyers[i].releaseAt {
                step(&flyers[i], dt: CGFloat(dt))
            }
        }
        stamps.removeAll { time - $0.time > Self.hold + Self.fade }
    }

    private func step(_ f: inout Flyer, dt: CGFloat) {
        f.vel.dy += Self.gravity * dt
        f.pos.x += f.vel.dx * dt
        f.pos.y += f.vel.dy * dt
        let floor = bounds.height - cardSize.height
        if f.pos.y > floor {
            f.pos.y = floor
            f.vel.dy = -max(abs(f.vel.dy) * Self.damping, 140)
        }
        if hypot(f.pos.x - f.lastStamp.x, f.pos.y - f.lastStamp.y) >= 11 {
            stamps.append(Stamp(face: f.face, pos: f.pos, time: time))
            f.lastStamp = f.pos
        }
        if f.pos.x < -cardSize.width || f.pos.x > bounds.width { f.done = true }
    }

    var finished: Bool { flyers.allSatisfy(\.done) && stamps.isEmpty }

    func alpha(of s: Stamp) -> Double {
        let age = time - s.time
        return age < Self.hold ? 1 : max(0, 1 - (age - Self.hold) / Self.fade)
    }
}

/// Siegesanimation. Antippen überspringt.
struct WaterfallView: View {
    let cards: [(face: CardFace, origin: CGPoint)]
    let cardSize: CGSize
    let size: CGSize
    let fourColor: Bool
    let onFinish: () -> Void

    @State private var sim: WaterfallSim?
    @State private var start: Date?
    @State private var finished = false

    var body: some View {
        let cw = cardSize.width, ch = cardSize.height
        ZStack {
            if let sim {
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSince(start ?? ctx.date)
                    Canvas { gc, _ in
                        // nach langem Hintergrund nicht alle verpassten Schritte auf einmal nachrechnen: höchstens eine halbe Sekunde pro Bild
                        sim.advance(to: min(t, sim.time + 0.5))
                        for s in sim.stamps {
                            gc.opacity = sim.alpha(of: s)
                            if let sym = gc.resolveSymbol(id: Self.faceID(s.face)) {
                                gc.draw(sym, at: CGPoint(x: s.pos.x + cw / 2, y: s.pos.y + ch / 2))
                            }
                        }
                        gc.opacity = 1
                        for f in sim.flyers where !f.done && sim.time >= f.releaseAt {
                            if let sym = gc.resolveSymbol(id: Self.faceID(f.face)) {
                                gc.draw(sym, at: CGPoint(x: f.pos.x + cw / 2, y: f.pos.y + ch / 2))
                            }
                        }
                    } symbols: {
                        ForEach(0..<52, id: \.self) { id in
                            CardFaceView(face: Self.face(id), width: cw, fourColor: fourColor).tag(id)
                        }
                    }
                    .onChange(of: sim.finished || t > 8) { _, done in if done { finish() } }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear {
            sim = WaterfallSim(cards: cards, cardSize: cardSize, bounds: size)
            start = .now
        }
        .accessibilityHidden(true)
    }

    /// Nummer für das Canvas-Symbol: Farbe × 13 + Wert − 1
    private static func faceID(_ f: CardFace) -> Int { f.suit.rawValue * 13 + f.rank - 1 }
    private static func face(_ id: Int) -> CardFace { CardFace(rank: id % 13 + 1, suit: Suit(rawValue: id / 13)!) }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }
}

/// Tipp: eine halbtransparente Kopie der Karte(n) gleitet zum Ziel und zurück (2 ×, je Weg 0,35 s, Pause 0,15 s).
struct HintGhostView: View {
    let cards: [(face: CardFace, frame: CGRect)]
    let delta: CGSize
    let fourColor: Bool
    @State private var moved = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, item in
                CardFaceView(face: item.face, width: item.frame.width, fourColor: fourColor)
                    .opacity(0.6)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                    .position(x: item.frame.midX, y: item.frame.midY)
                    .offset(moved ? delta : .zero)
            }
        }
        .allowsHitTesting(false)
        .task {
            for _ in 0..<2 {
                withAnimation(reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.35)) { moved = true }
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.35)) { moved = false }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
}

/// Goldrahmen, der zweimal pulsiert (Tipp „Stapel antippen“)
struct PulseFrame: View {
    let cornerRadius: CGFloat
    /// Zielgröße des Pulsierens (1 = nur Aufleuchten ohne Wachsen)
    var grow: CGFloat = 1.1
    @State private var scale: CGFloat = 1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(Color.appFarbe, lineWidth: 2.5)
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(Color.appFarbe.opacity(0.15)))
            .scaleEffect(scale)
            .task {
                for _ in 0..<2 {
                    withAnimation(.easeInOut(duration: 0.3)) { scale = grow }
                    try? await Task.sleep(for: .milliseconds(350))
                    withAnimation(.easeInOut(duration: 0.3)) { scale = 1 }
                    try? await Task.sleep(for: .milliseconds(350))
                }
            }
    }
}
