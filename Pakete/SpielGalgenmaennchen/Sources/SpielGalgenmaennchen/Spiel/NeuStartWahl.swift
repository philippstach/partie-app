// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Große Tinte-Runde, Punkt 7: Galgenmännchen hat nur eine Spielseite mit einem „Spielen“. Die Wahl, die bisher auf der zweiten
/// Startseite („Neues Spiel“ mit „Los geht's“, „Heute spielen“, „Überleben starten“) stand, liegt hier auf der Spielseite:
/// Sprache, Spielart (Freies Spiel, Wort des Tages, Überleben, Eigene Wörter), Thema, Stufe, Kinderleicht; mit mehreren die Party-Einstellungen.
/// „Spielen“ startet dann sofort (`NeuSpiel.startenNachWahl`). Nur in Tinte; in Klar und Salon ist die Karte leer und alles bleibt wie bisher.
struct NeuStartWahl: View {
    /// Vorgemerkte Spielart allein: "frei", "tag", "ueberleben", "eigene".
    static let schluessel = "galgen-neu.start"
    static let kinderSchluessel = "galgen-neu.kinder"
    static let partySchluessel = "galgen-neu.party"

    let eintraege: [SpielerEintrag]
    @Environment(\.designArt) private var art
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var breit: Bool { sizeClass == .regular }
    @AppStorage("galgen-neu.start") private var start = "frei"
    @AppStorage("galgen-neu.sprache") private var sprachRoh = WordLanguage.deviceDefault.rawValue
    @AppStorage("galgen-neu.kategorie") private var kategorieRoh = ""
    @AppStorage("galgen-neu.stufe") private var stufeRoh = Difficulty.medium.rawValue
    @AppStorage("galgen-neu.kinder") private var kinder = false
    @AppStorage("galgen-neu.party") private var partyRoh = Data()
    @State private var eigeneWoerter = NeuAblage.eigene()
    @State private var verwalten = false

    private var partyModus: Bool { eintraege.count >= 2 }
    private var sprache: WordLanguage { WordLanguage(rawValue: sprachRoh) ?? .de }
    private var liste: WordList { NeuAblage.liste(sprache) }
    private var heute: String { DayKey.string(for: Date()) }
    private var kategorie: Category? { Category(rawValue: kategorieRoh) }
    private var stufe: Difficulty { Difficulty(rawValue: stufeRoh) ?? .medium }

