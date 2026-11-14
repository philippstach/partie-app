// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import Baukasten
import SpieleKern
import UserNotifications

/// Einstellungen der Hülle: eine kurze Übersicht mit sechs Unterseiten. Spielspezifisches steckt im jeweiligen Spiel.
/// Häufiges steht oben in jeder Unterseite, Seltenes unten.
struct EinstellungenSeite: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Entwickler.key) private var entwickler = false
    @AppStorage("darstellung") private var darstellungRaw = Darstellung.system.rawValue
    @AppStorage(Modi.kinderKey) private var kinder = false
    @AppStorage(Modi.ruheKey) private var ruhe = false
    @Environment(\.dynamicTypeSize) private var schriftGroesse

    /// Paket G, Punkt 2 (Blatt 9): Steht auf `true`, zeigt „Spielen“ in Tinte Töne, Haptik und die Würfel-Wahl nicht mehr,
    /// weil sie schon in „Gleich hier“ stehen. AN seit Philipps Ja (13.11., Design-Chat: „Ja, nur noch oben“); jede Einstellung bleibt einmal erreichbar.
    static let doppelteZeilenInTinteAusblenden = true
    private static var spielenHinweis: LocalizedStringKey {
        (Design.art == .tinte && doppelteZeilenInTinteAusblenden) ? "Tempo, Schütteln, Game Center" : "Töne, Haptik, Würfel, Game Center"
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
                // Design-Runde 3 (R11): in Tinte stehen die häufigen Dinge gleich auf der ersten Seite; die Gruppen darunter bleiben vollständig.
                if Design.art == .tinte { EinstDirekt() }
                Section {
                    zeile("gamecontroller.fill", .blue, "Spielen", Self.spielenHinweis) { EinstSpielen() }
                    zeile("paintbrush.fill", .indigo, "Start und Aussehen", "Beim Öffnen, Darstellung, Sprache, App-Symbol") { EinstAussehen() }
                    zeile("moon.zzz.fill", .purple, "Familie und Ruhe", familieHinweis) { EinstFamilie() }
                }
                Section {
                    zeile("externaldrive.fill", .teal, "Daten und Sicherung", "Gespeicherte Daten, iCloud, Sicherung, Statistik") { DatenSeite() }
                    zeile("questionmark.circle.fill", .gray, "Hilfe und Über", "Einführung, Glossar, Open Source, Version") { EinstHilfe() }
                }
                }.designZeilen()
            }
            .designListe()
            .einstellungsSchalter()
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { SchliessenKnopf() } }
        }
        .preferredColorScheme((Darstellung(rawValue: darstellungRaw) ?? .system).farbschema)
    }

    private var familieHinweis: LocalizedStringKey {
        if kinder { return "Kinder-Modus ist an" }
        if ruhe { return "Ruhe-Modus ist an" }
        return "Kinder-Modus, Ruhe-Modus, Mitteilungen"
    }

    private func zeile<Ziel: View>(_ symbol: String, _ farbe: Color, _ titel: LocalizedStringKey, _ hinweis: LocalizedStringKey,
                                   @ViewBuilder ziel: () -> Ziel) -> some View {
        NavigationLink {
            ziel()
        } label: {
            // Blatt 24 (SE-2): Bei den Bedienungshilfe-Größen steht der Text unter dem Symbol und hat die ganze Breite,
            // damit kein Wort mitten im Wort getrennt wird („Hap-tik“, „Wür-fel“). Bei normaler Schrift wie bisher.
            if schriftGroesse.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    EinstellungsKachel(symbol: symbol, farbe: farbe)
                        .accessibilityHidden(true)
                    zeilenText(titel, hinweis)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    EinstellungsKachel(symbol: symbol, farbe: farbe)
                        .accessibilityHidden(true)
                    zeilenText(titel, hinweis)
                }
            }
        }
    }

    private func zeilenText(_ titel: LocalizedStringKey, _ hinweis: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel)
            Text(hinweis).font(.footnote).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)   // lieber eine Zeile mehr als abgeschnitten
        }
    }
}

