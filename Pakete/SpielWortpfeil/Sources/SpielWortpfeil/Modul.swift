// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import Baukasten
import SpieleKern

/// Kreuzworträtsel im `SpielRahmen`: Startseite, Regeln und Anleitung, Statistik, Fortsetzen und Ende kommen vom Rahmen.
/// Hier liegen nur das Rätsel selbst und seine eigenen Karten: Rätsel des Tages, Stufen, Themen, Archiv, Erfolge, Erinnerung.
@MainActor
public struct WortpfeilModul: SpielModul {
    public init() {}
    public let id = GameStore.kennung
    public let name = "Kreuzworträtsel"
    public let gattung = Gattung.wort
    public let farbe = AkzentFarbeWert(flaeche: KwFarbe.akzent.hell, textHell: KwFarbe.akzent.hell, textDunkel: KwFarbe.akzent.dunkel)
    public let symbol = "text.word.spacing"
    public let spielerzahl = 1...1
    public let stufenNamen = ["Leicht", "Mittel", "Schwer"]
    public func start(_ umgebung: SpielUmgebung) -> AnyView { AnyView(WortpfeilWurzel(modul: self, umgebung: umgebung)) }
}

/// Hält den einen `GameStore` des Spiels und reicht ihn an Startkarten, Partie und Ende-Inhalt des Rahmens.
struct WortpfeilWurzel: View {
    let modul: WortpfeilModul
    let umgebung: SpielUmgebung
    @State private var store: GameStore

    init(modul: WortpfeilModul, umgebung: SpielUmgebung) {
        self.modul = modul; self.umgebung = umgebung
        let store = GameStore()
        Self.altenStandUebernehmen(store, name: umgebung.spieler.ich?.name ?? "")
        _store = State(initialValue: store)
    }

    /// Ein laufendes Rätsel aus der Zeit vor dem Rahmen (Build 18 und früher) hat noch keinen Stand im Kern. Damit der Rahmen
    /// „Partie fortsetzen“ anbietet, wird er einmal nachgetragen. Verwirft der Rahmen einen Stand, räumt `GameStore.abgleichen`
    /// das Rätsel sofort mit ab; ein Rätsel ohne Stand kann beim Öffnen also nur ein altes sein.
    static func altenStandUebernehmen(_ store: GameStore, name: String) {
        guard store.hasRunningGame, let g = store.game, !SpielStand.vorhanden(GameStore.kennung),
              !SpielStand.verworfen.contains(GameStore.kennung) else { return }
        SpielStand.sichern(g.puzzle.id, spiel: GameStore.kennung)
        if LetzteRunde.laden(GameStore.kennung) == nil { LetzteRunde(plaetze: [.init(name: name, computer: false)]).speichern(GameStore.kennung) }
    }

    var body: some View {
        SpielRahmen(id: modul.id, name: modul.name, untertitel: "Fragen im Gitter, Pfeile zeigen den Weg.", farbe: modul.farbe, spieler: 1...1,
                    regeln: "Ein Schwedenrätsel hat keine Zahlen: Die Fragen stehen in Feldern mitten im Gitter. Der Pfeil zeigt, wohin das Wort läuft. Fülle alle Buchstabenfelder richtig aus. Es gibt keinen Zeitdruck und keine Strafen.",
                    umgebung: umgebung) { teilnehmer, ende, abbrechen in
            WortpfeilPartie(store: store, name: teilnehmer.first?.name ?? "", ende: ende, abbrechen: abbrechen)
        }
        .mitZiel("Fülle alle Felder mit den Lösungswörtern, die die Fragen in den Pfeilfeldern verlangen.")
        .mitAnleitung(Array(WortpfeilAnleitung.schritte.dropFirst()))
        .mitRegelnAnsicht { RulesDetailView().environment(store) }
        .mitStartInhalt { aktionen in WortpfeilStartKarten(aktionen: aktionen).environment(store) }
        .mitEndeInhalt { _, nochmal in WortpfeilEndeInhalt(nochmal: nochmal).environment(store) }
        .tint(Color.kwAkzent)   // Design-Akzent 1658D8 (hell) / 6FA8FF (dunkel) für alle Systemelemente im Spiel
    }
}

