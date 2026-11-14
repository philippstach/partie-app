// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielerleiste: je Person Avatar, Name, Deckelzahl und – wenn die Höhe reicht – die Deckelreihe. Der aktive Spieler ist gefüllt,
/// ausgeschiedene Spieler sind gedämpft. Tipp öffnet den Verlauf. Ab fünf Personen zwei Reihen, auf dem iPad quer als Spalte.
struct NeuSpielerLeiste: View {
    let z: Spielzustand
    var hoehe: Double
    var senkrecht = false
    var aufTipp: () -> Void = {}
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var spieler: [Int] { z.haelfte.spieler }
    private var mitReihe: Bool { senkrecht || NeuLogik.zeigtDeckelReihe(hoehe: hoehe, grosseSchrift: typeSize.isAccessibilitySize) }
    private var zweireihig: Bool { !senkrecht && spieler.count > 3 }

    var body: some View {
        if Tisch.aktiv && spieler.count <= 6 { tinteLeiste } else { bisherigeLeiste }
    }

    /// Große Tinte-Runde, Punkt 6: runde Leiste mit Bild und eigener Spielerfarbe wie in den Kartenspielen. Der Wert ist die Deckelzahl.
    private var tinteLeiste: some View {
        let aktiv = ![.rundenwertung].contains(z.phase) ? z.aktuellerSpieler : nil
        return SpielerLeiste(eintraege: spieler.map { s in
            .init(id: "\(s)", name: z.namen[s], farbe: Spieler.farbe(s), wert: "\(z.haelfte.deckelVon(s))")
        }, aktiv: aktiv.map { "\($0)" })
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .contentShape(.rect)
        .onTapGesture(perform: aufTipp)
        .accessibilityElement(children: .contain)
    }

    private var bisherigeLeiste: some View {
        Group {
            if senkrecht {
                VStack(spacing: 6) { ForEach(spieler, id: \.self) { kachel($0) } }
            } else {
                let reihen = zweireihig ? stride(from: 0, to: spieler.count, by: 3).map { Array(spieler[$0..<min($0 + 3, spieler.count)]) } : [spieler]
                VStack(spacing: Design.Abstand.xs) {
                    ForEach(Array(reihen.enumerated()), id: \.offset) { _, reihe in
                        HStack(spacing: Design.Abstand.xs) {
                            ForEach(reihe, id: \.self) { kachel($0) }
                            if zweireihig { ForEach(0..<(3 - reihe.count), id: \.self) { _ in Color.clear.frame(maxWidth: .infinity) } }
                        }
                    }
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .tischFlaeche(16)
        .contentShape(.rect)
        .onTapGesture(perform: aufTipp)
        .accessibilityElement(children: .contain)
    }

    private func kachel(_ s: Int) -> some View {
        let anzahl = z.haelfte.deckelVon(s)
        let aktiv = z.aktuellerSpieler == s && ![.rundenwertung].contains(z.phase)
        let raus = z.haelfte.raus.contains(s)
        let farbe = Theme.color(s)
        let inhalt = VStack(spacing: 2) {
            HStack(spacing: 3) {
                Text(z.avatare[s]).font(.subheadline)
                Text(z.namen[s]).font(.caption.weight(aktiv ? .bold : .regular)).lineLimit(1).minimumScaleFactor(0.6)
            }
            Text("\(anzahl)")
                .font(.system(.title3, design: Design.zahlDesign, weight: .heavy)).monospacedDigit()
                .contentTransition(.numericText(value: Double(anzahl)))
                .animation(reduceMotion ? nil : .snappy(duration: 0.5), value: anzahl)
            if mitReihe && !senkrecht { DeckelReihe(anzahl: anzahl).frame(height: 18) }
        }
        return Group {
            if senkrecht {
                HStack(spacing: Design.Abstand.s) {
                    Text(z.avatare[s]).font(.title3)
                    Text(z.namen[s]).font(.subheadline.weight(aktiv ? .bold : .regular)).lineLimit(1)
                    Spacer(minLength: 4)
                    DeckelReihe(anzahl: anzahl)
                    Text("\(anzahl)").font(.system(.headline, design: Design.zahlDesign, weight: .heavy)).monospacedDigit().frame(minWidth: 26, alignment: .trailing)
                }
            } else {
                inhalt
            }
        }
        .padding(.vertical, 5).padding(.horizontal, senkrecht ? 8 : 3)
        .frame(maxWidth: .infinity)
        .opacity(raus ? 0.45 : 1)
        .background(aktiv ? farbe.opacity(0.18) : .clear, in: .rect(cornerRadius: Design.Ecke.feld))
        .overlay(RoundedRectangle(cornerRadius: Design.Ecke.feld).strokeBorder(aktiv ? farbe.opacity(0.7) : .clear, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.sprechtext(z, s, aktiv: aktiv, raus: raus))
    }

    static func sprechtext(_ z: Spielzustand, _ s: Int, aktiv: Bool, raus: Bool) -> Text {
        let n = z.haelfte.deckelVon(s)
        var t = Text("\(z.namen[s]), \(n) Deckel")
        if raus { t = t + Text(", raus") } else if aktiv { t = t + Text(", am Zug") }
        return t
    }
}
