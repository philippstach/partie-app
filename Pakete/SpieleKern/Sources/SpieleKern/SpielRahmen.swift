// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import ArcadeKern

/// Teilnehmer einer neuen Partie.
public struct SpielTeilnehmer: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var computer: Bool
    public init(id: UUID = UUID(), name: String, computer: Bool = false) { self.id = id; self.name = name; self.computer = computer }
}

public extension SpielTeilnehmer {
    /// F21-013: Zwei-Spieler-Spiele mit genau einem Computer führen den Menschen als Spieler 1 und den Computer als Spieler 2
    /// (z. B. Viererreihe `Spielzustand.computerSpieler`). Steht der Computer in der Liste oben, wird getauscht; sonst bleibt alles.
    /// Nur in Spielen aufrufen, die den Computer fest auf Platz 2 erwarten (Mühle kann beide Plätze).
    static func menschZuerst(_ t: [SpielTeilnehmer]) -> [SpielTeilnehmer] {
        guard t.count == 2, t[0].computer, !t[1].computer else { return t }
        return [t[1], t[0]]
    }
}

/// Ausgang eines Arcade-Spiels. `sieg == nil`: Punktespiel (Aus, Punkte, Rekord – nie „gewonnen“); sonst Duell mit Sieg oder Niederlage.
public struct ArcadeAusgang {
    public var punkte: Int
    public var sieg: Bool?
    public var grund: String?
    /// Zusatzwerte für die Statistik (z. B. „stufe“, „rallye“).
    public var kennzahlen: [String: Double]
    public init(punkte: Int, sieg: Bool? = nil, grund: String? = nil, kennzahlen: [String: Double] = [:]) { self.punkte = punkte; self.sieg = sieg; self.grund = grund; self.kennzahlen = kennzahlen }
}

/// Ergebnis, das ein Spiel am Ende meldet: Namen vom Sieger zum Letzten, optional Punkte als Text und gleiche Plätze.
public struct SpielEnde {
    public var reihenfolge: [String]
    public var punkte: [String]
    public var plaetze: [Int]?
    public var info: String?
    public var arcade: ArcadeAusgang?
    /// Nur für Einzelspiele (ein Name, kein `arcade`): gewonnen (Standard, wie bisher), verloren oder Punktespiel ohne Sieg/Niederlage.
    /// Der Rahmen wählt danach die Überschrift („Geschafft!“, „Verloren“, „Partie beendet“/„Neuer Rekord!“) und die Buchung.
    public var einzel: EinzelAusgang
    /// Vom Rahmen gesetzt: Das Punktespiel (`einzel == .punkte`) hat den bisherigen Bestwert übertroffen.
    var neuerRekord = false
    /// C-027: Spiele, die ihre reine Spielzeit selbst messen (ohne Hintergrund und Pausen), melden sie hier; sonst zählt die Uhr des Rahmens.
    public var dauer: TimeInterval?
    /// Zusatzwerte für die Statistik, wenn kein `arcade` gemeldet wird: „stufe“ (0 = leichteste Stufe) für die Statistik je Stufe,
    /// „tages“ = 1 für ein Tagesrätsel (zählt dort eigens, nicht bei einer Stufe).
    public var kennzahlen: [String: Double] = [:]
    /// Optional für Einzelspiele: eigene Überschrift des Ende-Bildschirms (fertig übersetzt), z. B. „Tagesrätsel geschafft!“.
    public var titel: String?
    /// Optional: eigene Beschriftung des Hauptknopfs statt „Revanche“, z. B. „Nächstes Rätsel“. Der deutsche Text ist der Übersetzungsschlüssel.
    public var nochmalTitel: LocalizedStringKey?
    /// 1.0 (M4): Würfelbilanz der Partie; der Ende-Bildschirm zeigt dann „So fielen die Würfel“ (statt des Motivs).
    public var wuerfel: WuerfelBilanz?
    /// Blatt 22 (EB-K): zwei bis drei Wertzeilen der Ergebnisseite unter der Rangliste (höchstens drei werden gezeigt).
    /// `EndeWert.dauer` setzt die Dauer der Partie ein. Nur Anzeige: Statistik und Teilen bleiben bei `punkte`, `info`, `dauer`.
    public var werte: [EndeWert] = []
    /// Blatt 22 (EB-K): Bild vom Ende auf dem Filz des Spiels. Meldet ein Spiel Werte, ein Bild oder Würfel, steht auf der
    /// Ergebnisseite der Standardinhalt (`EndeStandardInhalt`) statt des Spielbilds mit dem Farbpunkt.
    public var bild: EndeBild?
    public init(reihenfolge: [String], punkte: [String] = [], plaetze: [Int]? = nil, info: String? = nil, arcade: ArcadeAusgang? = nil, einzel: EinzelAusgang = .gewonnen) {
        self.reihenfolge = reihenfolge; self.punkte = punkte; self.plaetze = plaetze; self.info = info; self.arcade = arcade; self.einzel = einzel
    }
    /// Einzelspiel verloren: `ende(.verloren(name))`. Kein Sieg in der Statistik, Überschrift „Verloren“.
    public static func verloren(_ name: String, punkte: String? = nil, info: String? = nil) -> SpielEnde {
        SpielEnde(reihenfolge: [name], punkte: punkte.map { [$0] } ?? [], info: info, einzel: .verloren)
    }
    /// Einzelspiel als Punktespiel ohne Sieg oder Niederlage: `ende(.punktespiel(name, punkte: "42"))`.
    public static func punktespiel(_ name: String, punkte: String, info: String? = nil) -> SpielEnde {
        SpielEnde(reihenfolge: [name], punkte: [punkte], info: info, einzel: .punkte)
    }
    /// Remis: mindestens zwei Teilnehmer, alle auf Platz 1 (dieselbe Regel wie in der Statistik, `PartieErgebnis.istRemis`).
    /// Zu kurze `plaetze` werden wie in der Statistik aufgefüllt (`EndeBuchung.platz`), damit Anzeige und Buchung übereinstimmen.
    public var istRemis: Bool { reihenfolge.count > 1 && Remis.gilt(plaetze: plaetze.map { EndeBuchung.plaetze($0, anzahl: reihenfolge.count) }) }
}

/// Was spieleigene Karten auf der Startseite auslösen können (`SpielRahmen.mitStartInhalt`).
@MainActor
public struct SpielStartAktionen {
    /// Startet sofort eine neue Partie, ohne das Neues-Spiel-Blatt. Das Spiel merkt sich vorher selbst, was gespielt werden soll
    /// (Stufe, Tagesrätsel …). Gibt es einen gespeicherten Stand, fragt der Rahmen erst, ob er verworfen werden soll.
    public let neu: () -> Void
    /// Setzt die gespeicherte Partie fort (ohne Stand passiert nichts).
    public let fortsetzen: () -> Void
    /// Ob eine gespeicherte Partie zum Fortsetzen vorliegt.
    public let standVorhanden: Bool
    /// Design-Runde 3 (Tinte, R2): Eine Karte der Spielseite merkt vor, was der eine Hauptknopf „Spielen“ unmittelbar vor dem Start
    /// ausführen soll (z. B. das Tagesrätsel wählen). `nil` nimmt die Vormerkung zurück. In den anderen Designs ohne Wirkung.
    public let vormerken: ((() -> Void)?) -> Void
}

/// Hält die Vormerkung einer Startkarte für den Hauptknopf „Spielen“ (Referenz: Setzen zeichnet die Seite nicht neu).
final class StartVormerkung {
    var aktion: (() -> Void)?
}

/// Gemeinsamer Rahmen für neue Spiele der Sammlung: Start, Neues-Spiel-Blatt mit Spielerverzeichnis, Spiel, Ende, Statistik.
/// Das Spiel liefert nur seine Spielansicht (`spiel`) und meldet das Ende. Regeln als Text.
public struct SpielRahmen<Spiel: View>: View {
    let id: String
    let name: String
    let untertitel: LocalizedStringKey
    let farbe: AkzentFarbeWert
    let spieler: ClosedRange<Int>
    let computerErlaubt: Bool
    let wuerfelWahl: Bool
    var wuerfelTexte: WuerfelTexte = .wuerfel
    let regeln: LocalizedStringKey
    var einzelText: LocalizedStringKey = "Ein Spieler: Du gegen das Rätsel."
    let umgebung: SpielUmgebung
    /// Arcade: Startseite zeigt Rekord statt Siege, Ende zeigt Punkte und Rekord.
    var zeigtRekord = false
    /// Optional: Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); die Regelseite bleibt als „Alle Regeln lesen“ erhalten.
    var anleitung: [AnleitungSchritt] = []
    /// Optional: Ziel des Spiels in einem Satz; erste Seite der Anleitung bzw. Karte über dem Regeltext.
    var ziel: LocalizedStringKey?
    /// Eigene erste Seite der Anleitung (statt der Standardseite „Ziel“ mit Fahne); der Text des Ziels bleibt für die Zielkarte der Spielseite.
    var zielSchritt: AnleitungSchritt?
    /// Optional: Karten mit Spielart, Stufe, Hausregeln im Neues-Spiel-Blatt. So gibt es nur EINEN Startschritt (B18: keine zweite Seite nach „Los geht's“).
    var startOptionen: (([SpielerEintrag]) -> AnyView)?
    /// Beschriftung des Hauptknopfs im Neues-Spiel-Blatt (Standard „Los geht's“; „Weiter“, wenn das Spiel danach noch eine Wahl zeigt).
    var startTitel: LocalizedStringKey?
    /// Optional: spieleigene Karten auf der Startseite (Tagesrätsel, Stufen mit Fortschritt, Themen …), unter dem Bild und über der
    /// Statistik. Ohne Angabe gibt es den Platz nicht.
    var startInhalt: ((SpielStartAktionen) -> AnyView)?
    /// Optional: spieleigener Inhalt im Ende-Bildschirm (an der Stelle des Motivs), z. B. Lösungswort oder neue Erfolge.
    /// Der zweite Wert startet die nächste Partie (wie der Hauptknopf).
    var endeInhalt: ((SpielEnde, @escaping () -> Void) -> AnyView)?
    /// Optional: eigene ausführliche Regelseite (mit Beispielbildern) hinter „Alle Regeln lesen“ statt des reinen Regeltexts.
    var regelnAnsicht: (() -> AnyView)?
    /// Optional (KI-3): eigene Quelle des Regelwissens für „Frag nach den Regeln“ (mit den eingestellten Hausregeln). Ohne sie gilt `RegelWissenKatalog`.
    var regelWissenQuelle: (() -> any RegelWissen)?
    let spiel: ([SpielTeilnehmer], @escaping (SpielEnde) -> Void, @escaping () -> Void) -> Spiel

