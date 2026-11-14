// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Party am Gerät, Ansichten außerhalb des Spiels: Übergabe, Wort eingeben, Zwischenstand. Die Spieler kommen vom Rahmen (Spielerwahl der Sammlung).
struct NeuUebergabe: View {
    let party: PartyMatch
    let abbrechen: () -> Void
    let bereit: () -> Void

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Runde \(min(party.round + 1, party.totalRounds)) von \(party.totalRounds)"), linksAktion: abbrechen)
            Spacer()
            VStack(spacing: Design.Abstand.l) {
                Image(systemName: "arrow.left.arrow.right").font(.largeTitle.weight(.semibold)).foregroundStyle(Color.appFlaeche)
                    .frame(width: 88, height: 88).background(Color.accentSoft, in: .circle).accessibilityHidden(true)
                Text(verbatim: titel).font(.title.weight(.bold)).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                if let u = untertitel { Text(verbatim: u).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }
            }
            .padding(.horizontal, Theme.seitenRand)
            Spacer()
            Button(action: bereit) { Text("Ich bin bereit").frame(maxWidth: .infinity) }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
                .accessibilityIdentifier("galgen-neu-bereit")
        }
        .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity, maxHeight: .infinity)
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
    }

    private var titel: String {
        if party.step == .giverHandover, let g = party.giver { return String(localized: "\(party.names[g]) denkt sich ein Wort aus") }
        return String(localized: "Gib das Gerät an \(party.names[party.guesser])")
    }

    private var untertitel: String? {
        if party.step == .giverHandover, let g = party.giver { return String(localized: "Gib das Gerät an \(party.names[g])") }
        return nil
    }
}

/// Der Wortgeber tippt sein Wort und einen freien Hinweis ein.
struct NeuWortEingabe: View {
    let party: PartyMatch
    let sprache: WordLanguage
    let abbrechen: () -> Void
    let fertig: (String, String?) -> Void
    @State private var wort = ""
    @State private var hinweis = ""
    @State private var fehler: String?
    @FocusState private var fokus: Bool

    var body: some View {
        VStack(spacing: 0) {
            SpielKopf(mitte: String(localized: "Wort eingeben"), linksAktion: abbrechen)
            VStack(alignment: .leading, spacing: 14) {
                Text("\(party.names[party.giver ?? 0]), denk dir ein Wort aus. \(party.names[party.guesser]) schaut nicht hin.")
                    .font(.subheadline).foregroundStyle(.secondary)
                TextField("Dein Wort", text: $wort).textFieldStyle(.roundedBorder).textInputAutocapitalization(.never).autocorrectionDisabled().focused($fokus)
                    .accessibilityIdentifier("galgen-neu-wort")
                TextField("Hinweis (freiwillig)", text: $hinweis).textFieldStyle(.roundedBorder)
                if let f = fehler { Label { Text(verbatim: f) } icon: { Image(systemName: "exclamationmark.triangle") }.font(.footnote.weight(.semibold)).foregroundStyle(Color.meldungRot) }
                Spacer()
                Button { pruefen() } label: { Text("Fertig").frame(maxWidth: .infinity) }.buttonStyle(HauptKnopfStil()).disabled(wort.isEmpty)
            }
            .padding(Theme.seitenRand).padding(.bottom, 8)
            .frame(maxWidth: Theme.wideColumnWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .onAppear { fokus = true }
    }

    private func pruefen() {
        switch WordInput.normalize(wort, language: sprache) {
        case .success(let l):
            let h = hinweis.trimmingCharacters(in: .whitespacesAndNewlines)
            fertig(l, h.isEmpty ? nil : h)
        case .failure(let f):
            fehler = switch f {
            case .tooShort: String(localized: "Das Wort braucht mindestens \(WordInput.minLetters) Buchstaben.")
            case .tooLong: String(localized: "Das Wort darf höchstens \(WordInput.maxLetters) Buchstaben haben.")
            case .invalidCharacter: String(localized: "Nur Buchstaben, Leerzeichen und Bindestrich sind erlaubt.")
            }
        }
    }
}

/// Zwischenstand nach einer Runde: Ergebnis, Punkte dieser Runde und Rangliste
struct NeuZwischenstand: View {
    let party: PartyMatch
    let abbrechen: () -> Void
    let weiter: () -> Void

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Zwischenstand"), linksAktion: abbrechen)
            VStack(spacing: 6) {
                Image(systemName: party.lastWon ? "party.popper.fill" : "balloon.fill").font(.largeTitle).foregroundStyle(Color.appFlaeche).accessibilityHidden(true)
                Text(verbatim: party.lastWon ? String(localized: "\(party.names[party.lastGuesser]) hat das Wort erraten") : String(localized: "\(party.names[party.lastGuesser]) hat das Wort nicht erraten"))
                    .font(.title3.weight(.bold)).multilineTextAlignment(.center)
                if let w = party.game { Text(verbatim: String(localized: "Das Wort war \(w.displayText ?? w.solution)")).font(.subheadline).foregroundStyle(.secondary) }
            }
            .padding(.top, 12).padding(.horizontal, Theme.seitenRand)
            VStack(spacing: 0) {
                ForEach(party.ranking, id: \.self) { i in
                    HStack {
                        Text(verbatim: "\(party.places[i]).").font(.headline.monospacedDigit()).frame(width: 30, alignment: .leading)
                        Text(verbatim: party.names[i]).font(.headline)
                        Spacer()
                        if party.lastGain[i] > 0 { Text(verbatim: "+\(party.lastGain[i])").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText) }
                        Text(verbatim: "\(party.scores[i])").font(.title3.weight(.bold).monospacedDigit()).frame(minWidth: 36, alignment: .trailing)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 14)
                    .accessibilityElement(children: .combine)
                    if i != party.ranking.last { Divider().padding(.leading, 14) }
                }
            }
            .spielTischKarte()
            .padding(.horizontal, Theme.seitenRand)
            Spacer()
            Button(action: weiter) { Text(party.isFinished ? "Zur Rangliste" : "Nächste Runde").frame(maxWidth: .infinity) }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
                .accessibilityIdentifier("galgen-neu-weiter")
        }
        .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity, maxHeight: .infinity)
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
    }
}
#endif
