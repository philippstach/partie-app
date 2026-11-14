// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Hand als Fächer: überlappende Karten, spielbare angehoben und umrandet, Tipp gelb. Bei vielen Karten zweilagig,
/// reicht auch das nicht, ist der Fächer horizontal scrollbar. Das Kartenbild kommt vom Spiel (`bild`).
public struct KartenFaecher<Karte: Hashable, Bild: View>: View {
    let karten: [Karte]
    let spielbar: Set<Karte>
    let tipp: Karte?
    let kartenBreite: CGFloat
    let kartenHoehe: CGFloat
    let beschriftung: (Karte) -> Text
    let aktion: (Karte) -> Void
    let bild: (Karte, Bool) -> Bild   // (Karte, spielbar)
    var mindestSchritt: CGFloat = 26
    var absenkung: CGFloat = 14   // wie tief unspielbare Karten sitzen
    @State private var breite: CGFloat = 0

    public init(karten: [Karte], spielbar: Set<Karte>, tipp: Karte? = nil, kartenBreite: CGFloat, kartenHoehe: CGFloat,
                mindestSchritt: CGFloat = 26, absenkung: CGFloat = 14, beschriftung: @escaping (Karte) -> Text, aktion: @escaping (Karte) -> Void, @ViewBuilder bild: @escaping (Karte, Bool) -> Bild) {
        self.karten = karten; self.spielbar = spielbar; self.tipp = tipp; self.kartenBreite = kartenBreite; self.kartenHoehe = kartenHoehe
        self.mindestSchritt = mindestSchritt; self.absenkung = absenkung; self.beschriftung = beschriftung; self.aktion = aktion; self.bild = bild
    }

    private static var anhebung: CGFloat { 14 }
    private var masse: FaecherMasse { FaecherMasse.berechne(anzahl: karten.count, breite: breite - 2 * Theme.seitenRand, kartenBreite: kartenBreite, mindestSchritt: mindestSchritt) }
    private var hoehe: CGFloat { CGFloat(max(masse.zeilen.count, 1)) * (kartenHoehe * 0.62) + kartenHoehe * 0.38 + Self.anhebung }

    public var body: some View {
        let m = masse
        let passt = m.inhaltsBreite <= breite - 2 * Theme.seitenRand + 0.5
        return Group {
            if passt { faecher(m).frame(maxWidth: .infinity) }
            else { ScrollView(.horizontal, showsIndicators: false) { faecher(m).padding(.horizontal, Theme.seitenRand) } }
        }
        .frame(height: hoehe)
        .background(GeometryReader { g in Color.clear.onAppear { breite = g.size.width }.onChange(of: g.size.width) { _, n in breite = n } })
        .accessibilityElement(children: .contain)
    }

    private func faecher(_ m: FaecherMasse) -> some View {
        let uberlapp = kartenHoehe * 0.62
        return ZStack(alignment: .topLeading) {
            ForEach(Array(m.zeilen.enumerated()), id: \.offset) { z, bereich in
                ForEach(Array(bereich), id: \.self) { i in
                    let k = karten[i]
                    let sp = spielbar.contains(k)
                    Button { aktion(k) } label: {
                        bild(k, sp)
                            .frame(width: kartenBreite, height: kartenHoehe)
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == k ? 1 : 0))
                    }
                    .buttonStyle(.plain)
                    .offset(x: CGFloat(i - bereich.lowerBound) * m.schritt, y: CGFloat(z) * uberlapp + (sp ? 0 : absenkung))
                    .zIndex(Double(z * 100 + i - bereich.lowerBound))
                    .accessibilityLabel(beschriftung(k))
                    .accessibilityValue(tipp == k ? Text("Tipp") : (sp ? Text("spielbar") : Text(verbatim: "")))
                }
            }
        }
        .frame(width: m.inhaltsBreite, height: hoehe, alignment: .topLeading)
    }
}

/// Stapel mit Zähler (Nachziehstapel oder Ablage): Rückseite bzw. oberste Karte und die Anzahl darunter.
public struct StapelAnzeige<Oben: View>: View {
    let titel: LocalizedStringKey
    let anzahl: Int
    let oben: Oben

    public init(_ titel: LocalizedStringKey, anzahl: Int, @ViewBuilder oben: () -> Oben) { self.titel = titel; self.anzahl = anzahl; self.oben = oben() }

    public var body: some View {
        VStack(spacing: Design.Abstand.xs) {
            oben.opacity(anzahl == 0 ? 0.25 : 1)
            Text(titel).font(.caption2).foregroundStyle(.secondary)
            Text(verbatim: "\(anzahl)").font(.footnote.weight(.semibold).monospacedDigit())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(titel)).accessibilityValue(Text(verbatim: "\(anzahl)"))
    }
}
#endif
