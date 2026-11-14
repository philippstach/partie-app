// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

/// Konfetti in der Farbe des Siegers: fällt von oben über den Sieger.
struct Konfetti: View {
    let farbe: Color
    @State private var fall = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0 ..< 36, id: \.self) { i in
                let w = Double(i)
                RoundedRectangle(cornerRadius: 2)
                    .fill(i % 3 == 0 ? Color.appFlaeche : farbe.opacity(i % 2 == 0 ? 0.9 : 0.6))
                    .frame(width: 6 + CGFloat(i % 3) * 3, height: 10 + CGFloat(i % 4) * 2)
                    .rotationEffect(.degrees(fall ? w * 40 : 0))
                    .position(x: geo.size.width * (0.5 + 0.48 * sin(w * 2.4)),
                              y: fall ? geo.size.height * (0.55 + 0.5 * abs(cos(w * 1.7))) : -10 - CGFloat(i % 5) * 12)
                    .opacity(fall ? 0.0 : 1)
                    .animation(.easeIn(duration: 1.6 + Double(i % 5) * 0.12).delay(Double(i % 6) * 0.05), value: fall)
            }
        }
        .allowsHitTesting(false)
        .onAppear { fall = true }
        .accessibilityHidden(true)
    }
}
