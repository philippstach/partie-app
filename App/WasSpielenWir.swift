// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// „Was spielen wir?“ (Version 1.0, A2): Spielerzahl und Zeit angeben, passende Spiele sehen, ein Zufallsvorschlag.
struct WasSpielenWirBlatt: View {
    let waehlen: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var anzahl = 2
    @State private var dauer: Dauer = .egal
    @State private var vorschlag: String?
    @State private var wunsch = ""
    @State private var kiTreffer: [String]?
    @State private var kiLaeuft = false
    @State private var kiHinweis: String?
    @FocusState private var wunschFokus: Bool

    /// Wie viel Denken ein Spiel verlangt (grobe Einordnung nach Spielart, für Vorschläge und die KI).
    enum Anspruch: String { case leicht, mittel, hoch }
    static func anspruch(_ m: any SpielModul) -> Anspruch {
        switch m.gattung {
        case .wuerfel, .arcade: .leicht
        case .karten, .wort: .mittel
        case .brett, .raetsel: .hoch
        }
    }

    enum Dauer: String, CaseIterable, Identifiable {
        case egal, kurz, mittel, lang
        var id: String { rawValue }
        var titel: LocalizedStringKey {
            switch self { case .egal: "Egal"; case .kurz: "Unter 10 Min."; case .mittel: "10–30 Min."; case .lang: "Über 30 Min." }
        }
        func passt(_ minuten: Int) -> Bool {
            switch self { case .egal: true; case .kurz: minuten < 10; case .mittel: (10...30).contains(minuten); case .lang: minuten > 30 }
        }
    }

    private var treffer: [any SpielModul] {
        SpielKatalog.sichtbar.filter { $0.spielerzahl.contains(anzahl) && dauer.passt(Self.minuten($0)) }
    }

    /// Grobe Spieldauer in Minuten nach Gattung (Schätzwert, nur für die Auswahl).
    static func minuten(_ m: any SpielModul) -> Int {
        switch m.gattung {
        case .arcade: 5
        case .wort: 8
        case .raetsel: 15
        case .wuerfel: 20
        case .karten: 20
        case .brett: 35
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    wunschKarte
                    VStack(alignment: .leading, spacing: Design.Abstand.m) {
                        Stepper(value: $anzahl, in: 1...8) { Text("Wie viele Spieler? \(anzahl)") }
                        Picker("Zeit", selection: $dauer) { ForEach(Dauer.allCases) { Text($0.titel).tag($0) } }
                            .pickerStyle(.menu)
                    }
                    .card()
                    if wunschText.isEmpty {
                        Button("Überrasch mich") { vorschlag = treffer.randomElement()?.id }
                            .buttonStyle(HauptKnopfStil()).disabled(treffer.isEmpty)
                    } else {
                        Button { vorschlagen() } label: {
                            Label(kiLaeuft ? "Suche läuft …" : (SpielSuche.kiVerfuegbar ? "Vorschlagen (Apple Intelligence)" : "Vorschlagen"),
                                  systemImage: SpielSuche.kiVerfuegbar ? "sparkles" : "wand.and.stars").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HauptKnopfStil()).disabled(kiLaeuft)
                    }
                    if let h = kiHinweis { Text(h).font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }
                    if let v = vorschlag, let m = SpielKatalog.modul(v) {
                        SpielartLabel("Mein Vorschlag", farbe: m.gattung.farbe.color)
                        SpielZeilen.zeile(m, untertitel: Text("\(m.gattung.anzeigeName) · ca. \(Self.minuten(m)) Min.")) { waehlen(m.id) }
                    }
                    if let ids = kiTreffer {
                        let liste = ids.compactMap { SpielKatalog.modul($0) }
                        if liste.isEmpty {
                            Text("Dazu passt kein Spiel in der Sammlung. Beschreibe es anders oder lockere Spielerzahl und Zeit.").font(.subheadline).foregroundStyle(.secondary).card()
                        } else {
                            SpielartLabel("Passt zu eurem Wunsch", farbe: .secondary)
                            ForEach(liste, id: \.id) { m in
                                SpielZeilen.zeile(m, untertitel: Text("\(m.gattung.anzeigeName) · \(SpielZeilen.spielerText(m)) · ca. \(Self.minuten(m)) Min.")) { waehlen(m.id) }
                            }
                        }
                    } else {
                        if treffer.isEmpty {
                            Text("Dafür gibt es kein Spiel. Ändere Spielerzahl oder Zeit.").font(.subheadline).foregroundStyle(.secondary).card()
                        }
                        SpielZeilen.gruppen(treffer) { m in
                            SpielZeilen.zeile(m, untertitel: Text("\(SpielZeilen.spielerText(m)) · ca. \(Self.minuten(m)) Min.")) { waehlen(m.id) }
                        }
                    }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Was spielen wir?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
        }
    }

