// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Auswahl nach „Neues Spiel“ im Rahmen. Mit einer Person: Allein, Wort des Tages, Überleben, eigene Wörter. Mit mehreren: Party-Einstellungen.
struct NeuWahl: View {
    let teilnehmer: [SpielTeilnehmer]
    let abbrechen: () -> Void
    let allein: (Category?, Difficulty?, Bool) -> Void
    let tagesraetsel: () -> Void
    let ueberleben: () -> Void
    let eigenesWort: (EigenesWort?) -> Void
    let party: (PartySettings) -> Void
    @Binding var sprache: WordLanguage
    @State private var kategorie: Category?
    @State private var stufe: Difficulty = .medium
    @State private var kinder = false
    @State private var eigeneWoerter = NeuAblage.eigene()
    @State private var verwalten = false
    @State private var partyEinst = PartySettings()
    @AppStorage("galgen-neu.kategorie") private var kategorieRoh = ""
    @AppStorage("galgen-neu.stufe") private var stufeRoh = Difficulty.medium.rawValue

    private var liste: WordList { NeuAblage.liste(sprache) }
    private var heute: String { DayKey.string(for: Date()) }
    private var partyModus: Bool { teilnehmer.count >= 2 }

    var body: some View {
        VStack(spacing: 0) {
            SpielKopf(mitte: partyModus ? String(localized: "Party") : String(localized: "Neues Spiel"), linksAktion: abbrechen)
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    spracheKarte
                    if partyModus { partyKarte } else {
                        alleinKarte
                        tagesKarte
                        karte(symbol: "heart.fill", titel: "Überleben", text: "Löse Wort für Wort mit drei Leben. Wer ein Wort gut löst, gewinnt ein Leben zurück, und die Wörter werden schwerer.", knopf: "Überleben starten", aktion: ueberleben)
                        eigeneKarte
                    }
                }
                .padding(.horizontal, Theme.seitenRand).padding(.top, Design.Abstand.m).padding(.bottom, 24)
                .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
            }
        }
        .background(Color.seitenGrund)
        .onAppear {
            kategorie = Category(rawValue: kategorieRoh)
            stufe = Difficulty(rawValue: stufeRoh) ?? .medium
        }
        .sheet(isPresented: $verwalten, onDismiss: { eigeneWoerter = NeuAblage.eigene() }) { NeuEigeneWoerter(sprache: sprache) }
    }

    private var spracheKarte: some View {
        // M-023: Bei großer Schrift bricht „Wörter auf Deutsch“ um; dann Titel und Auswahl untereinander statt nebeneinander
        ViewThatFits(in: .horizontal) {
            HStack {
                Label("Wörter auf", systemImage: "globe").font(.subheadline.weight(.semibold)).lineLimit(1)
                Spacer()
                spracheAuswahl
            }
            VStack(alignment: .leading, spacing: 6) {
                Label("Wörter auf", systemImage: "globe").font(.subheadline.weight(.semibold))
                spracheAuswahl
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 14).frame(minHeight: 52)
        .designFlaeche(Theme.cardRadius)
    }

    private var spracheAuswahl: some View {
        Picker("Wörter auf", selection: $sprache) {
            ForEach(WordLanguage.alle, id: \.self) { Text(verbatim: Self.name($0)).tag($0) }
        }
        .labelsHidden()
    }

    static func name(_ s: WordLanguage) -> String {
        switch s { case .de: "Deutsch"; case .en: "English"; case .es: "Español"; case .fr: "Français" }
    }

    // MARK: Allein

    private var kategorienWahl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Abstand.s) {
                chip(String(localized: "Alle"), gewaehlt: kategorie == nil) { kategorie = nil }
                ForEach(Category.allCases, id: \.self) { c in
                    chip(liste.categoryName(c), symbol: c.symbol, gewaehlt: kategorie == c) { kategorie = c }
                }
            }
        }
    }

    private func chip(_ text: String, symbol: String? = nil, gewaehlt: Bool, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: 5) {
                if let symbol { Image(systemName: symbol).font(.caption) }
                Text(verbatim: text).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 12).frame(minHeight: 36)
            .foregroundStyle(gewaehlt ? Color.onAccent : Color.accentText)
            .background(gewaehlt ? AnyShapeStyle(Color.appFlaeche) : AnyShapeStyle(Color.accentSoft), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }

    private var alleinKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Label("Allein", systemImage: "person.fill").font(.headline).foregroundStyle(Color.accentText)
            kategorienWahl
            Picker("Stufe", selection: $stufe) {
                ForEach(Difficulty.allCases, id: \.self) { Text($0.key).tag($0) }
            }
            .pickerStyle(.segmented).disabled(kinder)
            Toggle("Kinderleicht: nur leichte Wörter, mehr Hinweise", isOn: $kinder).font(.subheadline)
            Button {
                kategorieRoh = kategorie?.rawValue ?? ""
                stufeRoh = stufe.rawValue
                allein(kategorie, kinder ? .easy : stufe, kinder)
            } label: { Text("Los geht’s").frame(maxWidth: .infinity) }
                .buttonStyle(HauptKnopfStil())
                .accessibilityIdentifier("galgen-neu-los")
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }

    // MARK: Wort des Tages

    private var tagesKarte: some View {
        let e = NeuAblage.tagesErgebnis(heute, sprache)
        let st = NeuAblage.tagesStats()
        let serie = st.displayedStreak(today: heute)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Wort des Tages", systemImage: "calendar").font(.headline).foregroundStyle(Color.accentText)
            if let p = DailyWord.word(day: heute, in: liste.words), e == nil {
                Text(verbatim: String(localized: "\(liste.categoryName(p.category)) · \(p.solution.filter { sprache.alphabet.contains($0) }.count) Buchstaben")).font(.subheadline).foregroundStyle(.secondary)
            }
            if serie > 0 { Label(String(localized: "Serie: \(serie) Tage"), systemImage: "flame").font(.subheadline.weight(.semibold)) }
            if let e {
                Text(verbatim: e.gewonnen ? String(localized: "Heute erraten. Morgen gibt es ein neues Wort.") : String(localized: "Heute nicht erraten. Morgen gibt es ein neues Wort.")).font(.subheadline).foregroundStyle(.secondary)
                if TeilenFreigabe.erlaubt() { ShareLink(item: DailyShare.text(day: heute, mistakes: e.fehler, hints: e.hinweise, won: e.gewonnen, appLanguage: .appLanguage)) {
                    Label("Ergebnis teilen", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                }.buttonStyle(ZweitKnopfStil()) }
            } else {
                Button(action: tagesraetsel) { Text("Heute spielen").frame(maxWidth: .infinity) }.buttonStyle(HauptKnopfStil())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }

    // MARK: Eigene Wörter

    private var eigeneKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Eigene Wörter", systemImage: "square.and.pencil").font(.headline).foregroundStyle(Color.accentText)
            Text("Schreib deine eigene Wortliste, zum Beispiel für Familie oder Schule, mit freiem Hinweis.").font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button { verwalten = true } label: { Text(eigeneWoerter.isEmpty ? "Wörter eintragen" : "Wörter verwalten (\(eigeneWoerter.count))").frame(maxWidth: .infinity) }.buttonStyle(ZweitKnopfStil())
                Button { eigenesWort(eigeneWoerter.randomElement()) } label: { Text("Spielen").frame(maxWidth: .infinity) }.buttonStyle(ZweitKnopfStil()).disabled(eigeneWoerter.isEmpty)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }

    // MARK: Party

    private var partyKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Label("Party", systemImage: "person.3.fill").font(.headline).foregroundStyle(Color.accentText)
            Text(verbatim: teilnehmer.map(\.name).joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary)
            Toggle("Wörter selbst ausdenken", isOn: $partyEinst.ownWords).font(.subheadline)
            Text(verbatim: partyEinst.ownWords ? String(localized: "Reihum rät einer, der Nächste in der Reihe denkt sich das Wort aus. Wer scheitert, gibt dem Wortgeber 3 Punkte.") : String(localized: "Die App zieht die Wörter, ihr ratet reihum."))
                .font(.footnote).foregroundStyle(.secondary)
            if !partyEinst.ownWords {
                kategorienParty
                Picker("Stufe", selection: Binding(get: { partyEinst.difficulty }, set: { partyEinst.difficulty = $0 })) {
                    Text("Alle").tag(Difficulty?.none)
                    ForEach(Difficulty.allCases, id: \.self) { Text($0.key).tag(Optional($0)) }
                }.pickerStyle(.segmented)
            }
            Stepper(String(localized: "Runden je Spieler: \(partyEinst.roundsPerPlayer)"), value: $partyEinst.roundsPerPlayer, in: 1 ... 5).font(.subheadline)
            Button { party(partyEinst) } label: { Text("Los geht’s").frame(maxWidth: .infinity) }.buttonStyle(HauptKnopfStil())
                .accessibilityIdentifier("galgen-neu-los")
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }

    private var kategorienParty: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Abstand.s) {
                chip(String(localized: "Alle"), gewaehlt: partyEinst.category == nil) { partyEinst.category = nil }
                ForEach(Category.allCases, id: \.self) { c in
                    chip(liste.categoryName(c), symbol: c.symbol, gewaehlt: partyEinst.category == c) { partyEinst.category = c }
                }
            }
        }
    }

    private func karte(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey, knopf: LocalizedStringKey, aktion: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(titel, systemImage: symbol).font(.headline).foregroundStyle(Color.accentText)
            Text(text).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button(action: aktion) { Text(knopf).frame(maxWidth: .infinity) }.buttonStyle(ZweitKnopfStil())
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}

