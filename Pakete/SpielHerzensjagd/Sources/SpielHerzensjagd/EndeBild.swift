// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Herzensjagd (Blatt 22, Paket EB2-1). Nicht syntaxgeprüft.
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Bild vom Ende: „Punkte je Runde“ als kleine Tabelle. Vier Spalten mit dem Spielerzeichen, je Runde eine Zeile, unten „Gesamt“ fett;
/// ein Durchmarsch (0 neben dreimal 26) steht hell hervorgehoben. Mehr als sechs Runden: die letzten sechs, darüber „…“.
/// Nimmt nur Werte (Zahlen, Namen), keine Bindungen und keine Gesten.
enum HerzensjagdEndeBild {
    /// `nil`, wenn der Stand keinen Rundenverlauf kennt (Stände von vor dem Update) oder noch keine Runde beendet ist.
    static func bild(verlauf: [[Int]]?, gesamt: [Int], namen: [String]) -> EndeBild? {
        guard let verlauf, !verlauf.isEmpty, gesamt.count == 4, namen.count == 4, verlauf.allSatisfy({ $0.count == 4 }) else { return nil }
        let erste = max(0, verlauf.count - 6)
        let zeilen = Array(verlauf.enumerated()).filter { $0.offset >= erste }
        let hoehe = CGFloat(64 + 22 * (zeilen.count + 1))
        return EndeBild(Text("Punkte je Runde als Tabelle"), hoehe: hoehe) { groesse in
            VStack(spacing: 4) {
                EndeBildTitel("Punkte je Runde")
                HStack(spacing: 0) {
                    Color.clear.frame(width: 26)
                    ForEach(0..<4, id: \.self) { i in
                        SpielerAvatar(name: namen[i], farbe: Spieler.farbe(i), groesse: 18).frame(maxWidth: .infinity)
                    }
                }
                if erste > 0 { Text(verbatim: "…").font(.system(size: 12, weight: .semibold)).foregroundStyle(Tisch.hinweis) }
                ForEach(zeilen, id: \.offset) { n, werte in
                    let durchmarsch = werte.contains(0) && werte.filter { $0 == 26 }.count == 3
                    HStack(spacing: 0) {
                        Text(verbatim: "\(n + 1)").font(.system(size: 12, weight: .semibold).monospacedDigit()).foregroundStyle(Tisch.hinweis).frame(width: 26)
                        ForEach(0..<4, id: \.self) { i in
                            Text(verbatim: "\(werte[i])").font(.system(size: 14, weight: durchmarsch ? .bold : .regular).monospacedDigit())
                                .foregroundStyle(Tisch.elfenbein).frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 1)
                    .background(durchmarsch ? Tisch.elfenbein.opacity(0.22) : Color.clear, in: .capsule)
                }
                Rectangle().fill(Tisch.elfenbein.opacity(0.35)).frame(height: 0.5)
                HStack(spacing: 0) {
                    Text("Gesamt").font(.system(size: 11, weight: .semibold)).foregroundStyle(Tisch.hinweis).frame(width: 26).minimumScaleFactor(0.5).lineLimit(1)
                    ForEach(0..<4, id: \.self) { i in
                        Text(verbatim: "\(gesamt[i])").font(.system(size: 15, weight: .bold).monospacedDigit()).foregroundStyle(Tisch.elfenbein).frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(width: groesse.width, height: groesse.height, alignment: .center)
        }
    }
}
#endif
