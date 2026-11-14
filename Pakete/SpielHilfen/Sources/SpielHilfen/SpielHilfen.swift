// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Sagt VoiceOver einen kurzen Text an (z. B. was ein Tipp gemacht hat); ohne VoiceOver wirkungslos.
public func ansage(_ text: String) { AccessibilityNotification.Announcement(text).post() }

// MARK: Menschen und Sicht

public extension Array where Element == SpielTeilnehmer {
    /// Plätze der menschlichen Spieler.
    var menschen: [Int] { indices.filter { !self[$0].computer } }
    /// Ob mehrere Menschen an einem Gerät spielen (dann braucht es die Übergabe-Seite).
    var mehrereMenschen: Bool { menschen.count > 1 }
    /// Wessen Hand/Bogen unten gezeigt wird: der Spieler am Zug, wenn er ein Mensch ist, sonst der erste Mensch.
    func sicht(amZug: Int) -> Int { self[amZug].computer ? (menschen.first ?? 0) : amZug }
}

// MARK: Übergabe-Seite

/// Deckt das Spiel mit einer „Gerät weitergeben“-Seite ab, sobald bei mehreren Menschen ein anderer Mensch an die Reihe kommt.
/// Steuerung nur über `amZug`; die Seite merkt sich selbst, für wen sie schon bestätigt wurde. `aktiv: false` schaltet sie ab (z. B. nach Spielende).
public struct UebergabeSeite: ViewModifier {
    let teilnehmer: [SpielTeilnehmer]
    let amZug: Int
    let aktiv: Bool
    /// `true`: Es gibt verdeckte Informationen (Handkarten) – immer „Bereit“ verlangen. `false`: offenes Spiel, die Meldung blendet sich selbst aus (einstellbar).
    let geheim: Bool
    @State private var bestaetigtFuer: Int?
    @AppStorage(WeitergabeEinstellung.schluessel) private var automatisch = true

    private var braucht: Bool { aktiv && teilnehmer.mehrereMenschen && !teilnehmer[amZug].computer && bestaetigtFuer != amZug }

    public func body(content: Content) -> some View {
        ZStack {
            content
                .accessibilityHidden(braucht)
            if braucht {
                Group {
                    switch Design.art {
                    case .klar:
                VStack(spacing: Design.Abstand.l) {
                    Text("Gerät weitergeben").font(.title2.bold())
                    Text("\(teilnehmer[amZug].name) ist dran.").foregroundStyle(.secondary)
                    Button("Bereit") { bestaetigtFuer = amZug }.buttonStyle(HauptKnopfStil()).padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemBackground))   // voll deckend: nichts schimmert durch
                    case .tinte:
                        // Design-Runde 3: Übergabe auf dem Filz des Spiels, mittig: Bild der Person, „… ist dran.“, unten der eine Knopf
                        let name = teilnehmer[amZug].name
                        VStack(spacing: Design.Abstand.m) {
                            Spacer(minLength: 0)
                            SpielerAvatar(name: name, farbe: Spieler.farbe(amZug), groesse: 96).accessibilityHidden(true)
                            Text("Gerät weitergeben").designLabel(Color.schrift) .padding(.top, Design.Abstand.m)   // Fund 6: volle Schriftfarbe statt Grau
                            Text("\(name) ist dran.").font(Design.Schrift.serif(34, gewicht: .medium, relativ: .title, hoechstens: 1.2))
                                .foregroundStyle(Color.schrift).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            if geheim {
                                Text("Nur \(name) darf jetzt hinsehen.").font(Design.Schrift.serif(18, gewicht: .light, relativ: .body, kursiv: true))
                                    .foregroundStyle(Color.schriftZweit).multilineTextAlignment(.center)
                            }
                            Spacer(minLength: 0)
                            Spacer(minLength: 0)
                            Button("Ich bin \(name)") { bestaetigtFuer = amZug }.buttonStyle(HauptKnopfStil())
                        }
                        .padding(Theme.seitenRand)
                        .iPadSpalte()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aufTisch()   // voll deckend: Filz in der Spielart-Farbe, helle Schrift
                    case .salon:
                        // Farbfeld über die ganze Seite mit dem Namen als Schlagzeile („Ben.“)
                        let farben = Design.spielFarben
                        let schrift = farben?.aufFlaeche ?? Design.werte.aufHuelleFlaeche.color
                        let flaeche = farben?.flaecheFuerKleineSchrift ?? Color.hinweisFlaecheHuelle
                        VStack(alignment: .leading, spacing: Design.Abstand.m) {
                            Text("Gerät weitergeben").designLabel(schrift).opacity(0.9)
                            Text(verbatim: "\(teilnehmer[amZug].name).").font(Design.Schrift.serif(84, gewicht: .bold, relativ: .largeTitle, hoechstens: 1.15)).tracking(-2.5)
                                .lineLimit(2).minimumScaleFactor(0.35).accessibilityLabel(Text("\(teilnehmer[amZug].name) ist dran."))
                            Text("\(teilnehmer[amZug].name) ist dran.").font(Design.Schrift.serif(20, gewicht: .light, relativ: .title3, kursiv: true))
                            Button("Bereit") { bestaetigtFuer = amZug }.buttonStyle(HauptKnopfStil())
                                .environment(\.knopfFarben, (flaeche: schrift, schrift: flaeche)).padding(.top, Design.Abstand.l)
                        }
                        .foregroundStyle(schrift)
                        .padding(Theme.seitenRand)
                        .iPadSpalte()
                        .frame(maxHeight: .infinity).background(flaeche)
                    }
                }
                .accessibilityAddTraits(.isModal)
                .onTapGesture { if !geheim && automatisch { bestaetigtFuer = amZug } }   // offenes Spiel: Tippen überspringt das Warten
                .task(id: amZug) {
                    guard !geheim, automatisch else { return }
                    try? await Task.sleep(for: WeitergabeEinstellung.anzeigedauer)
                    if !Task.isCancelled { bestaetigtFuer = amZug }
                }
            }
        }
    }
    public init(teilnehmer: [SpielTeilnehmer], amZug: Int, aktiv: Bool = true, geheim: Bool = true) { self.teilnehmer = teilnehmer; self.amZug = amZug; self.aktiv = aktiv; self.geheim = geheim }
}

