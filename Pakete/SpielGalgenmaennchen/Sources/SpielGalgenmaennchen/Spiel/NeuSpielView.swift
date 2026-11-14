// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Spielbildschirm von „Galgenmännchen“: kein Scrollen.
/// iPhone von oben: Kopf · Chips (Ballons, Hinweise, Leben, Punkte; immer 28 pt) · Figur = Resthöhe, ohne Deckel · Wort · Lösen/Hinweis · Tastatur fest unten.
/// Lösen läuft über dieselbe Tastatur (kein Systemfeld). iPad quer: Figur und Wort links, Tastatur groß rechts. iPad hoch: Figur groß, Tasten 60 pt.
struct NeuSpielView: View {
    @Binding var stand: NeuStand
    let abbrechen: () -> Void
    let weiter: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hinweisMenue = false
    @State private var loesen: String?
    @State private var loesenMeldung: String?
    @State private var attrappe = GameStore(repository: GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "galgen-neu-attrappe.json")))

    private var game: Game { stand.aktuell ?? Game(solution: "A", language: .de) }

    var body: some View {
        VStack(spacing: 0) {
            kopf
            GeometryReader { geo in inhalt(geo.size) }
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .environment(attrappe)
        .confirmationDialog("Hinweis", isPresented: $hinweisMenue, titleVisibility: .visible) {
            Button("Beliebiger Buchstabe") { hinweis(.random) }.disabled(!game.canHint(.random))
            Button("Erster Buchstabe") { hinweis(.first) }.disabled(!game.canHint(.first))
            Button("Ein Vokal") { hinweis(.vowel) }.disabled(!game.canHint(.vowel))
        }
        // Hardware-Tastatur (iPad): Buchstaben tippen direkt
        .focusable()
        .onKeyPress(characters: .letters) { press in
            guard let c = press.characters.first else { return .ignored }
            taste(Letters.upper(c))
            return .handled
        }
    }

    // MARK: Aufbau

    private func inhalt(_ size: CGSize) -> some View {
        let layout = NeuLayout.entscheide(breite: size.width, hoehe: size.height + 56, sizeClass: sizeClass, grosseSchrift: typeSize.isAccessibilitySize)
        return Group {
            if layout == .breitQuer { quer(size) } else { hochformat(size, breit: layout.breit) }
        }
        .frame(width: size.width, height: size.height)
    }

    private func hochformat(_ size: CGSize, breit: Bool) -> some View {
        let klein = size.height < 560
        let hoehe: CGFloat = breit ? 60 : (klein ? 40 : 48)
        let spalten = typeSize.isAccessibilitySize ? 6 : 7
        return VStack(spacing: Design.Abstand.s) {
            // K-016: Jede Zeile bekommt die Bildschirmbreite fest, damit ein breites Wort oder eine breite Figur
            // die Tastatur nicht über den Rand schiebt.
            chips.frame(width: size.width, height: Theme.chipHoehe)
            if let h = game.hintText, !h.isEmpty { hinweisText(h).frame(width: size.width) }
            figur.frame(width: min(size.width, breit ? 520 : .infinity), alignment: .center).frame(minHeight: 90, maxHeight: .infinity)
            wort.frame(width: min(size.width, breit ? 720 : .infinity))
            unten.frame(width: size.width)
            tastatur(spalten: spalten, hoehe: hoehe).frame(width: min(size.width, breit ? 720 : .infinity))
        }
        .padding(.top, 4).padding(.bottom, 8)
        .frame(width: size.width)
        .clipped()
    }

    private func quer(_ size: CGSize) -> some View {
        HStack(alignment: .top, spacing: Design.Abstand.xl) {
            VStack(spacing: 10) {
                chips.frame(height: Theme.chipHoehe)
                if let h = game.hintText, !h.isEmpty { hinweisText(h) }
                figur.frame(maxHeight: .infinity)
                wort
            }
            .frame(width: size.width * 0.45)
            VStack(spacing: Design.Abstand.m) {
                Spacer(minLength: 0)
                unten
                tastatur(spalten: 6, hoehe: 64)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 640)
        }
        .padding(.horizontal, 24).padding(.vertical, 8)
    }

    private var figur: some View {
        FigureView(remaining: 8 - game.mistakes, outcome: game.status == .playing ? .playing : (game.status == .won ? .celebrating : .lost))
            .accessibilityLabel(Text("Noch \(8 - game.mistakes) Ballons"))
    }

    @ViewBuilder private var wort: some View {
        if let eingabe = loesen {
            VStack(spacing: Design.Abstand.xs) {
                Text(verbatim: eingabe.isEmpty ? " " : eingabe)
                    .font(.system(.title, design: Design.zahlDesign, weight: .bold)).foregroundStyle(Color.accentText)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 12)
                    .background(Color.accentSoft, in: .rect(cornerRadius: Theme.feldRadius))
                    .accessibilityLabel(Text("Dein Lösungsversuch: \(eingabe)"))
                if let m = loesenMeldung { Text(verbatim: m).font(.footnote).foregroundStyle(Color.meldungRot) }
            }
            .padding(.horizontal, Theme.seitenRand)
        } else {
            WordView(game: game).padding(.vertical, 4)
        }
    }

    // MARK: Chips und Kopf

    private var chips: some View {
        HStack(spacing: Design.Abstand.s) {
            StatusChip(symbol: "balloon.fill", text: String(8 - game.mistakes), beschriftung: "Ballons übrig")
            StatusChip(symbol: "lightbulb", text: String(game.hintLimit - game.hints.count), beschriftung: "Hinweise übrig")
            if stand.modus == .survival, let run = stand.survival {
                StatusChip(symbol: "heart.fill", text: String(run.lives), beschriftung: "Leben übrig")
                StatusChip(text: Text(verbatim: "\(run.wins)"), ton: .neutral, beschriftung: Text("\(run.wins) Wörter gelöst"))
            }
            if stand.modus == .party, let p = stand.party {
                StatusChip(symbol: "person.fill", text: Text(verbatim: p.names[p.guesser]), ton: .neutral)
            }
        }
        .lineLimit(1)
    }

    private func hinweisText(_ h: String) -> some View {
        Label { Text(verbatim: h) } icon: { Image(systemName: "lightbulb") }
            .font(.subheadline).multilineTextAlignment(.center).padding(.horizontal, 16)
            .accessibilityLabel(Text(verbatim: h))
    }

    private var kopf: some View {
        SpielKopf(mitte: titel, linksAktion: abbrechen) { EmptyView() }
    }

    private var titel: String {
        let kategorie = game.category.map { NeuAblage.liste(stand.sprache).categoryName($0) }
        switch stand.modus {
        case .party:
            let p = stand.party
            return String(localized: "\(p.map { $0.names[$0.guesser] } ?? "") rät · Runde \(min((p?.round ?? 0) + 1, p?.totalRounds ?? 0)) von \(p?.totalRounds ?? 0)")
        case .survival: return [kategorie, String(localized: "Wort \((stand.survival?.played ?? 0) + (game.status == .playing ? 1 : 0))")].compactMap { $0 }.joined(separator: " · ")
        case .daily: return String(localized: "Wort des Tages")
        default:
            if kategorie == nil && game.hintText != nil { return String(localized: "Eigenes Wort") }
            return [kategorie, game.difficulty.map { String(localized: $0.title) }].compactMap { $0 }.joined(separator: " · ")
        }
    }

    // MARK: Unten: Lösen/Hinweis, Lösen-Eingabe oder Karte am Ende eines Überleben-Worts

    @ViewBuilder private var unten: some View {
        if stand.modus == .survival, game.status != .playing, let run = stand.survival {
            ueberlebenKarte(run)
        } else if loesen != nil {
            HStack(spacing: 10) {
                Button { loesen = nil; loesenMeldung = nil } label: { Text("Abbrechen").frame(maxWidth: .infinity) }.buttonStyle(ZweitKnopfStil())
                Button { loesen = String((loesen ?? "").dropLast()) } label: { Image(systemName: "delete.left").frame(maxWidth: .infinity) }
                    .buttonStyle(ZweitKnopfStil()).accessibilityLabel("Löschen")
                Button { raten() } label: { Text("Raten").frame(maxWidth: .infinity) }.buttonStyle(HauptKnopfStil()).disabled((loesen ?? "").isEmpty)
            }
            .padding(.horizontal, Theme.seitenRand)
            .overlay(alignment: .top) { sonderzeichen.offset(y: -44) }
        } else {
            if Tisch.aktiv {
                // Tinte (große Runde, Punkt 10): runde Nebenknöpfe statt unterstrichener Wörter auf dem Filz
                HStack(spacing: 10) {
                    Button { loesen = ""; loesenMeldung = nil } label: { Label("Lösen", systemImage: "text.cursor").lineLimit(1).minimumScaleFactor(0.7) }
                        .tischNebenKnopf().disabled(game.status != .playing)
                    Button { hinweisMenue = true } label: { Label("Hinweis", systemImage: "lightbulb").lineLimit(1).minimumScaleFactor(0.7) }
                        .tischNebenKnopf().disabled(!game.canHint)
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .padding(.horizontal, Theme.seitenRand)
            } else {
            AktionsLeiste(eintraege: [
                AktionsEintrag(symbol: "text.cursor", titel: "Lösen", gesperrt: game.status != .playing) { loesen = ""; loesenMeldung = nil },
                AktionsEintrag(symbol: "lightbulb", titel: "Hinweis", gesperrt: !game.canHint) { hinweisMenue = true },
            ])
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
    }

    /// Leerzeichen und Bindestrich für mehrteilige Wörter, nur wenn das Wort sie enthält
    @ViewBuilder private var sonderzeichen: some View {
        let hat = Letters.open.filter { game.solution.contains($0) }.sorted { $0 < $1 }
        if !hat.isEmpty {
            HStack(spacing: Design.Abstand.s) {
                ForEach(hat, id: \.self) { c in
                    Button { loesen = (loesen ?? "") + String(c) } label: { Text(c == " " ? String(localized: "Leerzeichen") : "−").font(.footnote.weight(.semibold)).padding(.horizontal, 12).frame(minHeight: 36) }
                        .tischNebenKnopf()
                }
            }
        }
    }

    private func ueberlebenKarte(_ run: SurvivalRun) -> some View {
        let gewonnen = game.status == .won
        return HStack(spacing: Design.Abstand.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(gewonnen ? (stand.bonusLeben ? String(localized: "Gelöst – ein Leben dazu!") : String(localized: "Gelöst!")) : String(localized: "Ein Leben weniger"))
                    .font(.subheadline.weight(.semibold))
                Text(verbatim: String(localized: "Das Wort war \(game.displayText ?? game.solution)")).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Button(action: weiter) { Text(run.isOver ? "Ergebnis" : "Nächstes Wort") }.buttonStyle(AkzentPilleStil(gefuellt: true)).fixedSize()
        }
        .padding(12)
        .background(Color.accentSoft, in: .rect(cornerRadius: Theme.cardRadius))
        .padding(.horizontal, Theme.seitenRand)
    }

    private func tastatur(spalten: Int, hoehe: CGFloat) -> some View {
        NeuTastatur(sprache: game.language, geraten: game.guessed, loesung: game.solution, aktiv: game.status == .playing, spalten: spalten,
                    tastenHoehe: hoehe, alleFrei: loesen != nil, taste: { taste($0) })
    }

    // MARK: Eingaben

    private func taste(_ c: Character) {
        guard game.status == .playing else { return }
        if loesen != nil {
            guard game.language.alphabet.contains(c) else { return }
            loesen = (loesen ?? "") + String(c); loesenMeldung = nil
            return
        }
        var g = game
        let r = g.guess(String(c))
        guard r == .hit || r == .miss else { return }
        stand.aktuell = g
        if r == .hit {
            let n = g.solution.filter { $0 == c }.count
            ansage(n == 1 ? String(localized: "\(String(c)) kommt einmal vor") : String(localized: "\(String(c)) kommt \(n) mal vor"))
        } else {
            ansage(String(localized: "\(String(c)) kommt nicht vor, noch \(8 - g.mistakes) Ballons"))
        }
        if g.status == .won { ansage(String(localized: "Geschafft! Das Wort ist \(g.solution).")) }
        else if g.status == .lost { ansage(String(localized: "Alle Ballons sind geplatzt. Das Wort war \(g.solution).")) }
    }

    private func raten() {
        guard let text = loesen, !text.isEmpty else { return }
        var g = game
        switch g.solve(text) {
        case .solved:
            stand.aktuell = g; loesen = nil; loesenMeldung = nil
            ansage(String(localized: "Geschafft! Das Wort ist \(g.solution)."))
        case .wrong:
            stand.aktuell = g; loesen = nil; loesenMeldung = nil
            ansage(String(localized: "Falsch geraten, zwei Ballons weniger. Noch \(8 - g.mistakes) Ballons."))
        case .alreadyTried: loesenMeldung = String(localized: "Das hast du schon versucht.")
        case .invalid: loesenMeldung = String(localized: "Das ist kein gültiges Wort.")
        case .over: loesen = nil
        }
    }

    private func hinweis(_ art: HintKind) {
        var g = game
        var rng = SystemRandomNumberGenerator()
        guard let c = g.hint(art, using: &rng) else { return }
        stand.aktuell = g
        ansage(String(localized: "Hinweis: \(String(c))"))
    }

    private func ansage(_ t: String) { AccessibilityNotification.Announcement(t).post() }
}

/// Aufbau nach der Fenstergröße: unter 700 pt Breite iPhone-Aufbau, quer erst ab 1000 pt
enum NeuLayout: Equatable {
    case kompakt, breitHoch, breitQuer
    var breit: Bool { self != .kompakt }
    static func entscheide(breite: CGFloat, hoehe: CGFloat, sizeClass: UserInterfaceSizeClass?, grosseSchrift: Bool = false) -> NeuLayout {
        if sizeClass == .compact || breite < 700 { return .kompakt }
        if grosseSchrift { return .breitHoch }
        return breite > hoehe && breite >= 1000 ? .breitQuer : .breitHoch
    }
}
#endif
