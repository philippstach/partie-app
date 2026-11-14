// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Echte oder virtuelle Würfel, je Spiel gemerkt. Ohne eigene Wahl gilt die Vorgabe (Einstellung der Sammlung).
public enum WuerfelWahl {
    private static func schluessel(_ spiel: String) -> String { "partie.wuerfel.\(spiel)" }

    public static func quelle(_ spiel: String, vorgabe: WuerfelQuelle = .app, defaults: UserDefaults = .standard) -> WuerfelQuelle {
        defaults.string(forKey: schluessel(spiel)).flatMap(WuerfelQuelle.init(rawValue:)) ?? vorgabe
    }

    public static func setze(_ q: WuerfelQuelle, spiel: String, defaults: UserDefaults = .standard) {
        defaults.set(q.rawValue, forKey: schluessel(spiel))
    }
}

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Bezeichnungen der Wahlkarte. Standard = Würfel; z. B. Münzen oder Bohnen für Spiele ohne Würfel.
public struct WuerfelTexte {
    public var titel: LocalizedStringKey, virtuell: LocalizedStringKey, echt: LocalizedStringKey
    public var hinweisVirtuell: LocalizedStringKey, hinweisEcht: LocalizedStringKey
    public init(titel: LocalizedStringKey = "Würfel", virtuell: LocalizedStringKey = "Virtuell", echt: LocalizedStringKey = "Echt",
                hinweisVirtuell: LocalizedStringKey = "Die App würfelt für dich.", hinweisEcht: LocalizedStringKey = "Du würfelst am Tisch und tippst die Augen ein.") {
        self.titel = titel; self.virtuell = virtuell; self.echt = echt; self.hinweisVirtuell = hinweisVirtuell; self.hinweisEcht = hinweisEcht
    }
    public static let wuerfel = WuerfelTexte()
    public static let muenzen = WuerfelTexte(titel: "Münzen", hinweisVirtuell: "Die App wirft die Münzen für dich.", hinweisEcht: "Du wirfst am Tisch und tippst das Ergebnis ein.")
    public static let bohnen = WuerfelTexte(titel: "Bohnen", hinweisVirtuell: "Die App wirft die Bohnen für dich.", hinweisEcht: "Du wirfst am Tisch und tippst das Ergebnis ein.")
}

/// Umschalter „Virtuelle Würfel | Echte Würfel“ für den Spielstart, vor „Neues Spiel“.
public struct WuerfelWahlKarte: View {
    let spiel: String
    let geaendert: ((WuerfelQuelle) -> Void)?
    let texte: WuerfelTexte
    @State private var quelle: WuerfelQuelle
    @Environment(\.dynamicTypeSize) private var schrift

    public init(spiel: String, vorgabe: WuerfelQuelle = .app, geaendert: ((WuerfelQuelle) -> Void)? = nil, texte: WuerfelTexte = .wuerfel) {
        self.spiel = spiel; self.geaendert = geaendert; self.texte = texte
        _quelle = State(initialValue: WuerfelWahl.quelle(spiel, vorgabe: vorgabe))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(texte.titel)
            (schrift.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Design.Abstand.s)) : AnyLayout(HStackLayout(spacing: Design.Abstand.s))) {
                knopf(.app, texte.virtuell, "iphone")
                knopf(.echt, texte.echt, "dice")
            }
            Text(quelle == .app ? texte.hinweisVirtuell : texte.hinweisEcht)
                .font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .sensoryFeedback(.selection, trigger: quelle)
    }

    /// Auswahl in Tinte (Kreis wie ein Radio-Knopf) und Salon (Rechteck mit Rand, gewählt gefüllt).
    @ViewBuilder private func wahlNeu(_ aktiv: Bool, _ titel: LocalizedStringKey) -> some View {
        if Design.ist(.salon) {
            Text(titel).font(.subheadline.weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
                .foregroundStyle(aktiv ? Color.seitenGrund : Color.schrift)
                .background(aktiv ? Color.schrift : Color.clear)
                .overlay { Rectangle().strokeBorder(Color.linieStark, lineWidth: 2) }
                .contentShape(.rect)
        } else {
            HStack(spacing: Design.Abstand.s) {
                Circle().strokeBorder(Color.linieStark, lineWidth: 1.5).frame(width: 22, height: 22)
                    .overlay { if aktiv { Circle().fill(Color.linieStark).padding(4) } }
                Text(titel).font(.body.weight(aktiv ? .semibold : .regular)).foregroundStyle(Color.schrift).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.tapSize, alignment: .leading).contentShape(.rect)
        }
    }

    private func knopf(_ q: WuerfelQuelle, _ titel: LocalizedStringKey, _ symbol: String) -> some View {
        let aktiv = quelle == q
        return Button {
            quelle = q; WuerfelWahl.setze(q, spiel: spiel); geaendert?(q)
        } label: {
            if Design.art != .klar { wahlNeu(aktiv, titel) } else {   // Designwechsel: Tinte und Salon in der Formsprache des Designs
            Label(titel, systemImage: symbol).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
                .foregroundStyle(aktiv ? Color.onAccent : Color.primary)
                .background(aktiv ? Color.appFlaeche : Color(.tertiarySystemFill), in: .rect(cornerRadius: Theme.feldRadius))
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(aktiv ? .isSelected : [])
    }
}
#endif