    private var wunschText: String { wunsch.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Freitext: „Worauf habt ihr Lust?“ Apple Intelligence deutet ihn; ohne Apple Intelligence liest `WunschDeuter` Spielart, Zahl, Tempo und Anspruch heraus.
    private var wunschKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            KartenKopf("Worauf habt ihr Lust?", zusatz: SpielSuche.kiVerfuegbar ? String(localized: "Apple Intelligence") : nil)
            TextField("z. B. Würfelspiel zu viert, gemütlich, nicht viel Denken", text: $wunsch, axis: .vertical)
                .lineLimit(2...4)
                .focused($wunschFokus)
                .submitLabel(.search)
                .onSubmit { if !wunschText.isEmpty { vorschlagen() } }
                .onChange(of: wunsch) { _, _ in kiTreffer = nil; kiHinweis = nil; vorschlag = nil }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color.feldGrund, in: .rect(cornerRadius: Theme.feldRadius))
            if !wunsch.isEmpty {
                Button { wunsch = ""; kiTreffer = nil; kiHinweis = nil } label: { Label("Leeren", systemImage: "xmark.circle.fill").font(.subheadline) }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func vorschlagen() {
        let text = wunschText
        guard !text.isEmpty else { return }
        wunschFokus = false
        vorschlag = nil
        let deutung = WunschDeuter.deuten(text)
        if let z = deutung.spieler { anzahl = z }
        if let d = deutung.dauer { dauer = d }
        // Vorauswahl nach den harten Angaben (Spielerzahl, Zeit), die KI wählt daraus
        let vorauswahl = SpielKatalog.sichtbar.filter { $0.spielerzahl.contains(anzahl) && dauer.passt(Self.minuten($0)) }
        guard SpielSuche.kiVerfuegbar else {
            kiTreffer = deutung.filtern(vorauswahl.isEmpty ? SpielKatalog.sichtbar : vorauswahl).map(\.id)
            kiHinweis = String(localized: "Ohne Apple Intelligence: Vorschlag nach Spielart, Spielerzahl, Zeit und Anspruch aus deinem Text.")
            return
        }
        kiLaeuft = true; kiHinweis = nil
        Task {
            let r = await SpielSuche.ki(text, in: vorauswahl.isEmpty ? SpielKatalog.sichtbar : vorauswahl, wunsch: true)
            kiLaeuft = false
            if let r {
                kiTreffer = r.map(\.id)
                kiHinweis = r.isEmpty ? nil : String(localized: "Vorschläge von Apple Intelligence – tippe ein Spiel an.")
            } else {
                kiTreffer = deutung.filtern(vorauswahl.isEmpty ? SpielKatalog.sichtbar : vorauswahl).map(\.id)
                kiHinweis = String(localized: "Apple Intelligence ist gerade nicht verfügbar. Vorschlag nach Spielart, Spielerzahl, Zeit und Anspruch.")
            }
        }
    }
}

/// Liest aus einem Wunschtext ohne KI heraus: Spielart, Spielerzahl, Tempo, Anspruch. Grob, aber ehrlich – Rückfall ohne Apple Intelligence.
@MainActor
enum WunschDeuter {
    @MainActor struct Deutung {
        var gattungen: Set<Gattung> = []
        var spieler: Int?
        var dauer: WasSpielenWirBlatt.Dauer?
        var anspruch: WasSpielenWirBlatt.Anspruch?

        func filtern(_ module: [any SpielModul]) -> [any SpielModul] {
            var liste = module
            if !gattungen.isEmpty { liste = liste.filter { gattungen.contains($0.gattung) } }
            if let a = anspruch {
                let passend = liste.filter { WasSpielenWirBlatt.anspruch($0) == a }
                if !passend.isEmpty { liste = passend }
            }
            return Array(liste.shuffled().prefix(5))
        }
    }

    static func deuten(_ text: String) -> Deutung {
        let t = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
        var d = Deutung()
        let arten: [(Gattung, [String])] = [
            (.wuerfel, ["wurfel", "dice", "kniffel", "becher"]), (.karten, ["karte", "card", "stich", "blatt"]),
            (.brett, ["brett", "board", "schach", "dame", "stein", "figur"]), (.raetsel, ["ratsel", "puzzle", "sudoku", "logik", "knobel", "allein", "alleine", "solo"]),
            (.wort, ["wort", "worter", "buchstabe", "raten", "kreuzwort"]), (.arcade, ["arcade", "reaktion", "action", "schnell reagieren", "geschick"]),
        ]
        for (g, w) in arten where w.contains(where: { t.contains($0) }) { d.gattungen.insert(g) }
        let zahlen: [(String, Int)] = [("allein", 1), ("alleine", 1), ("solo", 1), ("zu zweit", 2), ("zwei", 2), ("zu dritt", 3), ("drei", 3), ("zu viert", 4), ("vier", 4),
                                       ("zu funft", 5), ("funf", 5), ("zu sechst", 6), ("sechs", 6), ("sieben", 7), ("acht", 8)]
        if let m = t.range(of: #"\b([1-8])\b"#, options: .regularExpression), let z = Int(t[m]) { d.spieler = z }
        else if let z = zahlen.first(where: { t.contains($0.0) }) { d.spieler = z.1 }
        let nichtSchnell = t.contains("nicht schnell") || t.contains("nicht so schnell") || t.contains("gemutlich") || t.contains("entspannt") || t.contains("lang") || t.contains("ruhig")
        if nichtSchnell { d.dauer = .mittel }
        else if t.contains("schnell") || t.contains("kurz") || t.contains("zwischendurch") { d.dauer = .kurz }
        let wenigDenken = t.contains("wenig denken") || t.contains("nicht viel denken") || t.contains("nicht so viel denken") || t.contains("ohne denken") || t.contains("einfach") || t.contains("locker") || t.contains("gluck")
        if wenigDenken { d.anspruch = .leicht }
        else if t.contains("viel denken") || t.contains("knobeln") || t.contains("strategie") || t.contains("taktik") || t.contains("anspruchsvoll") { d.anspruch = .hoch }
        return d
    }
}
