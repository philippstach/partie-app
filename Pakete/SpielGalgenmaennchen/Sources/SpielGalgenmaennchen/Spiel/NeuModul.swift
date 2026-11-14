// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Galgenmännchen : die eine Fassung des Spiels in der Sammlung. Spielbildschirm ohne Scrollen mit Lösen über die Spieltastatur,
/// iPad-Aufbau, Party über die Spielerwahl der Sammlung, eigene Wortliste, Wort des Tages und Überleben im Rahmen.
/// Regeln, Wörter, Punkte und Serien (`Game`, `PartyMatch`, `SurvivalRun`, `WordPicker`) sind im Spielkern, das unverändert bleibt.
@MainActor
public struct GalgenmaennchenModul: SpielModul {
    public init() {}
    public let id = NeuAblage.id
    public let name = "Galgenmännchen"
    public let gattung = Gattung.wort
    public let farbe = AkzentFarbeWert.violett
    public let symbol = "textformat.abc.dottedunderline"
    public let spielerzahl = 1...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Rate das Wort, bevor die Ballons platzen", farbe: farbe, spieler: 1...4,
                        regeln: "Ein Wort ist gesucht. Rate Buchstaben: Jeder Treffer deckt das Wort auf, jeder Fehler lässt einen von acht Ballons platzen. Platzt der letzte, ist das Spiel verloren. Du kannst zwei Hinweise nehmen (bei „Kinderleicht“ vier, solange noch mindestens zwei verschiedene Buchstaben fehlen) und das ganze Wort raten (ein falscher Versuch kostet zwei Ballons). Im freien Spiel wählst du allein Kategorie und Stufe; außerdem gibt es das Wort des Tages und Überleben mit drei Leben. Mit mehreren spielt ihr Party: Reihum rät einer, und der Nächste in der Reihe denkt sich das Wort aus – oder die App zieht eins. Du kannst auch eine eigene Wortliste anlegen.",
                        einzelText: "Allein oder mit mehreren: Allein rätst du Wörter, mit zwei bis vier Personen spielt ihr Party.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                NeuSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
            }
            .mitStartTitel("Weiter")
            .mitStartOptionen { NeuStartWahl(eintraege: $0) }   // Große Tinte-Runde, Punkt 7: Wahl auf der Spielseite (nur Tinte, sonst leer)
            .mitZiel("Errate das Wort, bevor alle acht Ballons geplatzt sind.")
            .mitZielSchritt(GalgenAnleitung.ziel)   // Blatt 14: Anleitung zum Durchwischen (fünf Seiten), Regeltext bleibt hinter „Alle Regeln lesen“
            .mitZielSchrittNeu(GalgenAnleitung.zielNeu)
            .mitAnleitung(RegelTexteNeu.anleitung(neu: GalgenAnleitung.schritteNeu, alt: GalgenAnleitung.schritte))
        )
    }
}

