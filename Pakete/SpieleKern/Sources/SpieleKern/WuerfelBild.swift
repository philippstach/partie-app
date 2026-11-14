// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

#if canImport(UIKit)
/// Ein Würfel als Bild (SF-Symbol `die.face.N.fill`) mit deutscher Beschriftung für VoiceOver („Würfel: 5“) statt „die face 5 fill“.
/// Die Augen sind als Muster lesbar, also auch ohne Farbe unterscheidbar (G2). Größe über `.font(...)` wie bei `Image`.
public struct WuerfelBild: View {
    let augen: Int
    var gehalten = false
    public init(_ augen: Int, gehalten: Bool = false) { self.augen = augen; self.gehalten = gehalten }
    @Environment(\.designArt) private var art   // Designwechsel D.3

    public var body: some View {
        Group {
            if WuerfelSatz.aktuell.bild(design: art) == .klar {
                Image(systemName: "die.face.\(min(max(augen, 1), 6)).fill")
            } else {
                // Tinte, Salon: Würfel des Designs in der Größe des Symbols (das unsichtbare Symbol liefert die Größe aus der Schrift)
                Image(systemName: "die.face.\(min(max(augen, 1), 6)).fill").hidden()
                    .overlay { GeometryReader { g in WuerfelFlaeche(augen: augen, gehalten: gehalten, groesse: min(g.size.width, g.size.height)) } }
            }
        }
            .accessibilityLabel(Text("Würfel: \(augen)"))
            .accessibilityValue(gehalten ? Text("gehalten") : Text(verbatim: ""))
    }
}
#endif
