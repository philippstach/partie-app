// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Start der Sammlung „Spieleabend“ (Entwurf C, Philipps Wahl 05.11.2026): dunkler Tisch in Nachtblau, Weiterspielen,
/// Spielart-Chips, eine Zeile je Spiel mit gezeichnetem Spielmaterial in der Spielart-Farbe, unten ein weißer Hauptknopf.
/// Suche, Herkunft und Sortierung liegen im Blatt `SpielSucheBlatt` (Lupe); Zufall und „Was spielen wir?“ im Würfel-Menü.
struct SammlungStart: View {
    let oeffnen: (String) -> Void
    var schliessen: (() -> Void)? = nil
    /// Designwechsel: Filter und Spielerzahl, mit denen die Sammlung startet (Kapitel in Tinte, Runde in Salon).
    var startFilter: Filter = .alle
    var startSpielerzahl = 0
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(StatistikDienst.self) private var statistik
    @Environment(Favoriten.self) private var favoriten
    @AppStorage("zuletztGespielt") private var zuletzt = ""
    @State private var einstellungen = false
    @State private var spielerSeite = false
    @State private var statistikSeite = false
    @State private var neuesSpiel = false
    @State private var suche = false
    @State private var sammlungen = Sammlungen()
    @State private var neueListe = false
    @State private var listenName = ""
    @State private var profil: ProfilWahl?
    @State private var filter: Filter = .alle
    @State private var glossar = false
    @AppStorage(Modi.kinderKey) private var kinder = false
    @AppStorage(Modi.gesperrtKey) private var gesperrt = ""
    @AppStorage(Modi.ruheKey) private var ruhe = false
    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar
    @Environment(\.horizontalSizeClass) private var breit   // E8: iPad zeigt die Spiele in Spalten

    enum Filter: Equatable {
        case alle, favoriten, gattung(Gattung), liste(UUID)
    }

    /// A7: Reihenfolge der Spiele auf dem Start (bleibt gemerkt).
    enum Sortierung: String, CaseIterable, Identifiable {
        case empfohlen, zuletzt, meist, nie, name
        var id: String { rawValue }
        var titel: LocalizedStringKey {
            switch self { case .empfohlen: "Empfohlen"; case .zuletzt: "Zuletzt gespielt"; case .meist: "Meistgespielt"; case .nie: "Noch nie gespielt"; case .name: "Name" }
        }
        var symbol: String {
            switch self { case .empfohlen: "sparkles"; case .zuletzt: "clock"; case .meist: "flame"; case .nie: "circle.dashed"; case .name: "textformat" }
        }
    }
    @AppStorage("startSortierung") private var sortierungRaw = Sortierung.empfohlen.rawValue
    /// A1: Spielerzahl (0 = alle) und Dauer als Chips auf dem Start, nicht gemerkt (jeder Abend ist anders).
    @State private var spielerzahl = 0
    @State private var dauer: WasSpielenWirBlatt.Dauer = .egal
    private var sortierung: Sortierung { Sortierung(rawValue: sortierungRaw) ?? .empfohlen }

