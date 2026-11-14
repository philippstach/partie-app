// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Deine Startseite: frei belegbare Kacheln wie auf dem iOS-Home-Bildschirm. Reihenfolge und Auswahl bleiben gespeichert.
@Observable @MainActor
final class StartLayout {
    private static let schluessel = "startLayout"
    static let vorgabe = ["yacht", "viererreihe", "sudoku", "solitaer", "minensuche", "schocken", "wortpfeil", "10k"]
    var ids: [String]

    init() {
        if let s = UserDefaults.standard.string(forKey: Self.schluessel) { ids = s.split(separator: ",").map(String.init) }
        else {
            let alle = SpielKatalog.spielbar.map(\.id)
            // Vorgabe in früheren Kennungen; gespeichert wird die heutige Kennung
            let v = Self.vorgabe.map(SpielKatalog.kennung).filter(alle.contains)
            ids = v.count >= 6 ? v : Array(alle.prefix(8))
        }
    }
    /// Funde 134/146 (Philipp 14.11.: eine gemeinsame Liste): Die Reihe der Startseite und „Spiele > Favoriten“ sind dieselbe Liste.
    /// Jede Änderung hier schreibt auch die Favoriten und meldet es; `Favoriten` schreibt umgekehrt das Layout.
    private func sichern() {
        UserDefaults.standard.set(ids.joined(separator: ","), forKey: Self.schluessel)
        UserDefaults.standard.set(ids, forKey: Favoriten.schluessel)
        FavoritenAktionen.aktualisieren(ids)
        NotificationCenter.default.post(name: .partieFavoritenGeaendert, object: nil)
    }
    /// Gespeicherte Liste des Layouts oder nil, solange nie eine gespeichert wurde.
    static func gespeichert() -> [String]? {
        UserDefaults.standard.string(forKey: schluessel).map { $0.split(separator: ",").map(String.init) }
    }

    // MARK: Favoriten aus der Einführung (Fund 4 / 44, Ursache bugs/FEHLER-einfuehrung-favoriten.md)
    /// ANNAHME (Frage 1 und 3 an Philipp offen): Die Auswahl der Einführung ERSETZT die Vorgabe, und zwar nur beim Erststart
    /// (noch kein `startLayout` gespeichert). Umstellen: `ersetzt = false` stellt die Auswahl VOR die Vorgabe;
    /// `nurErststart = false` übernimmt auch bei vorhandenem eigenem `startLayout`.
    static let ersetzt = true
    static let nurErststart = true

    /// Wird beim Abschluss der Einführung (Knopf und „Überspringen“) mit `Favoriten.ids` aufgerufen. Ohne Auswahl bleibt die Vorgabe.
    static func ausEinfuehrung(_ favoriten: [String]) {
        guard !favoriten.isEmpty else { vorgabeAlsFavoriten(); return }
        let ud = UserDefaults.standard
        if nurErststart, ud.string(forKey: schluessel) != nil { return }
        let alle = SpielKatalog.spielbar.map(\.id)
        var neu = favoriten.map(SpielKatalog.kennung).filter(alle.contains)
        guard !neu.isEmpty else { return }
        if !ersetzt {
            let vorn = Set(neu)
            neu += vorgabe.map(SpielKatalog.kennung).filter { alle.contains($0) && !vorn.contains($0) }
        }
        ud.set(neu.joined(separator: ","), forKey: schluessel)
        ud.set(neu, forKey: Favoriten.schluessel)
        NotificationCenter.default.post(name: .partieStartLayoutGeaendert, object: nil)
        NotificationCenter.default.post(name: .partieFavoritenGeaendert, object: nil)
    }
    /// Einführung ohne Auswahl: Die Vorgabe der Startseite gilt dann auch als Favoriten (eine Liste, keine zwei).
    static func vorgabeAlsFavoriten() {
        let ud = UserDefaults.standard
        guard ud.stringArray(forKey: Favoriten.schluessel) == nil || ud.stringArray(forKey: Favoriten.schluessel)?.isEmpty == true else { return }
        let alle = SpielKatalog.spielbar.map(\.id)
        let v = (gespeichert() ?? vorgabe.map(SpielKatalog.kennung)).filter(alle.contains)
        guard !v.isEmpty else { return }
        ud.set(v, forKey: Favoriten.schluessel)
        NotificationCenter.default.post(name: .partieFavoritenGeaendert, object: nil)
    }
    /// Liest die gespeicherte Liste neu (die Startseite liegt schon unter dem Einführungs-Cover und hat sie früher gelesen).
    func neuLaden() {
        guard let s = UserDefaults.standard.string(forKey: Self.schluessel) else { return }
        ids = s.split(separator: ",").map(String.init)
    }
    func hinzufuegen(_ id: String) { if !ids.contains(id) { ids.append(id); sichern() } }
    func entfernen(_ id: String) { ids.removeAll { $0 == id }; sichern() }
    /// Für VoiceOver und Tastatur: um `schritte` Plätze verschieben (negativ = nach vorn).
    func verschiebe(_ id: String, um schritte: Int) {
        guard let von = ids.firstIndex(of: id) else { return }
        let nach = min(max(von + schritte, 0), ids.count - 1)
        guard nach != von else { return }
        ids.remove(at: von); ids.insert(id, at: nach); sichern()
    }
    func verschieben(_ id: String, vor ziel: String) {
        guard id != ziel, let von = ids.firstIndex(of: id), let nach = ids.firstIndex(of: ziel) else { return }
        ids.remove(at: von); ids.insert(id, at: nach); sichern()
    }
}