    var body: some View {
        if art == .tinte {
            VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                spracheZeile
                if partyModus { partyKarte } else {
                    freiZeile
                    tagesZeile
                    ueberlebenZeile
                    eigeneZeile
                }
            }
            .onAppear {
                eigeneWoerter = NeuAblage.eigene()
                // Schon gespieltes Wort des Tages oder leere eigene Liste: zurück auf Freies Spiel, damit „Spielen“ immer etwas startet
                if start == "tag", NeuAblage.tagesErgebnis(heute, sprache) != nil { start = "frei" }
                if start == "eigene", eigeneWoerter.isEmpty { start = "frei" }
                if !["frei", "tag", "ueberleben", "eigene"].contains(start) { start = "frei" }
            }
            .sheet(isPresented: $verwalten, onDismiss: {
                eigeneWoerter = NeuAblage.eigene()
                if start == "eigene", eigeneWoerter.isEmpty { start = "frei" }
            }) { NeuEigeneWoerter(sprache: sprache) }
        }
    }

    // MARK: Bausteine

    private func zeichen(_ gewaehlt: Bool) -> some View {
        Image(systemName: gewaehlt ? "checkmark.circle.fill" : "circle").font(.title2)
            .foregroundStyle(gewaehlt ? Color.schrift : Color.schriftZweit).accessibilityHidden(true)
    }

    /// Eine Spielart als Wahlzeile (Vorbild Solitär/Sudoku): Kreis, Titel, eine Zeile darunter; gewählt mit den Einstellungen darunter.
    private func wahlZeile<Mehr: View>(_ kennung: String, symbol: String, titel: LocalizedStringKey, unter: String?, gesperrt: Bool = false,
                                       @ViewBuilder mehr: () -> Mehr) -> some View {
        let gewaehlt = start == kennung
        return VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Button { start = kennung } label: {
                HStack(spacing: Design.Abstand.m) {
                    zeichen(gewaehlt)
                    VStack(alignment: .leading, spacing: 2) {
                        Label(titel, systemImage: symbol).font(.headline).foregroundStyle(Color.schrift)
                        if let unter { Text(verbatim: unter).font(.footnote).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true) }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(gesperrt)
            .opacity(gesperrt ? 0.6 : 1)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(gewaehlt ? [.isButton, .isSelected] : .isButton)
            mehr()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var spracheZeile: some View {
        // Wie bisher auf der zweiten Seite: bei großer Schrift Titel und Auswahl untereinander
        ViewThatFits(in: .horizontal) {
            HStack {
                Label("Wörter auf", systemImage: "globe").font(.subheadline.weight(.semibold)).foregroundStyle(Color.schrift).lineLimit(1)
                Spacer()
                spracheAuswahl
            }
            VStack(alignment: .leading, spacing: 6) {
                Label("Wörter auf", systemImage: "globe").font(.subheadline.weight(.semibold)).foregroundStyle(Color.schrift)
                spracheAuswahl
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 14).frame(minHeight: 52)
        .designFlaeche(Theme.cardRadius)
    }

    private var spracheAuswahl: some View {
        Picker("Wörter auf", selection: Binding(get: { sprache }, set: { sprachRoh = $0.rawValue })) {
            ForEach(WordLanguage.alle, id: \.self) { Text(verbatim: NeuWahl.name($0)).tag($0) }
        }
        .labelsHidden()
    }

    private func chip(_ text: String, symbol: String? = nil, gewaehlt: Bool, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: 5) {
                if let symbol { Image(systemName: symbol).font(.caption) }
                Text(verbatim: text).font(.subheadline.weight(.semibold)).lineLimit(1)
            }
            .padding(.horizontal, 12).frame(minHeight: 36)
            .foregroundStyle(gewaehlt ? Color.onAccent : Color.accentText)
            .background(gewaehlt ? AnyShapeStyle(Color.appFlaeche) : AnyShapeStyle(Color.accentSoft), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }

    private func themen(gewaehlt: Category?, setzen: @escaping (Category?) -> Void) -> some View {
        let inhalt = Group {
            chip(String(localized: "Alle"), gewaehlt: gewaehlt == nil) { setzen(nil) }
            ForEach(Category.allCases, id: \.self) { c in
                chip(liste.categoryName(c), symbol: c.symbol, gewaehlt: gewaehlt == c) { setzen(c) }
            }
        }
        return Group {
            if breit {
                // T-035: auf dem iPad umbrechen die Chips statt am Rand abgeschnitten zu werden
                ChipUmbruch(abstand: Design.Abstand.s) { inhalt }
            } else {
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: Design.Abstand.s) { inhalt } }
            }
        }
    }

    private func stufeName(_ d: Difficulty) -> String {
        switch d {
        case .easy: String(localized: "Leicht")
        case .medium: String(localized: "Mittel")
        case .hard: String(localized: "Schwer")
        }
    }

    // MARK: Allein

    private var freiZeile: some View {
        let unter = kinder ? "\(NeuWahl.name(sprache)) · \(String(localized: "Kinderleicht"))" : "\(NeuWahl.name(sprache)) · \(stufeName(stufe))"
        return wahlZeile("frei", symbol: "textformat.abc", titel: "Freies Spiel", unter: unter) {
            if start == "frei" {
                themen(gewaehlt: kategorie) { kategorieRoh = $0?.rawValue ?? "" }
                Picker("Stufe", selection: Binding(get: { stufe }, set: { stufeRoh = $0.rawValue })) {
                    ForEach(Difficulty.allCases, id: \.self) { Text($0.key).tag($0) }
                }
                .pickerStyle(.segmented).disabled(kinder)
                Toggle(isOn: $kinder) { Text("Kinderleicht: nur leichte Wörter, mehr Hinweise").lineLimit(2).fixedSize(horizontal: false, vertical: true) }.font(.subheadline).foregroundStyle(Color.schrift)   // T-035: nicht mehr mit „…“ gekürzt
            }
        }
    }

    private var tagesZeile: some View {
        let e = NeuAblage.tagesErgebnis(heute, sprache)
        let serie = NeuAblage.tagesStats().displayedStreak(today: heute)
        var unter: String?
        if let e {
            unter = e.gewonnen ? String(localized: "Heute erraten. Morgen gibt es ein neues Wort.") : String(localized: "Heute nicht erraten. Morgen gibt es ein neues Wort.")
        } else if let p = DailyWord.word(day: heute, in: liste.words) {
            unter = String(localized: "\(liste.categoryName(p.category)) · \(p.solution.filter { sprache.alphabet.contains($0) }.count) Buchstaben")
        }
        return wahlZeile("tag", symbol: "calendar", titel: "Wort des Tages", unter: unter, gesperrt: e != nil) {
            if serie > 0 {
                Label(String(localized: "Serie: \(serie) Tage"), systemImage: "flame").font(.footnote.weight(.semibold)).foregroundStyle(Color.schriftZweit)
            }
            if let e, TeilenFreigabe.erlaubt() {
                ShareLink(item: DailyShare.text(day: heute, mistakes: e.fehler, hints: e.hinweise, won: e.gewonnen, appLanguage: .appLanguage)) {
                    Label("Ergebnis teilen", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                }
                .buttonStyle(ZweitKnopfStil())
            }
        }
    }

    private var ueberlebenZeile: some View {
        wahlZeile("ueberleben", symbol: "heart.fill", titel: "Überleben", unter: String(localized: "Drei Leben, die Wörter werden schwerer")) { EmptyView() }
    }

    private var eigeneZeile: some View {
        let unter = eigeneWoerter.isEmpty ? String(localized: "Schreib deine eigene Wortliste, zum Beispiel für Familie oder Schule, mit freiem Hinweis.")
                                          : String(localized: "\(eigeneWoerter.count) Wörter in deiner Liste")
        return wahlZeile("eigene", symbol: "square.and.pencil", titel: "Eigene Wörter", unter: unter, gesperrt: eigeneWoerter.isEmpty) {
            Button { verwalten = true } label: {
                Text(eigeneWoerter.isEmpty ? "Wörter eintragen" : "Wörter verwalten (\(eigeneWoerter.count))").frame(maxWidth: .infinity)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .buttonStyle(ZweitKnopfStil())
        }
    }

    // MARK: Party (zwei bis vier Personen)

    private var partyEinst: PartySettings {
        (try? JSONDecoder().decode(PartySettings.self, from: partyRoh)) ?? PartySettings()
    }

    private func partyAendern(_ aendern: (inout PartySettings) -> Void) {
        var p = partyEinst
        aendern(&p)
        if let d = try? JSONEncoder().encode(p) { partyRoh = d }
    }

    private var partyKarte: some View {
        let p = partyEinst
        return VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Label("Party", systemImage: "person.3.fill").font(.headline).foregroundStyle(Color.schrift)
            Toggle("Wörter selbst ausdenken", isOn: Binding(get: { p.ownWords }, set: { v in partyAendern { $0.ownWords = v } }))
                .font(.subheadline).foregroundStyle(Color.schrift)
            Text(verbatim: p.ownWords ? String(localized: "Reihum rät einer, der Nächste in der Reihe denkt sich das Wort aus. Wer scheitert, gibt dem Wortgeber 3 Punkte.") : String(localized: "Die App zieht die Wörter, ihr ratet reihum."))
                .font(.footnote).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
            if !p.ownWords {
                themen(gewaehlt: p.category) { c in partyAendern { $0.category = c } }
                Picker("Stufe", selection: Binding(get: { p.difficulty }, set: { d in partyAendern { $0.difficulty = d } })) {
                    Text("Alle").tag(Difficulty?.none)
                    ForEach(Difficulty.allCases, id: \.self) { Text($0.key).tag(Optional($0)) }
                }
                .pickerStyle(.segmented)
            }
            Stepper(String(localized: "Runden je Spieler: \(p.roundsPerPlayer)"),
                    value: Binding(get: { p.roundsPerPlayer }, set: { r in partyAendern { $0.roundsPerPlayer = r } }), in: 1 ... 5)
                .font(.subheadline).foregroundStyle(Color.schrift)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    /// Party-Einstellungen, wie sie die Spielseite vorgemerkt hat (für `NeuSpiel`).
    static func gespeicherteParty() -> PartySettings {
        guard let d = UserDefaults.standard.data(forKey: partySchluessel) else { return PartySettings() }
        return (try? JSONDecoder().decode(PartySettings.self, from: d)) ?? PartySettings()
    }
}
/// T-035: Einfacher Umbruch für Chips (Zeilen, so viele wie nötig).
private struct ChipUmbruch: Layout {
    var abstand: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let b = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, zeile: CGFloat = 0, breiteMax: CGFloat = 0
        for v in subviews {
            let g = v.sizeThatFits(.unspecified)
            if x > 0, x + g.width > b { y += zeile + abstand; x = 0; zeile = 0 }
            x += g.width + abstand; zeile = max(zeile, g.height); breiteMax = max(breiteMax, x - abstand)
        }
        return CGSize(width: proposal.width ?? breiteMax, height: y + zeile)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, zeile: CGFloat = 0
        for v in subviews {
            let g = v.sizeThatFits(.unspecified)
            if x > bounds.minX, x + g.width > bounds.maxX { y += zeile + abstand; x = bounds.minX; zeile = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(g))
            x += g.width + abstand; zeile = max(zeile, g.height)
        }
    }
}
#endif
