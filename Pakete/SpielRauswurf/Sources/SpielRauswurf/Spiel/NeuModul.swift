// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Rauswurf : die eine Fassung des Spiels in der Sammlung. Spielbildschirm ohne Scrollen, Anbindung an den `SpielRahmen`
/// (Start, Spielerwahl, Würfelwahl, Ende), Regelwahl vor der Partie, Verlauf im Spiel, iPad mit Seitenspalte.
/// Der Kern (Regeln, Computer, Spielstand-Logik, Brett) ist im Spielkern.
@MainActor
public struct RauswurfModul: SpielModul {
    public init() {}
    public let id = NeuLogik.id
    public let name = "Rauswurf"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "figure.stand"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Würfeln, ziehen, rauswerfen", farbe: farbe, spieler: 2...4, computerErlaubt: true, wuerfelWahl: true,
                        regeln: "Jeder Spieler hat im Haus vier Figuren (einstellbar: zwei bis vier). Mit einer 6 kommt eine Figur auf dein Startfeld, dann darfst du nochmal würfeln. Du ziehst eine Figur um die gewürfelte Zahl auf der Laufbahn vorwärts. Landest du auf einer fremden Figur, wird sie rausgeworfen und muss zurück ins Haus. Wer zuerst alle Figuren ins Ziel gebracht hat, gewinnt. Vor der Partie wählst du eine Spielart und kannst einzelne Hausregeln ändern: Rauspflicht, Startfeld räumen, Schlagpflicht, drei Versuche, Teams und mehr.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                RauswurfNeuWurzel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
            }
            .mitStartOptionen { RauswurfOptionen(eintraege: $0) }
            .mitZiel("Bring als Erster alle deine Figuren ins Ziel.")
            .mitZielSchrittNeu(.ziel("Bring als Erster alle deine Figuren ins Ziel. Rauswurf kennst du vielleicht als „Mensch ärgere dich nicht“. Jede Figur läuft einmal ums Brett und dann in dein Ziel. Unterwegs kannst du andere rauswerfen, und du kannst selbst rausfliegen. Es spielen 2 bis 4 Personen, auch gegen den Computer."))
            .mitAnleitung(RegelTexteNeu.anleitung(neu: Self.anleitungNeu, alt: Self.anleitung))
        )
    }
}

/// Wurzel im Rahmen: baut Spielstand, Einstellungen und Controller, zeigt erst die Regelwahl und dann das Spiel.
struct RauswurfNeuWurzel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var store: GameStore
    @State private var prefs: AppPreferences
    @State private var spiel: SpielController
    @State private var gestartet: Bool
    @State private var gemeldet = false

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        // Eigene interne Datei (nicht der Spielstand des Spielkerns). Ein vom Rahmen gesicherter Stand wird hineingelegt (Fortsetzen).
        let repo = GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "rauswurf-neu-intern.json"))
        if let alt = SpielStand.laden(Spielstand.self, spiel: NeuLogik.id), alt.zustand.istPlausibel, !alt.zustand.partie.vorbei {
            try? repo.speichern(alt)
        } else {
            repo.loeschen()
        }
        let store = GameStore(repository: repo)
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "de.philippstach.partie.rauswurf-neu") ?? .standard)
        _store = State(initialValue: store)
        _prefs = State(initialValue: prefs)
        _spiel = State(initialValue: SpielController(store: store, prefs: prefs))
        _gestartet = State(initialValue: store.hatSpielstand)
    }

    var body: some View {
        Group {
            if gestartet && store.zustand != nil {
                NeuSpielView(abbrechen: abbrechen)
            } else {
                // B18: Spielart, Hausregeln und Stärke wurden schon im Neues-Spiel-Blatt gewählt; hier startet die Partie sofort.
                (Tisch.aktiv ? AnyView(TischGrund().ignoresSafeArea()) : AnyView(Color.seitenGrund)).onAppear { starten() }   // Design-Runde 3: kein Aufblitzen vor dem Filz
            }
        }
        .environment(store)
        .environment(prefs)
        .environment(spiel)
        .environment(\.brettTheme, BrettTheme.fuerDesign(.standard))
        .onChange(of: store.zustand) { _, z in
            guard let z, !z.partie.vorbei, !SpielStand.verworfen.contains(NeuLogik.id) else { return }
            SpielStand.sichern(Spielstand(zustand: z, dauerSekunden: store.dauerSekunden), spiel: NeuLogik.id)
        }
        // Sieger-Moment vorbei: der Rahmen zeigt das Ende
        .onChange(of: spiel.endeSichtbar) { _, sichtbar in
            guard sichtbar, !gemeldet, let z = store.zustand, z.phase == .vorbei else { return }
            gemeldet = true
            SpielStand.loeschen(NeuLogik.id)   // C-036: kein vorletzter Stand als Geisterpartie
            ende(NeuLogik.ende(z))
        }
        .onDisappear { spiel.anhalten() }
    }
}

