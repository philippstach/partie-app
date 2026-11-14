// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Hinweise (Konzept 3.4 „Hinweis“): Erklär-Blatt für Tipps, Hinweiskarte für Zustände.
// Nie Text direkt auf dem Spielfeld, nie ein Rahmen, kein Banner, kein Dialog beim ersten Start.

#if canImport(UIKit)

/// Inhalt des Erklär-Sheets (Tipp mit Erklärung): Griff, Symbol-Kreis + Titel, Text, Hinweiszeile, zwei Pillen.
/// Wird in `.sheet` mit `.presentationDetents([.height(…)])` oder als schwebende Fläche am unteren Rand gezeigt.
public struct ErklaerSheet: View {
    let symbol: String
    let titel: Text
    let text: Text
    var hinweis: Text? = nil
    let sekundaerTitel: LocalizedStringKey
    let primaerTitel: LocalizedStringKey
    let sekundaer: () -> Void
    let primaer: () -> Void

    public init(symbol: String, titel: LocalizedStringKey, text: Text, hinweis: LocalizedStringKey? = nil,
                sekundaerTitel: LocalizedStringKey, primaerTitel: LocalizedStringKey,
                sekundaer: @escaping () -> Void, primaer: @escaping () -> Void) {
        self.init(symbol: symbol, titel: Text(titel), text: text, hinweis: hinweis.map { Text($0) },
                  sekundaerTitel: sekundaerTitel, primaerTitel: primaerTitel, sekundaer: sekundaer, primaer: primaer)
    }

    /// Mit fertig übersetzten Texten (Baustein-Wunsch 4): `titel: Text(verbatim: tipp.titel)`,
    /// `hinweis: tipp.notiz.map { Text(verbatim: $0) }`. Die Knopftitel bleiben Schlüssel.
    public init(symbol: String, titel: Text, text: Text, hinweis: Text? = nil,
                sekundaerTitel: LocalizedStringKey, primaerTitel: LocalizedStringKey,
                sekundaer: @escaping () -> Void, primaer: @escaping () -> Void) {
        self.symbol = symbol; self.titel = titel; self.text = text; self.hinweis = hinweis
        self.sekundaerTitel = sekundaerTitel; self.primaerTitel = primaerTitel
        self.sekundaer = sekundaer; self.primaer = primaer
    }

    @Environment(\.designArt) private var art

    public var body: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Capsule().fill(art == .klar ? Color(.systemGray4) : Color.linie).frame(width: 36, height: 5).frame(maxWidth: .infinity)
            HStack(spacing: 10) {
                if art == .klar {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentText)
                        .frame(width: 30, height: 30)
                        .background(Color.accentSoft, in: .circle)
                        .accessibilityHidden(true)
                    titel.font(.headline).accessibilityAddTraits(.isHeader)
                } else {
                    Image(systemName: symbol).font(.system(size: 17, weight: art == .salon ? .bold : .regular))
                        .foregroundStyle(Color.accentText).accessibilityHidden(true)
                    titel.font(Design.Schrift.name).foregroundStyle(Color.schrift).accessibilityAddTraits(.isHeader)
                }
            }
            text.font(.body)
            if let hinweis { hinweis.font(.footnote).foregroundStyle(.secondary) }
            HStack(spacing: Design.Abstand.s) {
                Button(action: sekundaer) { Text(sekundaerTitel) }
                    .buttonStyle(AkzentPilleStil(gefuellt: false))
                Button(action: primaer) { Text(primaerTitel) }
                    .buttonStyle(AkzentPilleStil(gefuellt: true))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if art != .klar {
                // Tinte: Papierzettel mit Tinte-Rand. Salon: Papier mit starker Linie oben.
                Rectangle().fill(Color.kartenGrund)
                    .overlay { if art == .tinte { RoundedRectangle(cornerRadius: Theme.sheetRadius).strokeBorder(Color.linieStark, lineWidth: 1) } }
                    .overlay(alignment: .top) { if art == .salon { ZeilenLinie(stark: true, staerke: 2) } }
                    .clipShape(.rect(cornerRadius: Theme.sheetRadius))
            } else if #available(iOS 26, *) {
                Color.clear.glassEffect(.regular, in: .rect(cornerRadius: Theme.sheetRadius))
            } else {
                RoundedRectangle(cornerRadius: Theme.sheetRadius).fill(.regularMaterial)
            }
        }
        .padding(.horizontal, 8)
    }
}