    @State private var phase: Phase = .start
    @State private var teilnehmer: [SpielTeilnehmer] = []
    @State private var neuesSpiel = false
    @State private var regelnOffen = false
    /// KI-3: Chat-Blatt „Frag nach den Regeln“ (aus dem Menü am Tisch) und ob es den Einstieg überhaupt gibt (sonst nichts sichtbar).
    @State private var regelChatOffen = false
    @State private var regelChatStatus: RegelChatStatus = .hidden
    @State private var eintraege: [SpielerEintrag] = []
    @State private var spielNummer = 0
    /// F2: nimmt eine Ende-Meldung nur von der laufenden, aktuellen Partie an (Referenz, damit die Prüfung sofort gilt).
    @State private var wache = PartieWache()
    @State private var rueckfrage = false
    /// Direktstart von der Startseite, obwohl ein Stand gespeichert ist: erst fragen
    @State private var verwerfenFrage = false
    /// G-012/G-019: Die Abfrage „Laufende Partie verwerfen?“ kam aus dem „…“-Menü des laufenden Spiels (`NeuePartieMenuePunkt`).
    @State private var neuImSpiel = false
    @State private var niederlageHinweis = false
    @State private var startzeit = Date()
    /// Reine Spielzeit (ohne Hintergrund und Pause) und ob ein Stand fortgesetzt wurde: für „Partie abbrechen“ (`AbbruchWertung`).
    @State private var uhr = Spieluhr()
    @State private var fortgesetzt = false
    /// Beim Öffnen der Abfrage „Spiel wirklich beenden?“ festgelegt: die Niederlage, die „Beenden“ buchen würde (nil = zählt nicht).
    /// Vorwarnung in der Abfrage und Buchung nutzen dieselbe Entscheidung, sie können nicht auseinanderlaufen.
    @State private var abbruchVorgemerkt: PartieErgebnis?
    @Environment(\.scenePhase) private var szene
    /// A-002/A-004/A-008: Schriftgröße der Bedienungshilfen: Startseite ohne feste Knopfleiste, Knöpfe am Ende des Inhalts.
    @Environment(\.dynamicTypeSize) private var schrift
    @Environment(\.horizontalSizeClass) private var breiteKlasse
    @State private var letzte: LetzteRunde?
    /// Design-Runde 3: was „Spielen“ in Tinte vor dem Start ausführt (z. B. Tagesrätsel wählen), gesetzt von einer Startkarte.
    @State private var vormerkung = StartVormerkung()
    @AppStorage(TischModus.schluessel) private var tischModus = false
    /// K-031/G-015: Neu eingetippte Namen kommen erst ins Verzeichnis, wenn das Neues-Spiel-Blatt ganz geschlossen ist (`onDismiss`).
    /// Vorher änderte das Anlegen das beobachtete Verzeichnis und schrieb in UserDefaults, während das Blatt noch zuging und
    /// das Spiel aufgebaut wurde; dabei blieb das Blatt sporadisch stehen bzw. der Start hing.
    @State private var anmeldenNachBlatt: [String] = []

    /// Setzt die Anleitung zum Durchwischen: `SpielRahmen(…) { … }.mitAnleitung([…])`.
    public func mitAnleitung(_ schritte: [AnleitungSchritt]) -> Self { var k = self; k.anleitung = schritte; return k }
    /// Setzt das Ziel des Spiels: `SpielRahmen(…) { … }.mitZiel("Sei als Erster fertig.")`. Der deutsche Text ist der Übersetzungsschlüssel.
    public func mitZiel(_ text: LocalizedStringKey) -> Self { var k = self; k.ziel = text; return k }
    /// Ersetzt die erste Seite der Anleitung („Ziel“ mit Fahne) durch eine eigene Seite mit eigener Bühne. Die Zielkarte der Spielseite bleibt (`mitZiel`).
    public func mitZielSchritt(_ schritt: AnleitungSchritt) -> Self { var k = self; k.zielSchritt = schritt; return k }

    /// Setzt Karten für das Neues-Spiel-Blatt: `.mitStartOptionen { StufenKarte() }`. Zustand über `@AppStorage`/Einstellungen des Spiels teilen.
    /// Der Block bekommt die gewählten Spieler (z. B. für Teams oder „mit Computer“).
    public func mitStartOptionen<V: View>(@ViewBuilder _ inhalt: @escaping ([SpielerEintrag]) -> V) -> Self { var k = self; k.startOptionen = { AnyView(inhalt($0)) }; return k }
    public func mitStartTitel(_ titel: LocalizedStringKey) -> Self { var k = self; k.startTitel = titel; return k }
    /// Setzt spieleigene Karten auf die Startseite: `.mitStartInhalt { aktionen in TagesKarte { aktionen.neu() } }`.
    /// Ein Tipp auf eine Karte kann die Partie direkt starten (`aktionen.neu()`); das Spiel merkt sich vorher selbst, was gespielt wird.
    /// Einzelspiele ohne Start-Optionen starten dann auch über „Neues Spiel“ direkt, ohne Blatt.
    public func mitStartInhalt<V: View>(@ViewBuilder _ inhalt: @escaping (SpielStartAktionen) -> V) -> Self { var k = self; k.startInhalt = { AnyView(inhalt($0)) }; return k }
    /// Setzt spieleigenen Inhalt in den Ende-Bildschirm (statt des Motivs): `.mitEndeInhalt { ende in Loesungswort() }`.
    /// `nochmal` startet die nächste Partie wie der Hauptknopf (z. B. für „Andere Stufe probieren“).
    public func mitEndeInhalt<V: View>(@ViewBuilder _ inhalt: @escaping (_ ende: SpielEnde, _ nochmal: @escaping () -> Void) -> V) -> Self { var k = self; k.endeInhalt = { AnyView(inhalt($0, $1)) }; return k }
    /// Setzt eine eigene ausführliche Regelseite (Abschnitte, Beispielbilder) hinter „Alle Regeln lesen“; sie bringt Titel und Schließen selbst mit.
    /// Braucht eine Anleitung (`mitAnleitung`); der Regeltext `regeln` bleibt die Kurzfassung.
    public func mitRegelnAnsicht<V: View>(@ViewBuilder _ inhalt: @escaping () -> V) -> Self { var k = self; k.regelnAnsicht = { AnyView(inhalt()) }; return k }

    /// Setzt das Regelwissen dieses Spiels für „Frag nach den Regeln“ (KI-3), zum Beispiel mit den eingestellten Hausregeln in `aktiveRegeln`.
    /// Ohne diesen Aufruf nimmt der Rahmen das Wissen aus `RegelWissenKatalog` (Grund-ID des Spiels).
    public func mitRegelWissen(_ quelle: @escaping () -> any RegelWissen) -> Self { var k = self; k.regelWissenQuelle = quelle; return k }

    /// Aktion für die Menüzeile „Frag nach den Regeln“; `nil`, wenn es den Chat hier nicht gibt (dann keine Zeile).
    private var regelFrageAktion: (() -> Void)? {
        regelChatStatus.zeigtEinstieg ? { regelChatOffen = true } : nil
    }

    enum Phase { case start, laeuft, ende(SpielEnde) }

    public init(id: String, name: String, untertitel: LocalizedStringKey, farbe: AkzentFarbeWert, spieler: ClosedRange<Int>,
                computerErlaubt: Bool = false, wuerfelWahl: Bool = false, wuerfelTexte: WuerfelTexte = .wuerfel, regeln: LocalizedStringKey, einzelText: LocalizedStringKey = "Ein Spieler: Du gegen das Rätsel.", zeigtRekord: Bool = false, umgebung: SpielUmgebung,
                @ViewBuilder spiel: @escaping ([SpielTeilnehmer], @escaping (SpielEnde) -> Void, @escaping () -> Void) -> Spiel) {
        self.id = id; self.name = name; self.untertitel = untertitel; self.farbe = farbe; self.spieler = spieler
        self.computerErlaubt = computerErlaubt; self.wuerfelWahl = wuerfelWahl; self.wuerfelTexte = wuerfelTexte; self.regeln = regeln; self.einzelText = einzelText; self.zeigtRekord = zeigtRekord; self.umgebung = umgebung; self.spiel = spiel
        _eintraege = State(initialValue: Self.vorgabe(spieler, umgebung, id: id))
        _letzte = State(initialValue: LetzteRunde.laden(id))
    }