extension Notification.Name {
    static let partieStartLayoutGeaendert = Notification.Name("partieStartLayoutGeaendert")
    static let partieFavoritenGeaendert = Notification.Name("partieFavoritenGeaendert")
}

struct StartSeite: View {
    let oeffnen: (String) -> Void
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(StatistikDienst.self) private var statistik
    @Environment(TurnierDienst.self) private var turnier
    @State private var turnierBlatt = false
    @AppStorage(Modi.kinderKey) private var kinder = false
    @AppStorage(Modi.ruheKey) private var ruhe = false
    @AppStorage(Modi.tagesaufgabeKey) private var tagesaufgabeAn = true
    @AppStorage(Modi.gesperrtKey) private var gesperrt = ""
    @State private var layout = StartLayout()
    @State private var bearbeiten = false
    @State private var einstellungen = false
    @State private var spielerSeite = false
    @State private var statistikSeite = false
    @State private var suche = false
    @State private var spieleListe = false
    @State private var hinzu = false
    @State private var glossar = false
    @State private var wackeln = false
    /// Designwechsel: Filter und Spielerzahl, mit denen die Sammlung aus Tinte/Salon geöffnet wird (klar: immer „Alle“).
    @State private var sammlungFilter: SammlungStart.Filter = .alle
    @State private var sammlungSpielerzahl = 0
    @Environment(\.accessibilityReduceMotion) private var weniger
    @Environment(\.horizontalSizeClass) private var breit
    @Environment(\.dynamicTypeSize) private var schrift

    /// Breite Fenster (iPad): größere Kacheln und breitere Kachelfläche; Kopf, Karten und Statistik bleiben in der schmalen Spalte.
    private var gross: Bool { breit == .regular }
    private var kante: CGFloat { gross ? 104 : 68 }   // M-014: Kachel füllt die Rasterzelle (iPad), weniger Leerraum
    private var spaltenBreite: CGFloat { gross ? 900 : Theme.wideColumnWidth }

    private var kacheln: [any SpielModul] {
        _ = kinder; _ = gesperrt
        let sichtbar = SpielKatalog.sichtbar
        return layout.ids.compactMap { id in sichtbar.first { $0.id == id } }
    }
    private var weiterspielen: [any SpielModul] {
        OffenesSpiel.alle().compactMap { id in SpielKatalog.sichtbar.first { $0.id == id } }.filter { !kinder || !Modi.gesperrt.contains($0.id) }.prefix(3).map { $0 }
    }
    /// Tinte: Stapel der offenen Partien zum Wischen. Dieselbe Quelle und Reihenfolge wie `weiterspielen`, aber bis zu sechs.
    private var offenePartien: [any SpielModul] {
        OffenesSpiel.alle().compactMap { id in SpielKatalog.sichtbar.first { $0.id == id } }.filter { !kinder || !Modi.gesperrt.contains($0.id) }.prefix(6).map { $0 }
    }

