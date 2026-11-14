// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(UIKit)
import SwiftUI
import KlarGlas
#endif

/// 1.0 (M4, Übertrag aus Rauswurf): Würfel-Ehrlichkeit als Baustein. Zählt je Spieler, wie oft welche Augenzahl fiel;
/// der Ende-Bildschirm des Rahmens zeigt daraus die Karte „So fielen die Würfel“ (`SpielEnde.wuerfel`).
/// Spiele mit Fortsetzen sichern die Bilanz über `sichern(spiel:)` und laden sie bei `standGeladen(true)` mit `laden(spiel:)`.
public struct WuerfelBilanz: Codable, Equatable, Sendable {
    public var namen: [String]
    /// je Spieler sechs Zähler: `augen[i][0]` = Einsen … `augen[i][5]` = Sechsen
    public var augen: [[Int]]
    /// je Spieler: davon mit echten Würfeln eingetippt
    public var eingetippt: [Int]
    /// Seiten des Würfels (6 für normale Würfel). Königsweg zählt Augen 0…4 und legt `seiten` fest.
    public var seiten: Int
    /// Kleinste Augenzahl (1 bei normalen Würfeln, 0 bei Königsweg)
    public var kleinste: Int

    public init(namen: [String], seiten: Int = 6, kleinste: Int = 1) {
        self.namen = namen; self.seiten = seiten; self.kleinste = kleinste
        augen = Array(repeating: Array(repeating: 0, count: seiten), count: namen.count)
        eingetippt = Array(repeating: 0, count: namen.count)
    }

    /// Zählt die Augen eines Wurfs für einen Spieler (Werte außerhalb des Bereichs werden übergangen).
    public mutating func zaehle(spieler: Int, _ werte: [Int], eingetippt echt: Bool = false) {
        guard augen.indices.contains(spieler) else { return }
        for w in werte {
            let k = w - kleinste
            guard k >= 0, k < seiten else { continue }
            augen[spieler][k] += 1
        }
        if echt { eingetippt[spieler] += werte.count }
    }

    public func wuerfe(_ spieler: Int) -> Int { augen.indices.contains(spieler) ? augen[spieler].reduce(0, +) : 0 }
    public var leer: Bool { augen.allSatisfy { $0.allSatisfy { $0 == 0 } } }

    /// Durchschnitt der Augen eines Spielers (nil ohne Würfe).
    public func schnitt(_ spieler: Int) -> Double? {
        let n = wuerfe(spieler)
        guard n > 0 else { return nil }
        let summe = augen[spieler].enumerated().reduce(0) { $0 + ($1.offset + kleinste) * $1.element }
        return Double(summe) / Double(n)
    }

    // MARK: Speichern (für Fortsetzen)

    private static func schluessel(_ spiel: String) -> String { "partie.wuerfelbilanz.\(spiel)" }

    public func sichern(spiel: String) {
        if let d = try? JSONEncoder().encode(self) { UserDefaults.standard.set(d, forKey: Self.schluessel(spiel)) }
    }

    /// Gespeicherte Bilanz, nur wenn sie zu den Spielern passt.
    public static func laden(spiel: String, namen: [String]) -> WuerfelBilanz? {
        guard let d = UserDefaults.standard.data(forKey: schluessel(spiel)),
              let b = try? JSONDecoder().decode(WuerfelBilanz.self, from: d), b.namen == namen else { return nil }
        return b
    }

    public static func loeschen(spiel: String) { UserDefaults.standard.removeObject(forKey: schluessel(spiel)) }
}

#if canImport(UIKit)
/// Karte „So fielen die Würfel“ im Ende-Bildschirm: je Spieler sechs kleine Balken, Würfe und Schnitt.
public struct WuerfelBilanzKarte: View {
    let bilanz: WuerfelBilanz
    @State private var offen = false

    public init(_ bilanz: WuerfelBilanz) { self.bilanz = bilanz }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("So fielen die Würfel", systemImage: "dice").font(.headline).foregroundStyle(Color.accentText)
            ForEach(bilanz.namen.indices.prefix(offen ? bilanz.namen.count : 4), id: \.self) { i in
                zeile(i)
            }
            if bilanz.namen.count > 4 {
                Button(offen ? "Weniger" : "Alle Spieler") { withAnimation { offen.toggle() } }.font(.footnote)
            }
            Text("Jeder Wurf ist zufällig, der Computer würfelt mit denselben Würfeln.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 420, alignment: .leading)
        .card()
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func zeile(_ i: Int) -> some View {
        let werte = bilanz.augen[i]
        let maximum = max(1, werte.max() ?? 1)
        let schnitt = bilanz.schnitt(i).map { String(format: "%.1f", $0).replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ",") } ?? "–"
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(verbatim: bilanz.namen[i]).font(.subheadline.weight(.semibold)).lineLimit(1)
                Spacer()
                Text("\(bilanz.wuerfe(i)) Würfe · Schnitt \(schnitt)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<bilanz.seiten, id: \.self) { k in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentText.opacity(0.75))
                            .frame(height: max(2, 22 * CGFloat(werte[k]) / CGFloat(maximum)))
                        Text(verbatim: "\(k + bilanz.kleinste)").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 40, alignment: .bottom)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: bilanz.namen[i]))
        .accessibilityValue(Text(verbatim: (0..<bilanz.seiten).map { "\($0 + bilanz.kleinste): \(werte[$0])" }.joined(separator: ", ")))
    }
}
#endif