    /// Spiele nach Filter; Favoriten und das zuletzt gespielte Spiel stehen vorn, der Rest in Katalogreihenfolge.
    private var module: [any SpielModul] {
        _ = kinder; _ = gesperrt
        var liste = SpielKatalog.sichtbar
        switch filter {
        case .alle: break
        case .favoriten: liste = liste.filter { favoriten.enthaelt($0.id) }
        case .gattung(let g): liste = liste.filter { $0.gattung == g }
        case .liste(let l): liste = liste.filter { sammlungen.enthaelt(l, $0.id) }
        }
        if spielerzahl > 0 { liste = liste.filter { $0.spielerzahl.contains(spielerzahl) } }
        if dauer != .egal { liste = liste.filter { dauer.passt(WasSpielenWirBlatt.minuten($0)) } }
        switch sortierung {
        case .empfohlen:
            return liste.sorted { a, b in
                let fa = favoriten.enthaelt(a.id), fb = favoriten.enthaelt(b.id)
                if fa != fb { return fa }
                if (a.id == zuletzt) != (b.id == zuletzt) { return a.id == zuletzt }
                return false
            }
        case .zuletzt:
            let datum = Dictionary(statistik.ereignisse.map { ($0.spiel, $0.datum) }, uniquingKeysWith: max)
            return liste.sorted { (datum[$0.id] ?? .distantPast) > (datum[$1.id] ?? .distantPast) }
        case .meist:
            let anzahl = Dictionary(statistik.ereignisse.map { ($0.spiel, 1) }, uniquingKeysWith: +)
            return liste.sorted { (anzahl[$0.id] ?? 0, $1.name) > (anzahl[$1.id] ?? 0, $0.name) }
        case .nie:
            let gespielt = Set(statistik.ereignisse.map(\.spiel))
            return liste.filter { !gespielt.contains($0.id) }
        case .name:
            return liste.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    private var weiterspielen: [any SpielModul] {
        OffenesSpiel.alle().compactMap { id in SpielKatalog.sichtbar.first { $0.id == id } }.filter { Modi.erlaubt($0.id) }.prefix(3).map { $0 }
    }

    /// E8: iPhone eine Spalte (wie bisher), iPad (breite Größenklasse) bis zu drei Spalten à mindestens 340 pt.
    private var spielSpalten: [GridItem] {
        breit == .regular ? [GridItem(.adaptive(minimum: 340), spacing: Theme.kartenAbstand, alignment: .top)]
                          : [GridItem(.flexible())]
    }

    /// Breite des Inhalts auf dem Start: schmale Lesespalte auf dem iPhone, breit auf dem iPad.
    static func spaltenBreite(breit: Bool) -> CGFloat { breit ? 1100 : Theme.wideColumnWidth }

    @ScaledMetric(relativeTo: .body) private var knopfReserve: CGFloat = Theme.hauptKnopfHoehe + 40
    var body: some View {
        ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    kopf
                    StartTitel("Spiele")
                        .padding(.bottom, 6)

                    ForEach(Array(weiterspielen.enumerated()), id: \.element.id) { i, weiter in
                        if i == 0 {
                            WeiterspielenKarte(beschreibung: weiter.name) { OffenesSpiel.direktMerken(SpielKatalog.kennung(weiter.id)); oeffnen(weiter.id) }
                                .tischKarte()   // weiße Karte auf dem Tisch (nur klar)
                        } else {
                            WeiterspielenZeile(name: weiter.name) { OffenesSpiel.direktMerken(SpielKatalog.kennung(weiter.id)); oeffnen(weiter.id) }.tischKarte()   // Fund S2-015: weitere Partien kompakt
                        }
                    }

                    chips

                    if module.isEmpty {
                        Text(sortierung == .nie ? "Ihr habt schon alles gespielt. Respekt!" : (spielerzahl > 0 || dauer != .egal ? "Dafür gibt es kein Spiel. Ändere Spielerzahl oder Zeit." : (filter == .favoriten ? "Noch keine Favoriten. Halte ein Spiel gedrückt, um es zu merken." : "Keine Spiele in dieser Liste.")))
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    }
                    LazyVGrid(columns: spielSpalten, spacing: Theme.kartenAbstand) {
                        ForEach(module, id: \.id) { m in
                            zeile(m)
                        }
                    }

                    let s = statistik.summe(ich: spieler.ich?.id)
                    StatistikZeile(titel: "Statistik", werte: [
                        .init(zahl: "\(s.partien)", name: "Partien"),
                        .init(zahl: "\(s.siege)", name: "Siege"),
                    ]) { statistikSeite = true }
                    .tischKarte()
                    .padding(.top, 8)
                }
                .padding(.horizontal, Theme.seitenRand)
                .padding(.bottom, Design.Abstand.l)
                .frame(maxWidth: Self.spaltenBreite(breit: breit == .regular))
                .frame(maxWidth: .infinity)
            }
            // R-002: Fußleiste per safeAreaInset: Die Liste endet über dem Knopf, nichts liegt darunter
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button("Neues Spiel") { neuesSpiel = true }
                    .hauptKnopf(hell: true)
                    .padding(.horizontal, Theme.seitenRand).padding(.top, 8).padding(.bottom, 8)
                    .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
                    // TestFlight-Foto „Spiele“: Ohne Grund schimmerten die Zeilen der Liste durch den Knopf. Tinte und Salon bekommen die Fläche der Seite
                    // und eine feine Linie darüber; Klar bleibt, wie es war (weißer Knopf auf dem Tisch).
                    .background(alignment: .bottom) {
                        if !Design.ist(.klar) {
                            Huelle.flaeche.ignoresSafeArea(edges: .bottom)
                                .overlay(alignment: .top) { Color.primary.opacity(0.08).frame(height: 1) }
                        }
                    }
            }
            .environment(\.startTitelFarbe, Design.ist(.klar) ? .white : nil)
            .spieleabendGrund(Huelle.flaeche)
        .sheet(isPresented: $einstellungen, onDismiss: { NotificationCenter.default.post(name: .partieDesignNeuaufbau, object: nil) }) { EinstellungenSeite().formSheet().presentationDetents([.large]).designWurzel() }   // P-004: volle Höhe statt niedrigem Blatt
        .sheet(isPresented: $spielerSeite) { SpielerSeite().formSheet().designWurzel() }
        .sheet(isPresented: $statistikSeite) { StatistikSeite().formSheet().designWurzel() }
        .sheet(isPresented: $glossar) { GlossarBlatt().formSheet().designWurzel() }
        .sheet(isPresented: $suche) { SpielSucheBlatt { id in suche = false; oeffnen(id) }.formSheet().designWurzel() }
        .alert("Neue Liste", isPresented: $neueListe) {
            TextField("Name", text: $listenName)
            Button("Anlegen") { if let id = sammlungen.neu(listenName) { filter = .liste(id) }; listenName = "" }
            Button("Abbrechen", role: .cancel) { listenName = "" }
        }
        .sheet(item: $profil) { w in
            if let m = SpielKatalog.modul(w.id) { SpielProfilBlatt(modul: m) { oeffnen(w.id) }.formSheet().designWurzel() }
        }
        .sheet(isPresented: $neuesSpiel) {
            SpielWahlBlatt { id in neuesSpiel = false; oeffnen(id) }.formSheet().designWurzel()
        }
        .onAppear { if startFilter != .alle { filter = startFilter }; if startSpielerzahl > 0 { spielerzahl = startSpielerzahl } }
    }

    /// Kopfzeile: Einstellungen links; rechts Suche, Spieler und das Würfel-Menü (Zufall, „Was spielen wir?“).
    private var kopf: some View {
        HStack(spacing: Design.Abstand.s) {
            if let schliessen { RundKnopf(symbol: "chevron.down", beschriftung: "Zur Startseite") { schliessen() } }
            else { RundKnopf(symbol: "gearshape.fill", beschriftung: "Einstellungen") { einstellungen = true } }
            Spacer()
            RundKnopf(symbol: "magnifyingglass", beschriftung: "Spiel suchen") { suche = true }
            RundKnopfMenue(symbol: "dice", beschriftung: "Zufall und Vorschlag") {
                Button("Zufälliges Spiel", systemImage: "dice") { if let m = SpielKatalog.sichtbar.randomElement() { oeffnen(m.id) } }
                Button("Was spielen wir?", systemImage: "questionmark.circle") { suche = true }
            }
        }
    }

    /// Chips: Alle · Favoriten · Spielarten (mit Farbpunkt) · eigene Listen · neue Liste.
    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Abstand.s) {
                FilterChip(text: Text("Alle \(SpielKatalog.sichtbar.count)"), aktiv: filter == .alle) { filter = .alle }
                FilterChip("Favoriten", symbol: "heart.fill", aktiv: filter == .favoriten) { filter = filter == .favoriten ? .alle : .favoriten }
                ForEach(SpielZeilen.spielarten.filter { g in SpielKatalog.sichtbar.contains { $0.gattung == g } }, id: \.self) { g in
                    FilterChip(g.name, punkt: g.farbe.color, symbol: farbenUnterscheidbar ? g.zeichen : nil, aktiv: filter == .gattung(g)) { filter = filter == .gattung(g) ? .alle : .gattung(g) }
                }
                ForEach(sammlungen.listen) { l in
                    FilterChip(text: Text(verbatim: l.name), symbol: "rectangle.stack", aktiv: filter == .liste(l.id)) { filter = filter == .liste(l.id) ? .alle : .liste(l.id) }
                        .contextMenu { Button("Liste löschen", systemImage: "trash", role: .destructive) { if filter == .liste(l.id) { filter = .alle }; sammlungen.loeschen(l.id) } }
                }
                FilterChip("Liste", symbol: "plus", aktiv: false) { neueListe = true }
                    .accessibilityLabel("Neue Liste")
                Menu {
                    Picker("Spieler", selection: $spielerzahl) {
                        Text("Alle").tag(0)
                        ForEach(1...8, id: \.self) { n in Text(n == 1 ? "Allein" : "\(n) Spieler").tag(n) }
                    }
                } label: {
                    FilterChip(text: spielerzahl == 0 ? Text("Spieler") : (spielerzahl == 1 ? Text("Allein") : Text("\(spielerzahl) Spieler")), symbol: "person.2", aktiv: spielerzahl != 0) {}
                        .allowsHitTesting(false)
                }
                .accessibilityLabel(Text("Spielerzahl"))
                .accessibilityValue(spielerzahl == 0 ? Text("alle") : Text("\(spielerzahl)"))
                Menu {
                    Picker("Zeit", selection: $dauer) { ForEach(WasSpielenWirBlatt.Dauer.allCases) { Text($0.titel).tag($0) } }
                } label: {
                    FilterChip(dauer == .egal ? "Zeit" : dauer.titel, symbol: "clock", aktiv: dauer != .egal) {}
                        .allowsHitTesting(false)
                }
                .accessibilityLabel(Text("Spielzeit"))
                .accessibilityValue(Text(dauer.titel))
                Menu {
                    Picker("Sortierung", selection: $sortierungRaw) {
                        ForEach(Sortierung.allCases) { s in Label(s.titel, systemImage: s.symbol).tag(s.rawValue) }
                    }
                } label: {
                    FilterChip(sortierung.titel, symbol: "arrow.up.arrow.down", aktiv: sortierung != .empfohlen) {}
                        .allowsHitTesting(false)
                }
                .accessibilityLabel(Text("Sortierung"))
                .accessibilityValue(Text(sortierung.titel))
            }
            .padding(.horizontal, Theme.seitenRand)
        }
        .padding(.horizontal, -Theme.seitenRand)
        .padding(.top, 4)
    }

    private func zeile(_ m: any SpielModul) -> some View {
        SpielZeile(name: m.name, untertitel: Text("\(m.gattung.anzeigeName) · \(SpielZeilen.spielerText(m))"),
                   farbe: m.gattung.farbe.color, miniatur: SpielMiniaturen.art(m), favorit: favoriten.enthaelt(m.id),
                   zeichen: farbenUnterscheidbar ? m.gattung.zeichen : nil) { oeffnen(m.id) }   // TestFlight 13.11., Nr. 15: keine „Neu“-Marke mehr neben den Namen
            .contextMenu {
                Button("Spielprofil", systemImage: "info.circle") { profil = ProfilWahl(id: m.id) }
                Button(favoriten.enthaelt(m.id) ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen",
                       systemImage: favoriten.enthaelt(m.id) ? "heart.slash" : "heart") { favoriten.umschalten(m.id) }
                if !sammlungen.listen.isEmpty {
                    Menu("Zu Liste", systemImage: "rectangle.stack") {
                        ForEach(sammlungen.listen) { l in
                            Button(l.name, systemImage: sammlungen.enthaelt(l.id, m.id) ? "checkmark" : "plus") { sammlungen.umschalten(l.id, m.id) }
                        }
                    }
                }
            }
    }

}

