// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Blatt 22 (EB2, Schritt 2): Bild „Zielzahlen und Treffer“ der Ergebnisseite. Je Person eine Zeile mit den Zahlen 2 bis 12:
/// getroffen = helle Kapsel mit dunkler Zahl (ein Pasch mit kleinem Punkt darunter), verfehlt = blasse Zahl.
/// Das Bild bekommt nur Werte (Namen, Farben, Punkte je Zug) und kennt weder Spielstand noch Zustand.
enum ChicagoEndeBild {
    @MainActor static func bild(namen: [String], farben: [Color], zuege: [[Int]]) -> EndeBild {
        EndeBild(Text("Zielzahlen und Treffer je Spieler"), hoehe: CGFloat(70 + 40 * namen.count)) { groesse in
            Tafel(namen: namen, farben: farben, zuege: zuege, groesse: groesse)
        }
    }

    private struct Tafel: View {
        let namen: [String]
        let farben: [Color]
        let zuege: [[Int]]
        let groesse: CGSize

        var body: some View {
            let ton: Color = Tisch.aktiv ? Tisch.elfenbein : Color.schrift
            let kopf: CGFloat = 22
            let zeile = max(28, min(40, (groesse.height - kopf) / CGFloat(max(namen.count, 1))))
            let nameBreite = min(groesse.width * 0.22, 70)
            let zelle = (groesse.width - nameBreite) / 11
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: nameBreite, height: kopf)
                    ForEach(2...12, id: \.self) { z in
                        Text("\(z)").font(.system(size: 10.5, weight: .semibold).monospacedDigit()).foregroundStyle(ton.opacity(0.6))
                            .frame(width: zelle, height: kopf)
                    }
                }
                ForEach(namen.indices, id: \.self) { i in
                    HStack(spacing: 0) {
                        HStack(spacing: 4) {
                            SpielerAvatar(name: namen[i], farbe: farben[i], groesse: 16)
                            Text(verbatim: namen[i]).font(.system(size: 11.5, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)
                        }.frame(width: nameBreite, alignment: .leading)
                        ForEach(0..<11, id: \.self) { k in
                            let p = zuege[i].indices.contains(k) ? zuege[i][k] : nil
                            let getroffen = (p ?? 0) > 0
                            let pasch = getroffen && p == (k + 2) * 2
                            VStack(spacing: 2) {
                                Text("\(k + 2)").font(.system(size: 12, weight: getroffen ? .bold : .regular).monospacedDigit())
                                    .foregroundStyle(getroffen ? Tisch.auge : ton.opacity(p == nil ? 0.25 : 0.42))
                                    .frame(width: max(zelle - 2, 14), height: 22)
                                    .background(Capsule().fill(getroffen ? Tisch.elfenbein : Color.clear))
                                Circle().fill(pasch ? ton : Color.clear).frame(width: 4, height: 4)
                            }.frame(width: zelle)
                        }
                    }
                    .frame(height: zeile)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: "\(namen[i]): \(zuege[i].filter { $0 > 0 }.count)"))
                }
            }
            .frame(width: groesse.width, height: groesse.height)
        }
    }
}
#endif