/// Erste Seite der Einstellungen in Tinte: Töne, Haptik, Darstellung, Design (eigene Seite) und Würfel direkt, ohne Untermenü.
/// Dieselben Schlüssel wie in „Spielen“ und „Start und Aussehen“; dort bleibt alles wie es war.
private struct EinstDirekt: View {
    @AppStorage("toeneAn") private var toene = true
    @AppStorage("haptikAn") private var haptik = true
    @AppStorage("darstellung") private var darstellungRaw = Darstellung.system.rawValue
    @AppStorage("wuerfelQuelle") private var quelleRaw = WuerfelQuelle.app.rawValue

    var body: some View {
        Section {
            Toggle("Töne", isOn: $toene)
            Toggle("Haptik", isOn: $haptik)
            // Punkt 3: bei großer Schrift steht der Wert unter der Bezeichnung (KlarGlas 2.45, Patch klarglas-darstellung-grosse-schrift.patch).
            DarstellungsAuswahl(darstellung: Binding(get: { Darstellung(rawValue: darstellungRaw) ?? .system }, set: { darstellungRaw = $0.rawValue }))
            NavigationLink { EinstDesign() } label: { Text("Design") }
            EinstWahl(titel: "Würfel", auswahl: $quelleRaw, optionen: [
                (WuerfelQuelle.app.rawValue, "App"),
                (WuerfelQuelle.echt.rawValue, "Echt (eintippen)")
            ])
        } header: { Text("Gleich hier") }
    }
}

/// Auswahlzeile (Punkt 3, große Schrift): bei normaler Schrift wie ein gewöhnlicher `Picker`; bei großer Schrift steht der gewählte Wert
/// unter der Bezeichnung statt daneben, damit keine Wörter getrennt werden. Dieselbe Auswahl, dieselben Werte.
private struct EinstWahl: View {
    let titel: LocalizedStringKey
    @Binding var auswahl: String
    let optionen: [(wert: String, text: LocalizedStringKey)]
    @Environment(\.dynamicTypeSize) private var schriftGroesse