public extension View {
    /// `geheim`: `true`, wenn das Spiel verdeckte Informationen hat (Handkarten); `false` bei offenen Spielen (blendet sich selbst aus).
    func uebergabeSeite(teilnehmer: [SpielTeilnehmer], amZug: Int, aktiv: Bool = true, geheim: Bool = true) -> some View {
        modifier(UebergabeSeite(teilnehmer: teilnehmer, amZug: amZug, aktiv: aktiv, geheim: geheim))
    }
}

// MARK: Zugknöpfe (Brettspiele)

/// Zwei Knöpfe für Brettspiele: „Zug zurück“ (nimmt auch die Antwort des Computers mit zurück) und „Tipp“.
public struct ZugKnoepfe: View {
    let kannZurueck: Bool
    let tippMoeglich: Bool
    let rechnet: Bool
    let zurueck: () -> Void
    let tipp: () -> Void
    public init(kannZurueck: Bool, tippMoeglich: Bool = true, rechnet: Bool = false, zurueck: @escaping () -> Void, tipp: @escaping () -> Void) {
        self.kannZurueck = kannZurueck; self.tippMoeglich = tippMoeglich; self.rechnet = rechnet; self.zurueck = zurueck; self.tipp = tipp
    }
    public var body: some View {
        HStack(spacing: Design.Abstand.m) {
            Button(action: zurueck) { Label("Zug zurück", systemImage: "arrow.uturn.backward") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!kannZurueck || rechnet)
            Button(action: tipp) { if rechnet { ProgressView() } else { Label("Tipp", systemImage: "lightbulb") } }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!tippMoeglich || rechnet)
        }
    }
}

// MARK: Rangliste

public extension SpielEnde {
    /// Baut das Ende aus Punktständen: sortiert, vergibt gleiche Plätze bei Gleichstand.
    static func nachPunkten(namen: [String], punkte: [Int], hoeherIstBesser: Bool = true, info: String? = nil) -> SpielEnde {
        let rang = Rangliste.reihenfolge(punkte: punkte, hoeherIstBesser: hoeherIstBesser)
        return SpielEnde(reihenfolge: rang.map { namen[$0] }, punkte: rang.map { "\(punkte[$0])" },
                         plaetze: Rangliste.plaetze(punkte: punkte, reihenfolge: rang), info: info)
    }
}

// MARK: Tageskarte mit Serie