    @ScaledMetric(relativeTo: .body) private var knopfReserve: CGFloat = Theme.hauptKnopfHoehe + 40
    /// Designwechsel: je Design ein eigener Aufbau, dieselben Daten und Blätter (`StartModell`).
    @ViewBuilder private var aufbau: some View {
        switch Design.art {
        case .klar: klar
        case .tinte: StartTinte(m: modell)
        case .salon: StartSalon(m: modell)
        }
    }

    private var modell: StartModell {
        StartModell(kacheln: kacheln, weiterspielen: weiterspielen, layout: layout, bearbeiten: $bearbeiten,
                    tagesaufgabe: Tagesaufgabe.sichtbar(ruhe: ruhe, kinder: kinder, an: tagesaufgabeAn), turnier: turnier.aktuell,
                    oeffnen: oeffnen, weiter: fortsetzen, zeigen: zeigen, offen: offenePartien)
    }

    /// „Weiterspielen“: gleich in die laufende Partie (TestFlight 13.11., Nr. 6), nicht erst auf die Spielseite.
    private func fortsetzen(_ id: String) {
        OffenesSpiel.direktMerken(SpielKatalog.kennung(id))
        oeffnen(id)
    }

    private func zeigen(_ ziel: StartZiel) {
        switch ziel {
        case .einstellungen: einstellungen = true
        case .spieler: spielerSeite = true
        case .statistik: statistikSeite = true
        case .suche: suche = true
        case .hinzufuegen: hinzu = true
        case .glossar: glossar = true
        case .turnier: turnierBlatt = true
        case .zufall: if let m = SpielKatalog.sichtbar.randomElement() { oeffnen(m.id) }
        case .sammlung(let filter, let spielerzahl):
            sammlungFilter = filter; sammlungSpielerzahl = spielerzahl; spieleListe = true
        }
    }