/// Blatt „Neues Spiel“: erst das Spiel wählen, dann übernimmt das Spiel (Konzept 5.4). Gruppen je Spielart, Favoriten zuerst.
struct SpielWahlBlatt: View {
    let waehlen: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(Favoriten.self) private var favoriten

    var body: some View {
        let favs = SpielKatalog.sichtbar.filter { favoriten.enthaelt($0.id) }
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    if !favs.isEmpty {
                        SpielartLabel(text: Text("Favoriten · \(favs.count)"), farbe: .secondary)
                        ForEach(favs, id: \.id) { m in SpielZeilen.zeile(m, favorit: true) { waehlen(m.id) } }
                    }
                    SpielZeilen.gruppen(SpielKatalog.sichtbar) { m in SpielZeilen.zeile(m, untertitel: Text(SpielZeilen.spielerText(m))) { waehlen(m.id) } }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Spiel wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
        }
    }
}

struct ProfilWahl: Identifiable { let id: String }

/// Weitere offene Partien unter der großen Weiterspielen-Karte: eine schmale Zeile je Partie (Fund S2-015).
/// Die jüngste Partie behält die große Karte, jede weitere bleibt mit einem Tipp erreichbar, braucht aber nur eine Zeile Höhe.
struct WeiterspielenZeile: View {
    let name: String
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            // F-AWS-K-004: bei großer Schrift Titel und Spielname untereinander statt „Wei-ter-spie-len“ in vier Zeilen
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Design.Abstand.s) {
                    Image(systemName: "play.fill").font(.footnote)
                    Text("Weiterspielen").font(.footnote.weight(.semibold)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                    Text(verbatim: name).font(.subheadline).lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                }
                HStack(spacing: Design.Abstand.s) {
                    Image(systemName: "play.fill").font(.footnote)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weiterspielen").font(.footnote.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
                        Text(verbatim: name).font(.subheadline).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Design.Abstand.s)
            .padding(.horizontal, Design.Abstand.l)
            .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
            .background(Color.kartenGrund, in: .rect(cornerRadius: Theme.cardRadius))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Setzt diese Partie fort"))
    }
}