/// 1.0 (P5): Karte für die Startseite eines Spiels mit Tagesrätsel: „Tagesrätsel heute“, Haken wenn gelöst, Serie in Tagen,
/// Knopf „Spielen“ und nach dem Lösen „Teilen“. Einsatz: `.mitStartInhalt { aktionen in TagesKarte(spiel: "farbflut", spielName: "Farbfüller", aktionen: aktionen) }`.
/// „Spielen“ merkt das Tagesrätsel vor (`Tagesraetsel.wunschMerken`) und startet über den Rahmen; das Spiel holt den Wunsch beim Start mit
/// `Tagesraetsel.wunschAbholen` ab. Gelöste Tage und Serie schreibt das Spiel beim Lösen mit `TagesSerie.melden`.
public struct TagesKarte: View {
    let spiel: String
    let spielName: String
    let titel: LocalizedStringKey
    let aktionen: SpielStartAktionen
    @Environment(\.scenePhase) private var szene
    /// Zählt hoch, wenn die Karte wieder erscheint oder die App aus dem Hintergrund kommt (Tageswechsel, frisch gelöst): Karte neu lesen.
    @State private var stand = 0
    /// Design-Runde 3 (Tinte): Die Karte ist eine Wahl. Angewählt startet der eine Knopf „Spielen“ der Seite das Tagesrätsel.
    @State private var gewaehlt = false
    @Environment(\.designArt) private var art

    public init(spiel: String, spielName: String, titel: LocalizedStringKey = "Tagesrätsel heute", aktionen: SpielStartAktionen) {
        self.spiel = spiel; self.spielName = spielName; self.titel = titel; self.aktionen = aktionen
    }

    public var body: some View {
        let _ = stand
        let heute = Tagesraetsel.tag()
        let geloest = TagesSerie.geloest(spiel: spiel, tag: heute)
        let serie = TagesSerie.serie(spiel: spiel)
        let ergebnis = TagesSerie.ergebnis(spiel: spiel, tag: heute)
        if art == .tinte {
            wahlKarte(geloest: geloest, serie: serie, ergebnis: ergebnis)
        } else {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            HStack(alignment: .firstTextBaseline) {
                Label(titel, systemImage: "calendar").font(.headline).foregroundStyle(Color.accentText)
                Spacer()
                if geloest { Label("Gelöst", systemImage: "checkmark.seal.fill").font(.subheadline.weight(.semibold)).foregroundStyle(.green) }
            }
            if geloest, let e = ergebnis, !e.isEmpty { Text(verbatim: e).font(.subheadline) }
            Label(TagesSerie.serieText(serie), systemImage: "flame.fill").font(.subheadline).foregroundStyle(serie > 0 ? Color.orange : Color.secondary)
            HStack(spacing: Design.Abstand.m) {
                Button(geloest ? "Noch einmal spielen" : "Spielen") { Tagesraetsel.wunschMerken(spiel: spiel); aktionen.neu() }
                    .buttonStyle(HauptKnopfStil())
                if geloest, TeilenFreigabe.erlaubt() {
                    ShareLink(item: TagesSerie.teilenText(spielName: spielName, ergebnis: ergebnis ?? "", serie: serie)) { Label("Teilen", systemImage: "square.and.arrow.up") }
                        .zweitKnopf()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
        .accessibilityElement(children: .contain)
        .onAppear { stand += 1 }
        .onChange(of: szene) { _, _ in stand += 1 }
        }
    }

    /// Meldet dem Rahmen, ob „Spielen“ das Tagesrätsel starten soll.
    private func vormerken() {
        let spiel = spiel
        if gewaehlt && !aktionen.standVorhanden { aktionen.vormerken({ Tagesraetsel.wunschMerken(spiel: spiel) }) } else { aktionen.vormerken(nil) }
    }

    /// Tinte: Zeile zum An- und Abwählen ohne eigenen Spielen-Knopf (auf der Seite gibt es genau einen Hauptknopf).
    private func wahlKarte(geloest: Bool, serie: Int, ergebnis: String?) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Button {
                gewaehlt.toggle(); vormerken()
            } label: {
                HStack(spacing: Design.Abstand.m) {
                    Image(systemName: gewaehlt ? "checkmark.circle.fill" : "circle").font(.title2)
                        .foregroundStyle(gewaehlt ? Color.schrift : Color.schriftZweit).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titel).font(.headline).foregroundStyle(Color.schrift)
                        Text(verbatim: geloest ? (ergebnis.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "Gelöst")) : TagesSerie.serieText(serie))
                            .font(.footnote).foregroundStyle(Color.schriftZweit)
                    }
                    Spacer(minLength: 8)
                    if geloest {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).accessibilityLabel(Text("Gelöst"))
                    } else if serie > 0 {
                        Label(TagesSerie.serieText(serie), systemImage: "flame.fill").labelStyle(.iconOnly).foregroundStyle(Color.orange).accessibilityHidden(true)
                    }
                }
                .frame(minHeight: 56).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(aktionen.standVorhanden)   // Fund 177: „Weiterspielen“ setzt die laufende Partie fort und ignorierte die Wahl still
            .opacity(aktionen.standVorhanden ? 0.5 : 1)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(gewaehlt ? [.isButton, .isSelected] : .isButton)
            if aktionen.standVorhanden {
                Text("Gilt erst, wenn die laufende Partie zu Ende ist.").font(.footnote).foregroundStyle(Color.schriftZweit)
            }
            if geloest, TeilenFreigabe.erlaubt() {
                ShareLink(item: TagesSerie.teilenText(spielName: spielName, ergebnis: ergebnis ?? "", serie: serie)) { Label("Teilen", systemImage: "square.and.arrow.up") }
                    .zweitKnopf()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
        .onAppear { stand += 1; vormerken() }
        .onChange(of: szene) { _, _ in stand += 1 }
    }
}
#endif