    public var body: some View {
        Group {
            switch phase {
            case .start: start
            case .laeuft:
                let partie = wache.nummer   // das `ende` dieser Partie trägt ihre Nummer; spätere Partien weisen es ab
                tischRahmen {
                    spiel(teilnehmer, { ende in beenden(ende, partie: partie) }, { rueckfrageOeffnen() }).id(spielNummer)
                        .environment(\.regelnOeffnen, { regelnOffen = true })
                        .environment(\.tischFarbe, SpielRahmenHaken.bild?(id)?.farbe)   // Design-Runde 3: Filz in der Spielart-Farbe
                        .environment(\.regelnKnopf, true)   // Buch-Knopf im SpielKopf: Regeln jederzeit im laufenden Spiel
                        .environment(\.neuePartie, { neuImSpiel = true; verwerfenFrage = true })   // G-012/G-019: `NeuePartieMenuePunkt`
                        .environment(\.regelFrage, regelFrageAktion)   // KI-3: `FragNachDenRegelnMenuePunkt`
                }
            case .ende(let e): endeAnsicht(e)
            }
        }
        // Design-Runde 3 (R6): Zurück-Wischen vom linken Rand, zentral für alle Spiele im Rahmen (nur Tinte). Auf der Spielseite geht es
        // zurück zur Sammlung, im laufenden Spiel kommt dieselbe Rückfrage wie beim Zurück-Knopf. Die Geste läuft neben den Gesten des Spiels.
        .simultaneousGesture(
            DragGesture(minimumDistance: 30).onEnded { wert in
                guard Design.ist(.tinte), wert.startLocation.x < 28, wert.translation.width > 90, abs(wert.translation.height) < 70 else { return }
                guard !rueckfrage, !verwerfenFrage, !neuesSpiel, !regelnOffen else { return }
                switch phase {
                case .start: umgebung.zurueck()
                case .laeuft: rueckfrageOeffnen()
                case .ende: break
                }
            }
        )
        .sheet(isPresented: $neuesSpiel, onDismiss: namenAnmelden) { blatt }
        .overlay(alignment: .top) {
            if niederlageHinweis {
                Text("Partie beendet – zählt als Niederlage").font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 12).toast()
                    .padding(.top, 8).padding(.horizontal, Theme.seitenRand)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityHidden(true)   // wird als Ansage vorgelesen
            }
        }
        // Zentrale Rückfrage für alle Spiele: Zurück-Knopf und „Spiel beenden“ rufen `abbrechen`.
        // DP1: Die Abfrage hängt an einem eigenen Hintergrund mit neutraler Tönung, damit „Abbrechen“ und „Pausieren“
        // nicht in der (bei manchen Spielen roten) App-Farbe erscheinen und nur „Beenden“ rot bleibt.
        .background {
            Color.clear.tint(.primary)
                .alert("Spiel wirklich beenden?", isPresented: $rueckfrage) {
                    if SpielStand.vorhanden(id) { Button("Pausieren") { pausieren() } }
                    Button("Beenden", role: .destructive) { abbrechen() }
                    Button("Abbrechen", role: .cancel) {}
                } message: {
                    let grund = SpielStand.vorhanden(id) ? String(localized: "Pausieren speichert die Partie, Beenden verwirft sie.") : String(localized: "Die laufende Partie geht verloren.")
                    // Vorwarnung nur, wenn „Beenden“ jetzt wirklich eine Niederlage bucht (Einstellung „Partie abbrechen“)
                    Text(verbatim: abbruchVorgemerkt == nil ? grund : grund + " " + String(localized: "Das zählt als Niederlage."))
                }
                .tint(.primary)   // B12-S2-031: auch der Dialog selbst neutral getönt (Knöpfe nicht lila auf dunkelgrau)
        }
        .background {
            Color.clear.tint(.primary)
                .alert("Laufende Partie verwerfen?", isPresented: $verwerfenFrage) {
                    Button("Neu starten", role: .destructive) { if neuImSpiel { neuImSpiel = false; neuePartieImSpiel() } else { if case .start = phase, Design.ist(.tinte) { vormerkung.aktion?() }; loslegen() } }
                    Button("Abbrechen", role: .cancel) { neuImSpiel = false }
                } message: { Text("Die laufende Partie geht verloren.") }
                .tint(.primary)
        }
        .sheet(isPresented: $regelnOffen) { regelnBlatt }
        .sheet(isPresented: $regelChatOffen) {
            if let w = regelWissenQuelle?() ?? RegelWissenKatalog.wissen(fuer: id) { RegelChatBlatt(wissen: w) }
        }
        .onAppear { regelChatStatus = RegelChatEinstieg.status(spielID: id, wissen: regelWissenQuelle?()) }
        .onChange(of: szene) { _, neu in if neu == .active { regelChatStatus = RegelChatEinstieg.status(spielID: id, wissen: regelWissenQuelle?()) } }
        // T-022: `.tint` erreicht die Systemabfrage nicht immer (B6: „Abbrechen“ und „Beenden“ beide in der roten App-Farbe).
        // Abfragen bekommen deshalb die neutrale Schriftfarbe; rot bleibt nur der Knopf mit `role: .destructive`.
        .onAppear { UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .label }
        .onChange(of: szene) { _, neu in if neu == .active { if case .laeuft = phase { uhr.weiter() } } else { uhr.anhalten() } }
        // TestFlight 13.11., Nr. 6: „Weiterspielen“ von der Startseite öffnet gleich die laufende Partie (auch Stapel und „Zuletzt“).
        .onAppear {
            guard OffenesSpiel.direktEinloesen(id) else { return }
            if case .start = phase, SpielStand.vorhanden(id), let l = letzte { fortsetzen(l) }
        }
        // KI-8: „Neue Partie“ per Siri oder Kurzbefehl (Spieler- und Computerzahl), siehe `StartWunsch`.
        .onAppear {
            guard let w = StartWunschPost.einloesen(id), case .start = phase else { return }
            wunschStarten(w)
        }
        .onDisappear { LaufendePartie.beenden(); namenAnmelden() }   // Spiel verlassen (Sammlung, Tab-Wechsel): Aktivität beenden, vorgemerkte Namen nicht verlieren
    }

    /// E8: Namensschilder rundherum, wenn der Tisch-Modus an ist (iPad, 2 bis 4 Menschen).
    @ViewBuilder private func tischRahmen<V: View>(@ViewBuilder _ inhalt: @escaping () -> V) -> some View {
        let menschen = teilnehmer.filter { !$0.computer }
        if tischModus, TischModus.passt(menschen: menschen.count, istIPad: TischModus.istIPad) {
            TischRahmen(namen: menschen.map(\.name), farbe: { i in
                let p = umgebung.spieler.menschen.first { $0.name.caseInsensitiveCompare(menschen[i].name) == .orderedSame }
                return Spieler.farbe(p?.farbeIndex ?? i)
            }, inhalt: inhalt)
        } else {
            inhalt()
        }
    }

    // MARK: Start

    /// Designwechsel: „Klar & Glas“ zeigt die Startseite wie bisher (`startKlar`); Tinte und Salon bauen sie aus dem
    /// Baustein `SpielStartSeite` (Baukasten). Inhalte und Knopf-Aktionen sind dieselben.
    @ViewBuilder private var start: some View {
        if Design.ist(.klar) { startKlar } else if Design.ist(.tinte) { startTinte } else { startNeu }
    }

    /// Statistik-Werte der Startseite (wie in `startKlar`): Punktespiele zeigen Bestwert und Durchschnitt statt Siege und Serie.
    private var startWerte: [StatistikZeile.Wert] {
        let b = umgebung.statistik.bilanz(spiel: id, ich: umgebung.spieler.ich?.id)
        if zeigtRekord {
            return [.init(zahl: "\(b.partien)", name: "Partien"),
                    .init(zahl: umgebung.statistik.rekord(spiel: id, stufe: ComputerStufe.gespeichert(id).rawValue).map(String.init) ?? "–", name: "Bestwert"),
                    .init(zahl: umgebung.statistik.durchschnitt(spiel: id, stufe: ComputerStufe.gespeichert(id).rawValue).map(String.init) ?? "–", name: "Durchschnitt")]
        }
        return [.init(zahl: "\(b.partien)", name: "Partien"), .init(zahl: "\(b.siege)", name: "Siege"), .init(zahl: "\(b.serie)", name: "Serie"),
                umgebung.statistik.besteRallye(spiel: id).map { .init(zahl: "\($0)", name: "Rallye") } ?? .init(zahl: b.rekord.map(String.init) ?? "–", name: "Bestwert")]
    }

    /// Startseite in Tinte und Salon: Aufbau im Baustein, hier nur Inhalte, Tisch-Modus, Würfelwahl und die drei Knöpfe.
    private var startNeu: some View {
        let bild = SpielRahmenHaken.bild?(id)
        return SpielStartSeite(name: Text(LocalizedStringKey(name)), untertitel: Text(untertitel),
                               spielart: bild?.spielart.map { Text(verbatim: $0) }, farbe: bild?.farbe, miniatur: bild?.miniatur,
                               statistikTitel: Text("Statistik"), werte: startWerte, zurueckTitel: Text("Sammlung"),
                               zurueck: { umgebung.zurueck() }, regeln: { regelnOffen = true }) {
            if spieler.upperBound >= 2, TischModus.istIPad {
                Toggle(isOn: $tischModus) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tisch-Modus").font(.headline)
                        Text("iPad flach auf den Tisch legen: Jede Person bekommt am Rand ein Namensschild zu sich hin.").font(.footnote).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)   // N-003: ein Name für den Schalter (Kästchen in Tinte/Salon war ohne Namen)
                }
                .card()
            }
            if wuerfelWahl { WuerfelWahlKarte(spiel: id, vorgabe: umgebung.wuerfelQuelle, texte: wuerfelTexte) }
            if let startInhalt { startInhalt(startAktionen) }
        } knoepfe: {
            Group {
                if SpielStand.vorhanden(id), let l = letzte {
                    Button { fortsetzen(l) } label: { Text("Partie fortsetzen").frame(maxWidth: .infinity) }
                        .buttonStyle(HauptKnopfStil())
                }
                if spieler.upperBound > 1, let l = letzte, l.plaetze.count >= spieler.lowerBound, l.plaetze.count <= spieler.upperBound {
                    Button { letzteRundeStarten(l) } label: {
                        Text(String(localized: "Letzte Runde wieder: \(l.kurz)")).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ZweitKnopfStil())
                }
                Button("Neues Spiel") { neuesSpielTippen() }
                    .buttonStyle(HauptKnopfStil())
            }
            // A-002: Die Knopfleiste bleibt bei größter Schrift niedrig, damit der Inhalt darüber (Würfelwahl) frei bleibt
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        // K-038: Namen aus einem Wort („Galgenmännchen“) bleiben im Salon einzeilig und werden verkleinert statt mitten im Wort zu brechen
        .nameEinzeilig(!String(localized: String.LocalizationValue(name)).contains(" "))
    }

    // MARK: Start in Tinte (Design-Runde 3)

    /// Spielseite in Tinte nach dem Entwurf „Spieltisch“: Filzkopf in der Spielart-Farbe mit Miniatur und Namen, das Ziel als Satz,
    /// „Regeln ansehen“, darunter die Inhalte wie bisher. Unten genau EIN Hauptknopf „Spielen“ (R2), „Letzte Runde wieder“ ist eine Zeile.
    /// Aktionen und Inhalte sind dieselben wie in `startNeu`.
    /// Große Tinte-Runde, Punkt 1: Läuft eine Partie, heißt der eine Knopf „Weiterspielen“. „Neue Partie beginnen“ steht klein darüber,
    /// nur dort kommt die Rückfrage „Laufende Partie verwerfen?“. Die Zeile „Laufende Partie“ zeigt, wer spielt.
    /// Punkt 2: Bei großer Schrift steht das Bild über dem Titel, und die Seite wächst gleichmäßig bis `accessibility2`
    /// (wie vorher das Neues-Spiel-Blatt), statt dass einzelne Zeilen auf das Doppelte gehen und andere gar nicht wachsen.
    private var startTinte: some View {
        let bild = SpielRahmenHaken.bild?(id)
        let laufend: LetzteRunde? = SpielStand.vorhanden(id) ? letzte : nil
        // Runde 5, Blatt 1 (K1): Nur auf breiten Seiten (iPad, mindestens 700 pt, normale Schrift) gilt der breite Aufbau.
        // Unter 700 pt (Split View), bei großer Schrift und auf dem iPhone bleibt alles wie vorher.
        return GeometryReader { geo in
            let breit = Design.ist(.tinte) && breiteKlasse == .regular && !schrift.isAccessibilitySize && geo.size.width >= 700
            ScrollView {
                if breit {
                    startTinteBreit(bild, laufend, oben: geo.safeAreaInsets.top)
                } else {
                    VStack(alignment: .leading, spacing: Design.Abstand.l) {
                        startTinteKopf(bild)
                        startTinteZiel
                        if let laufend { startTinteLaufend(laufend) }
                        startTinteTisch
                        if wuerfelWahl { WuerfelWahlKarte(spiel: id, vorgabe: umgebung.wuerfelQuelle, texte: wuerfelTexte) }
                        if let startInhalt { startInhalt(startAktionen) }
                        // R1: Wer spielt und die Regeln der Partie stehen auf der Seite selbst; in Tinte öffnet „Spielen“ kein Blatt mehr.
                        if spieler.upperBound > 1 { NeuesSpielKarte("Wer spielt?") { spielerWahl } }
                        if let startOptionen { startOptionen(eintraege) }
                        startTinteLetzteRunde
                        StatistikZeile(titel: "Statistik", werte: startWerte) {}
                            .accessibilityElement(children: .combine)
                    }
                    .padding(.horizontal, Theme.seitenRand).padding(.top, 4).padding(.bottom, Design.Abstand.l)
                    .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // KI-004: Schmale Seite (iPhone): gescrollter Text lief unter die Uhr in der Statusleiste. Ein Streifen in der Farbe
            // des Seitengrunds deckt den Bereich der Statusleiste ab; der Filzkopf liegt hier innerhalb der Safe Area und bleibt sichtbar.
            .overlay(alignment: .top) {
                if !breit { Color.clear.frame(height: 0).background(Color.seitenGrund, ignoresSafeAreaEdges: .top) }
            }
            // K1 (iPad-Nachbesserung): Auf breiten Seiten läuft die Scroll-Fläche selbst bis an den oberen Rand,
            // sonst bleibt über dem Filzkopf ein heller Streifen unter der Statusleiste.
            .ignoresSafeArea(edges: breit ? .top : [])
            .background(Color.seitenGrund.ignoresSafeArea())
            .onAppear { if eintraege.isEmpty { vorbereiten() } }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 2) {
                    if let laufend {
                        // Punkt 1: der kleine zweite Weg. Er fragt nach, bevor die laufende Partie verloren geht (`spielenTinte`).
                        Button { spielenTinte() } label: {
                            Text("Neue Partie beginnen").font(.subheadline.weight(.semibold)).foregroundStyle(Color.schrift)
                                .lineLimit(1).minimumScaleFactor(0.7).unterstrichen(1)
                                .frame(maxWidth: .infinity, minHeight: Theme.tapSize).contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(spieler.upperBound > 1 && eintraege.count < spieler.lowerBound)
                        Button { fortsetzen(laufend) } label: { Text("Weiterspielen").frame(maxWidth: .infinity) }
                            .buttonStyle(HauptKnopfStil())
                    } else {
                        Button { spielenTinte() } label: { Text("Spielen").frame(maxWidth: .infinity) }
                            .buttonStyle(HauptKnopfStil())
                            .disabled(spieler.upperBound > 1 && eintraege.count < spieler.lowerBound)
                    }
                }
                // Punkt 2: Der Knopf wächst ein Stück mit (vorher bei xxxLarge fest), bleibt aber niedrig genug, dass der Inhalt frei bleibt.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .padding(.horizontal, Theme.seitenRand).padding(.top, laufend == nil ? 10 : 2).padding(.bottom, 8)
                // K1: auf breiten Seiten höchstens 440 pt, in der Mitte
                .frame(maxWidth: breit ? 440 + 2 * Theme.seitenRand : Theme.wideColumnWidth).frame(maxWidth: .infinity)
                .background(Color.seitenGrund.ignoresSafeArea(edges: .bottom))
            }
        }
        // Punkt 2: eine Obergrenze für die ganze Seite, damit alle Texte gleich stark wachsen
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Ziel-Satz und „Regeln ansehen“ (schmal und breit gleich).
    private var startTinteZiel: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text(ziel ?? untertitel)
                .font(Design.Schrift.serif(20, relativ: .title3)).foregroundStyle(Color.schrift)
                .fixedSize(horizontal: false, vertical: true)
            Button { regelnOffen = true } label: {
                Label("Regeln ansehen", systemImage: "book").font(.subheadline.weight(.semibold)).foregroundStyle(Color.schrift)
                    .frame(minHeight: Theme.tapSize).contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    /// Tisch-Modus-Schalter (nur iPad, Spiele für mehrere).
    @ViewBuilder private var startTinteTisch: some View {
        if spieler.upperBound >= 2, TischModus.istIPad {
            Toggle(isOn: $tischModus) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tisch-Modus").font(.headline)
                    Text("iPad flach auf den Tisch legen: Jede Person bekommt am Rand ein Namensschild zu sich hin.").font(.footnote).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .card()
        }
    }

    /// „Letzte Runde wieder“ nur, wenn oben nicht ohnehin dieselben Namen stehen (keine Doppelung).
    @ViewBuilder private var startTinteLetzteRunde: some View {
        if spieler.upperBound > 1, let l = letzte, l.plaetze.count >= spieler.lowerBound, l.plaetze.count <= spieler.upperBound,
           l.plaetze.map(\.name) != eintraege.map(\.name) {
            Button { letzteRundeStarten(l) } label: {
                HStack(spacing: Design.Abstand.m) {
                    Image(systemName: "arrow.counterclockwise").font(.body.weight(.semibold)).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Letzte Runde wieder").font(.subheadline.weight(.semibold))
                        Text(verbatim: l.kurz).font(.footnote).foregroundStyle(Color.schriftZweit).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.schriftBlass).accessibilityHidden(true)
                }
                .foregroundStyle(Color.schrift)
                .padding(.horizontal, Design.Abstand.l).frame(minHeight: 60)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.kartenGrund))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.linie, lineWidth: 1))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        }
    }

    /// Runde 5, Blatt 1 (K1): Spielseite auf dem iPad. Filzkopf bis an die Ränder, darunter zwei Spalten
    /// (links Ziel, Regeln, laufende Partie, Statistik; rechts Spieler und Einstellungen). Ist die rechte Spalte leer, bleibt es bei einer Spalte.
    @ViewBuilder private func startTinteBreit(_ bild: SpielRahmenHaken.Bild?, _ laufend: LetzteRunde?, oben: CGFloat) -> some View {
        let rand: CGFloat = 44
        let rechtsLeer = spieler.upperBound <= 1 && startInhalt == nil && startOptionen == nil && !wuerfelWahl
        VStack(alignment: .leading, spacing: 0) {
            startTinteKopfBreit(bild, rand: rand, oben: oben)
            Group {
                if rechtsLeer {
                    startTinteSpalteLinks(laufend)
                        .frame(maxWidth: 640, alignment: .leading).frame(maxWidth: .infinity)
                } else {
                    HStack(alignment: .top, spacing: 48) {
                        startTinteSpalteLinks(laufend).frame(maxWidth: .infinity, alignment: .topLeading)
                        VStack(alignment: .leading, spacing: Design.Abstand.l) {
                            if spieler.upperBound > 1 { NeuesSpielKarte("Wer spielt?") { spielerWahl } }
                            startTinteLetzteRunde
                            startTinteTisch
                            if wuerfelWahl { WuerfelWahlKarte(spiel: id, vorgabe: umgebung.wuerfelQuelle, texte: wuerfelTexte) }
                            if let startInhalt { startInhalt(startAktionen) }
                            if let startOptionen { startOptionen(eintraege) }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
            .padding(.horizontal, rand).padding(.top, Design.Abstand.l).padding(.bottom, Design.Abstand.l)
        }
    }

    private func startTinteSpalteLinks(_ laufend: LetzteRunde?) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.l) {
            startTinteZiel
            if let laufend { startTinteLaufend(laufend) }
            StatistikZeile(titel: "Statistik", werte: startWerte) {}
                .accessibilityElement(children: .combine)
        }
    }

    /// Filzkopf auf dem iPad: ohne runde Ecken, bis unter die Statusleiste, etwa 300 pt hoch. Spielart und Titel unten links
    /// am Seitenrand, die Miniatur rechts, Zurück als runder Knopf oben links.
    private func startTinteKopfBreit(_ bild: SpielRahmenHaken.Bild?, rand: CGFloat, oben: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            ZStack {
                TischGrund(bild?.farbe)
                LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
            }
            .ignoresSafeArea(edges: .top)
            // AUS-008 / T-059: Der Filzkopf liegt auf dem iPad unter der Statusleiste. Uhr und Akku hell, solange er oben ist; die Seite
            // selbst behält ihre Darstellung. Beim Schieben aus dem Bild wird die Leiste wieder normal.
            .statusLeisteHell(true, nurWennOben: true)
            if let bild {
                MiniaturAnsicht(bild.miniatur, farbe: bild.farbe, groesse: 2.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, rand + 24).offset(y: -12).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                if let art = bild?.spielart {
                    Text(verbatim: art.uppercased()).font(.caption.weight(.semibold)).kerning(1.4).foregroundStyle(Tisch.elfenbein.opacity(0.8))
                }
                Text(LocalizedStringKey(name))
                    .font(Design.Schrift.serif(48, gewicht: .bold, relativ: .largeTitle)).foregroundStyle(Tisch.elfenbein)
                    .lineLimit(2).minimumScaleFactor(0.6).accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, rand).padding(.bottom, Design.Abstand.l + 4)
        }
        .frame(height: 300 + oben)
        .overlay(alignment: .topLeading) {
            RundKnopf(symbol: "chevron.left", beschriftung: "Sammlung") { umgebung.zurueck() }
                .padding(.leading, rand).padding(.top, 12 + oben)
                .environment(\.colorScheme, .dark)   // Knopf liegt auf dem dunklen Filz
        }
    }

    /// „Spielen“ in Tinte: startet ohne Blatt mit den Spielern und Regeln der Seite. Ein gespeicherter Stand wird nur nach Rückfrage verworfen.
    private func spielenTinte() {
        if eintraege.isEmpty || spieler.upperBound == 1 { vorbereiten() }
        guard spieler.upperBound == 1 || eintraege.count >= spieler.lowerBound else { return }
        // Die Vormerkung einer Startkarte (Tagesrätsel) läuft unmittelbar vor dem Start; nach einer Rückfrage erst bei „Neu starten“.
        if SpielStand.vorhanden(id) { verwerfenFrage = true } else { vormerkung.aktion?(); loslegen() }
    }

    /// Filzkopf der Spielseite: Spielart-Farbe als Filz, Miniatur groß, Spielart und Name in Elfenbein; darüber Zurück und Regeln.
    @ViewBuilder private func startTinteKopf(_ bild: SpielRahmenHaken.Bild?) -> some View {
        if schrift.isAccessibilitySize { startTinteKopfGross(bild) } else { startTinteKopfNormal(bild) }
    }

    /// Große Tinte-Runde, Punkt 2: Kopf bei großer Schrift. Das Bild steht über dem Titel und wird nie von ihm verdeckt,
    /// der Kopf wächst mit dem Titel in die Höhe. Der Name bricht an Wortgrenzen und bleibt ganz lesbar.
    private func startTinteKopfGross(_ bild: SpielRahmenHaken.Bild?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let bild {
                MiniaturAnsicht(bild.miniatur, farbe: bild.farbe, groesse: 1.9)
                    .frame(maxWidth: .infinity).frame(height: 128).accessibilityHidden(true)
            }
            if let art = bild?.spielart {
                Text(verbatim: art.uppercased()).font(.caption.weight(.semibold)).kerning(1.4).foregroundStyle(Tisch.elfenbein.opacity(0.8))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Text(LocalizedStringKey(name))
                .font(Design.Schrift.serif(34, gewicht: .bold, relativ: .largeTitle, hoechstens: 1.3)).foregroundStyle(Tisch.elfenbein)
                .lineLimit(3).minimumScaleFactor(0.7).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
        }
        .padding(Design.Abstand.l).padding(.top, 44)   // Platz für den Zurück-Knopf über dem Bild
        .frame(maxWidth: .infinity, minHeight: 236, alignment: .bottomLeading)
        .background {
            ZStack {
                TischGrund(bild?.farbe)
                LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .top) {
            HStack(spacing: Design.Abstand.xs) {
                RundKnopf(symbol: "chevron.left", beschriftung: "Sammlung") { umgebung.zurueck() }
                Spacer()
            }
            .padding(10)
            .environment(\.colorScheme, .dark)   // Knopf liegt auf dem dunklen Filz
        }
    }

    private func startTinteKopfNormal(_ bild: SpielRahmenHaken.Bild?) -> some View {
        ZStack(alignment: .bottomLeading) {
            TischGrund(bild?.farbe)
            if let bild {
                MiniaturAnsicht(bild.miniatur, farbe: bild.farbe, groesse: 2.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).offset(y: -18).accessibilityHidden(true)
            }
            LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                if let art = bild?.spielart {
                    Text(verbatim: art.uppercased()).font(.caption.weight(.semibold)).kerning(1.4).foregroundStyle(Tisch.elfenbein.opacity(0.8))
                }
                Text(LocalizedStringKey(name))
                    .font(Design.Schrift.serif(34, gewicht: .bold, relativ: .largeTitle)).foregroundStyle(Tisch.elfenbein)
                    .lineLimit(2).minimumScaleFactor(0.6).accessibilityAddTraits(.isHeader)
            }
            .padding(Design.Abstand.l)
        }
        .frame(height: 236)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .top) {
            HStack(spacing: Design.Abstand.xs) {
                RundKnopf(symbol: "chevron.left", beschriftung: "Sammlung") { umgebung.zurueck() }
                Spacer()   // kein zweiter Regeln-Knopf: „Regeln ansehen“ steht direkt unter dem Kopf
            }
            .padding(10)
            .environment(\.colorScheme, .dark)   // Knöpfe liegen auf dem dunklen Filz
        }
    }

    /// Große Tinte-Runde, Punkt 1: Zeile „Laufende Partie“ der Spielseite in Tinte. Sie zeigt, wer spielt; weiter geht es mit dem
    /// einen Knopf „Weiterspielen“ unten. Ersetzt die Karte „Fortsetzen“ (vorher zwei Startknöpfe auf einer Seite).
    private func startTinteLaufend(_ l: LetzteRunde) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text("Laufende Partie").designLabel()
            HStack(spacing: Design.Abstand.m) {
                HStack(spacing: -10) {
                    ForEach(Array(l.plaetze.prefix(4).enumerated()), id: \.offset) { i, platz in
                        laufendAvatar(platz, i).overlay(Circle().strokeBorder(Color.seitenGrund, lineWidth: 2))
                    }
                }
                .accessibilityHidden(true)
                Text(verbatim: l.kurz).font(.body.weight(.semibold)).foregroundStyle(Color.schrift)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .linieUnten()
        }
        .accessibilityElement(children: .combine)
    }

    /// Bild einer Person der laufenden Partie: Zeichen, Farbe und Foto aus dem Verzeichnis, damit sie aussieht wie überall.
    private func laufendAvatar(_ platz: LetzteRunde.Platz, _ i: Int) -> SpielerAvatar {
        let p = platz.computer ? nil : umgebung.spieler.menschen.first { $0.name.caseInsensitiveCompare(platz.name) == .orderedSame }
        let foto = p.flatMap { $0.bildNr != nil ? SpielerBilder.daten($0.id) : nil }
        return SpielerAvatar(name: platz.name, farbe: platz.computer ? nil : Spieler.farbe(p?.farbeIndex ?? i), symbol: p?.zeichen, bild: foto)
    }

    private var startKlar: some View {
        let b = umgebung.statistik.bilanz(spiel: id, ich: umgebung.spieler.ich?.id)
        return ScrollView {
            VStack(spacing: Theme.kartenAbstand) {
                HStack(spacing: Design.Abstand.xs) {
                    RundKnopf(symbol: "chevron.left", beschriftung: "Sammlung") { umgebung.zurueck() }
                    Spacer()
                    RundKnopf(symbol: "book", beschriftung: "Regeln") { regelnOffen = true }
                }
                StartTitel(LocalizedStringKey(name), untertitel: untertitel).padding(.bottom, 6)
                if let b = SpielRahmenHaken.bild?(id) { SpielBild(farbe: b.farbe, miniatur: b.miniatur, hoehe: 132) }   // Spieleabend: Spielart-Farbe + Miniatur
                if spieler.upperBound >= 2, TischModus.istIPad {
                    Toggle(isOn: $tischModus) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tisch-Modus").font(.headline)
                            Text("iPad flach auf den Tisch legen: Jede Person bekommt am Rand ein Namensschild zu sich hin.").font(.footnote).foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)   // N-003: ein Name für den Schalter (Kästchen in Tinte/Salon war ohne Namen)
                    }
                    .card()
                }
                if wuerfelWahl { WuerfelWahlKarte(spiel: id, vorgabe: umgebung.wuerfelQuelle, texte: wuerfelTexte) }
                if let startInhalt { startInhalt(startAktionen) }
                // Punktespiele (Arcade) können nicht „gewonnen“ werden: Partien, Bestwert, Durchschnitt statt Siege und Serie
                StatistikZeile(titel: "Statistik", werte: zeigtRekord ? [
                    .init(zahl: "\(b.partien)", name: "Partien"),
                    .init(zahl: umgebung.statistik.rekord(spiel: id, stufe: ComputerStufe.gespeichert(id).rawValue).map(String.init) ?? "–", name: "Bestwert"),
                    .init(zahl: umgebung.statistik.durchschnitt(spiel: id, stufe: ComputerStufe.gespeichert(id).rawValue).map(String.init) ?? "–", name: "Durchschnitt"),
                ] : [
                    .init(zahl: "\(b.partien)", name: "Partien"),
                    .init(zahl: "\(b.siege)", name: "Siege"),
                    .init(zahl: "\(b.serie)", name: "Serie"),
                    // Duell (Ballwechsel): Bestwert = längster Ballwechsel, nicht die Punktzahl (die ist durch das Spielziel begrenzt)
                    umgebung.statistik.besteRallye(spiel: id).map { .init(zahl: "\($0)", name: "Rallye") } ?? .init(zahl: b.rekord.map(String.init) ?? "–", name: "Bestwert"),
                ]) {}
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Statistik"))
                .accessibilityValue(zeigtRekord ? Text("\(b.partien) Partien, Bestwert \(b.rekord.map(String.init) ?? String(localized: "keiner")), Durchschnitt \(umgebung.statistik.durchschnitt(spiel: id).map(String.init) ?? String(localized: "keiner"))") : Text("\(b.partien) Partien, \(b.siege) Siege, Serie \(b.serie), Bestwert \(b.rekord.map(String.init) ?? String(localized: "keiner"))"))
                if schrift.isAccessibilitySize { startKnoepfeKlar.padding(.top, Design.Abstand.s) }
            }
            .padding(.horizontal, Theme.seitenRand).padding(.bottom, schrift.isAccessibilitySize ? 24 : 100)
            .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
        }
        .background(Color.seitenGrund)
        .safeAreaInset(edge: .bottom) {
            // A-002/A-004/A-008: Die Leiste nimmt unten ihren Platz weg (safeAreaInset). Bei Schriftgrößen der Bedienungshilfen
            // wäre sie bis zu 180 pt hoch und verdeckte beim Öffnen Würfelwahl und Kalender; dort stehen die Knöpfe deshalb
            // als letzter Block im Inhalt (siehe oben), und es gibt keine feste Leiste.
            if !schrift.isAccessibilitySize {
                startKnoepfeKlar
                    .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
                    .frame(maxWidth: Theme.wideColumnWidth)
            }
        }
    }

    /// Fortsetzen, Letzte Runde, Neues Spiel der Klar-Startseite (feste Leiste oder, bei großer Schrift, Ende des Inhalts).
    private var startKnoepfeKlar: some View {
        VStack(spacing: Design.Abstand.s) {
            if SpielStand.vorhanden(id), let l = letzte {
                Button { fortsetzen(l) } label: {
                    Label("Partie fortsetzen", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(HauptKnopfStil())
            }
            if spieler.upperBound > 1, let l = letzte, l.plaetze.count >= spieler.lowerBound, l.plaetze.count <= spieler.upperBound {
                Button { letzteRundeStarten(l) } label: {
                    Label(String(localized: "Letzte Runde wieder: \(l.kurz)"), systemImage: "arrow.counterclockwise")
                        .lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                }
                .buttonStyle(ZweitKnopfStil())
            }
            Button("Neues Spiel") { neuesSpielTippen() }
                .buttonStyle(HauptKnopfStil())
        }
        // A-002: Die Knopfleiste bleibt bei größter Schrift niedrig, damit der Inhalt darüber (Würfelwahl) frei bleibt
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// Aktionen für die spieleigenen Karten der Startseite.
    private var startAktionen: SpielStartAktionen {
        SpielStartAktionen(neu: { direktStarten() }, fortsetzen: { if SpielStand.vorhanden(id), let l = letzte { fortsetzen(l) } },
                           standVorhanden: SpielStand.vorhanden(id) && letzte != nil,
                           vormerken: { [vormerkung] in vormerkung.aktion = $0 })
    }

    /// Neue Partie ohne Blatt (von einer Karte der Startseite). Ein gespeicherter Stand wird nur nach Rückfrage verworfen.
    private func direktStarten() {
        vorbereiten()
        if SpielStand.vorhanden(id) { verwerfenFrage = true } else { loslegen() }
    }

    /// „Neues Spiel“: Einzelspiele mit eigenen Startkarten und ohne Start-Optionen brauchen kein Blatt (dort gäbe es nichts zu wählen).
    private func neuesSpielTippen() {
        if startInhalt != nil, startOptionen == nil, spieler.upperBound == 1 { direktStarten() }
        else { vorbereiten(); neuesSpiel = true }
    }

    @ViewBuilder private var regelnText: some View {
        // Bauplan RL-K: mit gegliedertem Text (nur Deutsch) die neue Seite
        if let q = RegelLeseKatalog.quelle(fuer: id) { RegelLeseAnsicht(quelle: q, spielName: name, spielID: id, wissen: regelWissenQuelle?()) }
        else { NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Abstand.l) {
                    if let ziel { zielKarte(ziel) }
                    Text(regeln).font(.body)
                }.padding(Theme.seitenRand).frame(maxWidth: .infinity, alignment: .leading)
            }
                .background(Color.seitenGrund)
                .regelFrageLeiste(spielID: id, wissen: regelWissenQuelle?())   // KI-3: Knopf „Frag nach den Regeln“ unten (nur mit Chat-Möglichkeit)
                .navigationTitle("Regeln").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { regelnOffen = false } } }
        }
        }
    }

    private func zielKarte(_ ziel: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Ziel", systemImage: "flag.checkered").font(.headline).foregroundStyle(Color.accentText)
            Text(ziel).font(.body)
        }.frame(maxWidth: .infinity, alignment: .leading).card()
    }

    @ViewBuilder
    private var regelnBlatt: some View {
        if anleitung.isEmpty { regelnText }
        else {
            AnleitungBlatt(titel: LocalizedStringKey(name), schritte: (zielSchritt ?? ziel.map { AnleitungSchritt.ziel($0) }).map { [$0] + anleitung } ?? anleitung, fertig: { regelnOffen = false },
                           logo: SpielRahmenHaken.bild?(id).map { b in
                               // T-042: In Tinte ist `SpielBild` eine Zeile über die ganze Breite; im 36-pt-Feld der Anleitung wurde es abgeschnitten. Dort die Miniatur selbst.
                               Design.ist(.tinte) ? AnyView(MiniaturAnsicht(b.miniatur, farbe: b.farbe, groesse: 36.0 / 52))
                                                  : AnyView(SpielBild(farbe: b.farbe, miniatur: b.miniatur, hoehe: 36)) }) {
                if let regelnAnsicht { regelnAnsicht().regelFrageLeiste(spielID: id, wissen: regelWissenQuelle?()) } else { RegelnLesen(regeln: regeln, spielID: id, spielName: name, wissen: regelWissenQuelle?()) }
            }
        }
    }

    // MARK: Neues Spiel

    /// Startaufstellung für das Neues-Spiel-Blatt: Einzelspiel = „Ich“, sonst die zuletzt gespielten Personen.
    /// Vorgabe mit der vorgemerkten Spielerzahl aus „Neue Partie sagen“ (nur innerhalb der Spielerzahl des Spiels; sonst wie bisher).
    private static func vorgabe(_ spieler: ClosedRange<Int>, _ umgebung: SpielUmgebung, id: String) -> [SpielerEintrag] {
        var liste = vorgabe(spieler, umgebung)
        guard spieler.upperBound > 1, let n = SpielerVormerkung.lesen(fuer: id), spieler.contains(n) else { return liste }
        while liste.count < n { liste.append(SpielerEintrag(name: Design.ist(.tinte) ? SpielerListe<EmptyView>.vorgabeName(liste.count + 1) : "", art: "mensch")) }
        while liste.count > n { liste.removeLast() }
        return liste
    }

    private static func vorgabe(_ spieler: ClosedRange<Int>, _ umgebung: SpielUmgebung) -> [SpielerEintrag] {
        if spieler.upperBound == 1 { return [eintrag(umgebung.spieler.ich?.name ?? "", umgebung)] }
        let liste = Self.mehrspielerVorgabe(spieler, umgebung)
        // Design-Runde 3 (Tinte): leere Zeilen zeigen „Spieler N“ statt „? Name“. Platz 1 bleibt der eigene Name aus der Einführung,
        // wenn er angelegt ist. Die Namen sind die Platzhalter der Spielerliste und kommen deshalb nicht ins Verzeichnis (siehe `loslegen`).
        guard Design.ist(.tinte) else { return liste }
        return liste.enumerated().map { i, e in
            guard e.art != "computer", e.name.trimmingCharacters(in: .whitespaces).isEmpty else { return e }
            var neu = e
            neu.name = SpielerListe<EmptyView>.vorgabeName(i + 1)
            return neu
        }
    }

    /// Mehrspieler: Platz 1 = „Ich“ (falls angelegt), dann die zuletzt gespielten Personen; jeder Mensch braucht einen Namen.
    private static func mehrspielerVorgabe(_ spieler: ClosedRange<Int>, _ umgebung: SpielUmgebung) -> [SpielerEintrag] {
        var namen: [String] = []
        if let ich = umgebung.spieler.ich?.name, !ich.isEmpty { namen.append(ich) }
        // F21-010: Platzhalter („Spieler 8“ aus älteren Ständen im Verzeichnis) nicht als Vorschlag für die nächste Zeile übernehmen
        let platzhalter = Set((1...12).map { SpielerListe<EmptyView>.vorgabeName($0).lowercased() })
        for p in umgebung.spieler.zuletztGespielt where !platzhalter.contains(p.name.lowercased()) && !namen.contains(where: { $0.caseInsensitiveCompare(p.name) == .orderedSame }) { namen.append(p.name) }
        // Designwechsel: Die Runde vom Salon-Start („Wer ist dabei?“) steht vorn, in der Reihenfolge der Auswahl; dann wie bisher.
        // Ohne Runde (und in den anderen Designs) ergibt das genau die bisherige Vorgabe.
        let runde = Design.ist(.salon) ? AktuelleRunde.namen(umgebung.spieler) : []
        // Spiele mit Solo-Modus: eine Zeile vorbelegen, sonst blockiert die leere zweite Zeile „Los geht's“ (S1-009)
        if runde.isEmpty && spieler.lowerBound == 1 {
            return [eintrag(namen.first ?? "", umgebung)]
        }
        return AktuelleRunde.aufstellung(runde: runde, bisher: namen, spieler: spieler).map { eintrag($0, umgebung) }
    }

    /// Eintrag für eine Person aus dem Verzeichnis: Zeichen, Farbe und Foto werden übernommen, damit sie in jedem Spiel gleich aussieht.
    private static func eintrag(_ name: String, art: String = "mensch", _ umgebung: SpielUmgebung) -> SpielerEintrag {
        let p = name.isEmpty ? nil : umgebung.spieler.menschen.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        let zeichen = p?.zeichen
        let hex = p.map { Spieler.farbenHex[$0.farbeIndex % Spieler.farbenHex.count] }
        let foto = p.flatMap { $0.bildNr != nil ? SpielerBilder.daten($0.id) : nil }
        return SpielerEintrag(name: name, art: art, farbeHex: hex, symbol: zeichen, bild: foto)
    }

    private func vorbereiten() {
        // Einzelspiel: immer frisch (der Name kommt aus dem Verzeichnis); Mehrspieler behalten ihre letzte Auswahl
        guard eintraege.isEmpty || spieler.upperBound == 1 else { return }
        if spieler.upperBound == 1 {
            eintraege = [Self.eintrag(umgebung.spieler.ich?.name ?? "", umgebung)]
        } else {
            eintraege = Self.vorgabe(spieler, umgebung, id: id)
        }
    }

    /// Spielerliste und bekannte Spieler: im Neues-Spiel-Blatt und, in Tinte, direkt auf der Spielseite (Design-Runde 3, R1).
    @ViewBuilder private var spielerWahl: some View {
        SpielerListe(spieler: $eintraege,
                     arten: computerErlaubt ? [SpielerArt(id: "mensch", name: "Mensch", symbol: "person.fill"),
                                               SpielerArt(id: "computer", name: "Computer", symbol: "cpu")] : [],
                     minimum: spieler.lowerBound, maximum: spieler.upperBound)
        BekannteSpielerLeiste(benutzt: eintraege.map(\.name)) { n in
            // Zeichen und Farbe der Person übernehmen, damit sie in jedem Spiel gleich aussieht
            let p = umgebung.spieler.menschen.first { $0.name.caseInsensitiveCompare(n) == .orderedSame }
            let zeichen = p?.zeichen
            let hex = p.map { Spieler.farbenHex[$0.farbeIndex % Spieler.farbenHex.count] }
            let foto = p.flatMap { $0.bildNr != nil ? SpielerBilder.daten($0.id) : nil }
            if let i = eintraege.firstIndex(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty && $0.art == "mensch" }) {
                eintraege[i].name = n; eintraege[i].symbol = zeichen; eintraege[i].farbeHex = hex; eintraege[i].bild = foto
            } else if eintraege.count < spieler.upperBound {
                eintraege.append(SpielerEintrag(name: n, farbeHex: hex, symbol: zeichen, bild: foto))
            }
        }
    }

    private var blatt: some View {
        // Leere Namenszeile = Platzhalter „Spieler N“ (siehe `loslegen`): Der Start wird nicht wegen leerer Namen gesperrt.
        NeuesSpielBlatt(losTitel: startTitel,
                        losAktiv: spieler.upperBound == 1 || eintraege.count >= spieler.lowerBound,
                        losHinweis: "Bitte füge mehr Spieler hinzu.",
                        // T-017: dieselbe Meldung als VoiceOver-Ansage
                        losHinweisAnsage: String(localized: "Bitte füge mehr Spieler hinzu."),
                        schliessen: { neuesSpiel = false }, los: loslegen) {
            if let b = SpielRahmenHaken.bild?(id) { SpielBild(farbe: b.farbe, miniatur: b.miniatur, hoehe: 96) }   // Spieleabend
            // G-001/P-001/M-004/N-006: Das Blatt nennt das Spiel (vorher nur Farbpunkt und Symbol, auch im Barrierefreiheitsbaum ohne Namen)
            Text(LocalizedStringKey(name)).font(.title3.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            if spieler.upperBound > 1 {
                NeuesSpielKarte("Spieler") {
                    spielerWahl
                }
            } else {
                Text(einzelText).font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).card()
            }
            if let startOptionen { startOptionen(eintraege) }
        }
    }

    /// Der eine Start für Neues Spiel, Fortsetzen, Revanche und „Noch einmal“ (F3): Zug-Meldung zurücksetzen, neue Partie-Nummer,
    /// Live Activity (E5, ab zwei Menschen) beginnen, Uhr stellen, Spielansicht neu aufbauen.
    private func partieStarten(fortgesetzt: Bool = false) {
        PartieStart.ausfuehren(spielID: id, spielName: name, menschen: teilnehmer.filter { !$0.computer }.map(\.name), wache: wache)
        PartieMeldung.computerNamen = Set(teilnehmer.filter(\.computer).map { $0.name.lowercased() })   // C-012
        self.fortgesetzt = fortgesetzt; uhr.starten()
        spielNummer += 1; startzeit = Date()
        phase = .laeuft
    }

    private func loslegen() {
        SpielerVormerkung.loeschen(fuer: id)
        if eintraege.isEmpty { vorbereiten() }
        var namen = Set<String>()
        teilnehmer = eintraege.enumerated().map { i, e in
            var basis = e.name.trimmingCharacters(in: .whitespaces)
            // Fund 112 (Philipp 14.11.: Computer als „Computer“ kennzeichnen): Ein Computerplatz mit einem Standardnamen „Spieler 2“ (in jeder Sprache) heißt „Computer“.
            if e.art == "computer", basis.range(of: #"^(Spieler|Joueur|Jugador|Player) \d+$"#, options: .regularExpression) != nil { basis = "" }
            var stamm = basis.isEmpty ? (e.art == "computer" ? "Computer" : String(localized: "Spieler \(i + 1)")) : basis
            // C-013/B12-S2-011: „Computer 2“ aus der Vorgabe nicht noch einmal nummerieren („Computer 2 3“)
            if e.art == "computer", stamm.range(of: #"^Computer \d+$"#, options: .regularExpression) != nil { stamm = "Computer" }
            var n = stamm
            var k = 2
            while namen.contains(n.lowercased()) { n = "\(stamm) \(k)"; k += 1 }
            namen.insert(n.lowercased())
            return SpielTeilnehmer(id: e.id, name: n, computer: e.art == "computer")
        }
        do {
            let l = LetzteRunde(plaetze: teilnehmer.map { .init(name: $0.name, computer: $0.computer) })
            l.speichern(id); letzte = l
        }
        // Nur selbst eingegebene Namen ins Verzeichnis (keine Platzhalter wie „Spieler 3“)
        // C-012: auch die vorgefüllten Namen der Spielerliste („Spieler 3“) sind Platzhalter
        let platzhalter = Set((1...12).map { SpielerListe<EmptyView>.vorgabeName($0).lowercased() })
        let neueNamen = eintraege.filter { $0.art != "computer" }.map { $0.name.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty && !platzhalter.contains($0.lowercased()) }
        // K-031/G-015: Start aus dem Blatt: erst nach dem Schließen anmelden (`namenAnmelden` über `onDismiss`); ohne Blatt sofort.
        if neuesSpiel { anmeldenNachBlatt = neueNamen } else { SpielerQuelle.menschen(neueNamen) }
        neuesSpiel = false
        SpielStand.verworfen.remove(id)
        SpielStand.loeschen(id)
        partieStarten()
    }

    /// K-031/G-015: Die beim Start aus dem Blatt vorgemerkten Namen ins Verzeichnis melden (nach dem Schließen des Blatts).
    private func namenAnmelden() {
        guard !anmeldenNachBlatt.isEmpty else { return }
        let n = anmeldenNachBlatt
        anmeldenNachBlatt = []
        SpielerQuelle.menschen(n)
    }

    /// Laufende Partie wieder aufnehmen: das Spiel liest seinen Zustand selbst aus `SpielStand`.
    private func fortsetzen(_ l: LetzteRunde) {
        teilnehmer = l.plaetze.enumerated().map { i, p in SpielTeilnehmer(name: p.name, computer: p.computer) }
        SpielStand.verworfen.remove(id)
        partieStarten(fortgesetzt: true)
    }

    /// KI-8: Startet die Partie, die Siri oder ein Kurzbefehl verlangt hat. Läuft schon eine Partie, fragt die Hülle vorher wie bei „Neu starten“.
    private func wunschStarten(_ w: StartWunsch) {
        let vorgabe = Self.vorgabe(spieler, umgebung).filter { $0.art != "computer" }.map(\.name)
        if let plaetze = w.aufstellung(spielerzahl: spieler, computerErlaubt: computerErlaubt, vorgabeNamen: vorgabe) {
            eintraege = plaetze.map { SpielerEintrag(name: $0.name, art: $0.computer ? "computer" : "mensch") }
        }
        if SpielStand.vorhanden(id) { verwerfenFrage = true } else { loslegen() }
    }

    /// „Neue Partie“ aus dem „…“-Menü (G-012/G-019): dieselben Teilnehmer wie in der laufenden Partie, ohne Neues-Spiel-Blatt.
    private func neuePartieImSpiel() {
        let gleich = eintraege.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() } == teilnehmer.map { $0.name.lowercased() }
        if !gleich { eintraege = teilnehmer.map { SpielerEintrag(name: $0.name, art: $0.computer ? "computer" : "mensch") } }
        SpielZug.zuruecksetzen(id)
        loslegen()
    }

    /// Ein Tipp: gleiche Spieler, gleiches Spiel (B4).
    private func letzteRundeStarten(_ l: LetzteRunde) {
        eintraege = l.plaetze.map { SpielerEintrag(name: $0.name, art: $0.computer ? "computer" : "mensch") }
        loslegen()
    }

    // MARK: Ende

    /// „Pausieren“: zurück zur Startseite, der Spielstand bleibt erhalten und „Partie fortsetzen“ führt zurück (kein Datenverlust beim Home-Knopf).
    private func pausieren() {
        guard SpielStand.vorhanden(id) else { abbrechen(); return }
        wache.schliessen()   // eine verzögerte Ende-Meldung der pausierten Partie verbucht nichts mehr
        uhr.anhalten()
        LaufendePartie.beenden()   // C-014: die Live Activity endet mit der Pause
        phase = .start
        // TestFlight 13.11., Nr. 5 (C-024): Nach „Pausieren“ geht es zur Startseite, wo „Weiterspielen“ wartet. Die Spielseite mit
        // „Neue Partie beginnen“ wäre dort ein Umweg (und die Startseite wüsste ohnehin von der offenen Partie).
        umgebung.zurueck()
    }

    /// Öffnet die Abfrage „Spiel wirklich beenden?“ und legt dabei fest, ob „Beenden“ eine Niederlage bucht (die eine Entscheidung
    /// für Vorwarnung und Buchung, `PartieMeldung.abbruchBuchung`).
    private func rueckfrageOeffnen() {
        let begonnen = AbbruchWertung.begonnen(hatZug: SpielZug.hatZug(id), fortgesetzt: fortgesetzt, spielzeit: uhr.zeit())
        abbruchVorgemerkt = PartieMeldung.abbruchBuchung(begonnen: begonnen, spiel: id, teilnehmer: teilnehmer.map { ($0.name, $0.computer) }, dauer: uhr.zeit(),
                                                         arcade: zeigtRekord || (SpielRahmenHaken.istArcade?(id) ?? false))
        rueckfrage = true
    }

    /// „Beenden“ mitten in der Partie: Ob das als Niederlage zählt, bestimmt die Einstellung „Partie abbrechen“ (`AbbruchWertung`,
    /// Standard: nie). Gebucht wird nur eine begonnene Partie (Zug gemeldet, Stand fortgesetzt oder lange genug gespielt);
    /// entschieden wurde das beim Öffnen der Abfrage (`rueckfrageOeffnen`).
    private func abbrechen() {
        if let e = abbruchVorgemerkt {
            Task { @MainActor in PartieMeldung.senke?(e) }
            zeigeNiederlageHinweis()
        }
        abbruchVorgemerkt = nil
        wache.schliessen()   // nach „Beenden“ darf kein verzögertes `ende` noch eine zweite Partie verbuchen
        SpielZug.zuruecksetzen(id); SpielStand.verworfen.insert(id); SpielStand.loeschen(id); phase = .start
        LaufendePartie.beenden()
    }

    /// Kurze Einblendung nach „Beenden“, wenn tatsächlich eine Niederlage gebucht wurde (und für VoiceOver angesagt).
    private func zeigeNiederlageHinweis() {
        withAnimation { niederlageHinweis = true }
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Partie beendet – zählt als Niederlage"))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            withAnimation { niederlageHinweis = false }
        }
    }

    /// Ende-Meldung des Spiels. Angenommen wird sie nur von der laufenden, aktuellen Partie und nur einmal (F2).
    private func beenden(_ e: SpielEnde, partie: Int) {
        var laeuft = false
        if case .laeuft = phase { laeuft = true }
        guard wache.annehmen(partie: partie, laeuft: laeuft) else { return }
        LaufendePartie.beenden()
        SpielStand.loeschen(id)
        var e = e
        if let a = e.arcade, a.sieg == nil {
            // Punktespiel: Rekord vor dem Verbuchen prüfen, Partie ohne Sieg zählen
            let neu = Rekord.istNeu(punkte: a.punkte, bisher: umgebung.statistik.rekord(spiel: id, stufe: Kennzahl.ganz(a.kennzahlen["stufe"], ersatz: 2)))
            e.info = [e.info, a.grund.map { String(localized: String.LocalizationValue($0)) }].compactMap { $0 }.joined(separator: " · ")
            e.punkte = [String(a.punkte)]
            e.plaetze = neu ? [-1] : [0]          // −1 = neuer Rekord (nur für die Anzeige, siehe endeAnsicht)
            PartieMeldung.punkte(spiel: id, name: umgebung.spieler.ich?.name ?? "", punkte: a.punkte, dauer: uhr.zeit(), kennzahlen: a.kennzahlen)
            e.dauer = e.dauer ?? uhr.zeit()   // EB-K: Dauer einmal festhalten (für `EndeWert.dauer`), nicht bei jedem Zeichnen neu lesen
            phase = .ende(e)
            return
        }
        // Punktespiel allein: Bestwert vor dem Verbuchen prüfen (danach wäre die eigene Partie schon der Bestwert)
        e.neuerRekord = EndeBuchung.neuerRekord(reihenfolge: e.reihenfolge, punkte: e.punkte, einzel: e.einzel,
                                                bisher: umgebung.statistik.bilanz(spiel: id, ich: umgebung.spieler.ich?.id).rekord)
        PartieMeldung.melden(spiel: id, reihenfolge: e.reihenfolge,
                             punkte: e.punkte.map(EndeBuchung.zahl), plaetze: e.plaetze, dauer: e.dauer ?? uhr.zeit(), kennzahlen: e.arcade?.kennzahlen ?? e.kennzahlen, einzel: e.einzel)
        e.dauer = e.dauer ?? uhr.zeit()   // EB-K: derselbe Wert wie in der Buchung, einmal festgehalten (für `EndeWert.dauer`)
        phase = .ende(e)
    }

    private func arcadeEnde(_ e: SpielEnde, _ a: ArcadeAusgang) -> some View {
        let neu = e.plaetze == [-1]
        let symbol: String, titel: String
        switch a.sieg {
        case .some(true): symbol = "trophy.fill"; titel = String(localized: "Gewonnen!")
        case .some(false): symbol = "flag.checkered"; titel = String(localized: "Verloren")
        case .none: symbol = neu ? "trophy.fill" : "flag.checkered"; titel = neu ? String(localized: "Neuer Rekord!") : String(localized: "Aus!")
        }
        let punkte = a.sieg == nil ? String(localized: "\(a.punkte) Punkte") : (e.info ?? "")
        let rekord = a.sieg == nil && !neu ? umgebung.statistik.rekord(spiel: id, stufe: Kennzahl.ganz(a.kennzahlen["stufe"], ersatz: 2)).map { String(localized: "Rekord: \($0)") } : nil
        let info = a.sieg == nil ? [e.info, rekord].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n") : nil
        let teilenText = ErgebnisText.text(spiel: name, reihenfolge: e.reihenfolge, punkte: e.punkte, plaetze: a.sieg == nil ? nil : e.plaetze,
                                           arcadePunkte: a.punkte, arcadeSieg: a.sieg, neuerRekord: neu)
        return SiegerBildschirm(symbol: symbol, titel: titel, untertitel: punkte, info: info,
                                teilen: TeilenFreigabe.aktion { ErgebnisTeilen.zeigen(teilenText) },
                                sekundaerTitel: "Zum Start", primaerTitel: "Noch einmal",
                                schliessen: { phase = .start }, sekundaer: zumStart,
                                primaer: { SpielStand.verworfen.remove(id); SpielStand.loeschen(id); partieStarten() },
                                motiv: {
                                    // EB-K: Galgenmännchen meldet über `arcade:`; mit Werten oder Bild gilt auch hier der Standardinhalt.
                                    if EndeAnordnung.zeigtStandard(e) { EndeStandardInhalt(ende: e, rangEintraege: 0, spielID: id) }
                                    else { endeMotiv }
                                })
    }

    /// „Zum Start“ auf dem Ende-Bildschirm: zur Startseite der App (wie „Pausieren“), nicht auf die Spielseite des Spiels. Die Partie ist zu Ende,
    /// dort gibt es nichts mehr fortzusetzen. Das X (`schliessen`) bleibt bei der Spielseite.
    private var zumStart: () -> Void { { phase = .start; umgebung.zurueck() } }

    /// Motiv des Ende-Bildschirms (Spieleabend): Bildfeld in Spielart-Farbe mit Miniatur und Pokal; ohne Haken der Symbolkreis.
    @ViewBuilder private var endeMotiv: some View { SpielBildMotiv(id: id) }

    @ViewBuilder private func endeAnsicht(_ e: SpielEnde) -> some View {
        if let a = e.arcade { arcadeEnde(e, a) } else { normalEnde(e) }
    }

    private func normalEnde(_ e: SpielEnde) -> some View {
        let gewinner = e.reihenfolge.first ?? ""
        let rang = e.reihenfolge.enumerated().map { i, n in
            RangEintrag(name: n, punkte: i < e.punkte.count ? e.punkte[i] : "", platz: e.plaetze.map { "\(EndeBuchung.platz($0, i))." })
        }
        let teilenText = ErgebnisText.text(spiel: name, reihenfolge: e.reihenfolge, punkte: e.punkte, plaetze: e.plaetze, neuerRekord: e.neuerRekord, einzel: e.einzel)
        let titel: String, symbol: String
        switch EndeBuchung.titel(reihenfolge: e.reihenfolge, remis: e.istRemis, einzel: e.einzel, neuerRekord: e.neuerRekord) {
        case .remis: titel = String(localized: "Remis"); symbol = "equal.circle.fill"
        case .sieger: titel = "\(gewinner)"; symbol = "trophy.fill"
        case .geschafft: titel = String(localized: "Geschafft!"); symbol = "trophy.fill"
        case .verloren: titel = String(localized: "Verloren"); symbol = "flag.checkered"
        case .beendet: titel = String(localized: "Partie beendet"); symbol = "flag.checkered"
        case .neuerRekord: titel = String(localized: "Neuer Rekord!"); symbol = "trophy.fill"
        }
        let ueberschrift = EndeBuchung.einzelGilt(e.reihenfolge) ? (e.titel ?? titel) : titel
        // Punktespiel allein: ohne eigenen Infotext stehen die Punkte unter der Überschrift
        let punkteZeile = EndeBuchung.einzelGilt(e.reihenfolge) && e.einzel == .punkte ? e.punkte.first.map { String(localized: "\($0) Punkte") } : nil
        let nochmal = { SpielStand.verworfen.remove(id); SpielStand.loeschen(id); partieStarten() }
        return SiegerBildschirm(symbol: symbol, titel: ueberschrift,
                                untertitel: e.info ?? punkteZeile ?? "", rangliste: e.reihenfolge.count > 1 ? rang : [],
                                info: Rivalitaet.zeile(namen: e.reihenfolge, verzeichnis: umgebung.spieler, statistik: umgebung.statistik),
                                teilen: TeilenFreigabe.aktion { ErgebnisTeilen.zeigen(teilenText) },
                                sekundaerTitel: "Zum Start", primaerTitel: e.nochmalTitel ?? (Design.ist(.tinte) && EndeBuchung.einzelGilt(e.reihenfolge) ? "Noch einmal" : "Revanche"),   // R2 Punkt 7: allein „Noch einmal“, nur Tinte
                                schliessen: { phase = .start }, sekundaer: zumStart,
                                primaer: nochmal,
                                motiv: {
                                    if let endeInhalt { endeInhalt(e, nochmal) }   // Minensuche, Kreuzworträtsel: eigener Inhalt wie bisher
                                    else if EndeAnordnung.zeigtStandard(e) {
                                        // EB-K (Blatt 22): Werte, Bild vom Ende oder „So fielen die Würfel“ (1.0 M4; Klar/Salon: WuerfelBilanzKarte)
                                        EndeStandardInhalt(ende: e, rangEintraege: e.reihenfolge.count > 1 ? e.reihenfolge.count : 0, spielID: id)
                                    }
                                    else { SpielBildMotiv(id: id, symbol: symbol) }   // Pokal nur bei Sieg, sonst Zielflagge
                                })
    }
}
#endif

