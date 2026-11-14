// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Würfelzone fest unten im Daumenbereich: fünf Würfel (gehaltene leicht abgesetzt), Wurfpunkte, Hinweiszeile und die Knöpfe.
struct NeuWuerfelZone: View {
    let record: GameRecord
    let kante: Double
    @Binding var gewaehlt: Category?
    var computerAmZug: Bool
    var wirbelnd: Set<Int>
    var gezeigt: [Int]
    var rat: HoldAdvice?
    @Binding var tippAn: Bool
    var wuerfeln: () -> Void
    var eintragen: (Category) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(GameStore.self) private var store
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.designArt) private var art   // Designwechsel D.4

    private var state: GameState { record.state }
    private var echt: Bool { record.settings.diceMode == .real }

    var body: some View {
        VStack(spacing: Design.Abstand.s) {
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in wuerfel(i) }
            }
            // Salon: die Würfel liegen auf einem Farbband in der Spielart-Farbe, das bis an die Ränder reicht (Entwurf S4)
            .padding(.vertical, art == .salon ? 10 : 0)
            .background { if art == .salon { Color.appFlaeche.padding(.horizontal, -12) } }
            HStack(spacing: Design.Abstand.s) {
                Text(hinweis).font(.footnote).foregroundStyle(tippAn && rat != nil ? (Tisch.aktiv ? Tisch.elfenbein : Color.accentText) : Color.schriftZweit)   // N-026: Zweitfarbe des Designs statt blassem System-Grau (Salon)
                    .lineLimit(2).minimumScaleFactor(0.8)
                    .tischHinweis(sonst: Color.schriftZweit)   // Tinte: heller Hinweis auf dem Filz
                    .frame(maxWidth: .infinity, alignment: .leading)
                punkte
            }
            knoepfe
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)   // B18 G-006/N-014: Hinweis und Knöpfe sprengen sonst die Zone, die Tabelle bleibt klein
        .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 6)
        .background(art == .klar ? AnyShapeStyle(.bar) : (art == .tinte ? AnyShapeStyle(Color.clear) : AnyShapeStyle(Color.seitenGrund)))   // Tinte: Würfel direkt auf dem Filz, ohne Kasten (Blatt 3); Salon: Papier
    }

    // MARK: Würfel

    private func wuerfel(_ i: Int) -> some View {
        let gehalten = record.held.contains(i)
        let rolls = state.rollsUsed
        let kannHalten = rolls > 0 && rolls < 3 && !computerAmZug && !state.finished
        let tipp = tippAn && !gehalten && (rat?.keep.contains(i) ?? false) && !(rat?.keepsAll ?? false)
        let wert = wirbelnd.contains(i) ? gezeigt[i] : (state.dice[safe: i] ?? 1)
        return Button {
            guard kannHalten else { return }
            store.toggleHold(i)
            SpielHaptik.tap()
            Sound.select.play()
        } label: {
            DieView(value: wert, state: state.dice.isEmpty ? .unknown : (gehalten ? .held : .free), size: kante, hinted: tipp, aufBand: art == .salon)
                .rotationEffect(.degrees(wirbelnd.contains(i) ? Double(gezeigt[i] * 9 - 30) : 0))
                .offset(y: gehalten ? -6 : 0)
                .animation(.snappy(duration: 0.2), value: gehalten)
                .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(kannHalten)   // M-009: nicht „disabled“, sonst werden die Augen grau wie deaktiviert
        .accessibilityLabel(state.dice.isEmpty ? String(localized: "Würfel \(i + 1): noch nicht gewürfelt")
                            : String(localized: "Würfel \(i + 1): \(state.dice[i])") + (gehalten ? String(localized: ", gehalten") : "") + (tipp ? String(localized: ", Tipp: behalten") : ""))
        .accessibilityHint(kannHalten ? (gehalten ? "Tippen zum Loslassen" : "Tippen zum Halten") : "")
    }

    private var punkte: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(i < state.rollsUsed ? Color.appFlaeche : Color.primary.opacity(0.15)).frame(width: 9, height: 9)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Wurf \(state.rollsUsed) von 3"))
    }

    private var hinweis: String {
        if tippAn, let rat {
            if rat.keepsAll { return String(localized: "Tipp: nicht mehr würfeln, nimm „\(ComputerPlayer.bestCategory(state, level: .gut).title(state.rules.variant))“") }
            if rat.keep.isEmpty { return String(localized: "Tipp: alle Würfel neu werfen") }
            return String(localized: "Tipp: die markierten Würfel halten")
        }
        if state.isYacht { return state.rollsUsed == 3 ? String(localized: "Yacht! 🎉 Wähle ein Feld") : String(localized: "Yacht! 🎉 Fünf gleiche") }
        return switch state.rollsUsed {
        case 0: String(localized: "Noch nicht gewürfelt")
        case 3: String(localized: "Letzter Wurf – wähle ein Feld")
        default: String(localized: "Wurf \(state.rollsUsed) von 3 · Würfel antippen zum Halten")
        }
    }

    // MARK: Knöpfe

    @ViewBuilder private var knoepfe: some View {
        if let c = gewaehlt, !computerAmZug, state.legalCategories.contains(c) {
            let p = state.potentialScore(c)
            HStack(spacing: 10) {
                Button("Abbrechen") { gewaehlt = nil }.zweitKnopf().frame(maxWidth: 120)
                Button { eintragen(c) } label: {
                    Text(p == 0 ? "\(c.title(state.rules.variant)) streichen" : "\(c.title(state.rules.variant)): \(p) eintragen").font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .hauptKnopf()
                .accessibilityIdentifier("eintragen")
            }
        } else {
            HStack(spacing: 10) {
                if state.rollsUsed > 0, state.rollsUsed < 3, !computerAmZug {
                    Button { tippAn.toggle() } label: { Label("Tipp", systemImage: "lightbulb").frame(maxWidth: .infinity) }
                        .buttonStyle(AkzentPilleStil(gefuellt: tippAn)).frame(maxWidth: 110)
                        .accessibilityIdentifier("tipp")
                }
                if state.rollsUsed < 3 {
                    Button(action: wuerfeln) {
                        Text(rollTitel).font(.headline).multilineTextAlignment(.center).lineLimit(typeSize.isAccessibilitySize ? 2 : 1).minimumScaleFactor(typeSize.isAccessibilitySize ? 0.7 : 0.6)   // B18 K-022: einzeilig
                            .frame(maxWidth: .infinity)
                    }
                    .hauptKnopf()
                    .disabled(!wirbelnd.isEmpty || alleGehalten || computerAmZug)
                    .accessibilityIdentifier("wuerfeln")
                } else {
                    Text("Alle Würfe verbraucht – wähle ein Feld").font(.headline).foregroundStyle(Color.schriftZweit)
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 50)
                        .tischHinweis(sonst: Color.schriftZweit)
                }
            }
        }
    }

    private var alleGehalten: Bool { state.rollsUsed > 0 && record.held.count == 5 }

    private var rollTitel: String {
        if computerAmZug { return String(localized: "Computer spielt …") }
        if alleGehalten { return String(localized: "Alle gehalten – wähle ein Feld") }
        if echt { return state.rollsUsed == 0 ? String(localized: "Wurf eintragen") : String(localized: "Nächsten Wurf eintragen") }
        return state.rollsUsed == 0 ? String(localized: "Würfeln") : String(localized: "Nochmal würfeln (\(3 - state.rollsUsed) übrig)")
    }
}
