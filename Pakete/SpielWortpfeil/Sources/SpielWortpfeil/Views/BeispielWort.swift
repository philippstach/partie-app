// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

// MARK: Animiertes Beispiel für die Karte „Neu hier?“

private func tile(_ content: AnyView, fill: Color, size: CGFloat = 44) -> some View {
    content.frame(width: size, height: size).background(fill).overlay(Rectangle().stroke(Color.linie, lineWidth: 0.5))
}

/// Beispiel 1: Frage mit Pfeil, das Wort füllt sich Buchstabe für Buchstabe
struct ExampleWord: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.7)) { ctx in
            let n = reduceMotion ? 4 : min(4, Int(ctx.date.timeIntervalSinceReferenceDate / 0.7) % 7)
            HStack(spacing: 0) {
                tile(AnyView(ZStack(alignment: .trailing) {
                    Text("Haus-tier").font(.system(size: 11, weight: .medium)).fontWidth(.condensed) // design:spielinhalt
                        .foregroundStyle(Color.frageTinte).frame(maxWidth: .infinity).padding(.trailing, 8)
                    Image(systemName: "arrowtriangle.right.fill").font(.system(size: 8)).foregroundStyle(Color.kwAkzent).padding(.trailing, 2) // design:spielinhalt
                }), fill: .feldFrage)
                ForEach(Array("HUND".enumerated()), id: \.offset) { i, ch in
                    tile(AnyView(Text(i < n ? String(ch) : "")
                        .font(.system(size: 26, weight: .semibold, design: Design.zahlDesign)).foregroundStyle(Color.tinte)), // design:spielinhalt
                         fill: .feldLeer)
                }
            }
            .overlay(Rectangle().stroke(Color.kwAkzent, lineWidth: 1.5))
            .animation(.snappy(duration: 0.12), value: n)
        }
        .accessibilityHidden(true)
    }
}
#endif