/// Reine Rechenhilfen (ohne Oberfläche, testbar).
public enum Rangliste {
    public static func reihenfolge(punkte: [Int], hoeherIstBesser: Bool) -> [Int] {
        punkte.indices.sorted { a, b in punkte[a] == punkte[b] ? a < b : (hoeherIstBesser ? punkte[a] > punkte[b] : punkte[a] < punkte[b]) }
    }
    /// Platz je Eintrag der Reihenfolge; gleiche Punkte = gleicher Platz (1, 1, 3 …).
    public static func plaetze(punkte: [Int], reihenfolge: [Int]) -> [Int] {
        reihenfolge.map { i in reihenfolge.firstIndex { punkte[$0] == punkte[i] }! + 1 }
    }
}

// MARK: Tier-Motive (Paarsuche, Pechvogel, Flinkhand)

public enum TierMotive {
    public static let symbole = ["tortoise.fill", "hare.fill", "bird.fill", "fish.fill", "ant.fill", "ladybug.fill", "pawprint.fill", "leaf.fill", "cat.fill", "dog.fill", "lizard.fill", "teddybear.fill", "tree.fill", "carrot.fill", "fossil.shell.fill"]
    #if canImport(UIKit)
    public static let farben: [Color] = [.green, .orange, .blue, .teal, .brown, .red, .purple, .mint, .pink, .indigo, .cyan, .yellow, .gray, .orange.opacity(0.6), .brown.opacity(0.6)]
    #endif
}

// MARK: Tagesrätsel und Bestleistungen

/// Tagesrätsel: Alle Spieler bekommen am selben Kalendertag dasselbe Rätsel (Startwert aus dem Datum).
public enum Tagesraetsel {
    public static func tag(_ datum: Date = Date()) -> String {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: datum)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
    /// Der Tag, an dem das laufende Tagesrätsel eines Spiels begonnen wurde. Wer kurz vor Mitternacht anfängt und danach fertig wird,
    /// bekommt das Ergebnis dem Rätsel seines Starttags gutgeschrieben, nicht dem von morgen.
    private static func startSchluessel(_ spiel: String) -> String { "partie.tagesstart.\(spiel)" }
    public static func merkeStart(spiel: String, datum: Date = Date(), defaults: UserDefaults = .standard) {
        // Nur schreiben, wenn sich etwas ändert: Wer das aus einem init/body heraus ruft, löste sonst mit jedem Aufruf eine
        // UserDefaults-Änderung aus, die @AppStorage-Ansichten neu rechnet (Endlosschleife, T-055).
        let neu = tag(datum)
        if defaults.string(forKey: startSchluessel(spiel)) != neu { defaults.set(neu, forKey: startSchluessel(spiel)) }
    }
    /// Starttag des laufenden Tagesrätsels, sonst der heutige Tag.
    public static func startTag(spiel: String, jetzt: Date = Date(), defaults: UserDefaults = .standard) -> String {
        defaults.string(forKey: startSchluessel(spiel)) ?? tag(jetzt)
    }
    /// Startwert für `ZufallsQuelle(seed:)`, je Spiel und Tag verschieden. Rein rechnerisch; den Starttag merkt `merkeStart`.
    public static func seed(spiel: String, datum: Date = Date()) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for b in (spiel + tag(datum)).utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return h == 0 ? 1 : h
    }
}

