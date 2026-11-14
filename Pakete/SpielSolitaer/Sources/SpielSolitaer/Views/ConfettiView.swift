// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei (Karten, Tischthemen, Farben und Konfetti sind Spielinhalt, DESIGN.md 3.6)
import SwiftUI
import KlarGlas
import SpieleKern

/// 1,2 s Konfetti: 60 Teilchen in Grüntönen fallen von oben (feste Zufallsfolge)
struct ConfettiView: View {
    private struct Piece {
        var x: CGFloat, delay: Double, speed: CGFloat, drift: CGFloat, spin: Double, size: CGFloat, color: Color
    }

    private let start = Date()
    private let pieces: [Piece] = {
        var rng = SplitMix64(seed: 777)
        func unit() -> Double { Double(rng.next() % 10_000) / 10_000 }
        let g = Familienfarbe.gruen
        let colors = [Color.familie(g.textHell), g.color, Color.familie(g.textDunkel), g.color.opacity(0.35), g.color.opacity(0.7)]   // Familienfarbe Grün in Stufen
        return (0..<60).map { i in
            Piece(x: unit(), delay: unit() * 0.35, speed: 200 + unit() * 280, drift: (unit() - 0.5) * 120,
                  spin: (unit() - 0.5) * 12, size: 6 + unit() * 6, color: colors[i % colors.count])
        }
    }()

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { gc, size in
                let t = ctx.date.timeIntervalSince(start)
                for p in pieces where t > p.delay {
                    let age = t - p.delay
                    let y = -20 + p.speed * age + 300 * age * age * 0.5
                    let x = p.x * size.width + p.drift * age
                    guard y < size.height + 20 else { continue }
                    var path = Path(CGRect(x: -p.size / 2, y: -p.size * 0.3, width: p.size, height: p.size * 0.6))
                    path = path.applying(CGAffineTransform(rotationAngle: p.spin * age).concatenating(CGAffineTransform(translationX: x, y: y)))
                    gc.fill(path, with: .color(p.color.opacity(age > 0.9 ? max(0, 1 - (age - 0.9) / 0.3) : 1)))
                }
            }
        }
    }
}
