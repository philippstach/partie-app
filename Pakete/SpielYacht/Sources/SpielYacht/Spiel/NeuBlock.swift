// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Wertungsblock von „Yacht“: Felder als Zeilen, Personen als Spalten, ohne Scrollen (auch nicht seitwärts).
/// Die Zeilenhöhe füllt die Resthöhe. In den freien Feldern der Person am Zug steht die Vorschau des Wurfs; Antippen wählt das Feld.
struct NeuBlock: View {
    /// C-044 (1): Schrift wächst mit der Schriftgröße, bleibt aber durch die Zeilenhöhe begrenzt
    @ScaledMetric(relativeTo: .footnote) private var schrift: CGFloat = 13
    let record: GameRecord
    @Binding var gewaehlt: Category?
    var bedienbar: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.designArt) private var art   // Designwechsel D.4
    private var klar: Bool { art == .klar }

    private var state: GameState { record.state }
    private var rules: Rules { state.rules }
    private var variant: Variant { rules.variant }
    private var gross: Bool { typeSize.isAccessibilitySize }
    private var spieler: [Int] { Array(record.players.indices) }

    var body: some View {
        GeometryReader { geo in
            let zeilen = NeuLogik.zeilen(rules)
            // G-006/N-014: bei großer Schrift wachsen die Zeilen mit der Schrift (statt in die Resthöhe gequetscht zu werden); was nicht passt, scrollt, „Gesamt“ bleibt erreichbar
            let h = max(NeuLogik.zeilenHoehe(verfuegbar: geo.size.height - 12, zeilen: zeilen, grosseSchrift: gross, regular: sizeClass == .regular), gross ? schrift * 2.1 : 0)
            let beschriftung = min(geo.size.width * (record.players.count > 3 ? 0.30 : 0.38), 150)
            let spalte = NeuLogik.spaltenBreite(gesamt: geo.size.width - 16, spalten: record.players.count, beschriftung: beschriftung)
            let inhalt = VStack(spacing: 0) {
                kopf(h: h, beschriftung: beschriftung, spalte: spalte)
                ForEach(Category.upper, id: \.self) { feld($0, h, beschriftung, spalte) }
                if rules.upperBonus > 0 { bonus(h, beschriftung, spalte) }
                ForEach(variant.fields.filter { !$0.isUpper }, id: \.self) { feld($0, h, beschriftung, spalte) }
                if rules.kniffelBonus > 0 { zeile(String(localized: "Yacht-Bonus"), h, beschriftung, spalte, fett: false) { "\(state.totals(player: $0).kniffelBonus)" } }
                zeile(String(localized: "Gesamt"), h, beschriftung, spalte, fett: true) { "\(state.totals(player: $0).total)" }
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            if gross { ScrollView { inhalt } } else { inhalt }
        }
        .background {
            if klar { RoundedRectangle(cornerRadius: 16).fill(Color.kartenGrund) }
            else if Tisch.aktiv { RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.10)) }   // Design-Runde 3: Tinte = runde Fläche auf dem Filz
        }   // Salon: Tabelle auf dem Papier, ohne Kasten
        // Der Block ist selbst schon auf die Höhe gerechnet: noch größere Schrift würde nur Zeilen sprengen
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    // MARK: Zeilen

    private func kopf(h: Double, beschriftung: Double, spalte: Double) -> some View {
        HStack(spacing: 0) {
            Text(variant.titel).font(.caption2.weight(.semibold))
                .lineLimit(1).minimumScaleFactor(0.6)
                .tischHinweis(zeilen: 1)
                .frame(width: beschriftung, alignment: .leading)
            ForEach(spieler, id: \.self) { i in
                let p = record.players[i]
                let aktiv = i == state.current && !state.finished
                VStack(spacing: 0) {
                    if Tisch.aktiv {
                        SpielerAvatar(name: p.name, farbe: Spieler.farbe(p.colorIndex), groesse: 22)   // Blatt 3: Spielerfarbe wie in der Spielerleiste
                    } else {
                        Text(p.avatar).font(.system(size: 15)) // design:spielinhalt
                    }
                    Text(p.name).font(.caption2.weight(aktiv ? .bold : .regular)).lineLimit(1).minimumScaleFactor(0.6)
                }
                .frame(width: spalte, height: max(h * 1.8, 34))
                .background(aktiv ? (klar ? p.color.opacity(0.22) : (Tisch.aktiv ? Color.white.opacity(0.16) : Color.feldGrund)) : .clear, in: .rect(cornerRadius: Design.Ecke.klein))   // Tinte, Salon: aktive Spalte auf Feldgrund
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(aktiv ? Text("\(p.name), am Zug") : Text(verbatim: p.name))
            }
        }
    }

    private func feld(_ c: Category, _ h: Double, _ beschriftung: Double, _ spalte: Double) -> some View {
        HStack(spacing: 0) {
            Text(c.title(variant)).font(.system(size: min(schrift, h * 0.52))).lineLimit(1).minimumScaleFactor(0.55)
                .frame(width: beschriftung, height: h, alignment: .leading)
            ForEach(spieler, id: \.self) { i in zelle(c, i, h, spalte) }
        }
        .overlay(alignment: .bottom) { if !klar { Color.linie.frame(height: 1) } }   // Tinte, Salon: Haarlinie unter jeder Zeile
    }

    private func zelle(_ c: Category, _ i: Int, _ h: Double, _ spalte: Double) -> some View {
        let p = record.players[i]
        let aktiv = i == state.current && !state.finished
        let belegt = state.players[i].scores[c]
        let vorschau = aktiv && state.rollsUsed > 0 && belegt == nil && state.legalCategories.contains(c) ? state.potentialScore(c) : nil
        let waehlbar = vorschau != nil && bedienbar
        let ist = gewaehlt == c && aktiv
        return Button {
            if waehlbar { gewaehlt = ist ? nil : c }
        } label: {
            ZStack {
                if aktiv { Rectangle().fill(klar ? p.color.opacity(0.12) : (Tisch.aktiv ? Color.white.opacity(0.14) : Color.feldGrund)) }
                if ist { RoundedRectangle(cornerRadius: klar ? 6 : Design.Ecke.klein).strokeBorder(Tisch.aktiv ? Tisch.elfenbein : Color.appFlaeche, lineWidth: 2).padding(1) }
                if let b = belegt {
                    Text("\(b)").font(.system(size: min(schrift + 1, h * 0.58), weight: .semibold, design: Design.zahlDesign)).monospacedDigit()
                        .foregroundStyle(Self.belegtFarbe(b, klar: klar))   // Fund 40/67: eingetragene Punkte kräftig, nicht blass
                } else if let v = vorschau {
                    Text("\(v)").font(.system(size: min(schrift + 1, h * 0.58), weight: ist ? .bold : .regular, design: Design.zahlDesign)).monospacedDigit()
                        .foregroundStyle(v == 0 ? Color.secondary.opacity(0.7) : (Tisch.aktiv ? Tisch.elfenbein : Color.accentText))
                }
            }
            .frame(width: spalte, height: h)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!waehlbar)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.sprechtext(c, variant, spieler: p.name, belegt: belegt, vorschau: vorschau))
        .accessibilityAddTraits(ist ? .isSelected : [])
        .accessibilityHint(waehlbar ? Text("Doppeltippen zum Wählen") : Text(verbatim: ""))
    }

    private func bonus(_ h: Double, _ beschriftung: Double, _ spalte: Double) -> some View {
        zeile(String(localized: "Bonus (ab \(rules.upperBonusThreshold))"), h, beschriftung, spalte, fett: false) { i in
            let t = state.totals(player: i)
            return t.bonus > 0 ? "+\(t.bonus)" : "\(t.upper)/\(rules.upperBonusThreshold)"
        }
    }

    private func zeile(_ titel: String, _ h: Double, _ beschriftung: Double, _ spalte: Double, fett: Bool, wert: @escaping (Int) -> String) -> some View {
        HStack(spacing: 0) {
            Text(titel).font(.system(size: min(schrift, h * 0.52), weight: fett ? .bold : .regular)).lineLimit(1).minimumScaleFactor(0.55)
                .frame(width: beschriftung, height: h, alignment: .leading)
            ForEach(spieler, id: \.self) { i in
                let w = wert(i)
                Text(w).font(.system(size: min(schrift + 1, h * 0.58), weight: fett ? .heavy : .medium, design: Design.zahlDesign)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(width: spalte, height: h)
                    .accessibilityLabel(Text("\(titel), \(record.players[i].name): \(w)"))
            }
        }
        .overlay(alignment: .top) { if fett { Divider() } }
    }

    /// Farbe einer eingetragenen Punktzahl: auf dem Tisch Elfenbein, in Klar die Primärfarbe, sonst die Tintenschrift. Null etwas leiser, aber lesbar.
    @MainActor static func belegtFarbe(_ b: Int, klar: Bool) -> Color {
        let voll: Color = Tisch.aktiv ? Tisch.elfenbein : (klar ? Color.primary : Color.schrift)
        return b == 0 ? voll.opacity(0.7) : voll
    }

    static func sprechtext(_ c: Category, _ v: Variant, spieler: String, belegt: Int?, vorschau: Int?) -> Text {
        if let b = belegt { return Text("\(c.title(v)), \(spieler): \(b) Punkte") }
        if let p = vorschau { return Text("\(c.title(v)), \(spieler): frei, bringt \(p) Punkte") }
        return Text("\(c.title(v)), \(spieler): frei")
    }
}
