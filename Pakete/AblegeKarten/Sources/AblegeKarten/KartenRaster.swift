// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Hand als Raster ohne Überlappung (F-AWS-G-013, K-029): jede Karte liegt ganz frei, Zahl und Zeichen werden nie verdeckt.
/// Spielbare Karten bekommen den Rand aus dem Kartenbild, der Tipp einen gelben Rahmen. Die Maße kommen aus `RasterMasse`;
/// passt die Hand auch mit der kleinsten Kartengröße nicht in die Höhe, scrollt sie senkrecht. Das Kartenbild liefert das Spiel.
public struct KartenRaster<Karte: Hashable, Bild: View>: View {
    let karten: [Karte]
    let spielbar: Set<Karte>
    let tipp: Karte?
    let masse: RasterMasse
    let beschriftung: (Karte) -> Text
    let aktion: (Karte) -> Void
    let bild: (Karte, Bool, CGSize) -> Bild   // (Karte, spielbar, Größe)

    public init(karten: [Karte], spielbar: Set<Karte>, tipp: Karte? = nil, masse: RasterMasse,
                beschriftung: @escaping (Karte) -> Text, aktion: @escaping (Karte) -> Void,
                @ViewBuilder bild: @escaping (Karte, Bool, CGSize) -> Bild) {
        self.karten = karten; self.spielbar = spielbar; self.tipp = tipp; self.masse = masse
        self.beschriftung = beschriftung; self.aktion = aktion; self.bild = bild
    }

    public var body: some View {
        Group {
            if masse.passt { raster }
            else { ScrollView(.vertical, showsIndicators: true) { raster }.scrollBounceBehavior(.basedOnSize) }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var raster: some View {
        let m = masse
        return VStack(spacing: m.abstand) {
            ForEach(0..<m.zeilen, id: \.self) { z in
                HStack(spacing: m.abstand) {
                    ForEach(Array(karten.indices.dropFirst(z * m.spalten).prefix(m.spalten)), id: \.self) { i in
                        let k = karten[i]
                        let sp = spielbar.contains(k)
                        Button { aktion(k) } label: {
                            bild(k, sp, m.karte)
                                .frame(width: m.karte.width, height: m.karte.height)
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == k ? 1 : 0))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(beschriftung(k))
                        .accessibilityValue(tipp == k ? Text("Tipp") : (sp ? Text("spielbar") : Text(verbatim: "")))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
#endif