/// Hinweiskarte für Zustände („Clara verliert die Runde“, „Wendepunkt“, „So geht's“, „Erste Partie – geführt“):
/// Karte mit accentSoft-Fläche, Symbol, Titel, Text, optional EIN Zweitknopf. Ersetzt Rahmenkarten, Banner und Textlinks.
/// Zwei Aktionen („Nächste Übung“ + „Weiterspielen“) sind kein Fall für die Karte, sondern für `ErklaerSheet` (Wunsch 5).
public struct HinweisKarte: View {
    let symbol: String
    let titel: Text
    let text: Text
    let knopfTitel: Text?
    let knopfAktion: (() -> Void)?

    public init(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey,
                knopfTitel: LocalizedStringKey? = nil, knopfAktion: (() -> Void)? = nil) {
        self.symbol = symbol; self.titel = Text(titel); self.text = Text(text)
        self.knopfTitel = knopfTitel.map { Text($0) }; self.knopfAktion = knopfAktion
    }

    public init(symbol: String, titel: Text, text: Text, knopfTitel: Text? = nil, knopfAktion: (() -> Void)? = nil) {
        self.symbol = symbol; self.titel = titel; self.text = text
        self.knopfTitel = knopfTitel; self.knopfAktion = knopfAktion
    }

    @Environment(\.designArt) private var art

    public var body: some View {
        switch art {
        case .klar:
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: Design.Abstand.s) {
                    Image(systemName: symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentText)
                        .accessibilityHidden(true)
                    titel.font(.headline).accessibilityAddTraits(.isHeader)
                }
                text.font(.subheadline).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                if let knopfTitel, let knopfAktion {
                    Button(action: knopfAktion) { knopfTitel.lineLimit(1).minimumScaleFactor(0.7) }.zweitKnopf().padding(.top, 2)
                }
            }
            .padding(Theme.innen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentSoft, in: .rect(cornerRadius: Theme.cardRadius))
        case .tinte:
            // Papierzettel mit Tinte-Rand: Titel in Serifenschrift, Text darunter
            VStack(alignment: .leading, spacing: Design.Abstand.s) {
                HStack(alignment: .firstTextBaseline, spacing: Design.Abstand.s) {
                    Image(systemName: symbol).font(.subheadline).foregroundStyle(Color.accentText).accessibilityHidden(true)
                    titel.font(Design.Schrift.serif(18, gewicht: .medium, relativ: .headline)).italic().foregroundStyle(Color.schrift)
                        .accessibilityAddTraits(.isHeader)
                }
                text.font(.subheadline).foregroundStyle(Color.schrift).fixedSize(horizontal: false, vertical: true)
                if let knopfTitel, let knopfAktion {
                    Button(action: knopfAktion) { knopfTitel.lineLimit(1).minimumScaleFactor(0.7) }.zweitKnopf().padding(.top, 2)
                }
            }
            .padding(Theme.innen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.kartenGrund)
            .overlay { Rectangle().strokeBorder(Color.linieStark, lineWidth: 1) }
        case .salon:
            // Farbblock in der Spielart-Farbe (für kleine Schrift so weit nötig abgedunkelt), Label oben, Text kursiv in Serifenschrift
            let farben = Design.spielFarben
            let schrift = farben?.aufFlaeche ?? Design.werte.aufHuelleFlaeche.color
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: Design.Abstand.s) {
                    Image(systemName: symbol).font(.caption.weight(.bold)).accessibilityHidden(true)
                    titel.font(Design.Schrift.label).tracking(Design.Schrift.labelSperrung).textCase(.uppercase)
                        .accessibilityAddTraits(.isHeader)
                }
                .opacity(0.9)
                text.font(Design.Schrift.serif(18, gewicht: .light, relativ: .body, kursiv: true)).fixedSize(horizontal: false, vertical: true)
                if let knopfTitel, let knopfAktion {
                    Button(action: knopfAktion) { knopfTitel.lineLimit(1).minimumScaleFactor(0.7) }.zweitKnopf().padding(.top, 4)
                        .environment(\.knopfFarben, (flaeche: schrift, schrift: schrift))
                }
            }
            .foregroundStyle(schrift)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(farben?.flaecheFuerKleineSchrift ?? Color.hinweisFlaecheHuelle)
        }
    }
}

public extension Color {
    /// Farbblock der Hülle (Salon: Terrakotta) für Stellen mit kleiner Schrift: die Hüllenfläche, so weit nötig abgedunkelt,
    /// bis die Schrift darauf 4,5:1 erreicht. In klar und Tinte die Hüllenfläche selbst.
    static var hinweisFlaecheHuelle: Color {
        let w = Design.werte
        return Color(hell: Kontrast.angepasst(flaeche: w.huelleFlaeche.hell, schrift: w.aufHuelleFlaeche.hell),
                     dunkel: Kontrast.angepasst(flaeche: w.huelleFlaeche.dunkel, schrift: w.aufHuelleFlaeche.dunkel))
    }
}

#endif