/// Eigene Wortliste: Wörter mit freiem Hinweis eintragen und löschen
struct NeuEigeneWoerter: View {
    let sprache: WordLanguage
    @Environment(\.dismiss) private var dismiss
    @State private var liste = NeuAblage.eigene()
    @State private var wort = ""
    @State private var hinweis = ""
    @State private var fehler: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Wort", text: $wort).autocorrectionDisabled()
                    TextField("Hinweis (freiwillig)", text: $hinweis)
                    if let f = fehler { Text(verbatim: f).font(.footnote).foregroundStyle(Color.meldungRot) }
                    Button("Hinzufügen") { hinzufuegen() }.disabled(wort.isEmpty)
                }
                Section {
                    if liste.isEmpty { Text("Noch keine eigenen Wörter.").foregroundStyle(.secondary) }
                    ForEach(liste) { w in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: w.text).font(.body.weight(.semibold))
                            if let h = w.hinweis { Text(verbatim: h).font(.footnote).foregroundStyle(.secondary) }
                        }
                    }
                    .onDelete { liste.remove(atOffsets: $0); NeuAblage.eigeneSichern(liste) }
                }
            }
            .navigationTitle("Eigene Wörter").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
        }
    }

    private func hinzufuegen() {
        switch NeuAblage.eigenesWort(text: wort, hinweis: hinweis, sprache: sprache) {
        case .success(let w):
            if !liste.contains(where: { $0.loesung == w.loesung }) { liste.append(w); NeuAblage.eigeneSichern(liste) }
            wort = ""; hinweis = ""; fehler = nil
        case .failure(let f):
            fehler = switch f {
            case .tooShort: String(localized: "Das Wort braucht mindestens \(WordInput.minLetters) Buchstaben.")
            case .tooLong: String(localized: "Das Wort darf höchstens \(WordInput.maxLetters) Buchstaben haben.")
            case .invalidCharacter: String(localized: "Nur Buchstaben, Leerzeichen und Bindestrich sind erlaubt.")
            }
        }
    }
}
#endif
