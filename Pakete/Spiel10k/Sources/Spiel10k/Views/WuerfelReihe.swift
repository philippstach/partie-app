// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Würfelreihe als eigenes Layout (1.1, Build 10): Die Kantenlänge kommt direkt aus dem Platzangebot –
/// kein nachträglich gemessener Zustand, keine Rückkopplung, kein falscher erster Frame. Die Reihe ist nie
/// breiter als das Angebot (vorher: iPad quer, erster Würfel fehlte, Würfel stießen an den Kartenrand).
struct WuerfelReihe: Layout {
    /// Abstand zwischen den Würfeln
    var abstand: CGFloat
    /// Höchste Kantenlänge (z. B. 96 iPhone, 200 Spieltisch)
    var hoechstens: CGFloat

    /// Kantenlänge für `n` Würfel in `breite` – reine Funktion, unit-getestet.
    nonisolated static func kante(breite: CGFloat?, n: Int, abstand: CGFloat, hoechstens: CGFloat) -> CGFloat {
        guard n > 0 else { return 0 }
        guard let breite, breite.isFinite else { return hoechstens }
        let passend = (breite - CGFloat(n - 1) * abstand) / CGFloat(n)
        return max(min(hoechstens, passend), 1)
    }

    /// Gesamtbreite der Reihe bei Kantenlänge `kante`
    nonisolated static func breite(kante: CGFloat, n: Int, abstand: CGFloat) -> CGFloat {
        n > 0 ? kante * CGFloat(n) + abstand * CGFloat(n - 1) : 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let n = subviews.count
        let k = Self.kante(breite: proposal.width, n: n, abstand: abstand, hoechstens: hoechstens)
        return CGSize(width: Self.breite(kante: k, n: n, abstand: abstand), height: k)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let n = subviews.count
        let k = Self.kante(breite: bounds.width, n: n, abstand: abstand, hoechstens: hoechstens)
        var x = bounds.midX - Self.breite(kante: k, n: n, abstand: abstand) / 2
        for sub in subviews {
            sub.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(width: k, height: k))
            x += k + abstand
        }
    }
}

/// Ein Platz in der `WuerfelReihe`: liefert die zugeteilte Kantenlänge an den Inhalt (z. B. `DieView(size:)`).
struct WuerfelFeld<Content: View>: View {
    @ViewBuilder let inhalt: (CGFloat) -> Content

    var body: some View {
        GeometryReader { geo in
            let k = min(geo.size.width, geo.size.height)
            inhalt(k)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
