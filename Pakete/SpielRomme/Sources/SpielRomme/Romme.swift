// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import RommeKern

@MainActor
public struct RommeModul: SpielModul {
    public init() {}
    public let id = "romme"
    public let name = "Rommé"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "rectangle.on.rectangle.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Folgen und Sätze auslegen", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            regeln: "Jeder bekommt 13 Karten. Du ziehst eine Karte vom Stapel oder die oberste Ablagekarte. Dann darfst du auslegen: Sätze (3–4 gleiche Werte in verschiedenen Farben, höchstens 2 Joker) und Folgen (3 bis 14 aufsteigende Karten einer Farbe, das Ass unten oder oben, nicht „um die Ecke“ von König über Ass zur 2; mindestens eine echte Karte). Joker (★) ersetzen jede Karte. Deine erste Auslage muss zusammen mindestens 40 Augen haben (Ass unten 1, oben 11, Bilder 10; ein Joker zählt wie die Karte, die er ersetzt). Danach darfst du Karten an ausliegende Reihen anlegen. Liegt ein Joker aus und du hast die Karte, die er ersetzt, darfst du sie gegen den Joker tauschen; Anlegen und Tauschen gehen erst nach deiner eigenen ersten Auslage. Zum Schluss wirfst du eine Karte ab. Wer als Erster keine Karten mehr hat, gewinnt – die anderen zählen Strafpunkte (ein Joker auf der Hand 20). Vor dem Start kannst du statt einer Runde genau 3 oder genau 5 Runden wählen: Dann zählen die Strafpunkte (Augen der Resthand) zusammen, und wer nach der letzten Runde die wenigsten hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            RommeSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { _ in RommeOptionen() }   // 1.0 (M8): eine Runde oder mehrere, vor dem Start
        .mitZiel("Lege Sätze und Folgen aus und werde als Erster alle Karten los. Die anderen bekommen Strafpunkte.")
        .mitZielSchrittNeu(.ziel("Lege Sätze und Folgen aus und werde als Erster alle Karten los. Die anderen bekommen Strafpunkte für ihre Restkarten. Rommé ist ein Klassiker für 2 bis 4 Personen. Jede Person bekommt 13 Karten, gespielt wird mit zwei Blättern und 6 Jokern."))   // B25: neue deutsche Anleitung (RegelTexteNeu), die alte bleibt für alle anderen Sprachen
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "rectangle.stack", titel: "Ziehen", text: "Jeder Zug beginnt mit einer Karte: Nimm sie vom Stapel oder die oberste Karte der Ablage. Die Ablagekarte ist sichtbar. Nimm sie, wenn sie dir hilft. Erst danach darfst du auslegen.", figuren: ["🂠", "🂱"], bewegt: 0),
            .figuren(symbol: "square.stack.3d.up", titel: "Sätze und Folgen", text: "Ein Satz sind 3 oder 4 Karten mit gleichem Wert in verschiedenen Farben, etwa drei Könige. Eine Folge sind mindestens 3 Karten einer Farbe in einer Reihe, etwa Herz 5, 6, 7. Das Ass darf unten (A-2-3) oder oben (D-K-A) liegen, aber nicht um die Ecke.", figuren: ["K♠", "K♥", "K♦", "5♥", "6♥", "7♥"], bewegt: nil),
            .figuren(symbol: "star", titel: "Joker", text: "Ein Joker ersetzt jede Karte. Er füllt Lücken oder verlängert eine Folge. Ein Satz darf höchstens zwei Joker haben. Liegt ein Joker auf dem Tisch und du hast die Karte, die er ersetzt, darfst du tauschen und den Joker auf die Hand nehmen.", figuren: ["8♥", "★", "10♥"], bewegt: nil),
            .figuren(symbol: "40.circle", titel: "Die ersten 40 Augen", text: "Deine erste Auslage muss zusammen mindestens 40 Augen haben. Bube, Dame und König zählen 10, die anderen Karten ihren Wert. Du darfst dafür mehrere Sätze und Folgen auf einmal legen. Die App zeigt beim Wählen, wie viele Augen du hast und was noch fehlt.", figuren: ["10♣", "B♣", "D♣", "K♣"], bewegt: nil),
            .figuren(symbol: "plus.rectangle.on.rectangle", titel: "Anlegen", text: "Nach deiner ersten Auslage darfst du einzelne Karten an Auslagen auf dem Tisch anlegen, auch an die der anderen. Wähle eine Karte und tippe die Auslage an. So wirst du Karten los, die allein nichts wären.", figuren: ["5♥", "6♥", "7♥", "8♥"], bewegt: 3),
            .figuren(symbol: "flag.checkered", titel: "Abwerfen und gewinnen", text: "Zum Schluss wirfst du eine Karte auf die Ablage. Wer keine Karte mehr hat, gewinnt die Runde, auch schon durch Auslegen oder Anlegen der letzten Karte. Alle anderen zählen Strafpunkte: Joker 20, Ass 11, Bilder 10, sonst der Wert. Vor dem Start kannst du 3 oder 5 Runden wählen.", figuren: ["🂠", "🏁"], bewegt: 0),
            .figuren(symbol: "lightbulb", titel: "Hilfen", text: "„Sortieren“ ordnet deine Hand nach Farbe oder Wert. „Tipp“ zeigt, was ein starker Spieler jetzt tun würde, und wählt die Karten schon aus. Einen Zug zurücknehmen geht nicht, überleg also vor dem Abwerfen. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["💡", "↕️"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "arrow.down.doc", titel: "Ziehen", text: "Ziehe eine Karte vom Stapel oder nimm die oberste Ablagekarte.", figuren: ["🂡", "🂱"], bewegt: nil),
            .figuren(symbol: "rectangle.3.group", titel: "Auslegen", text: "Lege Sätze (gleicher Wert) und Folgen (aufsteigend, eine Farbe) aus. Joker ersetzen jede Karte. Die erste Auslage braucht 40 Augen.", figuren: ["🂡", "🂱", "🂻"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Ablegen und gewinnen", text: "Wirf zum Schluss eine Karte ab. Wer zuerst keine Karten mehr hat, gewinnt.", figuren: ["🂡", "🏁"], bewegt: nil),
        ])))
    }
}