    /// „Klar & Glas“: der bisherige Aufbau (Spieleabend), unverändert.
    private var klar: some View {
        ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    kopf.schmal()
                    StartTitel("Partie").padding(.bottom, 6).schmal()
                    if Tagesaufgabe.sichtbar(ruhe: ruhe, kinder: kinder, an: tagesaufgabeAn) { TagesaufgabeKarte(oeffnen: oeffnen).schmal() }
                    if let t = turnier.aktuell { TurnierKarte(turnier: t) { turnierBlatt = true }.colorScheme(.light).schmal() }
                    else if !kinder { SpieleabendStartKarte { turnierBlatt = true }.colorScheme(.light).schmal() }
                    ForEach(Array(weiterspielen.enumerated()), id: \.element.id) { i, w in
                        if i == 0 { WeiterspielenKarte(beschreibung: w.name) { fortsetzen(w.id) }.colorScheme(.light).schmal() }
                        else { WeiterspielenZeile(name: w.name) { fortsetzen(w.id) }.colorScheme(.light).schmal() }   // Fund S2-015: weitere Partien kompakt
                    }
                    LazyVGrid(columns: schrift.isAccessibilitySize   // N-013/K-004: bei großer Schrift untereinander, Name daneben statt unter der Kachel
                              ? [GridItem(.flexible())]
                              : [GridItem(.adaptive(minimum: gross ? 104 : 78, maximum: gross ? 120 : 110), spacing: gross ? 18 : 14, alignment: .top)], spacing: 18) {
                        ForEach(kacheln, id: \.id) { m in kachel(m) }
                        if bearbeiten {
                            Button { hinzu = true } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus").font(.title2.weight(.semibold)).foregroundStyle(.white)
                                        .frame(width: kante, height: kante).background(.white.opacity(0.14), in: .rect(cornerRadius: kante * 0.235))
                                    Text("Hinzufügen").font(.caption).foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                    .schmal()   // P-003/M-014: Symbolreihe in derselben Spalte wie die Karten
                    if kacheln.isEmpty && !bearbeiten {
                        Text("Noch keine Spiele hier. Tippe auf „Startseite anpassen“ oder öffne „Alle Spiele“.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.8)).schmal()
                    }
                    Button(bearbeiten ? "Fertig" : "Startseite anpassen") { withAnimation { bearbeiten.toggle() } }
                        .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.85)).frame(minHeight: 44).schmal()
                    let s = statistik.summe(ich: spieler.ich?.id)
                    StatistikZeile(titel: "Statistik", werte: [
                        .init(zahl: "\(s.partien)", name: "Partien"), .init(zahl: "\(s.siege)", name: "Siege"),
                    ]) { statistikSeite = true }.colorScheme(.light).schmal()
                }
                .padding(.horizontal, Theme.seitenRand)
                .padding(.bottom, Design.Abstand.l)
                .frame(maxWidth: spaltenBreite).frame(maxWidth: .infinity)
            }
            // R-002: Der Knopf hängt als Fußleiste unter der Liste (safeAreaInset), nichts liegt mehr darunter und er wächst mit der Schrift
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button("Alle Spiele") { spieleListe = true }
                    .hauptKnopf(hell: true)
                    .padding(.horizontal, Theme.seitenRand).padding(.top, 8).padding(.bottom, 8)
                    .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
            }
            .environment(\.startTitelFarbe, .white)
            .spieleabendGrund(Huelle.flaeche)
    }

    var body: some View {
        aufbau
        .onChange(of: bearbeiten) { _, an in
            wackeln = false
            if an, !weniger { withAnimation(.easeInOut(duration: 0.13).repeatForever(autoreverses: true)) { wackeln = true } }
        }
        .sheet(isPresented: $einstellungen, onDismiss: { NotificationCenter.default.post(name: .partieDesignNeuaufbau, object: nil) }) { EinstellungenSeite().formSheet().presentationDetents([.large]).designWurzel() }   // P-004: volle Höhe statt niedrigem Blatt
        .sheet(isPresented: $spielerSeite) { SpielerSeite().formSheet().designWurzel() }
        .sheet(isPresented: $statistikSeite) { StatistikSeite().formSheet().designWurzel() }
        .sheet(isPresented: $turnierBlatt) { TurnierBlatt(oeffnen: oeffnen).formSheet().designWurzel() }
        .sheet(isPresented: $glossar) { GlossarBlatt().formSheet().designWurzel() }
        .sheet(isPresented: $suche) { SpielSucheBlatt { id in suche = false; oeffnen(id) }.formSheet().designWurzel() }
        .onReceive(NotificationCenter.default.publisher(for: .partieStartLayoutGeaendert)) { _ in layout.neuLaden() }
        .sheet(isPresented: $hinzu) { KachelWahlBlatt(schon: Set(layout.ids)) { layout.hinzufuegen($0) }.formSheet().designWurzel() }
        .fullScreenCover(isPresented: $spieleListe) {
            SammlungStart(oeffnen: { id in spieleListe = false; oeffnen(id) }, schliessen: { spieleListe = false },
                          startFilter: sammlungFilter, startSpielerzahl: sammlungSpielerzahl)
                .designWurzel()
        }
        .onChange(of: spieleListe) { _, offen in if !offen { sammlungFilter = .alle; sammlungSpielerzahl = 0 } }
    }

    private var kopf: some View {
        HStack(spacing: Design.Abstand.s) {
            RundKnopf(symbol: "gearshape.fill", beschriftung: "Einstellungen") { einstellungen = true }
            Spacer()
            RundKnopf(symbol: "magnifyingglass", beschriftung: "Spiel suchen") { suche = true }
            RundKnopf(symbol: "person.2.fill", beschriftung: "Spieler") { spielerSeite = true }
            RundKnopfMenue(symbol: "dice", beschriftung: "Zufall und Vorschlag") {
                Button("Zufälliges Spiel", systemImage: "dice") { if let m = SpielKatalog.sichtbar.randomElement() { oeffnen(m.id) } }
                Button("Was spielen wir?", systemImage: "questionmark.circle") { suche = true }
                Button("Spieleabend", systemImage: "trophy") { turnierBlatt = true }
                Button("Glossar", systemImage: "character.book.closed") { glossar = true }
            }
        }
    }

    /// Kachel mit Namen: normal untereinander, bei großer Schrift Kachel links und Name rechts (kein Umbruch mitten im Wort).
    private func kachelLayout<V: View>(@ViewBuilder _ inhalt: () -> V) -> some View {
        let l = schrift.isAccessibilitySize ? AnyLayout(HStackLayout(spacing: 14)) : AnyLayout(VStackLayout(spacing: 6))
        return l { inhalt() }
    }

    private func kachel(_ m: any SpielModul) -> some View {
        let farbe = m.gattung.farbe.color
        return Button {
            if bearbeiten { return }
            oeffnen(m.id)
        } label: {
            kachelLayout {
                ZStack { farbe; MiniaturAnsicht(SpielMiniaturen.art(m), farbe: farbe, groesse: 0.95 * kante / 68) }
                    .frame(width: kante, height: kante).clipShape(.rect(cornerRadius: kante * 0.235))
                    .overlay(alignment: .topLeading) {
                        if bearbeiten {
                            Button { withAnimation { layout.entfernen(m.id) } } label: {
                                Image(systemName: "minus.circle.fill").font(.title3).symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .gray)
                                    .padding(10).contentShape(.circle)
                            }.offset(x: -18, y: -18).accessibilityHidden(true)   // VoiceOver: Aktionen am Spiel selbst (unten)
                        }
                    }
                Text(verbatim: m.name).font(.caption).foregroundStyle(.white).multilineTextAlignment(schrift.isAccessibilitySize ? .leading : .center).frame(maxWidth: schrift.isAccessibilitySize ? .infinity : nil, alignment: .leading).fixedSize(horizontal: false, vertical: true)   // große Schrift: Name bricht um statt abgeschnitten zu werden
            }
            .rotationEffect(.degrees(bearbeiten ? (wackeln ? 1.6 : -1.6) : 0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: m.name))
        .accessibilityHint(bearbeiten ? Text("Aktionen: nach vorn, nach hinten oder entfernen") : Text("Öffnet das Spiel"))
        .accessibilityActions {
            if bearbeiten {
                Button("Nach vorn") { withAnimation { layout.verschiebe(m.id, um: -1) } }
                Button("Nach hinten") { withAnimation { layout.verschiebe(m.id, um: 1) } }
                Button("Von der Startseite entfernen") { withAnimation { layout.entfernen(m.id) } }
            }
        }
        .draggable(m.id)
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            withAnimation { layout.verschieben(id, vor: m.id) }; return true
        }
        .contextMenu {
            Button("Von der Startseite entfernen", systemImage: "minus.circle", role: .destructive) { withAnimation { layout.entfernen(m.id) } }
        }
    }
}