extension RauswurfNeuWurzel {
    private func starten() {
        let echt = WuerfelWahl.quelle(NeuLogik.id, vorgabe: .app) == .echt
        let lieb = UserDefaults.standard.bool(forKey: RauswurfOptionen.liebSchluessel)
        let aktuell = RauswurfOptionen.einstellungen()   // frisch aus den Einstellungen: die Karte im Blatt hat sie dort abgelegt
        let spieler = NeuLogik.spieler(teilnehmer, computer: NeuLogik.strategie(stufe: ComputerStufe.gespeichert(NeuLogik.id), lieb: lieb), echteWuerfel: echt, buchstaben: Design.ist(.tinte))
        SpielerQuelle.menschen(teilnehmer.filter { !$0.computer }.map(\.name))
        store.neuePartie(spieler: spieler, optionen: aktuell.hausregeln)
        gestartet = true
    }
}

extension RauswurfModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "dice", titel: "Würfeln", text: "Tippe den Würfel oder den Knopf „Würfeln“. Mit einer 6 kommt eine Figur aus dem Haus und du würfelst nochmal.", geste: .tippen(.center)) { _, _ in Color.clear },
        AnleitungSchritt(symbol: "figure.walk", titel: "Ziehen und rauswerfen", text: "Tippe eine leuchtende Figur an. Landest du auf einer fremden Figur, muss sie zurück ins Haus.", geste: .tippen(.center)) { _, _ in Color.clear },
    ] }

    /// Figurenreihe als Bühne, mit Geste (die Gesten der alten Seiten bleiben).
    private static func figurenSeite(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey, figuren: [String], bewegt: Int? = nil, geste: AnleitungGeste = .keine) -> AnleitungSchritt {
        AnleitungSchritt(symbol: symbol, titel: titel, text: text, geste: geste) { fortschritt, aktiv in
            HStack(spacing: 18) {
                ForEach(Array(figuren.enumerated()), id: \.offset) { i, f in
                    Text(verbatim: f).font(.system(size: 44))   // design:spielinhalt (Figuren auf der Anleitungsbühne)
                        .scaleEffect(aktiv && bewegt == i ? 1 + 0.18 * sin(fortschritt * .pi) : 1)
                        .offset(x: bewegt == i ? 30 * anleitungAbschnitt(fortschritt, von: 0.2, bis: 0.7) : 0)
                }
            }
            .accessibilityHidden(true)
        }
    }

    /// Neue deutsche Fassung (Regeltexte neu, Build 25) ohne Zielseite (`mitZielSchrittNeu`).
    static var anleitungNeu: [AnleitungSchritt] { [
        figurenSeite(symbol: "dice", titel: "Würfeln", text: "Bist du dran, tippe auf den Würfel oder auf „Würfeln“. Du kannst das Gerät auch schütteln. Am Anfang stehen alle Figuren im Haus. Herauskommen kannst du nur mit einer 6. Hast du noch keine Figur draußen, darfst du bis zu dreimal würfeln. Nach jeder 6 würfelst du noch einmal.", figuren: ["🎲"], bewegt: 0, geste: .tippen(.center)),
        figurenSeite(symbol: "figure.walk", titel: "Ziehen", text: "Tippe eine leuchtende Figur an. Sie zieht genau so viele Felder vorwärts, wie der Würfel zeigt. Über andere Figuren darfst du springen, aber nicht auf einer eigenen landen. Hältst du eine Figur gedrückt, siehst du vorher, wo sie ankommt. Gibt es nur einen Zug, zieht die App von selbst.", figuren: ["🔴","▫️","▫️","▫️"], bewegt: 0, geste: .tippen(.center)),
        figurenSeite(symbol: "xmark.circle", titel: "Rauswerfen", text: "Landest du genau auf einer fremden Figur, fliegt sie raus und muss zurück in ihr Haus. Dann braucht sie wieder eine 6, um herauszukommen. Pass also auf deine eigenen Figuren auf: Steht eine fremde Figur 1 bis 6 Felder hinter dir, kann sie dich erwischen.", figuren: ["🔴","🟡","🏠"], bewegt: 0),
        figurenSeite(symbol: "flag.checkered", titel: "Ins Ziel", text: "Nach einer Runde ums Brett biegt deine Figur in dein Ziel ab. Es hat vier Felder. Du darfst nicht über das letzte Zielfeld hinausziehen. Wer zuerst alle Figuren im Ziel hat, gewinnt. Mit „Ganze Reihenfolge“ spielt ihr weiter, bis alle Plätze vergeben sind.", figuren: ["🔴","🔴","🔴","🔴","🏁"]),
        figurenSeite(symbol: "exclamationmark.circle", titel: "Pflichten", text: "Manchmal musst du einen bestimmten Zug machen. Mit einer 6 musst du eine Figur aus dem Haus holen. Steht eine Figur auf deinem Startfeld und warten noch andere im Haus, muss sie zuerst Platz machen. Die Hinweiszeile sagt dir dann genau, was zu tun ist.", figuren: ["6️⃣","🏠","➡️"]),
        figurenSeite(symbol: "slider.horizontal.3", titel: "Spielarten und Hilfen", text: "Vor dem Start wählst du eine Spielart: Familie, Offiziell, Kinder (niemand fliegt raus), Schnell oder Streng. Zu viert könnt ihr in Teams spielen. Jede Regel kannst du auch einzeln unter „Hausregeln“ ändern. „Tipp“ schlägt dir einen Zug vor, „Rückgängig“ nimmt ihn zurück. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["👨‍👩‍👧","⚡️","👥"]),
    ] }
}
