// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Blatt 22 (EB-2, Schritt 1): Der Zettel am Ende für die Ergebnisseite. Nur lesen: Die Werte werden beim Melden des Endes
/// festgehalten, das Bild kennt weder Spielstand noch Store. Alle Personen als Spalten, Zeilen so hoch, dass alles in die Karte passt.
enum NeuEndeBild {
    struct Zeile { let titel: String; let werte: [String]; let fett: Bool }
    struct Spalte { let name: String; let farbe: Color }

    /// Bonus oben: Namen derer, die ihn haben, sonst „niemand“. Nur wenn die Regel einen Bonus kennt.
    @MainActor static func bonusWert(_ r: GameRecord) -> EndeWert? {
        guard r.state.rules.upperBonus > 0 else { return nil }
        let namen = r.players.indices.filter { r.state.totals(player: $0).bonus > 0 }.map { r.players[$0].name }
        return EndeWert("Bonus oben", namen.isEmpty ? String(localized: "niemand") : namen.joined(separator: ", "))
    }

    /// Blatt 22 (EB2, Schritt 2): „Yacht geworfen“ = Yachts im Feld und Zusatz-Yachts, aller Personen zusammen (`yachts`, wie schon im Satz).
    /// Nur in Varianten mit dem Yacht-Feld; 0 wird als „0“ gezeigt.
    @MainActor static func yachtWert(_ r: GameRecord) -> EndeWert? {
        guard r.state.rules.variant.fields.contains(.kniffel) else { return nil }
        return EndeWert("Yacht geworfen", "\(r.players.indices.reduce(0) { $0 + r.yachts($1) })")
    }

    /// Die Zeilen des Zettels in der Reihenfolge von `NeuBlock`: obere Felder, Bonus, untere Felder, Yacht-Bonus, Gesamt.
    @MainActor static func zeilen(_ r: GameRecord) -> [Zeile] {
        let s = r.state, v = s.rules.variant
        func feld(_ c: Category) -> Zeile {
            Zeile(titel: c.title(v), werte: r.players.indices.map { s.players[$0].scores[c].map(String.init) ?? "–" }, fett: false)
        }
        var z: [Zeile] = Category.upper.filter { v.fields.contains($0) }.map(feld)
        if s.rules.upperBonus > 0 {
            z.append(Zeile(titel: String(localized: "Bonus (ab \(s.rules.upperBonusThreshold))"),
                           werte: r.players.indices.map { i in
                               let t = s.totals(player: i)
                               return t.bonus > 0 ? "+\(t.bonus)" : "\(t.upper)/\(s.rules.upperBonusThreshold)"
                           }, fett: false))
        }
        z += v.fields.filter { !$0.isUpper }.map(feld)
        if s.rules.kniffelBonus > 0 {
            z.append(Zeile(titel: String(localized: "Yacht-Bonus"), werte: r.players.indices.map { "\(s.totals(player: $0).kniffelBonus)" }, fett: false))
        }
        z.append(Zeile(titel: String(localized: "Gesamt"), werte: r.players.indices.map { "\(s.totals(player: $0).total)" }, fett: true))
        return z
    }

    @MainActor static func bild(_ r: GameRecord) -> EndeBild {
        let zeilen = zeilen(r)
        let spalten = r.players.map { Spalte(name: $0.name, farbe: Spieler.farbe($0.colorIndex)) }
        return EndeBild(Text("Zettel am Ende"), hoehe: 320) { groesse in
            Zettel(zeilen: zeilen, spalten: spalten, groesse: groesse)
        }
    }

    private struct Zettel: View {
        let zeilen: [Zeile]
        let spalten: [Spalte]
        let groesse: CGSize

        var body: some View {
            let kopfH: CGFloat = 26
            let h = max(10, min(20, (groesse.height - kopfH) / CGFloat(max(zeilen.count, 1))))
            let beschriftung = min(groesse.width * (spalten.count > 3 ? 0.30 : 0.38), 120)
            let spalte = max(24, (groesse.width - beschriftung) / CGFloat(max(spalten.count, 1)))
            let schrift = min(12, h * 0.62)
            let ton: Color = Tisch.aktiv ? Tisch.elfenbein : Color.schrift
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: beschriftung, height: kopfH)
                    ForEach(spalten.indices, id: \.self) { i in
                        SpielerAvatar(name: spalten[i].name, farbe: spalten[i].farbe, groesse: 20)
                            .frame(width: spalte, height: kopfH)
                            .accessibilityLabel(Text(verbatim: spalten[i].name))
                    }
                }
                ForEach(zeilen.indices, id: \.self) { j in
                    let z = zeilen[j]
                    HStack(spacing: 0) {
                        Text(z.titel).font(.system(size: schrift, weight: z.fett ? .bold : .regular)).lineLimit(1).minimumScaleFactor(0.5)
                            .frame(width: beschriftung, height: h, alignment: .leading)
                        ForEach(z.werte.indices, id: \.self) { i in
                            Text(z.werte[i]).font(.system(size: schrift, weight: z.fett ? .heavy : .medium, design: Design.zahlDesign)).monospacedDigit()
                                .lineLimit(1).minimumScaleFactor(0.6)
                                .frame(width: spalte, height: h)
                                .accessibilityLabel(Text("\(z.titel), \(spalten[i].name): \(z.werte[i])"))
                        }
                    }
                    .overlay(alignment: .bottom) { ton.opacity(0.18).frame(height: 0.5) }
                }
            }
            .foregroundStyle(ton)
            .frame(width: groesse.width, height: groesse.height)
        }
    }
}