    var body: some View {
        if schriftGroesse.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(titel)
                Menu {
                    Picker(titel, selection: $auswahl) {
                        ForEach(optionen, id: \.wert) { Text($0.text).tag($0.wert) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(optionen.first { $0.wert == auswahl }?.text ?? "")
                        Image(systemName: "chevron.up.chevron.down").font(.footnote.weight(.semibold)).accessibilityHidden(true)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            Picker(titel, selection: $auswahl) {
                ForEach(optionen, id: \.wert) { Text($0.text).tag($0.wert) }
            }
        }
    }
}

/// Eigene Seite für das Design (Design-Runde 3, R12): große Vorschau auf dem Spieltisch, darunter die Wahl des Designs und hell oder dunkel.
private struct EinstDesign: View {
    @AppStorage("darstellung") private var darstellungRaw = Darstellung.system.rawValue

    var body: some View {
        Form {
            Group {
            Section {
                ZStack(alignment: .bottomLeading) {
                    TischGrund(nil)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vorschau").font(.caption.weight(.semibold)).kerning(1.4).textCase(.uppercase).foregroundStyle(Tisch.elfenbein.opacity(0.8))
                        Text(verbatim: "Partie").font(Design.Schrift.serif(30, gewicht: .bold, relativ: .title)).foregroundStyle(Tisch.elfenbein)
                    }
                    .padding(Design.Abstand.l)
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .listRowInsets(EdgeInsets())
                .accessibilityHidden(true)
            }
            Section {
                DesignAuswahl()
            } header: { Text("Aussehen") }   // Fund 63: „Design“ stand dreimal übereinander (Titel, Abschnitt, Kartenüberschrift)
            KartenWuerfelZeilen()   // KS Schritt 2: Karten und Würfel wählbar
            Section {
                DarstellungsAuswahl(darstellung: Binding(get: { Darstellung(rawValue: darstellungRaw) ?? .system }, set: { darstellungRaw = $0.rawValue }))
            } header: { Text("Darstellung") }
            }.designZeilen()
        }
        .designListe()
        .einstellungsSchalter()
        .navigationTitle("Design")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Karten und Würfel wählen (Runde 5, Blatt 17, KS Schritt 2)

/// Abschnitt „Karten und Würfel“ unter „Design“: zwei Zeilen, dahinter je eine Seite mit Bildern zum Antippen.
/// Gespeichert unter `kartenSatz` und `wuerfelSatz`; leer = „Wie das Design“ (alles wie vorher).
private struct KartenWuerfelZeilen: View {
    @AppStorage(KartenSatz.schluessel) private var kartenRaw = ""
    @AppStorage(WuerfelSatz.schluessel) private var wuerfelRaw = ""

    private var kartenName: Text {
        if let s = KartenSatz(rawValue: kartenRaw), s != .wieDesign {
            if s == .figuren { return Text("Figuren") }
            if let n = s.name { return Text(verbatim: n) }
        }
        return Text("Wie das Design")
    }
    private var wuerfelName: Text {
        if let s = WuerfelSatz(rawValue: wuerfelRaw), s != .wieDesign, let n = s.name { return Text(verbatim: n) }
        return Text("Wie das Design")
    }

    var body: some View {
        Section {
            NavigationLink { KartenWahlSeite() } label: {
                HStack(spacing: 10) {
                    Text("Karten")
                    Spacer(minLength: 8)
                    HStack(spacing: -8) {
                        MiniKarte(rang: "B", zeichen: "♥", rot: true).rotationEffect(.degrees(-6))
                        MiniKarte(rang: "10", zeichen: "♠", rot: false).rotationEffect(.degrees(6))
                    }
                    .accessibilityHidden(true)
                    kartenName.foregroundStyle(.secondary)
                }
            }
            NavigationLink { WuerfelWahlSeite() } label: {
                HStack(spacing: 10) {
                    Text("Würfel")
                    Spacer(minLength: 8)
                    HStack(spacing: 4) {
                        WuerfelFlaeche(augen: 5, groesse: 26)
                        WuerfelFlaeche(augen: 3, groesse: 26)
                    }
                    .accessibilityHidden(true)
                    wuerfelName.foregroundStyle(.secondary)
                }
            }
        } header: { Text("Karten und Würfel") }
    }
}

/// Kleine Karte im gewählten Satz (Zeile „Karten“).
private struct MiniKarte: View {
    let rang: String
    let zeichen: String
    let rot: Bool
    var vorschau: KartenSatz? = nil
    var breite: CGFloat = 26
    @AppStorage(KartenSatz.schluessel) private var satzGewaehlt = ""

    var body: some View {
        let stil = vorschau.map { KartenStil.fuer($0.bild(design: Design.werte.art)) } ?? KartenStil.aktuell
        let hoehe = breite * 1.45
        let form = RoundedRectangle(cornerRadius: stil.ecke(breite: breite), style: .continuous)
        ZStack {
            form.fill(stil.papier)
            KartenIndex(rang: rang, zeichen: zeichen, farbe: stil.farbe(rot: rot), breite: breite, hoehe: hoehe, vorschau: vorschau)
        }
        .frame(width: breite, height: hoehe)
        .overlay { if let rand = stil.rand { form.strokeBorder(rand, lineWidth: 1) } }
        .shadow(color: .black.opacity(stil.schatten ? 0.15 : 0), radius: 2, y: 1)
    }
}

/// Eine Kachel der Wahlseiten: 150 pt hoch, Ecke 14, gewählt mit 2,5 pt Rand und Haken (wie die Design-Kacheln).
private struct SatzKachel<Bild: View>: View {
    let name: String
    let gewaehlt: Bool
    let aktion: () -> Void
    let bild: Bild

    init(name: String, gewaehlt: Bool, aktion: @escaping () -> Void, @ViewBuilder bild: () -> Bild) {
        self.name = name; self.gewaehlt = gewaehlt; self.aktion = aktion; self.bild = bild()
    }

    var body: some View {
        Button(action: aktion) {
            VStack(spacing: 8) {
                ZStack {
                    TischGrund(nil)
                    bild
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(gewaehlt ? Color.schrift : Color.clear, lineWidth: 2.5) }
                .overlay(alignment: .topTrailing) {
                    if gewaehlt {
                        Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(Tisch.elfenbein, Color.schrift).padding(8)   // design:spielinhalt
                    }
                }
                Text(verbatim: name).font(.subheadline.weight(gewaehlt ? .semibold : .regular)).foregroundStyle(Color.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: name))
        .accessibilityAddTraits(gewaehlt ? [.isButton, .isSelected] : .isButton)
    }
}

/// Zeile „Wie das Design“ mit Haken.
private struct WieDesignZeile: View {
    let gewaehlt: Bool
    let aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            HStack {
                Text("Wie das Design").foregroundStyle(Color.primary)
                Spacer()
                if gewaehlt { Image(systemName: "checkmark").foregroundStyle(Color.appFlaeche).accessibilityHidden(true) }
            }
        }
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }
}

private struct KartenWahlSeite: View {
    @AppStorage(KartenSatz.schluessel) private var raw = ""
    private var eigen: Bool { KartenSatz(rawValue: raw).map { $0 != .wieDesign } ?? false }

    var body: some View {
        Form {
            Group {
                Section {
                    // iPad: vier Kacheln nebeneinander, iPhone: zwei mal zwei
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
                        ForEach(KartenSatz.wahl, id: \.self) { satz in
                            SatzKachel(name: satz == .figuren ? String(localized: "Figuren") : (satz.name ?? ""), gewaehlt: raw == satz.rawValue, aktion: { raw = satz.rawValue }) {
                                // „Figuren“ zeigt Bube Herz, Dame Pik, König Karo; die anderen Sätze Bube, 10, 7
                                let karten: [(String, String, Bool)] = satz == .figuren
                                    ? [("B", "♥", true), ("D", "♠", false), ("K", "♦", true)]
                                    : [("B", "♥", true), ("10", "♠", false), ("7", "♦", true)]
                                HStack(spacing: -6) {
                                    ForEach(Array(karten.enumerated()), id: \.offset) { i, k in
                                        MiniKarte(rang: k.0, zeichen: k.1, rot: k.2, vorschau: satz, breite: 34).rotationEffect(.degrees(Double(i - 1) * 8))
                                    }
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowBackground(Color.clear)
                } footer: { Text("Gilt für alle Kartenspiele, in jedem Design.") }
                Section {
                    WieDesignZeile(gewaehlt: !eigen) { raw = "" }
                }
            }.designZeilen()
        }
        .designListe()
        .navigationTitle("Karten")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WuerfelWahlSeite: View {
    @AppStorage(WuerfelSatz.schluessel) private var raw = ""
    private var eigen: Bool { WuerfelSatz(rawValue: raw).map { $0 != .wieDesign } ?? false }

    var body: some View {
        Form {
            Group {
                Section {
                    HStack(spacing: 10) {
                        ForEach(WuerfelSatz.wahl, id: \.self) { satz in
                            SatzKachel(name: satz.name ?? "", gewaehlt: raw == satz.rawValue, aktion: { raw = satz.rawValue }) {
                                HStack(spacing: 14) {
                                    WuerfelFlaeche(augen: 5, groesse: 52, aufBand: true, vorschau: satz)
                                    WuerfelFlaeche(augen: 3, groesse: 52, aufBand: true, vorschau: satz)
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowBackground(Color.clear)
                } footer: { Text("Gilt für alle Würfelspiele, in jedem Design.") }
                Section {
                    WieDesignZeile(gewaehlt: !eigen) { raw = "" }
                }
            }.designZeilen()
        }
        .designListe()
        .navigationTitle("Würfel")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Spielen: Ton, Haptik, Würfel und Bestenlisten; Seltenes unter „Weitere Optionen“.
private struct EinstSpielen: View {
    @AppStorage("wuerfelQuelle") private var quelleRaw = WuerfelQuelle.app.rawValue
    @AppStorage("wuerfelBleibenGehalten") private var gehalteneBleiben = true
    @AppStorage("haptikAn") private var haptik = true
    @AppStorage("toeneAn") private var toene = true
    @AppStorage("schuettelnAn") private var schuetteln = true
    @AppStorage(AbbruchWertung.schluessel) private var abbruchRaw = AbbruchWertung.nie.rawValue
    @AppStorage(ComputerTempo.schluessel) private var tempoRaw = ComputerTempo.normal.rawValue
    private var ausblenden: Bool { Design.art == .tinte && EinstellungenSeite.doppelteZeilenInTinteAusblenden }

    var body: some View {
        Form {
            Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
            if !ausblenden {
                Section {
                    Toggle("Töne", isOn: $toene)
                    Toggle("Haptik", isOn: $haptik)
                }
            }
            // 1.0 (M2): neue Zeile, nichts fällt weg
            Section {
                Picker("Tempo des Computers", selection: $tempoRaw) {
                    ForEach(ComputerTempo.allCases, id: \.self) { t in Text(t.titel).tag(t.rawValue) }
                }
            } footer: {
                Text("Wie schnell Computergegner ziehen. Gilt für alle Spiele; Rauswurf und Schocken haben zusätzlich eine eigene Wahl.")
            }
            Section {
                if !ausblenden {
                    Picker("Würfel", selection: $quelleRaw) {
                        Text("App").tag(WuerfelQuelle.app.rawValue)
                        Text("Echt (eintippen)").tag(WuerfelQuelle.echt.rawValue)
                    }
                }
                Toggle("Gehaltene Würfel bleiben liegen", isOn: $gehalteneBleiben)
                Toggle("Schütteln zum Würfeln", isOn: $schuetteln)
                    .disabled(quelleRaw != WuerfelQuelle.app.rawValue)
                WuerfelLiveEintrag()
            } header: { Text("Würfel") } footer: {
                Text("Mit „Echt“ würfelst du auf dem Tisch und tippst das Ergebnis ein. Schütteln wirkt nur bei App-Würfeln.")
            }
            GameCenterAbschnitt()
            Section {
                WeitergabeSchalter()
                GegenueberSchalter()
                Picker(selection: $abbruchRaw) {
                    Text("Zählt nicht").tag(AbbruchWertung.nie.rawValue)
                    Text("Gegen den Computer als Niederlage").tag(AbbruchWertung.computer.rawValue)
                    Text("Immer als Niederlage").tag(AbbruchWertung.immer.rawValue)
                } label: { Text("Partie abbrechen") }
                .pickerStyle(.navigationLink)
            } header: { Text("Weitere Optionen") } footer: {
                Text("„Partie abbrechen“ legt fest, ob „Beenden“ mitten in einer Partie als Niederlage zählt. Eine Partie gilt als begonnen, sobald ein Zug gemacht wurde, sie fortgesetzt wurde oder länger als 20 Sekunden läuft. Im Kinder-Modus und in Arcade-Spielen zählt ein Abbruch nie.")
            }
            }.designZeilen()
        }
        .designListe()
        .einstellungsSchalter()
        .navigationTitle("Spielen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Start und Aussehen.
private struct EinstAussehen: View {
    @AppStorage("startetMit") private var startetMit = ""
    @AppStorage("darstellung") private var darstellungRaw = Darstellung.system.rawValue
    @AppStorage("farbenUnterscheidbar") private var farbenUnterscheidbar = false
    @AppStorage("symbolFolgtStart") private var symbolFolgtStart = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
            Section {
                DarstellungsAuswahl(darstellung: Binding(get: { Darstellung(rawValue: darstellungRaw) ?? .system }, set: { darstellungRaw = $0.rawValue }))
                if Design.umschalterOeffentlich { DesignAuswahl() }   // Designwechsel: öffentlich erst, wenn die Konstante es freigibt
                LabeledContent("Sprache") {
                    Button(sprachName) { if let u = URL(string: UIApplication.openSettingsURLString) { openURL(u) } }
                }
                Toggle(isOn: $farbenUnterscheidbar) {
                    VStack(alignment: .leading, spacing: 2) {   // Fund 16/35: ein Stapel in voller Breite statt schmaler Spalte neben dem Schalter
                        Text("Farben unterscheidbar")
                        Text("Zeigt zu jeder Spielart ein Zeichen und zu Spielerfarben Muster, für Menschen mit Farbsehschwäche.").font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Section {
                Picker(selection: $startetMit) {
                    Text("Startseite").tag("")
                    ForEach(SpielKatalog.sichtbar, id: \.id) { Text(verbatim: $0.name).tag($0.id) }
                } label: { Text("Beim Öffnen zeigen") }
                if !startetMit.isEmpty {
                    Toggle(isOn: $symbolFolgtStart) {
                        VStack(alignment: .leading, spacing: 2) {   // Fund 16/35: ein Stapel in voller Breite statt schmaler Spalte neben dem Schalter
                            Text("App-Symbol anpassen")
                            Text("Das Bild von Partie auf dem Home-Bildschirm zeigt dann das Symbol dieses Spiels.").font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } header: { Text("Start") } footer: {
                Text("„Startseite“ zeigt deine Übersicht. Mit einem Spiel startet Partie direkt dort. Vom linken Rand wischst du zurück zur Startseite.")
            }
            Section {
                NavigationLink { SymbolSeite() } label: { Label("App-Symbol auf dem Home-Bildschirm", systemImage: "app.badge") }
            } footer: {
                Text("Das App-Symbol ist das Bild von Partie auf deinem Home-Bildschirm; du kannst es durch das Symbol eines Spiels ersetzen. Die Symbole in der Spieleliste zeigen dagegen das Spielmaterial, ihre Farbe die Spielart.")
            }
            }.designZeilen()
        }
        .designListe()
        .einstellungsSchalter()
        .onChange(of: startetMit) { _, _ in AppSymbol.anwenden(folgtStart: symbolFolgtStart, spiel: startetMit) }
        .onChange(of: symbolFolgtStart) { _, _ in AppSymbol.anwenden(folgtStart: symbolFolgtStart, spiel: startetMit) }
        .navigationTitle("Start und Aussehen")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sprachName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "de"
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? code
    }
}

/// Familie und Ruhe: Kinder-Modus, Ruhe-Modus, Tagesaufgabe und Mitteilungen.
private struct EinstFamilie: View {
    @AppStorage(Modi.kinderKey) private var kinder = false
    @AppStorage(Modi.ruheKey) private var ruhe = false
    @AppStorage("mitteilungenAn") private var mitteilungenAn = true
    @AppStorage("mitteilungTagesraetsel") private var mitteilungTagesraetsel = true
    @Environment(Favoriten.self) private var favoriten
    @Environment(\.openURL) private var openURL
    @State private var mitteilungen: MitteilungsStatus = .offen

    var body: some View {
        Form {
            Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
            Section {
                Toggle(isOn: Binding(get: { kinder }, set: { an in
                    if an { kinder = true } else {
                        Task { if await KinderSchutz.freigeben(grund: String(localized: "Kinder-Modus ausschalten")) { kinder = false } }
                    }
                })) {
                    Text("Kinder-Modus")
                    Text("Blendet die Spiele aus, die du unter „Spiele für Kinder“ abwählst. Ausschalten und Ändern der Auswahl verlangt Face ID oder den Gerätecode.")
                }
                if kinder { NavigationLink("Spiele für Kinder") { KinderSpieleSeite() } }
            } footer: {
                if kinder {
                    VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                        Text("Zeitlimit über iOS-Bildschirmzeit einstellen:")
                        Text("1. Einstellungen öffnen > Bildschirmzeit")
                        Text("2. App-Limits > Limit hinzufügen")
                        Text("3. Partie wählen und die Zeit festlegen")
                    }
                }
            }
            .onChange(of: kinder) { _, _ in Modi.kinderWirkungenAnwenden(favoriten: favoriten.ids) }

            Section {
                Toggle(isOn: $ruhe) {
                    VStack(alignment: .leading, spacing: 2) {   // Fund 16/35: ein Stapel in voller Breite statt schmaler Spalte neben dem Schalter
                        Text("Ruhe-Modus")
                        Text("Keine Mitteilungen, keine Tagesaufgabe, keine „Neu“-Marken.").font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                TagesaufgabeSchalter()
            }
            .onChange(of: ruhe) { _, an in if an { Modi.ruheAnwenden() } }

            mitteilungenAbschnitt
            }.designZeilen()
        }
        .designListe()
        .einstellungsSchalter()
        .navigationTitle("Familie und Ruhe")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Mitteilungen: Hauptschalter und Auswahl der Arten.
    @ViewBuilder private var mitteilungenAbschnitt: some View {
        Section {
            Toggle(isOn: Binding(
                get: { mitteilungenAn && mitteilungen == .erlaubt && !ruhe },
                set: { an in
                    if an {
                        mitteilungenAn = true
                        Task { mitteilungen = await Mitteilungen.fragen(ruhe: ruhe) }
                    } else {
                        mitteilungenAn = false
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                })) { Text("Mitteilungen") }
                .disabled(ruhe)
            if mitteilungen == .abgelehnt && !ruhe {
                Text("Du hast Mitteilungen für Partie abgelehnt. Erlaube sie in den iOS-Einstellungen, dann lässt sich der Schalter einschalten.").font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)   // Fund 195: der Schalter wirkte tot
                Button("In iOS-Einstellungen erlauben") { if let u = URL(string: UIApplication.openSettingsURLString) { openURL(u) } }
            }
            if mitteilungenAn && mitteilungen == .erlaubt && !ruhe {
                Toggle(isOn: $mitteilungTagesraetsel) {
                    VStack(alignment: .leading, spacing: 2) {   // Fund 16/35: ein Stapel in voller Breite statt schmaler Spalte neben dem Schalter
                        Text("Tagesrätsel-Erinnerung")
                        Text("Die Uhrzeit stellst du im Kreuzworträtsel ein.").font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: mitteilungTagesraetsel) { _, an in
                    if !an { UNUserNotificationCenter.current().getPendingNotificationRequests { r in
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: r.map(\.identifier).filter { $0.hasPrefix("tagesraetsel-") })
                    } }
                }
            }
        } header: { Label("Mitteilungen", systemImage: "bell") } footer: {
            if ruhe { Text("Im Ruhe-Modus sind Mitteilungen aus.") }
            else { Text("Partie meldet sich nur mit den Arten, die du hier angeschaltet lässt. Ausschalten löscht alle geplanten Mitteilungen.") }
        }
        .task { mitteilungen = await SystemMitteilungen().status() }
    }
}

/// Hilfe und Über: Einführung, Glossar, Open Source, Version; versteckt der Entwicklermodus.
private struct EinstHilfe: View {
    @Environment(StatistikDienst.self) private var statistik
    @Environment(SpielerVerzeichnis.self) private var spielerVerz
    @Environment(Favoriten.self) private var favoritenReset
    @Environment(IcloudVerwalter.self) private var icloudReset
    @AppStorage(Entwickler.key) private var entwickler = false
    @State private var glossar = false
    @State private var einfuehrung = false
    @State private var versionTipps = 0
    @State private var entwicklerReset = false

    var body: some View {
        Form {
            Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
            Section {
                Button { einfuehrung = true } label: { HStack { Label("Einführung und „Was ist neu?“", systemImage: "sparkles"); Spacer(); Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary) } }.foregroundStyle(.primary)   // Fund 30: Pfeil wie bei „Open Source“
                Button { glossar = true } label: { HStack { Label("Glossar der Spielbegriffe", systemImage: "character.book.closed"); Spacer(); Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary) } }.foregroundStyle(.primary)
                NavigationLink { OpenSourceSeite() } label: { Label("Open Source und Quellen", systemImage: "chevron.left.forwardslash.chevron.right") }
            }

            Section {
                BaukastenUeberGruppe(konfig: PartieKonfig.konfig, trinkgeldLager: nil)
            } header: { EinstellungsKopf(gruppe: .ueber) } footer: {
                Text(verbatim: "Partie \(version)")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        versionTipps += 1
                        if versionTipps >= 7 { entwickler = true; versionTipps = 0 }
                    }
            }

            if entwickler {
                Section {
                    Button("Partie zurücksetzen", role: .destructive) { entwicklerReset = true }
                    if !Design.umschalterOeffentlich { DesignAuswahl() }   // Designwechsel: vorerst nur im Entwicklermodus
                    DesignReglerZeilen()
                    Button("Entwicklermodus beenden") { entwickler = false }
                } header: { Label("Entwickler", systemImage: "hammer") } footer: {
                    Text("Zum Testen: setzt Partie auf den Zustand nach der Installation zurück.")
                }
            }
            }.designZeilen()
        }
        .designListe()
        .einstellungsSchalter()
        .navigationTitle("Hilfe und Über")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $glossar) { GlossarBlatt().formSheet() }
        .fullScreenCover(isPresented: $einfuehrung) { EinfuehrungBlatt(update: true) { einfuehrung = false } }
        .confirmationDialog("Partie zurücksetzen?", isPresented: $entwicklerReset, titleVisibility: .visible) {
            Button("Alles zurücksetzen", role: .destructive) {
                Entwickler.alleDatenLoeschen(statistik: statistik, spieler: spielerVerz, favoriten: favoritenReset, icloud: icloudReset)
                entwickler = false
            }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Statistik, Spieler, Favoriten, Spielstände, Einstellungen und das App-Symbol werden gelöscht. Danach startet Partie wie neu installiert; beende die App und öffne sie neu.") }
    }

    private var version: String {
        let i = Bundle.main.infoDictionary
        return "\(i?["CFBundleShortVersionString"] as? String ?? "?") (\(i?["CFBundleVersion"] as? String ?? "?"))"
    }
}

/// Hinweis zu Open Source: was in Partie steckt und woher es kommt.
struct OpenSourceSeite: View {
    var body: some View {
        List {
            Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
            Section {
                Text("Partie ist mit Apples Bausteinen gebaut (Swift, SwiftUI, Swift Charts). Keine fremden Bibliotheken, keine Werbung, kein Tracking.")
                Text("Die Regeln stammen aus alten, frei bekannten Spielen. Namen, Texte, Bilder, Töne und Rätsel sind eigens für Partie gemacht.")
            } header: { Text("Was drinsteckt") }
            // Fund 32: Die Seite nannte keinen Weg zum Quelltext, obwohl „Über mich“ ihn erwähnt. Das Repo ist noch privat: Der Link
            // kommt erst zur Veröffentlichung (Philipp). Bis dahin ehrlicher Satz; dann hier `Link("Quelltext auf GitHub", destination:)` einsetzen.
            Section {
                Text("Der Quelltext wird mit der Veröffentlichung auf GitHub zugänglich. Den Link findest du hier, sobald das Projekt veröffentlicht ist.")
            } header: { Text("Quelltext") }
            }.designZeilen()
        }
        .designListe()
        .navigationTitle("Open Source und Quellen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum PartieKonfig {
    @MainActor static let konfig = BaukastenKonfiguration(appName: "Partie", links: AppLinks(key: "partie", appStoreID: nil), standardAkzent: .schiefer)
}


/// Regler für das zentrale Design (Design.swift): Abstände, Ecken, Titelgröße. Wirkt, sobald ein Bildschirm neu aufgebaut wird
/// (zurück zum Start und wieder hinein). Nur im Entwicklermodus sichtbar.
private struct DesignReglerZeilen: View {
    @State private var abstand = Design.Regler.abstand
    @State private var ecken = Design.Regler.ecken
    @State private var schrift = Design.Regler.schrift

    var body: some View {
        reglerZeile("Abstände", wert: $abstand, bereich: 0.75...1.5) { Design.Regler.abstand = $0 }
        reglerZeile("Ecken", wert: $ecken, bereich: 0...1.5) { Design.Regler.ecken = $0 }
        reglerZeile("Titelgröße", wert: $schrift, bereich: 0.85...1.25) { Design.Regler.schrift = $0 }
        Button("Regler zurücksetzen") {
            Design.Regler.zuruecksetzen()
            abstand = 1; ecken = 1; schrift = 1
        }
    }

    private func reglerZeile(_ titel: String, wert: Binding<Double>, bereich: ClosedRange<Double>, setzen: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading) {
            Text(verbatim: "\(NSLocalizedString(titel, comment: "")): \(wert.wrappedValue.formatted(.number.precision(.fractionLength(2))))")
            Slider(value: Binding(get: { wert.wrappedValue }, set: { wert.wrappedValue = $0; setzen($0) }), in: bereich, step: 0.05)
        }
    }
}