/// Bestleistungen, auf dem Gerät gespeichert. Standard: kleiner ist besser (Züge, Sekunden); mit `hoeherIstBesser` für Punkte.
public enum Bestleistung {
    private static func k(_ schluessel: String) -> String { "partie.best.\(schluessel)" }
    public static func lesen(_ schluessel: String) -> Int? {
        let w = UserDefaults.standard.integer(forKey: k(schluessel)); return w > 0 ? w : nil
    }
    /// Speichert den Wert, wenn er besser ist als der bisherige; `true` bei neuem Rekord.
    @discardableResult
    public static func melden(_ schluessel: String, wert: Int, hoeherIstBesser: Bool = false) -> Bool {
        guard wert > 0 else { return false }
        if let alt = lesen(schluessel), hoeherIstBesser ? alt >= wert : alt <= wert { return false }
        UserDefaults.standard.set(wert, forKey: k(schluessel)); return true
    }

    /// Schlüssel für Normal- oder Tagesrätsel eines Spiels (Variante z. B. Größe).
    public static func schluessel(_ spiel: String, variante: String = "", tages: Bool) -> String {
        tages ? tagesSchluessel(spiel, variante: variante, tag: Tagesraetsel.tag()) : (variante.isEmpty ? spiel : "\(spiel).\(variante)")
    }

    /// RT-005: Das Tagesrätsel hängt von der Variante ab (z. B. Größe), also auch die Tages-Bestleistung; sonst mischen sich die Größen.
    /// Ohne Variante bleibt der Schlüssel wie bisher (`spiel.tag.TAG`), gespeicherte Werte gehen nicht verloren.
    static func tagesSchluessel(_ spiel: String, variante: String, tag: String) -> String {
        variante.isEmpty ? "\(spiel).tag.\(tag)" : "\(spiel).tag.\(tag).\(variante)"
    }

    /// Schlüssel für das Ergebnis eines gerade beendeten Spiels: bei Tagesrätseln der Starttag, nicht der Tag des Endes.
    public static func ergebnisSchluessel(_ spiel: String, variante: String = "", tages: Bool) -> String {
        tages ? tagesSchluessel(spiel, variante: variante, tag: Tagesraetsel.startTag(spiel: spiel)) : (variante.isEmpty ? spiel : "\(spiel).\(variante)")
    }

    /// Meldet den Wert und liefert den Zusatz für den Endbildschirm (leer oder „ · Neue Bestleistung!“).
    public static func zusatz(_ spiel: String, variante: String = "", tages: Bool, wert: Int, hoeherIstBesser: Bool = false) -> String {
        let neu = melden(ergebnisSchluessel(spiel, variante: variante, tages: tages), wert: wert, hoeherIstBesser: hoeherIstBesser)
        let tag = tages ? " · " + String(localized: "Tagesrätsel") : ""
        return tag + (neu ? " · " + String(localized: "Neue Bestleistung!") : "")
    }
}

public extension Tagesraetsel {
    /// Zufallsquelle, die am selben Tag und für dasselbe Spiel/dieselbe Variante dieselbe Folge liefert.
    static func generator(spiel: String, variante: String = "") -> ZufallsQuelle {
        merkeStart(spiel: spiel)
        return reinerGenerator(spiel: spiel, variante: variante)
    }
    /// Wie `generator`, aber ohne Nebenwirkung (merkt den Starttag nicht): für `init` von Ansichten, die dabei nichts schreiben dürfen.
    static func reinerGenerator(spiel: String, variante: String = "") -> ZufallsQuelle {
        ZufallsQuelle(seed: seed(spiel: spiel + variante))
    }
}

