// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Blatt „Spiel suchen“: Stichwortsuche beim Tippen, mit Apple Intelligence zusätzlich „Beschreiben“, dazu Herkunft und Sortierung.
/// Vom Rundknopf (Lupe) der Startseite geöffnet; die Startseite selbst zeigt nur noch die Spielart-Chips.
struct SpielSucheBlatt: View {
    let waehlen: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(Favoriten.self) private var favoriten
    @FocusState private var fokus: Bool
    @Environment(\.dynamicTypeSize) private var schrift
    @State private var suche = ""
    @State private var land: String?
    @State private var sortierung: Sortierung = .name
    @State private var kiTreffer: [String]?
    @State private var kiLaeuft = false
    @State private var kiHinweis: String?
    /// Blatt 18 „Neue Partie sagen“: Spiel, Spielerzahl und Regeln aus dem Satz, erst nach „Übernehmen“ gesetzt.
    @State private var partie: PartieVorschlag?
    // Filter aus „Was spielen wir?“ (zusammengeführt): Spielerzahl und Dauer grenzen die Liste ein, „Überrasch mich“ wählt daraus
    @State private var anzahl: Int?
    @State private var dauer: WasSpielenWirBlatt.Dauer = .egal
    @State private var vorschlag: String?

    enum Sortierung: String, CaseIterable, Identifiable {
        case name, herkunft, kategorie
        var id: String { rawValue }
        var titel: LocalizedStringKey {
            switch self { case .name: "Name"; case .herkunft: "Herkunft"; case .kategorie: "Spielart" }
        }
    }

    /// Katalog nach Spielerzahl und Dauer vorgefiltert; auch die KI-Suche arbeitet nur auf dieser Liste.
    private var vorgefiltert: [any SpielModul] {
        var gesehen = Set<String>()   // N-009: jedes Spiel nur einmal
        return SpielKatalog.sichtbar.filter { gesehen.insert($0.id).inserted }.filter { m in
            (anzahl.map { m.spielerzahl.contains($0) } ?? true) && dauer.passt(WasSpielenWirBlatt.minuten(m))
        }
    }