/// Wurzel im Rahmen: Wahl, Spiel, Party-Schritte und Ende. Der Stand wird über `fortsetzbar` gesichert.
struct NeuSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var stand: NeuStand?
    @State private var sprachRoh: String = UserDefaults.standard.string(forKey: "galgen-neu.sprache") ?? WordLanguage.deviceDefault.rawValue
    @State private var gemeldet = false
    @State private var meldung: String?
    /// Tinte (Punkt 7): Die zweite Startseite gibt es nur noch als Rückfall, wenn der Start nach der Wahl der Spielseite nicht klappt.
    @State private var wahlZeigen = !Design.ist(.tinte)
    @State private var angestartet = false

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var alt = SpielStand.laden(NeuStand.self, spiel: NeuAblage.id).flatMap { $0.fortsetzbar ? $0 : nil }
        alt?.partyVerdecken()
        _stand = State(initialValue: alt)
    }

    private var sprache: Binding<WordLanguage> {
        Binding(get: { WordLanguage(rawValue: sprachRoh) ?? .de },
                set: { sprachRoh = $0.rawValue; UserDefaults.standard.set($0.rawValue, forKey: "galgen-neu.sprache") })
    }

    private var name: String { teilnehmer.first?.name ?? "" }

    var body: some View {
        ZStack {
            if let b = Binding($stand) { partie(b) } else if !wahlZeigen {
                Color.clear.aufTisch()
            } else {
                NeuWahl(teilnehmer: teilnehmer, abbrechen: abbrechen, allein: startAllein, tagesraetsel: startTag, ueberleben: startUeberleben,
                        eigenesWort: startEigenes, party: startParty, sprache: sprache)
            }
        }
        .fortsetzbar(NeuAblage.id, $stand, pruefen: { $0.fortsetzbar })
        .onAppear { startenNachWahl() }
        #if DEBUG
        .testEndeMelden {   // -testZustand ende: der letzte fehlende Buchstabe wird nach dem Laden als normaler Tipp geraten
            guard var st = stand, var g = st.aktuell, g.status == .playing,
                  let c = g.solution.first(where: { !g.guessed.contains($0) && Letters.upper(String($0)).count == 1 && g.language.alphabet.contains($0) }) else { return }
            g.guess(String(c))
            st.aktuell = g
            stand = st
        }
        #endif
        .alert(meldung ?? "", isPresented: Binding(get: { meldung != nil }, set: { if !$0 { meldung = nil } })) { Button("OK") { meldung = nil } }
    }

    // MARK: Ansicht je Stand

    @ViewBuilder
    private func partie(_ b: Binding<NeuStand>) -> some View {
        let s = b.wrappedValue
        if s.modus == .party, let p = s.party {
            switch p.step {
            case .giverHandover, .guesserHandover:
                NeuUebergabe(party: p, abbrechen: abbrechen) { b.wrappedValue.partyWeiter() }
            case .entry:
                NeuWortEingabe(party: p, sprache: s.sprache, abbrechen: abbrechen) { l, h in b.wrappedValue.partyWort(solution: l, hinweis: h) }
            case .score:
                NeuZwischenstand(party: p, abbrechen: abbrechen) { naechsteRunde(b) }
            case .playing:
                NeuSpielView(stand: b, abbrechen: abbrechen, weiter: {})
                    .task(id: p.game?.status == .playing) { await rundeBeenden(b) }
            }
        } else {
            NeuSpielView(stand: b, abbrechen: abbrechen, weiter: { ueberlebenWeiter(b) })
                .task(id: s.game?.status == .playing) { await spielBeenden(b) }
        }
    }

    // MARK: Ende einer Runde

    private func spielBeenden(_ b: Binding<NeuStand>) async {
        guard let g = b.wrappedValue.game, g.status != .playing, !gemeldet else { return }
        if b.wrappedValue.modus == .survival {
            b.wrappedValue.ueberlebenVerbuchen()
            return
        }
        // C-040: Das Tagesergebnis zählt sofort, die Wartezeit ist nur für die Anzeige
        if b.wrappedValue.modus == .daily, let tag = b.wrappedValue.tag {
            NeuAblage.tagVerbuchen(tag, NeuTagesErgebnis(gewonnen: g.status == .won, fehler: g.mistakes, hinweise: g.hints.count, sprache: g.language))
        }
        // Kurz den Sieg oder die Niederlage zeigen, dann meldet der Rahmen das Ende
        try? await Task.sleep(for: .milliseconds(g.status == .won ? 1300 : 1600))
        guard !Task.isCancelled, !gemeldet, let e = b.wrappedValue.endeAllein(name: name) else { return }
        gemeldet = true
        ende(e)
    }

    private func rundeBeenden(_ b: Binding<NeuStand>) async {
        guard let g = b.wrappedValue.party?.game, g.status != .playing else { return }
        try? await Task.sleep(for: .milliseconds(g.status == .won ? 1300 : 1600))
        guard !Task.isCancelled else { return }
        b.wrappedValue.partyRundeBeenden()
    }

    private func naechsteRunde(_ b: Binding<NeuStand>) {
        guard let p = b.wrappedValue.party else { return }
        if p.isFinished {
            guard !gemeldet, let e = b.wrappedValue.endeParty() else { return }
            gemeldet = true
            ende(e)
            return
        }
        if p.settings.ownWords { b.wrappedValue.partyNaechsteRunde(wort: nil); return }
        var rng = SystemRandomNumberGenerator()
        let sp = b.wrappedValue.sprache
        guard let w = NeuAblage.ziehe(NeuAblage.liste(sp), kategorie: p.settings.category, stufe: p.settings.difficulty, sprache: sp, rng: &rng) else {
            meldung = String(localized: "Es gibt keine Wörter für diese Auswahl."); return
        }
        b.wrappedValue.partyNaechsteRunde(wort: w)
    }

    private func ueberlebenWeiter(_ b: Binding<NeuStand>) {
        guard let run = b.wrappedValue.survival else { return }
        if run.isOver {
            guard !gemeldet else { return }
            gemeldet = true
            ende(b.wrappedValue.endeUeberleben(name: name))
            return
        }
        var rng = SystemRandomNumberGenerator()
        let sp = b.wrappedValue.sprache
        guard let w = NeuAblage.ziehe(NeuAblage.liste(sp), kategorie: nil, stufe: run.nextDifficulty, sprache: sp, rng: &rng) else {
            meldung = String(localized: "Es gibt keine Wörter für diese Auswahl."); return
        }
        b.wrappedValue.ueberlebenNaechstes(w)
    }

    // MARK: Start

    /// Große Tinte-Runde, Punkt 7: „Spielen“ der Spielseite startet sofort, was dort gewählt ist (`NeuStartWahl`).
    /// Nur beim ersten Erscheinen und nur ohne offene Partie (Fortsetzen geht vor). Klappt der Start nicht, kommt die alte Wahl als Rückfall.
    private func startenNachWahl() {
        guard Design.ist(.tinte), !angestartet, stand == nil else { return }
        angestartet = true
        let d = UserDefaults.standard
        if teilnehmer.count >= 2 {
            startParty(NeuStartWahl.gespeicherteParty())
        } else {
            let kategorie = Category(rawValue: d.string(forKey: "galgen-neu.kategorie") ?? "")
            let stufe = Difficulty(rawValue: d.object(forKey: "galgen-neu.stufe") as? Int ?? Difficulty.medium.rawValue) ?? .medium
            let kinder = d.bool(forKey: NeuStartWahl.kinderSchluessel)
            switch d.string(forKey: NeuStartWahl.schluessel) ?? "frei" {
            case "tag" where NeuAblage.tagesErgebnis(DayKey.string(for: Date()), sprache.wrappedValue) == nil:
                startTag()
                // Nach dem Wort des Tages startet „Nochmal“ ein freies Spiel (das Tageswort gibt es nur einmal)
                d.set("frei", forKey: NeuStartWahl.schluessel)
            case "ueberleben":
                startUeberleben()
            case "eigene" where !NeuAblage.eigene().isEmpty:
                startEigenes(NeuAblage.eigene().randomElement())
            default:
                startAllein(kategorie, kinder ? .easy : stufe, kinder)
            }
        }
        if stand == nil { wahlZeigen = true }
    }

    private func startAllein(_ k: Category?, _ stufe: Difficulty?, _ kinder: Bool) {
        var rng = SystemRandomNumberGenerator()
        let sp = sprache.wrappedValue
        guard let w = NeuAblage.ziehe(NeuAblage.liste(sp), kategorie: k, stufe: kinder ? .easy : stufe, sprache: sp, rng: &rng) else {
            meldung = String(localized: "Es gibt keine Wörter für diese Auswahl."); return
        }
        stand = .allein(w, sprache: sp, kids: kinder)
    }

    private func startTag() {
        let sp = sprache.wrappedValue
        let tag = DayKey.string(for: Date())
        guard NeuAblage.tagesErgebnis(tag, sp) == nil, let w = DailyWord.word(day: tag, in: NeuAblage.liste(sp).words) else {
            meldung = String(localized: "Es gibt keine Wörter für diese Auswahl."); return
        }
        stand = .tag(w, sprache: sp, tag: tag)
    }

    private func startUeberleben() {
        var rng = SystemRandomNumberGenerator()
        let sp = sprache.wrappedValue
        guard let w = NeuAblage.ziehe(NeuAblage.liste(sp), kategorie: nil, stufe: .easy, sprache: sp, rng: &rng) else {
            meldung = String(localized: "Es gibt keine Wörter für diese Auswahl."); return
        }
        stand = .ueberleben(w, sprache: sp)
    }

    private func startEigenes(_ w: EigenesWort?) {
        guard let w else { return }
        stand = .eigenes(solution: w.loesung, text: w.text, hinweis: w.hinweis, sprache: sprache.wrappedValue)
    }

    private func startParty(_ einst: PartySettings) {
        let sp = sprache.wrappedValue
        var rng = SystemRandomNumberGenerator()
        var w: Word?
        if !einst.ownWords {
            w = NeuAblage.ziehe(NeuAblage.liste(sp), kategorie: einst.category, stufe: einst.difficulty, sprache: sp, rng: &rng)
            if w == nil { meldung = String(localized: "Es gibt keine Wörter für diese Auswahl."); return }
        }
        SpielerQuelle.menschen(teilnehmer.filter { !$0.computer }.map(\.name))
        stand = .party(names: teilnehmer.map(\.name), settings: einst, sprache: sp, erstesWort: w)
    }
}

extension NeuStand {
    /// Ein Stand, der beim Fortsetzen weitergespielt werden darf (kein beendetes Einzelspiel, nichts Kaputtes)
    var fortsetzbar: Bool {
        guard stimmig else { return false }
        if modus == .single || modus == .daily { return game?.status == .playing }
        if modus == .party, party?.isFinished == true, party?.step != .score { return false }
        return true
    }
}
#endif
