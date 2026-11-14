// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

struct RulesDetailView: View {
    @Environment(\.dismiss) private var dismiss

    /// Bauplan RS / Blatt 29: eine Regelseite für alle Spiele; ohne gegliederten Text (andere Sprache) die bisherige Seite.
    var body: some View {
        if let q = RegelLeseKatalog.quelle(fuer: "yacht") { RegelLeseAnsicht(quelle: q, spielName: "Yacht", spielID: "yacht", wissen: nil) }
        else { alteSeite }
    }

    private var alteSeite: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Abstand.m) {
                    block("Ablauf", """
                    Du hast pro Zug bis zu 3 Würfe mit 5 Würfeln. Nach dem ersten und zweiten Wurf tippst du die Würfel an, die du behalten willst. Nur die anderen werden neu gewürfelt.
                    Danach musst du ein freies Feld wählen. Passt nichts, streichst du ein Feld (0 Punkte). Das Spiel ist zu Ende, wenn alle Felder belegt sind (Klassisch 13 Runden, Yatzy 15, Original-Yacht 11); die meisten Punkte gewinnen.
                    """)
                    block("Oberer Block", "Einser bis Sechser zählen die Würfel mit dieser Augenzahl. Ab 63 Punkten im oberen Block gibt es einen Bonus (Klassisch 35 Punkte, Yatzy 50, Original-Yacht keinen).")
                    VStack(alignment: .leading, spacing: Design.Abstand.s) {
                        SectionLabel("Unterer Block (Klassisch)")
                        ForEach(Category.lower, id: \.self) { c in
                            HStack(alignment: .firstTextBaseline) {
                                Text(c.title).font(.subheadline.weight(.semibold)).frame(width: 120, alignment: .leading)
                                Text(c.explanation).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .card()
                    block("Joker (Variante)", "Hast du schon ein Yacht gewertet (auch mit 0) und würfelst noch eins: Ist das obere Feld dieser Augenzahl frei, musst du es nehmen. Sonst darfst du ein freies unteres Feld nehmen; Full House (25), kleine (30) und große Straße (40) zählen dann voll. Sind alle unteren Felder belegt, darfst du ein freies oberes Feld nehmen.")
                    block("Yacht-Bonus (Variante)", "Steht im Yacht-Feld 50 Punkte, bringt jedes weitere Yacht, das du mit dem Joker einträgst, 100 Punkte extra. Joker und Yacht-Bonus gibt es nur bei Klassisch; der Yacht-Bonus zählt nur, wenn der Joker auch eingeschaltet ist.")
                    block("Echte Würfel", "Wähle beim Start „Echte Würfel“: Du würfelst am Tisch und tippst nach jedem Wurf die Augen ein. Mit „Wurf korrigieren“ kannst du dich vertippen.")
                }
                .padding()
            }
            .background(Color.seitenGrund)
            .navigationTitle("So wird gespielt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }   // Fund 23/26/76: überall dasselbe runde Schließen-Kreuz statt Textknopf „Fertig“
        }
    }

    private func block(_ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(title)
            Text(text).font(.subheadline)
        }
        .card()
    }
}
