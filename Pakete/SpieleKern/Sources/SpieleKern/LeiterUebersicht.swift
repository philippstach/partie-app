// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// D4: Die Treppe. Je Rätselspiel eine Treppe aus Stufen; offene Stufen sind gefüllt, gesperrte zeigen ein Schloss und die Zahl der Siege.
public struct LeiterUebersicht: View {
    @AppStorage(Leiter.alleOffenKey) private var alleOffen = false
    @AppStorage(Leiter.kinderKey) private var kinder = false
    public init() {}

    public var body: some View {
        List {
            Section {
                Toggle(isOn: $alleOffen) {
                    Text("Alle Stufen offen")
                    Text("Dann ist keine Stufe gesperrt. Im Kinder-Modus sind ohnehin alle offen.")
                }
                .disabled(kinder)
            } footer: {
                Text("Jede Stufe öffnet sich, wenn du \(Leiter.siegeNoetig) Mal ohne Tipp auf der Stufe davor gewinnst. Tagesrätsel zählen nicht.")
            }
            Section {
                ForEach(Leiter.spiele.filter { Leiter.istSichtbar($0.id) }, id: \.id) { s in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey(s.name)).font(.headline)
                        Treppe(spiel: s.id, namen: s.stufen)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("Schwierigkeitsleiter")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct Treppe: View {
        let spiel: String
        let namen: [String]
        var body: some View {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(namen.enumerated()), id: \.offset) { i, n in
                    let offen = Leiter.offen(spiel, stufe: i)
                    let siege = min(Leiter.siege(spiel, stufe: i), Leiter.siegeNoetig)
                    VStack(spacing: 4) {
                        Text(offen ? "\(siege)/\(Leiter.siegeNoetig)" : "🔒").font(.caption2).foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(offen ? Color.accentColor : Color(.tertiarySystemFill))
                            .frame(height: 16 + CGFloat(i) * 14)
                        Text(LocalizedStringKey(n)).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(LocalizedStringKey(n)))
                    .accessibilityValue(offen ? Text("offen, \(siege) von \(Leiter.siegeNoetig) Siegen") : Text("gesperrt"))
                }
            }
        }
    }
}
#endif
