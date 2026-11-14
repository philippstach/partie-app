// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import SpieleKern

/// Bogen mit dem Kartenset: alle vier Farben, Bildkarten, Rückseite, gewählt, markiert, gedimmt, leerer Platz, vier Größen, spanisches Blatt.
/// Dieselbe Ansicht steht auch im Klar-Vergleich (Test/KlarVergleich), dort mit dem Stand von Build 12 gezeichnet.
struct KartenBogen: View {
    private func zeile(_ g: KartenGroesse, _ karten: [SkatKarte?]) -> some View {
        HStack(spacing: 8) { ForEach(Array(karten.enumerated()), id: \.offset) { _, k in SkatKartenBild(k, groesse: g) } }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            zeile(.normal, [SkatKarte(.herz, 10), SkatKarte(.pik, 7), SkatKarte(.karo, 12), SkatKarte(.kreuz, 14), SkatKarte(.herz, 2)])
            zeile(.gross, [SkatKarte(.herz, 13), SkatKarte(.pik, 12), SkatKarte(.karo, 9), SkatKarte(.kreuz, 11)])
            HStack(spacing: 8) {
                SkatKartenBild(nil)
                SkatKartenBild(SkatKarte(.herz, 13), gewaehlt: true)
                SkatKartenBild(SkatKarte(.pik, 8), markiert: true)
                SkatKartenBild(SkatKarte(.karo, 5), gedimmt: true)
                KartenPlatz()
            }
            .padding(.top, 10)
            HStack(spacing: 6) {
                SkatKartenBild(SkatKarte(.herz, 6), groesse: .klein); SkatKartenBild(SkatKarte(.kreuz, 10), groesse: .klein)
                SkatKartenBild(SkatKarte(.karo, 14), groesse: .klein); SkatKartenBild(nil, groesse: .klein); KartenPlatz(groesse: .klein)
            }
            HStack(alignment: .top, spacing: 12) {
                SkatKartenBild(SkatKarte(.herz, 14), groesse: .riesig)
                SkatKartenBild(nil, groesse: .riesig)
                VStack(spacing: 6) {
                    HStack(spacing: 6) { SpanischeKarteBild(rang: 3, farbe: 0, groesse: .klein); SpanischeKarteBild(rang: 7, farbe: 1, groesse: .klein) }
                    HStack(spacing: 6) { SpanischeKarteBild(rang: 11, farbe: 2, groesse: .klein); SpanischeKarteBild(rang: 1, farbe: 3, groesse: .klein) }
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
#endif
