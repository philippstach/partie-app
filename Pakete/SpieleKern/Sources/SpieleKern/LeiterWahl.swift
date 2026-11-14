// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI

/// D4: Stufenwahl als Leiter. Wie ein Segment-Schalter, aber gesperrte Stufen zeigen ein Schloss und sind abgeschaltet;
/// darunter steht, was noch fehlt. `stufe` zählt ab 0 (leicht).
public struct LeiterWahl: View {
    let spiel: String
    let namen: [LocalizedStringKey]
    @Binding var stufe: Int
    @Environment(\.dynamicTypeSize) private var schrift

    public init(spiel: String, namen: [LocalizedStringKey], stufe: Binding<Int>) {
        self.spiel = spiel; self.namen = namen; _stufe = stufe
    }

    public var body: some View {
        let anzahl = namen.count
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: schrift.isAccessibilitySize ? 1 : (anzahl == 4 ? 2 : max(anzahl, 1))), spacing: 8) {
                ForEach(0..<anzahl, id: \.self) { i in
                    let offen = Leiter.offen(spiel, stufe: i)
                    Button { stufe = i } label: {
                        HStack(spacing: 4) {
                            if !offen { Image(systemName: "lock.fill").font(.caption2) }
                            Text(namen[i]).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.bordered)
                    .tint(stufe == i ? .accentColor : .secondary)
                    .disabled(!offen)
                    .accessibilityAddTraits(stufe == i ? .isSelected : [])
                    .accessibilityHint(offen ? Text("") : Text("Gesperrt. Gewinne \(Leiter.fehlend(spiel, stufe: i)) Mal ohne Tipp auf der Stufe davor."))
                }
            }
            if let naechste = (0..<anzahl).first(where: { !Leiter.offen(spiel, stufe: $0) }) {
                Label("Noch \(Leiter.fehlend(spiel, stufe: naechste)) Siege ohne Tipp für die nächste Stufe", systemImage: "lock.open")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .onAppear { stufe = Leiter.begrenzt(spiel, stufe: stufe, anzahl: anzahl) }
    }
}
#endif