    private var module: [any SpielModul] {
        var liste = vorgefiltert
        if let ids = kiTreffer { return ids.compactMap { id in liste.first { $0.id == id } } }
        let text = suche.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty { liste = SpielSuche.stichwort(text, in: liste) }
        if let l = land { liste = liste.filter { SpielMetadaten.info($0.id).land == l } }
        if !text.isEmpty { return liste }          // Suchtreffer behalten ihre Trefferreihenfolge
        switch sortierung {
        case .name: return liste.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .herkunft: return liste.sorted { (SpielMetadaten.info($0.id).land, $0.name) < (SpielMetadaten.info($1.id).land, $1.name) }
        case .kategorie: return liste.sorted { ($0.gattung.rawValue, $0.name) < ($1.gattung.rawValue, $1.name) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    suchfeld
                    zeile {
                        Menu {
                            Button("Alle Länder") { land = nil }
                            ForEach(SpielMetadaten.laender, id: \.self) { l in Button(SpielMetadaten.landText(l)) { land = l } }
                        } label: { Label(land.map { SpielMetadaten.landText($0) } ?? String(localized: "Herkunft"), systemImage: "globe.europe.africa").font(.subheadline) }
                        Menu {
                            Picker("Sortierung", selection: $sortierung) { ForEach(Sortierung.allCases) { Text($0.titel).tag($0) } }
                        } label: { Label("Sortieren", systemImage: "arrow.up.arrow.down").font(.subheadline) }
                        if !schrift.isAccessibilitySize { Spacer() }
                        Text("\(module.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    filterZeile
                    if let p = partie {
                        PartieVorschlagAbschnitt(vorschlag: p, uebernehmen: { PartieAnsage.uebernehmen(p); partie = nil; waehlen(p.modul.id) }, verwerfen: { partie = nil })
                    }
                    if let h = kiHinweis { Text(h).font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }
                    if let v = vorschlag, let m = SpielKatalog.modul(v) {
                        SpielartLabel("Mein Vorschlag", farbe: m.gattung.farbe.color)
                        SpielZeilen.zeile(m, untertitel: Text("\(m.gattung.anzeigeName) · ca. \(WasSpielenWirBlatt.minuten(m)) Min.")) { waehlen(m.id) }
                    }
                    if module.isEmpty {
                        Text("Kein Spiel gefunden. Versuche andere Stichwörter oder beschreibe das Spiel.").font(.subheadline).foregroundStyle(.secondary).card()
                    }
                    // G-003/N-009: Der „Vorschlag“ steht schon oben, in der Liste nicht noch einmal
                    ForEach(module.filter { $0.id != vorschlag }, id: \.id) { m in
                        let land = SpielMetadaten.info(m.id).land
                        SpielZeilen.zeile(m, untertitel: Text(land.isEmpty ? "\(m.gattung.anzeigeName) · \(SpielZeilen.spielerText(m))" : "\(m.gattung.anzeigeName) · \(SpielMetadaten.landText(land))"),
                                          favorit: favoriten.enthaelt(m.id)) { waehlen(m.id) }
                    }
                }
                .padding(Theme.seitenRand)
            }
            .scrollDismissesKeyboard(.interactively)   // Fund 80: Tastatur verschwindet beim Wischen durch die Treffer
            .background(Color.seitenGrund)
            .navigationTitle("Spiel suchen")
            .navigationBarTitleDisplayMode(schrift.isAccessibilitySize ? .large : .inline)   // K-020: Titel wächst bei großer Schrift mit
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fertig") { dismiss() } } }
            .onAppear { fokus = true; SpielSuche.aufwaermen(in: SpielKatalog.sichtbar) }
        }
    }

    /// Spielerzahl, Dauer und „Überrasch mich“ (aus „Was spielen wir?“).
    private var filterZeile: some View {
        VStack(spacing: Design.Abstand.s) {
            zeile {
                Menu {
                    Button("Egal") { anzahl = nil; filterGeaendert() }
                    ForEach(1...8, id: \.self) { n in Button("\(n) Spieler") { anzahl = n; filterGeaendert() } }
                } label: { Label(anzahl.map { String(localized: "\($0) Spieler") } ?? String(localized: "Spieler"), systemImage: "person.2").font(.subheadline) }
                Menu {
                    Picker("Zeit", selection: $dauer) { ForEach(WasSpielenWirBlatt.Dauer.allCases) { Text($0.titel).tag($0) } }
                } label: { Label { dauer == .egal ? Text("Zeit") : Text(dauer.titel) } icon: { Image(systemName: "clock") }.font(.subheadline) }
                    .onChange(of: dauer) { _, _ in filterGeaendert() }
                if !schrift.isAccessibilitySize { Spacer() }
            }
            Button("Überrasch mich") { vorschlag = module.randomElement()?.id }
                .buttonStyle(HauptKnopfStil()).disabled(module.isEmpty)
        }
    }

    /// N-013/K-015: Menüs nebeneinander, bei großer Schrift untereinander (Wörter brechen nicht mitten im Wort).
    private func zeile<V: View>(@ViewBuilder _ inhalt: () -> V) -> some View {
        let l = schrift.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Design.Abstand.s)) : AnyLayout(HStackLayout(spacing: Design.Abstand.s))
        return l { inhalt() }
    }

    private func filterGeaendert() { kiTreffer = nil; kiHinweis = nil; vorschlag = nil; partie = nil }

    private var suchfeld: some View {
        VStack(spacing: Design.Abstand.s) {
            HStack(spacing: Design.Abstand.s) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Spiel suchen oder beschreiben", text: $suche)
                    .focused($fokus)
                    .submitLabel(.search)
                    .onChange(of: suche) { _, _ in kiTreffer = nil; kiHinweis = nil; vorschlag = nil; partie = nil }
                    .onSubmit { if SpielSuche.kiVerfuegbar, suche.count >= 8 { kiSuchen() } }
                if !suche.isEmpty {
                    Button { suche = ""; kiTreffer = nil; kiHinweis = nil; partie = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.plain).frame(minWidth: 44, minHeight: 44).contentShape(.rect).accessibilityLabel("Suche löschen")
                }
            }
            .padding(.horizontal, 12).frame(minHeight: 44)
            .background(Color.kartenGrund, in: .rect(cornerRadius: Theme.feldRadius))
            if SpielSuche.kiVerfuegbar, suche.count >= 8 {
                Button { kiSuchen() } label: {
                    Label(kiLaeuft ? "Suche läuft …" : "Mit Apple Intelligence finden", systemImage: "text.bubble").frame(maxWidth: .infinity)
                }
                .zweitKnopf().disabled(kiLaeuft)
            }
        }
    }

    private func kiSuchen() {
        let text = suche
        kiLaeuft = true; kiHinweis = nil; partie = nil
        Task {
            let r = await SpielSuche.ki(text, in: vorgefiltert, wunsch: true)
            kiLaeuft = false
            guard text == suche else { return }   // C-006: Eingabe hat sich inzwischen geändert, alte Antwort verwerfen
            if let erstes = r?.first { kiLaeuft = true; let p = await PartieAnsage.vorschlag(text, modul: erstes); kiLaeuft = false; guard text == suche else { return }; partie = p }
            if let r, !r.isEmpty { kiTreffer = r.map(\.id); kiHinweis = String(localized: "Vorschläge von Apple Intelligence – tippe ein Spiel an.") }
            else if r != nil { kiHinweis = String(localized: "Apple Intelligence hat kein passendes Spiel gefunden.") }
            else { kiHinweis = String(localized: "Apple Intelligence ist gerade nicht verfügbar. Ich suche nach Stichwörtern.") }
        }
    }
}