/// Die laufende Partie im Rahmen: setzt das gespeicherte Rätsel fort oder startet das vorgemerkte, hält die Uhr beim Wechsel
/// in den Hintergrund an und meldet das Ende, sobald die Gewinn-Welle durch ist.
struct WortpfeilPartie: View {
    let store: GameStore
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var gestartet = false
    @State private var gemeldet = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.game != nil {
                GameView(abbrechen: abbrechen)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // Spiel wächst bis xxxLarge, das Gitter bleibt fest
            } else if gestartet {
                keinRaetsel
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.papier)
            }
        }
        .environment(store)
        .task { await starten() }
        .onDisappear { store.goHome(); store.abgleichen() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.appBecameActive() } else { store.appMovedToBackground() }
        }
        .onChange(of: fertig) { _, _ in melden() }
        #if DEBUG
        .testEndeMelden {   // -testZustand ende: der letzte fehlende Buchstabe wird nach dem Laden als normale Eingabe gesetzt
            guard let g = store.game, !g.finished,
                  let p = g.puzzle.letterCells.first(where: { g.entries[$0] == nil }), let c = g.puzzle.solution(p) else { return }
            store.tap(row: p.r, col: p.c)
            store.type(String(c))
        }
        #endif
        .alert("Speichern fehlgeschlagen", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.saveError = nil } })) {
            Button("OK") { store.saveError = nil }
        } message: {
            Text(store.saveError ?? "")
        }
    }

    /// Gelöst und die Gewinn-Welle ist durch
    private var fertig: Bool { store.result != nil && !store.celebrating }

    /// Fortsetzen, wenn der Rahmen einen Stand hat; sonst das vorgemerkte Rätsel (oder das nächste passende).
    /// Die Rätselpakete laden beim ersten Öffnen kurz im Hintergrund, so lange dreht das Rad.
    private func starten() async {
        guard !gestartet else { return }
        while store.packsLoading { try? await Task.sleep(for: .milliseconds(50)) }
        let wunsch = store.vorgemerkt
        store.vorgemerkt = nil
        if SpielStand.vorhanden(GameStore.kennung), store.hasRunningGame {
            store.resume()
        } else {
            store.abgleichen()   // der Rahmen hat einen alten Stand verworfen: hier auch
            store.starten(wunsch)
        }
        gestartet = true
        melden()   // falls ein schon gelöstes Rätsel geladen wurde
    }

    private func melden() {
        guard fertig, !gemeldet, let r = store.result else { return }
        gemeldet = true
        var ausgang = SpielEnde(reihenfolge: [name], info: untertitel(r), einzel: .gewonnen)
        ausgang.dauer = r.time
        if r.isDaily { ausgang.titel = String(localized: "Tagesrätsel geschafft!") }
        ausgang.nochmalTitel = r.levelCompleted ? "Von vorn beginnen" : "Nächstes Rätsel"
        // Statistik je Stufe im Kern; Tagesrätsel zählen eigens, Themenrätsel bei keiner Stufe
        if r.isDaily { ausgang.kennzahlen["tages"] = 1 }
        else if r.themeID == nil, let i = Level.allCases.firstIndex(of: r.level) { ausgang.kennzahlen["stufe"] = Double(i) }
        ende(ausgang)
    }

    /// „Leicht · 4:12“ (Tagesrätsel: Datum, Thema: Themenname statt Stufe)
    private func untertitel(_ r: WinResult) -> String {
        var teile: [String] = []
        if r.isDaily, let key = store.letztes?.spiel.dailyKey, let d = Day(key)?.date() {
            teile.append(d.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        } else if let t = r.themeID, let theme = store.library.themes.first(where: { $0.id == t }) {
            teile.append(theme.name)
        } else { teile.append(levelNameText(r.level)) }
        teile.append(Zeitformat.text(r.time))
        return teile.joined(separator: " · ")
    }

    /// Kein Rätsel startbar (Rätselpakete fehlen): Hinweis und zurück zur Startseite
    private var keinRaetsel: some View {
        VStack(spacing: Theme.kartenAbstand) {
            Text("Die Rätsel konnten nicht geladen werden.").font(.headline)
            Text("Bitte starte die App neu. Hilft das nicht, installiere sie noch einmal.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Zum Start", action: abbrechen).buttonStyle(ZweitKnopfStil())
        }
        .padding(Theme.seitenRand)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.papier)
    }
}
#endif