public extension Tagesraetsel {
    private static func wunschSchluessel(_ spiel: String) -> String { "partie.tageswunsch.\(spiel)" }
    /// So lange gilt ein vorgemerkter Wunsch: Bricht jemand die Rückfrage „Laufende Partie verwerfen?“ ab, soll aus einem späteren
    /// „Neues Spiel“ nicht plötzlich das Tagesrätsel werden.
    static let wunschDauer: TimeInterval = 120
    /// 1.0 (P5): Die Tageskarte der Startseite merkt vor, dass die nächste Partie das Tagesrätsel sein soll (einmalig).
    static func wunschMerken(spiel: String, jetzt: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(jetzt.timeIntervalSince1970, forKey: wunschSchluessel(spiel))
    }
    /// Holt den Wunsch ab (`true` genau einmal und nur kurz nach dem Vormerken): so bleibt eine normale Partie über „Neues Spiel“ normal.
    static func wunschAbholen(spiel: String, jetzt: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        guard let seit = defaults.object(forKey: wunschSchluessel(spiel)) as? Double else { return false }
        defaults.removeObject(forKey: wunschSchluessel(spiel))
        return jetzt.timeIntervalSince1970 - seit < wunschDauer
    }
}

/// 1.0 (P5): Gelöste Tagesrätsel und Serie je Spiel, auf dem Gerät gespeichert (`UserDefaults`, Tag → Ergebnistext).
/// Die Serie zählt die Tage in Folge bis heute; ist heute noch offen, lebt sie weiter, wenn gestern gelöst wurde.
public enum TagesSerie {
    private static func schluessel(_ spiel: String) -> String { "partie.tagesserie.\(spiel)" }
    /// So viele gelöste Tage bleiben gespeichert (ältere fallen weg; die Serie ist praktisch nie länger).
    static let behalten = 400

    /// Alle gelöst gemeldeten Tage („20261113“) mit dem Ergebnistext.
    public static func gespeichert(spiel: String, defaults: UserDefaults = .standard) -> [String: String] {
        defaults.dictionary(forKey: schluessel(spiel)) as? [String: String] ?? [:]
    }

    /// Meldet den Tag als gelöst. Das erste Ergebnis eines Tages bleibt stehen (ein zweiter Lauf desselben Tages ändert nichts).
    public static func melden(spiel: String, tag: String = Tagesraetsel.tag(), ergebnis: String = "", defaults: UserDefaults = .standard) {
        var d = gespeichert(spiel: spiel, defaults: defaults)
        if d[tag] == nil { d[tag] = ergebnis }
        if d.count > behalten { for k in d.keys.sorted().prefix(d.count - behalten) { d.removeValue(forKey: k) } }
        defaults.set(d, forKey: schluessel(spiel))
    }

    public static func geloest(spiel: String, tag: String = Tagesraetsel.tag(), defaults: UserDefaults = .standard) -> Bool {
        gespeichert(spiel: spiel, defaults: defaults)[tag] != nil
    }

    public static func ergebnis(spiel: String, tag: String = Tagesraetsel.tag(), defaults: UserDefaults = .standard) -> String? {
        gespeichert(spiel: spiel, defaults: defaults)[tag]
    }

    /// Tage in Folge, gezählt von heute (bzw. von gestern, wenn heute noch offen ist) rückwärts.
    public static func serie(spiel: String, heute: Date = Date(), defaults: UserDefaults = .standard) -> Int {
        let d = gespeichert(spiel: spiel, defaults: defaults)
        let kalender = Calendar(identifier: .gregorian)
        var tag = heute
        if d[Tagesraetsel.tag(tag)] == nil {
            guard let gestern = kalender.date(byAdding: .day, value: -1, to: tag) else { return 0 }
            tag = gestern
        }
        var n = 0
        while d[Tagesraetsel.tag(tag)] != nil {
            n += 1
            guard let davor = kalender.date(byAdding: .day, value: -1, to: tag) else { break }
            tag = davor
        }
        return n
    }

    public static func serieText(_ n: Int) -> String {
        switch n {
        case 0: String(localized: "Noch keine Serie")
        case 1: String(localized: "Serie: 1 Tag")
        default: String(localized: "Serie: \(n) Tage")
        }
    }

    /// Text zum Teilen nach dem Lösen, z. B. „Farbfüller · Tagesrätsel 13.11.2026: In 14 von 20 Zügen geschafft · Serie: 3 Tage“.
    public static func teilenText(spielName: String, ergebnis: String, serie: Int, datum: Date = Date()) -> String {
        let tag = datum.formatted(date: .numeric, time: .omitted)
        var t = "\(spielName) · " + String(localized: "Tagesrätsel \(tag)")
        if !ergebnis.isEmpty { t += ": " + ergebnis }
        if serie > 0 { t += " · " + serieText(serie) }
        return t
    }
}
