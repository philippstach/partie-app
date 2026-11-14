// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Designwechsel (KlarGlas 2.17): Auswahl des Designs in den Einstellungen. Drei Vorschaukarten mit einer kleinen
// gezeichneten Miniatur je Design (Grund, Titelzeile, Linie oder Farbblock, Knopfform), Name darunter, Haken beim gewählten.
// Die Miniaturen zeichnen immer IHR Design (nicht das gerade gewählte), deshalb lesen sie die Werte direkt aus `DesignWerte`.

#if canImport(UIKit)

/// Zeile „Design“ für die Einstellungen: drei Vorschaukarten nebeneinander, darunter der Kurztext des gewählten Designs.
/// Antippen wechselt sofort (`Design.art`); die Hülle baut die Wurzel nach dem Schließen der Einstellungen einmal neu auf.
public struct DesignAuswahl: View {
    @Environment(\.designArt) private var art

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Design", bundle: .module)
            HStack(alignment: .top, spacing: 10) {
                ForEach(DesignArt.allCases) { a in
                    Button { Design.art = a } label: { karte(a, gewaehlt: a == art) }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: a.name))
                        .accessibilityValue(Text(verbatim: a.kurztext))
                        .accessibilityAddTraits(a == art ? [.isButton, .isSelected] : .isButton)
                }
            }
            Text(verbatim: art.kurztext).font(.footnote).foregroundStyle(.secondary)
                .accessibilityHidden(true)   // steht als Wert an jeder Karte
        }
        .padding(.vertical, 4)
    }

    private func karte(_ a: DesignArt, gewaehlt: Bool) -> some View {
        VStack(spacing: 6) {
            DesignMiniatur(art: a)
                .aspectRatio(0.72, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(gewaehlt ? Color.accentText : Color.linie, lineWidth: gewaehlt ? 2.5 : 1)
                }
                .overlay(alignment: .topTrailing) {
                    if gewaehlt {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.accentText)
                            .padding(5)
                    }
                }
            Text(verbatim: a.name)
                .font(.caption.weight(gewaehlt ? .bold : .regular))
                .lineLimit(1).minimumScaleFactor(0.7)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
    }
}

/// Kleine gezeichnete Vorschau eines Designs: Grund, Titelzeile, Linien oder Farbblock, Knopfform.
struct DesignMiniatur: View {
    let art: DesignArt

    var body: some View {
        GeometryReader { g in
            let b = g.size.width, h = g.size.height
            switch art {
            case .klar: klar(b, h)
            case .tinte: tinte(b, h)
            case .salon: salon(b, h)
            }
        }
        .accessibilityHidden(true)
    }

    /// Klar & Glas: Gruppengrund, fetter Titel in Nachtblau, zwei runde Karten, Pille in der Hüllenfarbe.
    private func klar(_ b: CGFloat, _ h: CGFloat) -> some View {
        let w = DesignWerte.klar
        return ZStack(alignment: .topLeading) {
            Color(.systemGroupedBackground)
            VStack(alignment: .leading, spacing: h * 0.05) {
                RoundedRectangle(cornerRadius: 2).fill(w.huelleFlaeche.color).frame(width: b * 0.5, height: h * 0.085)
                RoundedRectangle(cornerRadius: b * 0.09).fill(Color(.secondarySystemGroupedBackground)).frame(height: h * 0.2)
                RoundedRectangle(cornerRadius: b * 0.09).fill(Color(.secondarySystemGroupedBackground)).frame(height: h * 0.2)
                Spacer(minLength: 0)
                Capsule().fill(w.huelleFlaeche.color).frame(height: h * 0.13)
            }
            .padding(b * 0.1)
        }
    }

    /// Tinte: Papier, Serifen-Titel, Tinte-Linie und Haarlinien mit Tintenpunkten, schwarze Pille.
    private func tinte(_ b: CGFloat, _ h: CGFloat) -> some View {
        let w = DesignWerte.tinte
        let punkte: [Design.Spielart] = [.karten, .wuerfel, .brett]
        return ZStack(alignment: .topLeading) {
            (w.seitenGrund ?? FarbPaar(0xFBFBF8)).color
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "Aa").font(.system(size: h * 0.17, weight: .medium, design: .serif))
                    .foregroundStyle((w.schrift ?? FarbPaar(0x1B1B1F)).color)
                Rectangle().fill((w.linieStark ?? FarbPaar(0x1B1B1F)).color).frame(height: 1).padding(.top, h * 0.03)
                ForEach(punkte, id: \.self) { p in
                    HStack(spacing: b * 0.06) {
                        Circle().fill(w.palette?[p]?.flaeche ?? .gray).frame(width: b * 0.07, height: b * 0.07)
                        RoundedRectangle(cornerRadius: 1).fill((w.schrift ?? FarbPaar(0x1B1B1F)).color.opacity(0.75))
                            .frame(width: b * (p == .wuerfel ? 0.3 : 0.42), height: h * 0.03)
                    }
                    .frame(height: h * 0.11)
                    Rectangle().fill((w.linie ?? FarbPaar(0xE3E3DE)).color).frame(height: 1)
                }
                Spacer(minLength: 0)
                Capsule().fill((w.knopf ?? FarbPaar(0x1B1B1F)).color).frame(height: h * 0.13)
            }
            .padding(b * 0.1)
        }
    }

    /// Salon: obere Hälfte Farbblock in Terrakotta mit großer Serife, darunter Linien-Zeilen, Rechteck-Knopf in Espresso.
    private func salon(_ b: CGFloat, _ h: CGFloat) -> some View {
        let w = DesignWerte.salon
        return ZStack(alignment: .top) {
            (w.seitenGrund ?? FarbPaar(0xF3EBDD)).color
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    w.huelleFlaeche.color
                    Text(verbatim: "Aa").font(.system(size: h * 0.22, weight: .bold, design: .serif))
                        .foregroundStyle(w.aufHuelleFlaeche.color)
                        .padding(.leading, b * 0.1).padding(.bottom, h * 0.02)
                }
                .frame(height: h * 0.44)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<2, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1).fill((w.schrift ?? FarbPaar(0x1E1A17)).color.opacity(0.75))
                            .frame(width: b * (i == 0 ? 0.45 : 0.32), height: h * 0.035)
                            .frame(height: h * 0.11)
                        Rectangle().fill((w.linie ?? FarbPaar(0xD9CDB8)).color).frame(height: 1)
                    }
                    Spacer(minLength: 0)
                    Rectangle().fill((w.knopf ?? FarbPaar(0x1E1A17)).color).frame(height: h * 0.13)
                }
                .padding(.horizontal, b * 0.1).padding(.bottom, b * 0.1)
            }
        }
    }
}

#endif