#if canImport(UIKit)
private struct NeuePartieSchluessel: EnvironmentKey { static let defaultValue: (() -> Void)? = nil }
public extension EnvironmentValues {
    /// Vom `SpielRahmen` im laufenden Spiel gesetzt: fragt „Laufende Partie verwerfen?“ und startet dann mit denselben Spielern neu.
    var neuePartie: (() -> Void)? {
        get { self[NeuePartieSchluessel.self] }
        set { self[NeuePartieSchluessel.self] = newValue }
    }
}

/// Eintrag „Neue Partie“ für das „…“-Menü eines Spiels (G-012/G-019), für alle Spiele gleich benannt:
/// `RundKnopfMenue { NeuePartieMenuePunkt(); … }`. Außerhalb des `SpielRahmen` (kein `neuePartie`) bleibt er leer.
public struct NeuePartieMenuePunkt: View {
    @Environment(\.neuePartie) private var neuePartie
    public init() {}
    public var body: some View {
        if let neuePartie {
            Button("Neue Partie", systemImage: "arrow.counterclockwise") { neuePartie() }
        }
    }
}

/// „Alle Regeln lesen“ aus der Anleitung: der ausführliche Regeltext mit Titel und Schließen-Knopf (schließt nur dieses Blatt).
private struct RegelnLesen: View {
    let regeln: LocalizedStringKey
    var spielID = ""
    var spielName = ""
    var wissen: (any RegelWissen)?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        // Bauplan RL-K: gibt es einen gegliederten Text (nur Deutsch), zeigt die neue Seite ihn mit Abschnitten und „Inhalt“
        if let q = RegelLeseKatalog.quelle(fuer: spielID) { RegelLeseAnsicht(quelle: q, spielName: spielName, spielID: spielID, wissen: wissen) }
        else { heutigeSeite }
    }
    private var heutigeSeite: some View {
        NavigationStack {
            ScrollView { Text(regeln).font(.body).padding(Theme.seitenRand).frame(maxWidth: .infinity, alignment: .leading) }
                .background(Color.seitenGrund)
                .regelFrageLeiste(spielID: spielID, wissen: wissen)   // KI-3: Knopf „Frag nach den Regeln“ unten (nur mit Chat-Möglichkeit)
                .navigationTitle("Regeln").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
        }
    }
}
#endif
