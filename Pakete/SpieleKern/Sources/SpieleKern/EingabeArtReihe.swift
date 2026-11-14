// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Ein Knopf der Reihe „Kamera · Scanner · Ansagen · Zurück“ über den Würfeltasten (Blatt 15).
public struct EingabeKnopfDaten: Identifiable {
    public let id: String
    public let symbol: String
    public let wort: LocalizedStringKey
    /// Langer Text für VoiceOver („Mit Kamera lesen“).
    public let vorlesetext: LocalizedStringKey
    public let hinweis: LocalizedStringKey?
    /// Gefüllt in Tinte (zum Beispiel „Fertig“ beim Zuhören).
    public let hervorgehoben: Bool
    /// Blass und nicht antippbar (zum Beispiel „Zurück“, solange nichts eingetragen ist).
    public let gesperrt: Bool
    public let aktion: () -> Void

    public init(id: String, symbol: String, wort: LocalizedStringKey, vorlesetext: LocalizedStringKey, hinweis: LocalizedStringKey? = nil,
                hervorgehoben: Bool = false, gesperrt: Bool = false, aktion: @escaping () -> Void) {
        self.id = id; self.symbol = symbol; self.wort = wort; self.vorlesetext = vorlesetext; self.hinweis = hinweis
        self.hervorgehoben = hervorgehoben; self.gesperrt = gesperrt; self.aktion = aktion
    }
}

/// Gleich breite Flächen mit Zeichen oben und Kurzwort darunter (Höhe 60, Ecke 14, Abstand 8). Fehlt ein Knopf, teilen sich die übrigen die Breite.
/// Das Wort schrumpft bei Bedarf, bricht aber nie mitten im Wort.
public struct EingabeArtReihe: View {
    let knoepfe: [EingabeKnopfDaten]

    public init(_ knoepfe: [EingabeKnopfDaten]) { self.knoepfe = knoepfe }

    private static let flaeche = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.12) : UIColor(red: 0xEF / 255, green: 0xEE / 255, blue: 0xE9 / 255, alpha: 1) })

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(knoepfe) { k in
                Button(action: k.aktion) {
                    VStack(spacing: 4) {
                        Image(systemName: k.symbol).font(.system(size: 22))
                        Text(k.wort).font(.system(size: 12.5, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundStyle(k.hervorgehoben ? Color.onAccent : Color.primary)
                    .background(k.hervorgehoben ? Color.accentColor : Self.flaeche, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(k.gesperrt)
                .opacity(k.gesperrt ? 0.38 : 1)
                .accessibilityLabel(Text(k.vorlesetext))
                .accessibilityHint(k.hinweis.map { Text($0) } ?? Text(verbatim: ""))
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}
#endif
