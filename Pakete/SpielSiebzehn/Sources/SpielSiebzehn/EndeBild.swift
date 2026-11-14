// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Siebzehn und Vier (Blatt 22, Paket EB-1, Schritt 1). Nicht syntaxgeprüft.
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SiebzehnKern

/// Bild vom Ende: die letzte Hand. Eine Zeile für die Bank und je Person eine Zeile mit ihren Karten und der Summe.
/// Nimmt nur Werte (Karten, Namen), keine Bindungen und keine Gesten.
enum SiebzehnEndeBild {
    /// `nil`, wenn keine Hand mehr liegt.
    static func bild(bank: [SKarte], haende: [[SKarte]], namen: [String]) -> EndeBild? {
        let personen = namen.indices.filter { haende.indices.contains($0) && !haende[$0].isEmpty }
        guard !bank.isEmpty, !personen.isEmpty else { return nil }
        let zeilen = personen.count + 1
        return EndeBild(Text("Die letzte Hand"), hoehe: zeilen > 3 ? 190 : 150) { groesse in
            let zeilenHoehe = (groesse.height - 6 * CGFloat(zeilen - 1)) / CGFloat(zeilen)
            let skala = max(0.28, min(0.5, zeilenHoehe / 84))   // Karte „normal“ ist 58 × 84 pt
            VStack(spacing: 6) {
                zeile(name: String(localized: "Bank"), karten: bank, skala: skala)
                ForEach(personen, id: \.self) { i in zeile(name: namen[i], karten: haende[i], skala: skala) }
            }
            .frame(width: groesse.width, height: groesse.height, alignment: .center)
        }
    }

    private static func zeile(name: String, karten: [SKarte], skala: CGFloat) -> some View {
        let summe = siebzehnSumme(karten)
        return HStack(spacing: 10) {
            Text(verbatim: name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Tisch.elfenbein).lineLimit(1).minimumScaleFactor(0.7)
                .frame(width: 84, alignment: .leading)
            HStack(spacing: 3) {
                ForEach(Array(karten.enumerated()), id: \.offset) { _, k in
                    SkatKartenBild(SkatKarte(farbIndex: k.farbe, wert: k.wert), groesse: .normal)
                        .scaleEffect(skala, anchor: .topLeading)
                        .frame(width: 58 * skala, height: 84 * skala, alignment: .topLeading)
                }
            }
            Spacer(minLength: 4)
            Text(verbatim: "\(summe)").font(.system(size: 15, weight: .semibold).monospacedDigit()).foregroundStyle(summe > 21 ? Tisch.hinweis.opacity(0.7) : Tisch.elfenbein)
        }
    }
}
#endif