/// 1.0 (M8): Rundenzahl im Blatt „Neues Spiel“. Standard bleibt eine Runde; die Partie liest den Wert beim Start.
struct RommeOptionen: View {
    static let schluessel = "romme.runden"
    static var gespeicherteRunden: Int {
        let n = UserDefaults.standard.integer(forKey: schluessel)
        return Romme.rundenWahl.contains(n) ? n : 1
    }
    @AppStorage("romme.runden") private var runden = 1
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Runden", systemImage: "arrow.triangle.2.circlepath").font(.headline).foregroundStyle(Color.accentText)
            Picker("Runden", selection: $runden) {
                Text("Eine Runde").tag(1)
                Text("3 Runden").tag(3)
                Text("5 Runden").tag(5)
            }
            .pickerStyle(.segmented).labelsHidden()
            Text(runden == 1 ? "Wer zuerst alle Karten los ist, gewinnt." : "Strafpunkte sind die Augen der Resthand. Nach der letzten Runde gewinnt, wer die wenigsten hat.")
                .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}

struct RBild: View {
    let karte: RKarte
    var markiert = false
    var klein = false
    /// Kartenbreite; nil = Grundmaß (46 pt, klein 30 pt). Die Hand gibt eine größere Breite, wenn Platz ist (F-AWS-G-005, M-003).
    var breite: CGFloat? = nil
    /// Joker: Klar Magenta wie bisher; Tinte und Salon in der Akzent-Rolle des Designs (Tinte: Textakzent, Salon: Spielart-Farbe)
    private var jokerFarbe: Color {
        switch KartenStil.aktuell.art {   // KS: folgt dem Kartensatz
        case .klar: return Color.purple
        case .tinte: return Tisch.violett   // Design-Runde 3: der Joker liegt auf hellem Kartenpapier, dort trägt Violett (Textakzent wäre auf dem Filz hell)
        case .salon: return Design.spielFarben?.flaeche ?? Color.accentText
        }
    }
    static func hoehe(_ b: CGFloat) -> CGFloat { (b * 1.43).rounded() }
    var body: some View {
        let b = breite ?? (klein ? 30 : 46)
        // F-AWS-P-016, M-025: Rang und Zeichen folgen der Kartenbreite statt der Systemschrift, so passt der Rang immer
        // (kein „…“ bei größter Schrift). Mit der Schrift wächst stattdessen die Karte selbst (RommeSpiel.kartenBreite).
        Group {
            if !karte.joker && KartenSatz.istGewaehlt {   // gewählter Kartensatz (Blatt 17/19): Kartenbild und Figuren vom Satz
                KartenIndex(rang: karte.name, zeichen: karte.symbol, farbe: KartenStil.aktuell.farbe(rot: karte.farbe >= 2), breite: b, hoehe: Self.hoehe(b))
            } else {
                VStack(spacing: 0) {
                    Text(karte.name).font(.system(size: b * 0.44, weight: .bold, design: Design.zahlDesign)).lineLimit(1).minimumScaleFactor(0.5)   // design:spielinhalt (Rang folgt der Kartengröße)
                    Text(karte.symbol).font(.system(size: b * 0.4)).lineLimit(1).minimumScaleFactor(0.5)   // design:spielinhalt (Farbsymbol)
                }
            }
        }
        .foregroundStyle(karte.joker ? jokerFarbe : KartenStil.aktuell.farbe(rot: karte.farbe >= 2))   // Designwechsel D.2: Rot und Schwarz des Kartenstils (klar: Systemrot, Label)
        .frame(width: b, height: Self.hoehe(b))
        .kartenPapier(ecke: b > 40 ? 7 : 6, breite: b, gewaehlt: markiert)
        .offset(y: markiert ? -8 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(karte.joker ? Text("Joker") : Text(verbatim: Kartensprache.name(rang: karte.name, symbol: karte.symbol)))
        .accessibilityAddTraits(markiert ? .isSelected : [])
    }
}

/// Maße der Rommé-Hand (reine Rechnung): größte Kartenbreite, bei der die ganze Hand ohne Überlappung in `hoechstHoehe` passt.
enum RommeHandMasse {
    static let abstandH: CGFloat = 4, abstandV: CGFloat = 10
    /// - Returns: Kartenbreite und Spaltenzahl.
    static func berechne(anzahl: Int, breite: CGFloat, hoechstHoehe: CGFloat, mindest: CGFloat, hoechst: CGFloat = 80, kleinsteSpalten: Int = 1) -> (breite: CGFloat, spalten: Int) {   // Blatt 16: kleinsteSpalten = 7 hält die Hand auf dem iPad in Reihen zu sieben
        let n = max(anzahl, 1)
        let maxSpalten = max(Int((breite + abstandH) / (mindest + abstandH)), 1)
        var beste: (CGFloat, Int) = (mindest, maxSpalten)
        let start = min(maxSpalten, n)
        for spalten in stride(from: start, through: min(max(kleinsteSpalten, 1), start), by: -1) {
            let b = min((breite - CGFloat(spalten - 1) * abstandH) / CGFloat(spalten), hoechst)
            let zeilen = (n + spalten - 1) / spalten
            let h = CGFloat(zeilen) * RBild.hoehe(b) + CGFloat(zeilen - 1) * abstandV
            if h <= hoechstHoehe, b >= mindest { beste = (b, spalten) } else if b >= mindest { break }
        }
        return (beste.0.rounded(.down), beste.1)
    }
}

struct RommeSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Romme
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var aufgedeckt = false
    @State private var gewaehlt: Set<Int> = []
    @State private var meldung: String?
    @State private var stufe = ComputerStufe.gespeichert("romme", standard: .schwer)
    /// 1.0 (M19): Sortierung der Hand, nur Anzeige; gemerkt für die nächste Partie.
    @AppStorage("romme.sortierung") private var sortierung: RommeSortierung = .gezogen
    /// 1.0 (S3 Jokertausch): Passt die Karte an eine Auslage und kann sie dort auch einen Joker ersetzen, wird gefragt (Index der Auslage).
    @State private var tauschFrage: Int?
    /// 1.0 (M13): Einmal-Hinweis zum Jokertausch, gemerkt auf dem Gerät.
    static let jokerHinweisSchluessel = "romme.hinweis.jokertausch"
    @Environment(\.dynamicTypeSize) private var schrift
    /// Mindestbreite der Karten: wächst mit der Schrift (F-AWS-P-016, M-025).
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// Blatt 16 (iPad, nur Tinte): Tisch bis kurz über die Hand, Hand in Reihen zu sieben, Karten 1,25-fach.
    private var breitTisch: Bool { sizeClass == .regular && Tisch.aktiv && !schrift.isAccessibilitySize }
    private var mindestBreite: CGFloat { schrift.isAccessibilitySize ? 58 : (schrift >= .xxLarge ? 50 : 46) }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, vorgabe: Romme? = nil) {   // vorgabe: nur für Bildtests
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: vorgabe ?? Romme(spieler: teilnehmer.count, runden: RommeOptionen.gespeicherteRunden, mit: &g))   // 1.0 (M8)
    }

    private var computerDran: Bool { teilnehmer[spiel.dran].computer }

    var body: some View {
        GeometryReader { g in inhalt(g.size) }
            .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
    }

    @Environment(\.regelnOeffnen) private var regelnOeffnen   // Fund 36/47: „Regeln“ im Mehr-Menü wie bei Yacht
    private func inhalt(_ g: CGSize) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: teilnehmer[spiel.dran].name, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    if let regelnOeffnen { Button("Regeln", systemImage: "book") { regelnOeffnen() } }   // Fund 36
                    if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "romme", stufe: $stufe) }   // T-084: nur mit Computer
                    NeuePartieMenuePunkt()   // F-AWS-G-019: „Neue Partie“ wie in allen Spielen
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: teilnehmer.indices.map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: Spieler.farbe($0), wert: leistenWert($0)) }, aktiv: "\(spiel.dran)").padding(.horizontal, Theme.seitenRand)
            if Tisch.aktiv && schrift.isAccessibilitySize {
                // Tinte, größte Schrift: Tisch, Hand und Knöpfe stehen zusammen in einem Scrollfenster, nichts wird verdeckt oder abgeschnitten.
                ScrollView {
                    VStack(spacing: Design.Abstand.s) {
                        tischKarte
                        unten(g)
                    }
                }
            } else {
            if breitTisch {
                GeometryReader { s in ScrollView { tischKarte(mindestHoehe: s.size.height - 40) } }
                    .frame(minHeight: 96)
                    .layoutPriority(-1)
            } else {
            ScrollView {
                tischKarte
            }
            .frame(minHeight: 96)
            .layoutPriority(-1)
            }
            unten(g)
            }
        }
        #if DEBUG
        .testEndeMelden { if let w = spiel.gewinner, !spiel.hatWeitereRunde { fertig(w) } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("romme", $spiel, pruefen: { $0.haende.count == teilnehmer.count && $0.istKonsistent })
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.gewinner != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        // Der Computer hängt am Stand, nicht am Erscheinen: Er zieht auch nach dem Laden eines Stands, in dem er am Zug ist.
        .computerZug(aktiv: spiel.gewinner == nil && computerDran, id: spiel) {
            guard spiel.gewinner == nil, computerDran else { return }
            RommeComputer.zug(&spiel, stufe: stufe.rawValue, mit: &zufall)
            meldung = nil
        }
        // 1.0 (M13): beim ersten möglichen Jokertausch kurz erklären, einmal je Gerät
        .onChange(of: spiel) { _, _ in jokerHinweis() }
        .onChange(of: aufgedeckt) { _, _ in jokerHinweis() }
        .confirmationDialog("Joker tauschen oder anlegen?", isPresented: Binding(get: { tauschFrage != nil }, set: { if !$0 { tauschFrage = nil } }), titleVisibility: .visible, presenting: tauschFrage) { m in
            Button("Joker nehmen") { if let i = gewaehlt.first { jokerTauschen(i, an: m) } }
            Button("Karte anlegen") { if let i = gewaehlt.first { anlegenAusfuehren(i, an: m) } }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    /// Kleine Karten auf dem Tisch wachsen mit der Schrift mit.
    private var tischBreite: CGFloat { schrift.isAccessibilitySize ? 40 : 30 }

    /// Karte „Auf dem Tisch“ mit Auslage, Stapel, Ablage und Meldung.
    @ViewBuilder private var tischKarte: some View { tischKarte(mindestHoehe: nil) }

    @ViewBuilder private func tischKarte(mindestHoehe: CGFloat?) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            TischUeberschrift("Auf dem Tisch")
            if spiel.tisch.isEmpty { Text("Noch nichts ausgelegt.").font(.footnote).tischHinweis() }
            ForEach(spiel.tisch.indices, id: \.self) { m in
                Button { anlegen(an: m) } label: {
                    ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 3) { ForEach(spiel.tisch[m], id: \.self) { RBild(karte: $0, klein: true, breite: tischBreite) } } }
                }.buttonStyle(.plain)
                .accessibilityHint(Text("Doppeltippen, um die gewählte Karte anzulegen oder gegen einen Joker zu tauschen"))
            }
            if breitTisch {
                // Bauplan T3-1 / Blatt 27: Stapel und Ablage als zwei Karten mittig; die Textzeile fällt weg, „Runde n von m“ bleibt.
                if spiel.rundenZiel > 1 { Text("Runde \(spiel.runde) von \(spiel.rundenZiel)").font(.footnote.weight(.semibold)).tischHinweis() }
                HStack(alignment: .top, spacing: 28) {
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Tisch.elfenbein.opacity(0.9))
                            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Tisch.violett.opacity(0.6), lineWidth: 2).padding(6))
                            .frame(width: 92, height: RBild.hoehe(92))
                        Text("Stapel · \(spiel.stapel.count)").font(.footnote).tischHinweis(zeilen: 1)
                    }
                    .accessibilityElement(children: .ignore).accessibilityLabel(Text("Stapel: \(spiel.stapel.count)"))
                    VStack(spacing: 4) {
                        if let o = spiel.ablage.last { RBild(karte: o, breite: 92) }
                        else { RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Tisch.elfenbein.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])).frame(width: 92, height: RBild.hoehe(92)) }
                        Text("Ablage").font(.footnote).tischHinweis(zeilen: 1)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
            HStack(spacing: 14) {
                if spiel.rundenZiel > 1 { Text("Runde \(spiel.runde) von \(spiel.rundenZiel)").font(.footnote.weight(.semibold)).tischHinweis() }   // 1.0 (M8)
                Text("Stapel: \(spiel.stapel.count)").font(.footnote).tischHinweis()
                if let o = spiel.ablage.last { HStack(spacing: 6) { Text("Ablage:").font(.footnote).tischHinweis(zeilen: 1); RBild(karte: o, klein: true, breite: tischBreite) } }
            }
            }
            if let m = meldung { Text(m).font(.footnote.weight(.semibold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText) }
        }.frame(maxWidth: mindestHoehe == nil ? nil : .infinity, minHeight: mindestHoehe, alignment: .topLeading).spielTischKarte().padding(.horizontal, Theme.seitenRand)
    }

    /// Knöpfe unter der Hand: nebeneinander; in Tinte bei größter Schrift untereinander, damit nichts gekürzt wird.
    private func knopfZeile<Inhalt: View>(@ViewBuilder _ inhalt: () -> Inhalt) -> some View {
        let untereinander = Tisch.aktiv && schrift.isAccessibilitySize
        let layout = untereinander ? AnyLayout(VStackLayout(spacing: Design.Abstand.s)) : AnyLayout(HStackLayout(spacing: Design.Abstand.s))
        return layout { inhalt() }
    }

    @ViewBuilder private func unten(_ g: CGSize) -> some View {
        if let w = spiel.gewinner, spiel.hatWeitereRunde {
            rundenEnde(w)   // 1.0 (M8)
        } else if let w = spiel.gewinner {
            Button("Ergebnis") { fertig(w) }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        } else if computerDran {
            Text("\(teilnehmer[spiel.dran].name) spielt …").tischHinweis().padding(.bottom, 16)
        } else if !aufgedeckt && teilnehmer.mehrereMenschen {
            SichtschutzKarte(name: teilnehmer[spiel.dran].name, farbe: Spieler.farbe(spiel.dran)) { aufgedeckt = true }
                .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        } else {
            VStack(spacing: Design.Abstand.s) {
                // Die Hand umbricht in Zeilen und nimmt sich ihre volle Höhe (B18, F-AWS-K-003): Sie liegt nicht in einem eigenen
                // Scrollfenster, sondern der Tisch darüber gibt Platz ab. So bleiben alle 14 Karten sichtbar und erreichbar.
                // F-AWS-G-005, M-003: Die Karten werden so groß, wie es die Breite und gut 40 % der Höhe erlauben, statt klein am Rand zu liegen.
                let hand = spiel.haende[spiel.dran]
                // 1.0 (M19): Knopf „Sortieren“ über der Hand. Die Auswahl hängt an den echten Handindizes, sie bleibt beim Umsortieren erhalten.
                HStack {
                    Spacer(minLength: 0)
                    Menu {
                        Picker("Sortieren", selection: $sortierung) {
                            Text("Wie gezogen").tag(RommeSortierung.gezogen)
                            Text("Nach Farbe").tag(RommeSortierung.farbe)
                            Text("Nach Wert").tag(RommeSortierung.wert)
                        }
                    } label: {
                        Label("Sortieren", systemImage: "arrow.up.arrow.down").font(.footnote.weight(.semibold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText)
                    }
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .accessibilityHint(Text("Ordnet deine Hand nach Farbe oder nach Wert"))
                }
                .padding(.horizontal, Theme.seitenRand).padding(.top, 6)
                let m = RommeHandMasse.berechne(anzahl: hand.count, breite: g.width - 2 * Theme.seitenRand, hoechstHoehe: g.height * 0.42, mindest: mindestBreite, hoechst: breitTisch ? 100 : 80, kleinsteSpalten: breitTisch ? 7 : 1)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(m.breite), spacing: RommeHandMasse.abstandH), count: m.spalten), spacing: RommeHandMasse.abstandV) {
                    ForEach(sortierung.reihenfolge(hand), id: \.self) { i in   // 1.0 (M19): Anzeige-Reihenfolge, i bleibt der Handindex
                        let k = hand[i]
                        Button { if gewaehlt.contains(i) { gewaehlt.remove(i) } else { gewaehlt.insert(i) } } label: { RBild(karte: k, markiert: gewaehlt.contains(i), breite: m.breite) }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.seitenRand).padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
                if !spiel.gezogen {
                    knopfZeile {
                        Button { tipp() } label: { Label("Tipp", systemImage: "lightbulb") }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                        Button { ziehe(true) } label: { Text("Vom Stapel ziehen").rommeKnopfText() }.buttonStyle(HauptKnopfStil())
                        if spiel.ablage.last != nil { Button { ziehe(false) } label: { Text("Ablage nehmen").rommeKnopfText() }.buttonStyle(ZweitKnopfStil()) }
                    }.padding(.horizontal, Theme.seitenRand)
                } else {
                    Text(verbatim: hinweisZeile).font(.caption).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).tischHinweis().padding(.horizontal, Theme.seitenRand)
                    knopfZeile {
                        Button { tipp() } label: { Label("Tipp", systemImage: "lightbulb") }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                            .accessibilityHint(Text("Wählt die vorgeschlagenen Karten aus und erklärt den Zug."))
                        Button { auslegen() } label: { Text("Auslegen").rommeKnopfText() }.buttonStyle(ZweitKnopfStil()).disabled(gewaehlt.count < 3)
                        // F-AWS-K-021: nicht ausgegraut (in Salon dunkel kaum lesbar), sondern mit Hinweis, wenn nicht genau eine Karte gewählt ist
                        Button { abwerfen() } label: { Text("Abwerfen").rommeKnopfText() }.buttonStyle(HauptKnopfStil())
                    }.padding(.horizontal, Theme.seitenRand)
                }
            }.padding(.bottom, 8)
        }
    }

    /// Zeile unter der Hand. 1.0 (S3 Augen): Sind mindestens drei Karten gewählt, steht dort, wie viele Augen die Auswahl
    /// als Auslage hat – vor der ersten Auslage im Verhältnis zu den nötigen 40.
    private var hinweisZeile: String {
        let erste = !spiel.hatAusgelegt[spiel.dran]
        if gewaehlt.count >= 3 {
            let hand = spiel.haende[spiel.dran]
            let karten = gewaehlt.filter { hand.indices.contains($0) }.map { hand[$0] }
            if let a = RommeRegeln.auslageAugen(karten) {
                if !erste { return String(localized: "Gewählte Auslage: \(a) Augen.") }
                return a >= Romme.mindestens ? String(localized: "Gewählte Auslage: \(a) von 40 Augen – das reicht.") : String(localized: "Gewählte Auslage: \(a) von 40 Augen – es fehlen noch \(Romme.mindestens - a).")
            }
            return String(localized: "Die gewählten Karten sind noch keine gültige Auslage.")
        }
        return erste ? String(localized: "Erste Auslage: mindestens 40 Augen.") : String(localized: "Wähle Karten, dann Auslegen – oder eine Karte und tippe eine Reihe zum Anlegen.")
    }

    /// Spielerleiste: Kartenzahl; bei mehreren Runden dazu der Zwischenstand der Strafpunkte (1.0, M8).
    private func leistenWert(_ s: Int) -> String {
        guard spiel.rundenZiel > 1 else { return "\(spiel.haende[s].count)" }
        return String(localized: "\(spiel.haende[s].count) · \(spiel.gesamt[s]) P.")
    }

    /// 1.0 (M8): Zwischenstand nach einer Runde, dann geht es mit „Nächste Runde“ weiter.
    private func rundenEnde(_ w: Int) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text("\(teilnehmer[w].name) gewinnt Runde \(spiel.runde) von \(spiel.rundenZiel).").font(.headline)
            ForEach(spiel.gesamtRangfolge, id: \.self) { s in
                HStack {
                    Text(verbatim: teilnehmer[s].name)
                    Spacer(minLength: 8)
                    Text(verbatim: "+\(spiel.strafpunkte(s))").monospacedDigit().tischHinweis(zeilen: 1)
                    Text("\(spiel.gesamt[s]) Punkte").fontWeight(.semibold).monospacedDigit()
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
            Button("Nächste Runde") {
                spiel.naechsteRunde(mit: &zufall)
                gewaehlt = []; aufgedeckt = false; meldung = nil
            }
            .buttonStyle(HauptKnopfStil())
        }
        .spielTischKarte()
        .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
    }

    private func ziehe(_ stapel: Bool) { spiel.ziehe(vomStapel: stapel, mit: &zufall); meldung = nil }

    /// F4: Vorschlag des Kerns anzeigen – Karten vorwählen, Text erklärt den Zug (auch für VoiceOver).
    private func tipp() {
        guard !computerDran, let v = RommeComputer.vorschlag(spiel) else { return }
        let h = spiel.haende[spiel.dran]
        switch v {
        case .ablageNehmen: meldung = String(localized: "Tipp: Nimm die Karte von der Ablage – sie passt zu deinen Karten.")
        case .vomStapelZiehen: meldung = String(localized: "Tipp: Zieh vom Stapel.")
        case .auslegen(let idx): gewaehlt = Set(idx); meldung = String(localized: "Tipp: Diese \(idx.count) Karten auslegen (\(idx.map { h[$0].symbol + h[$0].name }.joined(separator: " "))).")
        case .anlegen(let i, let m): gewaehlt = [i]; meldung = String(localized: "Tipp: \(h[i].symbol)\(h[i].name) an Auslage \(m + 1) anlegen.")
        case .jokerTauschen(let i, let m): gewaehlt = [i]; meldung = String(localized: "Tipp: \(h[i].symbol)\(h[i].name) gegen den Joker in Auslage \(m + 1) tauschen – tippe die Auslage an.")   // 1.0 (S3 Jokertausch)
        case .abwerfen(let i): gewaehlt = [i]; meldung = String(localized: "Tipp: \(h[i].symbol)\(h[i].name) abwerfen.")
        }
        UIAccessibility.post(notification: .announcement, argument: meldung)
    }

    private func auslegen() {
        if spiel.auslegen(Array(gewaehlt)) { gewaehlt = []; meldung = nil; if spiel.gewinner != nil { return } }
        else { meldung = spiel.hatAusgelegt[spiel.dran] ? String(localized: "Das ist keine gültige Auslage.") : String(localized: "Keine gültige Auslage oder unter 40 Augen.") }
    }

    private func anlegen(an m: Int) {
        guard !computerDran, gewaehlt.count == 1, let i = gewaehlt.first else { return }
        // 1.0 (S3 Jokertausch): Ersetzt die Karte einen Joker der Auslage, wird getauscht; passt sie zugleich zum Anlegen, wird gefragt.
        if spiel.kannJokerTauschen(i, an: m) {
            if spiel.kannAnlegen(i, an: m) { tauschFrage = m } else { jokerTauschen(i, an: m) }
            return
        }
        anlegenAusfuehren(i, an: m)
    }

    private func anlegenAusfuehren(_ i: Int, an m: Int) {
        if spiel.anlegen(i, an: m) { gewaehlt = []; meldung = nil } else { meldung = String(localized: "Die Karte passt dort nicht (oder du musst erst auslegen).") }
    }

    /// 1.0 (S3 Jokertausch): Die Karte geht in die Auslage, der Joker liegt an ihrer Stelle in der Hand und ist gleich gewählt.
    private func jokerTauschen(_ i: Int, an m: Int) {
        guard spiel.jokerTauschen(i, an: m) else { meldung = String(localized: "Die Karte ersetzt hier keinen Joker."); return }
        gewaehlt = [i]
        meldung = String(localized: "Joker genommen. Du kannst ihn auslegen, anlegen oder behalten.")
        UserDefaults.standard.set(true, forKey: Self.jokerHinweisSchluessel)
        UIAccessibility.post(notification: .announcement, argument: meldung)
    }

    /// 1.0 (M13): Einmal-Hinweis, sobald ein Mensch mit sichtbarer Hand zum ersten Mal einen Joker tauschen könnte.
    private func jokerHinweis() {
        guard !UserDefaults.standard.bool(forKey: Self.jokerHinweisSchluessel), spiel.gewinner == nil, !computerDran,
              aufgedeckt || !teilnehmer.mehrereMenschen, spiel.jokerTauschMoeglich else { return }
        UserDefaults.standard.set(true, forKey: Self.jokerHinweisSchluessel)
        meldung = String(localized: "Jokertausch: Du hast die Karte, die ein Joker auf dem Tisch ersetzt. Wähle sie und tippe die Auslage an – der Joker kommt auf deine Hand.")
        UIAccessibility.post(notification: .announcement, argument: meldung)
    }

    private func abwerfen() {
        guard gewaehlt.count == 1, let i = gewaehlt.first else { meldung = String(localized: "Wähle genau eine Karte zum Abwerfen."); return }
        if spiel.abwerfen(i) { gewaehlt = []; aufgedeckt = false; meldung = nil }
    }

    private func fertig(_ w: Int) {
        // 1.0 (M8): mehrere Runden – Gesamtwertung, wenigste Strafpunkte gewinnen
        if spiel.rundenZiel > 1 {
            let o = spiel.gesamtRangfolge
            let gleich = o.count > 1 && spiel.gesamt[o[0]] == spiel.gesamt[o[1]]
            let info = gleich ? String(localized: "Gleichstand nach \(spiel.rundenZiel) Runden") : String(localized: "\(teilnehmer[o[0]].name) gewinnt nach \(spiel.rundenZiel) Runden")
            ende(mitInhalt(SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { spiel.gesamt[$0] == 0 ? "0" : "−\(spiel.gesamt[$0])" }, info: info), sieger: w))
            return
        }
        let rest = teilnehmer.indices.filter { $0 != w }.sorted { spiel.strafpunkte($0) < spiel.strafpunkte($1) }
        let o = [w] + rest
        ende(mitInhalt(SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { $0 == w ? "0" : "−\(spiel.strafpunkte($0))" }, info: String(localized: "\(teilnehmer[w].name) gewinnt")), sieger: w))
    }

    /// Blatt 22 (EB-1): Runden (nur bei mehr als einer) und Dauer als Werte, dazu die Auslagen auf dem Tisch als Bild.
    private func mitInhalt(_ e: SpielEnde, sieger w: Int) -> SpielEnde {
        var e = e
        e.werte = (spiel.rundenZiel > 1 ? [EndeWert("Runden", "\(spiel.rundenZiel)")] : []) + [.dauer]
        // Blatt 22 (EB2): nur die Auslagen des Siegers, wenn das Spiel sie kennt (tischVon) und er welche gelegt hat; sonst alle wie in Schritt 1.
        e.bild = RommeEndeBild.bild(tisch: spiel.tisch, von: spiel.tischVon, sieger: w, siegerName: teilnehmer[w].name)
        return e
    }
}
#endif


/// Tinte: Die Schrift der Knöpfe unter der Hand sitzt nicht am Rand. Sie bekommt Luft links und rechts; bis „xxxLarge“ bleibt sie einzeilig
/// und schrumpft notfalls, bei größter Schrift bricht sie um, statt zu enden wie „Vom Stapel z…“. Klar und Salon bleiben, wie sie waren.
private struct RommeKnopfText: ViewModifier {
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    @Environment(\.dynamicTypeSize) private var schrift

    @ViewBuilder func body(content: Content) -> some View {
        if art == .tinte && schrift.isAccessibilitySize {
            content.multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).padding(.horizontal, 10).frame(maxWidth: .infinity)
        } else if art == .tinte {
            content.lineLimit(1).minimumScaleFactor(0.6).padding(.horizontal, 10).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        } else {
            content.lineLimit(1).minimumScaleFactor(0.6)
        }
    }
}

private extension View {
    func rommeKnopfText() -> some View { modifier(RommeKnopfText()) }
}
