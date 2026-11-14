// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Regeln-Blatt: animierte Anleitung zum Durchwischen, die ausführlichen Regeln dahinter (`RulesDetailView`).
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        AnleitungBlatt(titel: "Yacht", schritte: Self.schritte, fertig: { dismiss() }) { RulesDetailView() }
    }

    static let schritte: [AnleitungSchritt] = [
        AnleitungSchritt.ziel("Fülle alle Felder der Wertungstabelle mit möglichst vielen Punkten. Wer am Ende die meisten hat, gewinnt."),
        AnleitungSchritt(symbol: "dice", titel: "Würfeln und behalten",
                         text: "Du würfelst bis zu dreimal. Tippe Würfel an, die du behalten willst – nur die anderen werden neu geworfen.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.5))) { p, aktiv in Self.buehneWuerfeln(p, aktiv) },
        AnleitungSchritt(symbol: "tablecells", titel: "Feld wählen",
                         text: "Danach trägst du das Ergebnis in ein freies Feld der Wertungstabelle ein. Passt nichts, streichst du ein Feld.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.52))) { p, _ in Self.buehneFeld(p) },
        AnleitungSchritt(symbol: "flag.checkered", titel: "Alle Felder voll",
                         text: "Sind alle Felder voll (Klassisch: 13 Runden), gewinnt, wer die meisten Punkte hat. Bei Klassisch gibt es ab 63 Punkten im oberen Block 35 Punkte Bonus.",
                         geste: .keine) { p, _ in Self.buehneVoll(p) },
    ]

    @ViewBuilder static func buehneWuerfeln(_ p: Double, _ aktiv: Bool) -> some View {
        HStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { i in
                    let fest = [4, 3, 5, 5, 1][i]
                    let haelt = i == 2 && p > 0.45
                    let rollt = aktiv && !haelt && p < 0.8
                    AnleitungWuerfel(augen: rollt ? ((Int(p * 14) + i * 2) % 6) + 1 : fest, groesse: 46, gehalten: haelt)
                        .offset(y: rollt ? CGFloat(sin(p * 30 + Double(i))) * 4 : 0)
                }
            }
    }

    @ViewBuilder static func buehneFeld(_ p: Double) -> some View {
            VStack(spacing: Design.Abstand.s) {
                ForEach(Array(["Dreier", "Full House", "Yacht"].enumerated()), id: \.offset) { i, name in
                    let an = i == 1
                    HStack {
                        Text(LocalizedStringKey(name)).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(an && p > 0.5 ? "25" : "–").font(.system(.subheadline, design: Design.zahlDesign).bold().monospacedDigit())
                    }
                    .foregroundStyle(an && p > 0.5 ? Color.onAccent : (Tisch.aktiv ? Tisch.auge : Color.primary))   // Tinte: Papier auf dem Filz (Runde 5, Blatt 11)
                    .padding(.horizontal, 14).frame(height: 40)
                    .background(an && p > 0.5 ? Color.appFlaeche : (Tisch.aktiv ? Tisch.elfenbein : Color(.systemBackground)), in: .rect(cornerRadius: Theme.feldRadius))
                }
            }
            .padding(.horizontal, 40)
    }

    @ViewBuilder static func buehneVoll(_ p: Double) -> some View {
            VStack(spacing: Design.Abstand.l) {
                HStack(spacing: Design.Abstand.xs) {
                    ForEach(0..<13, id: \.self) { i in
                        Capsule().fill(Double(i) < p * 13 ? Color.appFlaeche : Color.appFlaeche.opacity(0.25)).frame(width: 14, height: 34)
                    }
                }
                Text("63 → +35").font(.system(.title3, design: Design.zahlDesign).bold().monospacedDigit()).foregroundStyle(Color.accentText)
            }
    }

    // MARK: Neue Anleitung (nur Deutsch, Build 25): Texte aus plan/regeln-neu/yacht/anleitung.md; Bühnen wie bisher, neue Seiten mit Zeichen
    static let schritteNeu: [AnleitungSchritt] = [
        AnleitungSchritt(symbol: "dice", titel: "Würfeln und halten",
                         text: "Du würfelst bis zu dreimal. Tippe die Würfel an, die du halten willst, nur die anderen rollen neu. Gehaltene Würfel bleiben für den nächsten Wurf liegen, bis du sie wieder antippst. Bist du zufrieden, kannst du auch schon nach dem ersten Wurf eintragen.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.5))) { p, aktiv in Self.buehneWuerfeln(p, aktiv) },
        AnleitungSchritt(symbol: "tablecells", titel: "Feld wählen",
                         text: "Danach trägst du das Ergebnis in ein freies Feld ein. Die App zeigt dir bei jedem Feld, wie viele Punkte es bringt. Passt nichts, streichst du ein Feld: Es bekommt null Punkte und ist verbraucht. Die Chance nimmt immer die Summe, sie ist dein Notfeld.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.52))) { p, _ in Self.buehneFeld(p) },
        AnleitungSchritt.figuren(symbol: "list.bullet.rectangle", titel: "Die Felder",
                                 text: "Oben zählen Einser bis Sechser die Würfel ihrer Zahl. Unten gibt es Dreierpasch und Viererpasch (drei oder vier gleiche), Full House (drei und zwei gleiche, 25), kleine Straße (vier hintereinander, 30), große Straße (fünf hintereinander, 40) und Yacht (fünf gleiche, 50). So zählt die Wertung Klassisch. Die ganze Wertungstabelle steht unter „Alle Regeln lesen“.",
                                 figuren: ["⚃⚃⚃", "⚂⚂⚂⚄⚄", "⚀⚁⚂⚃", "⚅⚅⚅⚅⚅"], bewegt: nil),
        AnleitungSchritt(symbol: "flag.checkered", titel: "Bonus und Ende",
                         text: "Hast du im oberen Block mindestens 63 Punkte, gibt es 35 Bonus. Das schaffst du zum Beispiel mit je drei Würfeln jeder Zahl. Sind alle Felder voll, bei Klassisch nach 13 Runden, zählt die App zusammen. Die höchste Summe gewinnt.",
                         geste: .keine) { p, _ in Self.buehneVoll(p) },
        AnleitungSchritt.figuren(symbol: "slider.horizontal.3", titel: "Drei Wertungen",
                                 text: "Vor dem ersten Wurf wählst du unter „Mehr“ die Wertung. Klassisch hat 13 Felder wie Kniffel. Yatzy hat 15 Felder mit Paaren und 50 Bonus. Original-Yacht hat nur 11 Felder, ohne Chance und ohne Bonus. Bei Klassisch kannst du Joker und Yacht-Bonus für weitere Yachts einschalten.",
                                 figuren: ["13", "15", "11"], bewegt: nil),
        AnleitungSchritt.figuren(symbol: "lightbulb", titel: "Hilfen",
                                 text: "„Tipp“ zeigt dir, welche Würfel du halten solltest. Den letzten Eintrag nimmst du mit dem Pfeil oben zurück, solange nicht weitergewürfelt wurde. Jeden Tag gibt es die Tageswürfel, für alle gleich. Mit echten Würfeln tippst du die Augen ein. Alles Weitere unter „Alle Regeln lesen“.",
                                 figuren: ["💡", "↩️", "📅"], bewegt: nil),
    ]
}