/// Blatt zum Hinzufügen von Spielen zur Startseite.
struct KachelWahlBlatt: View {
    let schon: Set<String>
    /// C-009: Das Blatt dient auch dem Spieleabend; dort passen nur Spiele für mehrere Personen, und die Zeile sagt „Im Spieleabend“.
    var nurMehrspieler = false
    var dabeiText: LocalizedStringKey = "Auf der Startseite"
    let hinzufuegen: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var neu: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    SpielZeilen.gruppen(nurMehrspieler ? SpielKatalog.sichtbar.filter { $0.spielerzahl.upperBound >= 2 && $0.gattung != .raetsel } : SpielKatalog.sichtbar) { m in
                        let drauf = schon.contains(m.id) || neu.contains(m.id)
                        SpielZeilen.zeile(m, untertitel: Text(drauf ? dabeiText : "Tippen zum Hinzufügen"), favorit: drauf) {
                            if !drauf { hinzufuegen(m.id); neu.insert(m.id) }
                        }
                    }
                }.padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Spiel hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fertig") { dismiss() } } }
        }
    }
}


private extension View {
    /// Spalte für Kopf, Karten und Statistik (auf breiten Fenstern schmaler als die Kachelfläche).
    func schmal() -> some View { frame(maxWidth: Theme.wideColumnWidth) }
}
