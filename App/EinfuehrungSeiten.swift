// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import Baukasten
import SpieleKern

/// Erster Start: vier Seiten zum Durchwischen (Willkommen, Spiele, Favoriten, Erinnerungen und Game Center).
/// Überspringen ist jederzeit möglich; alles Weitere steht in den Einstellungen.
struct EinfuehrungSeiten: View {
    let fertig: () -> Void
    @AppStorage("startetMit") private var startetMit = ""
    @Environment(Favoriten.self) private var favoriten
    @Environment(SpielerVerzeichnis.self) private var verzeichnis
    @State private var spielerAnlegen = false
    @State private var ichName = ""   // T-010: die Einführung fragt nur den Namen; Foto und mehr stehen später unter „Spieler“
    @FocusState private var ichFokus: Bool
    @Environment(\.accessibilityReduceMotion) private var weniger
    @State private var seite = 0
    @State private var nameUebersprungen = false
    @State private var nameFrage = false   // T-065: Nachfrage, wenn Seite 2 ohne Namen verlassen wird (Tinte)
    @State private var suche = ""
    @State private var startEndeHinweis: String?   // Name des Spiels, dessen „Nur … nutzen“ gerade geendet ist (kurz sichtbar)
    @AppStorage(GameCenterBruecke.schalterKey) private var gameCenterAn = false
    @AppStorage(Modi.kinderKey) private var kinder = false
    @State private var mitteilungen: MitteilungsStatus = .offen
    /// Tinte: kurz (Willkommen, Name, Favoriten, Erinnerungen). Klar und Salon behalten die Seite „Für jeden etwas“.
    private var letzte: Int { art == .tinte ? 3 : 4 }
    /// Seitennummer im Kopf: In Tinte fehlt Seite 2, die späteren rücken auf.
    private func nr(_ n: Int) -> Int { art == .tinte && n >= 3 ? n - 1 : n }
    @Environment(\.designArt) private var art
    @Environment(\.horizontalSizeClass) private var groesse
    @ScaledMetric(relativeTo: .body) private var schriftSkala: CGFloat = 1


    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if seite < letzte {
                    // Designwechsel: Tinte zeigt „Überspringen“ als unterstrichenes Wort, Salon als Label
                    switch art {
                    case .klar: Button("Überspringen") { fertig() }.foregroundStyle(.secondary).frame(minHeight: 44)
                    case .tinte: Button { fertig() } label: { Text("Überspringen").unterstrichen(1, farbe: Color.schriftZweit) }.buttonStyle(.plain).foregroundStyle(Color.schriftZweit).frame(minHeight: 44).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    case .salon: Button { fertig() } label: { Text("Überspringen").designLabel(EinfuehrungKopfNeu.blockFarben(nummer: seite).schrift) }.buttonStyle(.plain).frame(minHeight: 44)
                    }
                }
            }.padding(.horizontal, Theme.seitenRand).frame(height: 44)
            // Salon: die Leiste trägt die Farbe des Blocks der Seite und reicht bis an den oberen Rand (kein Streifen über dem Farbblock)
            .background { if art == .salon { EinfuehrungKopfNeu.blockFarben(nummer: seite).flaeche.ignoresSafeArea(edges: .top).animation(weniger ? nil : .easeInOut(duration: 0.25), value: seite) } }

            TabView(selection: $seite) {
                if art == .tinte {
                    // Runde 5 (Paket E): alle vier Seiten im Stil der letzten Seite, siehe `EinfuehrungTinte.swift`-Teil unten
                    tinteWillkommen.tag(0)
                    tinteSpieler.tag(1)
                    tinteFavoriten.tag(2)
                    tinteFreiwillig.tag(3)
                } else {
                    willkommen.tag(0)
                    spielerSeite.tag(1)
                    spiele.tag(2)
                    favoritenSeite.tag(3)
                    freiwilligSeite.tag(4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: art == .klar ? .always : .never))   // Tinte, Salon: eigene Punktzeile in der Farbe des Designs
            if art != .klar { EinfuehrungPunkte(seite: seite, anzahl: letzte + 1).padding(.top, 10) }

            Button { hauptAktion() } label: { Text(hauptTitel) }
                .buttonStyle(HauptKnopfStil())
                .frame(maxWidth: art == .tinte && groesse == .regular ? 440 : .infinity)
                .padding(.horizontal, Theme.seitenRand).padding(.vertical, 16)
        }
        .modifier(EinfuehrungSpalte(tinte: art == .tinte))
        .background(Color.seitenGrund)
        // T-065 (alle Designs, Seite 2 ist überall die Namensseite): Von Seite 2 ohne Namen weiter, per Knopf oder Wischen: erst nachfragen. Beim Wischen federt die Seite zurück.
        .onChange(of: seite) { alt, neu in
            if alt == 1, neu > 1, nameFehlt { seite = 1; nameFrage = true }
        }
        .confirmationDialog("Ohne Namen weiter?", isPresented: $nameFrage, titleVisibility: .visible) {
            Button("Namen eingeben") { ichFokus = true }
            Button("Ohne Namen weiter") { nameUebersprungen = true; weiter() }
        } message: {
            Text("Mit deinem Namen stehst du in jedem Spiel gleich bereit. Das geht auch später unter Spieler.")
        }
        .task { mitteilungen = await SystemMitteilungen().status() }
    }

    /// Stapel einer Seite ohne eigenes Rollen: „Klar & Glas“ mittig wie bisher, Tinte und Salon von oben, linksbündig und zum Rollen.
    @ViewBuilder private func seitenStapel<V: View>(@ViewBuilder _ inhalt: () -> V) -> some View {
        if art == .klar {
            // K-001/K-002: Passt die Seite nicht (englischer Text, große Schrift, kleines Gerät), rollt sie, statt unten abgeschnitten zu werden
            // und unter die Seitenpunkte zu laufen.
            ViewThatFits(in: .vertical) {
                VStack(spacing: 20) { inhalt() }.padding(.bottom, 28)
                ScrollView { VStack(spacing: 20) { inhalt() }.padding(.vertical, 8).padding(.bottom, 28) }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Abstand.l) { inhalt() }
                    .padding(.top, art == .salon ? 0 : 8).padding(.bottom, 8).frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// Titel des einen Hauptknopfs. Tinte, Seite 2: mit Namen „Anlegen und weiter“ (legt den Spieler an), sonst „Weiter“.
    /// Zurücknehmen (Blatt 5b ohne Ja): `Self.mitAnlegenKnopf` auf true stellen, dann gilt wieder „Mich anlegen“ als eigener Knopf.
    private var hauptTitel: LocalizedStringKey {
        if seite == letzte { return "Los geht’s" }
        if art == .tinte && seite == 1 && tinteNameBereit && !Self.mitAnlegenKnopf { return "Anlegen und weiter" }
        return "Weiter"
    }

    /// Seite 2 (Tinte) würde ohne Namen und ohne vorhandenen Spieler verlassen, und das wurde noch nicht bestätigt.
    private var nameFehlt: Bool {
        verzeichnis.ich == nil && ichName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !nameUebersprungen
    }

    private var tinteNameBereit: Bool {
        verzeichnis.ich == nil && !ichName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func hauptAktion() {
        if art == .tinte && seite == 1 && tinteNameBereit && !Self.mitAnlegenKnopf {
            guard verzeichnis.speichern(name: ichName, avatar: "", farbeIndex: 0, ich: true) != nil else { return }
            ichFokus = false
        }
        weiter()
    }

    private func weiter() {
        if seite < letzte { withAnimation(weniger ? nil : .easeInOut) { seite += 1 } } else { fertig() }
    }

    /// Kopf einer Seite. `seite` (Nummer wie das `tag` im `TabView`), `symbol` und `rand` braucht nur der Kopf der Designs Tinte und Salon
    /// (`EinfuehrungKopfNeu`: Seitenzahl bzw. Farbblock, der bis an die Seitenränder reicht); „Klar & Glas“ zeigt Titel und Text wie bisher.
    /// Die erste Seite ruft ohne Angaben auf (ihre Zeile bleibt wie in Build 12): Seite 0 mit dem Kachel-Symbol.
    @ViewBuilder private func kopf(_ titel: LocalizedStringKey, _ text: LocalizedStringKey, seite nummer: Int = 0, symbol: String? = nil, rand: CGFloat = 1) -> some View {
        if art != .klar {
            EinfuehrungKopfNeu(nummer: nummer, anzahl: letzte + 1, symbol: symbol ?? (nummer == 0 ? "square.grid.2x2" : nil), titel: titel, text: text,
                               rand: Theme.seitenRand * rand)
                .padding(.horizontal, Theme.seitenRand)
        } else {
        VStack(spacing: Design.Abstand.s) {
            Text(titel).font(.largeTitle.bold()).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
            Text(text).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding(.horizontal, Theme.seitenRand)
        }
    }

    private var willkommen: some View {
        seitenStapel {
            if art == .klar { Spacer() }
            if art == .klar { Image(systemName: "square.grid.2x2.fill").font(.system(size: 72)).foregroundStyle(.tint).accessibilityHidden(true) }
            kopf("Willkommen bei Partie", "\(SpielKatalog.standardModule.count) Spiele für Familie, Freunde und dich allein. Karten, Würfel, Rätsel und mehr, alles in einer App. Wischen, um loszulegen.")
            VStack(alignment: .leading, spacing: Design.Abstand.s) {
                versprechen("nosign", "Keine Werbung")
                versprechen("eurosign.circle", "Kein Bezahlen")
                versprechen("eye.slash", "Kein Tracking")
            }
            .padding(.horizontal, Theme.seitenRand).accessibilityElement(children: .combine)
            // Das Design wählt man auf der eigenen Seite „Design“ in den Einstellungen (Design-Runde 3, R12), nicht mehr hier.
            if art == .klar { Spacer(); Spacer() }
        }
    }

    /// TestFlight 12.11.: Beim ersten Öffnen wählt man das Design. Die Wahl gilt sofort; sie steht auch später in den Einstellungen.
    private var designWahl: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text("Wähle dein Design").font(.headline)
            // K-001: kompakte Wahl (Segmente) statt dreier Zeilen, damit die Seite auf kleinen iPhones ohne Wischen vollständig sichtbar bleibt
            Picker("Design", selection: Binding(get: { art }, set: { Design.art = $0 })) {
                ForEach(DesignArt.allCases) { d in Text(verbatim: d.name).tag(d) }
            }
            .pickerStyle(.segmented).frame(minHeight: 44)
            Text(verbatim: art.kurztext).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text("Du kannst das Design jederzeit in den Einstellungen ändern.").font(.footnote).foregroundStyle(.secondary)
        }.padding(.horizontal, Theme.seitenRand)
    }

    private func versprechen(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        Label { Text(text).font(.headline) } icon: { Image(systemName: symbol).foregroundStyle(.tint).frame(width: 28) }
    }

    /// Zweite Seite: der feste lokale Spieler („Ich“) mit Name und optionalem Foto, ohne Konto. Er ist danach in jedem Spiel vorbelegt.
    /// Überspringen ist erlaubt; auf der Seite „Spieler“ kann man sich jederzeit anlegen. Die Eingabe selbst ist das Blatt aus SpieleKern.
    private var spielerSeite: some View {
        seitenStapel {
            if art == .klar { Spacer() }
            kopf("Wer spielt?", "Lege dich einmal an, mit Name und auf Wunsch Foto. Du stehst dann in jedem Spiel schon bereit. Es gibt kein Konto, alles bleibt auf deinem Gerät.", seite: 1, symbol: "person.crop.circle")
            VStack(spacing: Design.Abstand.m) {
                if let ich = verzeichnis.ich {
                    SpielerBildKreis(ich, groesse: 96).accessibilityHidden(true)
                    Text(verbatim: ich.name).font(.title3.weight(.semibold))
                    Button("Ändern") { spielerAnlegen = true }.zweitKnopf()
                } else {
                    TextField("Dein Name", text: $ichName)
                        .textContentType(.givenName)   // T-023: Apple schlägt den eigenen Vornamen über der Tastatur vor; der Platzhalter „Dein Name“ bleibt
                        .textInputAutocapitalization(.words).autocorrectionDisabled().submitLabel(.done).focused($ichFokus)
                        .onSubmit { ichAnlegen() }
                        .padding(Design.Abstand.m).frame(minHeight: 44)
                        .background(Color.kartenGrund, in: RoundedRectangle(cornerRadius: Design.Ecke.feld))
                    Button("Mich anlegen") { ichAnlegen() }.buttonStyle(HauptKnopfStil())
                        .disabled(ichName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text("Foto und mehr kannst du später unter „Spieler“ ergänzen. Du kannst auch ganz darauf verzichten.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity).padding(.horizontal, Theme.seitenRand)
            if art == .klar { Spacer(); Spacer() }
        }
        .sheet(isPresented: $spielerAnlegen) {
            SpielerBearbeitenBlatt(person: verzeichnis.ich, verzeichnis: verzeichnis, alsIch: true).formSheet()
        }
    }

    /// T-010: legt „Ich“ nur mit dem Namen an (Avatar-Buchstabe und Farbe automatisch).
    private func ichAnlegen() {
        if verzeichnis.speichern(name: ichName, avatar: "", farbeIndex: 0, ich: true) != nil { ichFokus = false }
    }

    private var spiele: some View {
        seitenStapel {
            if art == .klar { Spacer() }
            kopf("Für jeden etwas", "Die Farbe zeigt die Spielart. Beim ersten Mal erklärt sich jedes Spiel selbst.", seite: 2)
            if art != .klar { EinfuehrungSpielarten().padding(.horizontal, Theme.seitenRand) } else {   // Tinte, Salon: Zeilen statt Farbkacheln
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.m), count: 3), spacing: Design.Abstand.m) {
                ForEach(Gattung.allCases.filter { g in SpielKatalog.spielbar.contains { $0.gattung == g } }, id: \.self) { g in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(g.farbe.color)
                            MiniaturAnsicht(g.miniatur, farbe: g.farbe.color, groesse: 1.25)
                        }
                        .frame(height: 76)
                        Text(g.name).font(.footnote.weight(.medium))
                    }.accessibilityElement(children: .combine)
                }
            }.padding(.horizontal, Theme.seitenRand)
            }
            if art == .klar { Spacer(); Spacer() }
        }
    }

    private var favoritenSeite: some View {
        ScrollView {
            VStack(spacing: Design.Abstand.l) {
                kopf("Deine Favoriten", "Tippe die Spiele an, die du oft spielst. Sie liegen dann auf der Startseite ganz vorn. Du kannst das jederzeit ändern.", seite: nr(3))
                // TestFlight 12.11. / T-008: der Schalter steht ganz oben über Suche und Spielkacheln und blendet animiert aus, sobald ein zweites Spiel gewählt ist
                if favoriten.ids.count == 1, let id = favoriten.ids.first, let m = SpielKatalog.modul(id) {
                    Button { startetMit = (startetMit == id) ? "" : id } label: {
                        Label(startetMit == id ? "Startet direkt mit \(Startauswahl.anzeigename(m))" : "Nur \(Startauswahl.anzeigename(m)) nutzen: App startet direkt dort", systemImage: startetMit == id ? "checkmark.circle.fill" : "bolt")
                    }.zweitKnopf().padding(.horizontal, Theme.seitenRand)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                // TestFlight 13.11., Nr. 3: Kommt ein zweiter Favorit dazu, endet „Nur … nutzen“. Das sagt ein kurzer Hinweis, ein paar Sekunden lang,
                // statt dass der Schalter wortlos verschwindet (und die App im Hintergrund weiter direkt in das eine Spiel startet, siehe 10-024).
                if let name = startEndeHinweis {
                    Label("Startet jetzt wieder auf der Startseite, nicht mehr direkt mit \(name). Du hast mehrere Favoriten.", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(Color.schriftZweit).multilineTextAlignment(.leading)
                        .padding(Design.Abstand.m).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.kartenGrund, in: RoundedRectangle(cornerRadius: Design.Ecke.feld))
                        .padding(.horizontal, Theme.seitenRand)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .accessibilityAddTraits(.isStaticText)
                }
                HStack(spacing: Design.Abstand.s) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                    TextField("Spiel suchen", text: $suche).textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.search)
                    if !suche.isEmpty { Button { suche = "" } label: { Image(systemName: "xmark.circle.fill") }.foregroundStyle(.secondary).accessibilityLabel(Text("Suche löschen")) }
                }
                .padding(Design.Abstand.m).background(Color.kartenGrund, in: RoundedRectangle(cornerRadius: Design.Ecke.feld))
                .padding(.horizontal, Theme.seitenRand)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(gefiltert, id: \.id) { m in
                        let an = favoriten.enthaelt(m.id)
                        Button { favoriten.umschalten(m.id) } label: {
                            if art != .klar { EinfuehrungFavoritKachel(modul: m, name: Startauswahl.anzeigename(m), an: an) } else {   // Tinte, Salon: Rand statt Farbfläche
                            VStack(spacing: Design.Abstand.xs) {
                                Image(systemName: EinfuehrungSymbol.name(m.symbol)).font(.title2).frame(height: 32)
                                Text(verbatim: Startauswahl.anzeigename(m)).font(.caption).lineLimit(2).multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 80).padding(6)
                            .foregroundStyle(an ? Color.white : m.gattung.farbe.color)
                            .background(an ? m.gattung.farbe.color : m.gattung.farbe.weich, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(alignment: .topTrailing) { if an { Image(systemName: "checkmark.circle.fill").foregroundStyle(.white).padding(6) } }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(verbatim: Startauswahl.anzeigename(m)))
                        .accessibilityAddTraits(an ? [.isSelected] : [])
                    }
                }.padding(.horizontal, Theme.seitenRand)
            }.padding(.vertical, 8)
            .animation(weniger ? nil : .easeInOut(duration: 0.25), value: favoriten.ids.count)
            .animation(weniger ? nil : .easeInOut(duration: 0.25), value: startEndeHinweis)
        }
        .onChange(of: favoriten.ids.count) { alt, neu in
            // Von einem auf mehr Favoriten: „Nur … nutzen“ endet. Der Wert wird zurückgesetzt, sonst öffnete die App weiter dort (10-024).
            guard alt == 1, neu >= 2, !startetMit.isEmpty, let m = SpielKatalog.modul(startetMit) else { return }
            startetMit = ""
            let name = Startauswahl.anzeigename(m)
            startEndeHinweis = name
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(5))
                if startEndeHinweis == name { startEndeHinweis = nil }
            }
        }
    }

    private var gefiltert: [any SpielModul] {
        let alle = Startauswahl.module
        return suche.trimmingCharacters(in: .whitespaces).isEmpty ? alle : SpielSuche.stichwort(suche, in: alle)
    }

    /// Letzte Seite: zwei freiwillige Dinge, Erinnerungen und Game Center, nebeneinander gestellt. Game Center bleibt aus, bis man es einschaltet.
    private var freiwilligSeite: some View {
        ScrollView {
            VStack(spacing: Design.Abstand.l) {
                kopf("Zwei Dinge, beide freiwillig", "Du kannst beides jederzeit in den Einstellungen ändern. Partie funktioniert auch ohne.", seite: nr(4), symbol: "bell", rand: 2)
                VStack(alignment: .leading, spacing: Design.Abstand.s) {
                    Label { Text("Erinnerungen").font(.headline) } icon: { Image(systemName: "bell.badge").foregroundStyle(.tint).frame(width: 28) }
                    Text("Partie kann dich an die Tagesaufgabe und an angefangene Partien erinnern.").foregroundStyle(.secondary)
                    switch mitteilungen {
                    case .offen:
                        Button("Mitteilungen erlauben") { Task { mitteilungen = await Mitteilungen.fragen(ruhe: false) } }.zweitKnopf()
                    case .erlaubt:
                        Label("Mitteilungen erlaubt", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
                    case .abgelehnt:
                        Text("Nicht erlaubt. Änderbar in den iOS-Einstellungen.").foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()
                VStack(alignment: .leading, spacing: Design.Abstand.s) {
                    Label { Text("Game Center").font(.headline) } icon: { Image(systemName: "trophy").foregroundStyle(.tint).frame(width: 28) }
                    Text("Game Center ist der Spieledienst von Apple. Wenn du ihn einschaltest, sendet Partie deine besten Zeiten und Punkte dorthin, und du kannst Erfolge sammeln. Das ist nicht nötig, um Partie zu spielen. Ohne Game Center bleiben alle Ergebnisse nur auf deinem Gerät.").foregroundStyle(.secondary)
                    if kinder {
                        Text("Im Kinder-Modus ist Game Center aus.").foregroundStyle(.secondary)
                    } else {
                        Toggle("Game Center verwenden", isOn: Binding(get: { gameCenterAn }, set: { an in
                            gameCenterAn = an
                            if an { GameCenterBruecke.geteilt.anmelden() }
                        })).frame(minHeight: 44)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()
            }
            .padding(.horizontal, Theme.seitenRand).padding(.vertical, 8)
        }
    }
}

// MARK: - Tinte, Runde 5 Paket E (Blatt 5 und 5b): alle vier Seiten mit runden Karten

extension EinfuehrungSeiten {
    /// Zwei Wegfälle aus Blatt 5b, deren Ja von Philipp noch aussteht. Zurücknehmen = Wert ändern:
    /// `mitWischenSatz`: Seite 1 zeigt wieder „Wischen, um loszulegen.“ im Text.
    /// `mitAnlegenKnopf`: Seite 2 zeigt wieder den eigenen Knopf „Mich anlegen“ (der Hauptknopf heißt dann immer „Weiter“).
    static let mitWischenSatz = false
    static let mitAnlegenKnopf = false

    fileprivate var kartenRadius: CGFloat { groesse == .regular ? 26 : 22 }
    /// Maß aus dem Entwurf: erster Wert iPad, zweiter iPhone. Schrift wächst mit der Schriftgröße, aber höchstens um 30 %, damit die Überschrift das Größte bleibt.
    fileprivate func p(_ ipad: CGFloat, _ phone: CGFloat) -> CGFloat { (groesse == .regular ? ipad : phone) }
    fileprivate func sz(_ ipad: CGFloat, _ phone: CGFloat) -> CGFloat { p(ipad, phone) * min(schriftSkala, 1.3) }
    fileprivate var innen: CGFloat { p(24, 18) }

    /// Rahmen einer Tinte-Seite: Kopf (n / 4, Serifen-Überschrift, grauer Fließtext) und darunter die Karten; rollt; auf dem iPad höchstens 640 pt breit.
    @ViewBuilder fileprivate func tinteSeite<K: View>(_ nummer: Int, _ titel: LocalizedStringKey, _ text: LocalizedStringKey, @ViewBuilder _ inhalt: () -> K) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "\(nummer + 1) / \(letzte + 1)")
                        .font(Design.Schrift.serif(p(21, 18), relativ: .body, kursiv: true)).foregroundStyle(Color.schriftZweit)
                        .accessibilityLabel(Text("Seite \(nummer + 1) von \(letzte + 1)"))
                    Text(titel)
                        .font(Design.Schrift.serif(p(54, 40), gewicht: .bold, relativ: .largeTitle, hoechstens: 1.2)).tracking(-0.6)
                        .foregroundStyle(Color.schrift).fixedSize(horizontal: false, vertical: true)
                        .padding(.top, p(12, 8)).accessibilityAddTraits(.isHeader)
                    // große Schrift: der Fließtext bleibt kleiner als die Überschrift
                    Text(text).font(.system(size: sz(19, 17))).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
                        .padding(.top, p(16, 12))
                }
                VStack(alignment: .leading, spacing: p(24, 14)) { inhalt() }
                    .padding(.top, p(30, 22))
            }
            .frame(maxWidth: groesse == .regular ? 560 : .infinity, alignment: .leading)
            .padding(.horizontal, Theme.seitenRand).padding(.top, p(70, 16)).padding(.bottom, ichFokus ? 120 : 12)   // Fund 2: bei offener Tastatur Platz, damit die zweite Hinweiszeile über die Seitenpunkte hochrollen kann
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
    }

    // Seite 1
    fileprivate var tinteWillkommen: some View {
        tinteSeite(0, "Willkommen bei Partie", Self.mitWischenSatz
                   ? "\(SpielKatalog.standardModule.count) Spiele für Familie, Freunde und dich allein. Karten, Würfel, Rätsel und mehr, alles in einer App. Wischen, um loszulegen."
                   : "\(SpielKatalog.standardModule.count) Spiele für Familie, Freunde und dich allein. Karten, Würfel, Rätsel und mehr, alles in einer App.") {
            // Spielkacheln nur zur Ansicht (nicht antippbar, für VoiceOver verborgen). T-064: nichts angeschnitten und nichts, das nach Wischen aussieht:
            // genau so viele Kacheln, wie nebeneinander passen (iPhone drei, iPad vier), jede gleich breit.
            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(["yacht", "viererreihe", "sudoku", "solitaer"].compactMap { SpielKatalog.modul($0) }.prefix(groesse == .regular ? 4 : 3)), id: \.id) { k in tinteKachel(k) }
            }
            .padding(.vertical, 4)
            .allowsHitTesting(false).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                tinteVersprechen("nosign", "Keine Werbung"); Rectangle().fill(Color.linie).frame(height: 1)
                tinteVersprechen("eurosign.circle", "Kein Bezahlen"); Rectangle().fill(Color.linie).frame(height: 1)
                tinteVersprechen("eye.slash", "Kein Tracking")
            }
            .accessibilityElement(children: .combine)
            .einfuehrungKarte(kartenRadius, innen: innen, senkrecht: p(8, 6))
        }
    }

    private func tinteKachel(_ k: any SpielModul) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                TischGrund(k.gattung.farbe.color)
                MiniaturAnsicht(SpielMiniaturen.art(k), farbe: k.gattung.farbe.color, groesse: 1.25)
            }
            .frame(maxWidth: .infinity).frame(height: 92)
            VStack(alignment: .leading, spacing: 2) {
                KachelName(name: k.name, festeSkala: 0.8)   // Fund 1: alle Kachelnamen gleich groß (kein Verkleinern je Name)
                Text(verbatim: SpielZeilen.spielerText(k)).font(.caption).foregroundStyle(Color.schriftZweit).lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(Color.kartenGrund)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.linie, lineWidth: 1))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func tinteVersprechen(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            EinfuehrungMarke(symbol: symbol, farbe: EinfuehrungMarke.akzent, zeichen: EinfuehrungMarke.elfenbein, groesse: p(42, 36))
            Text(text).font(.system(size: sz(20, 17.5), weight: .bold)).foregroundStyle(Color.schrift)
            Spacer(minLength: 0)
        }.padding(.vertical, p(13, 11))
    }

    // Seite 2
    fileprivate var tinteSpieler: some View {
        tinteSeite(1, "Wer spielt?", "Lege dich einmal an, mit Name und auf Wunsch Foto. Du stehst dann in jedem Spiel schon bereit. Es gibt kein Konto, alles bleibt auf deinem Gerät.") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    if let ich = verzeichnis.ich {
                        SpielerBildKreis(ich, groesse: 56).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: ich.name).font(.title3.weight(.semibold)).foregroundStyle(Color.schrift)
                            Button("Ändern") { spielerAnlegen = true }.zweitKnopf()
                        }
                        Spacer(minLength: 0)
                    } else {
                        let buchstabe = ichName.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() }
                        ZStack {
                            Circle().fill(buchstabe == nil ? Color.schriftZweit.opacity(0.25) : Spieler.farbe(0))
                            if let b = buchstabe { Text(verbatim: b).font(.title2.weight(.semibold)).foregroundStyle(.white) }
                            else { Image(systemName: "person.fill").font(.title2).foregroundStyle(Color.schriftZweit) }
                        }
                        .frame(width: 56, height: 56).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dein Name").font(.caption.weight(.semibold)).foregroundStyle(Color.schriftZweit).textCase(.uppercase)
                            TextField("", text: $ichName)   // Platzhalter leer: „Dein Name“ steht schon darüber
                                .accessibilityLabel(Text("Dein Name"))
                                .textContentType(.givenName)   // T-023: Apple schlägt den eigenen Vornamen über der Tastatur vor
                                .textInputAutocapitalization(.words).autocorrectionDisabled().submitLabel(.done).focused($ichFokus)
                                .onSubmit { if tinteNameBereit { hauptAktion() } }
                                .padding(.horizontal, 12).frame(minHeight: 44)
                                .background(Color.seitenGrund, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.linie, lineWidth: 1))
                        }
                    }
                }
                if Self.mitAnlegenKnopf && verzeichnis.ich == nil {
                    Button("Mich anlegen") { ichAnlegen() }.buttonStyle(HauptKnopfStil()).disabled(!tinteNameBereit)
                }
            }
            .einfuehrungKarte(kartenRadius, innen: innen)
            if verzeichnis.ich == nil {
                Text("Foto und mehr kannst du später unter „Spieler“ ergänzen. Du kannst auch ganz darauf verzichten.")
                    .font(.footnote).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
        .sheet(isPresented: $spielerAnlegen) {
            SpielerBearbeitenBlatt(person: verzeichnis.ich, verzeichnis: verzeichnis, alsIch: true).formSheet()
        }
    }

    // Seite 3
    fileprivate var tinteFavoriten: some View {
        tinteSeite(2, "Deine Favoriten", "Tippe die Spiele an, die du oft spielst. Sie liegen dann auf der Startseite ganz vorn. Du kannst das jederzeit ändern.") {
            HStack(spacing: Design.Abstand.s) {
                Image(systemName: "magnifyingglass").foregroundStyle(Color.schriftZweit).accessibilityHidden(true)
                TextField("Spiel suchen", text: $suche).textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.search)
                if !suche.isEmpty { Button { suche = "" } label: { Image(systemName: "xmark.circle.fill") }.foregroundStyle(Color.schriftZweit).accessibilityLabel(Text("Suche löschen")) }
            }
            .padding(.horizontal, 16).frame(minHeight: 46)
            .background(Color.schrift.opacity(0.06), in: Capsule())   // gefüllte Kapsel ohne Rand (Entwurf: #F1F0EC)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: p(14, 10)), count: 3), spacing: p(14, 10)) {
                ForEach(gefiltert, id: \.id) { m in
                    let an = favoriten.enthaelt(m.id)
                    Button { favoriten.umschalten(m.id) } label: {
                        VStack(spacing: 9) {
                            EinfuehrungMarke(symbol: EinfuehrungSymbol.name(m.symbol), farbe: m.gattung.farbe.color, groesse: 46)
                            Text(verbatim: Startauswahl.anzeigename(m)).font(.system(size: sz(14.5, 13), weight: an ? .semibold : .medium)).foregroundStyle(Color.schrift).lineLimit(2).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: p(118, 104)).padding(.vertical, 10).padding(.horizontal, 6)
                        .background(Color.kartenGrund, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(an ? Color.schrift : Color.linie, lineWidth: an ? 2 : 1))
                        .overlay(alignment: .topTrailing) {
                            if an {
                                Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(Color.seitenGrund)
                                    .frame(width: 20, height: 20).background(Color.schrift, in: Circle()).padding(6)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: Startauswahl.anzeigename(m)))
                    .accessibilityAddTraits(an ? [.isSelected] : [])
                }
            }
            // T-068: Platz unter der letzten Reihe, damit sie sich unter der schwebenden Einblendung hervorscrollen lässt
            Color.clear.frame(height: p(96, 90)).accessibilityHidden(true)
        }
        // T-068: Schalter „Nur … nutzen“ und der Hinweis schweben unten über der Liste (nicht im Layoutfluss). Beim Ein- und Ausblenden
        // ändert sich die Höhe der Liste nicht, sie springt nicht und lässt keine Lücke.
        .overlay(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                if favoriten.ids.count == 1, let id = favoriten.ids.first, let m = SpielKatalog.modul(id) {
                    let name = Startauswahl.anzeigename(m)
                    Toggle(isOn: Binding(get: { startetMit == id }, set: { startetMit = $0 ? id : "" })) {
                        HStack(spacing: 12) {
                            EinfuehrungMarke(symbol: "bolt.fill", farbe: EinfuehrungMarke.akzent, zeichen: EinfuehrungMarke.elfenbein, groesse: p(40, 34))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Nur \(name) nutzen").font(.system(size: sz(16, 15), weight: .semibold)).foregroundStyle(Color.schrift)
                                Text("Die App startet direkt dort.").font(.system(size: sz(13.5, 13.5))).foregroundStyle(Color.schriftZweit)
                            }
                        }
                    }
                    .einstellungsSchalter()   // ST Stufe 1: an grün, aus grau (T-066)
                    .frame(minHeight: 44)
                    .einfuehrungKarte(kartenRadius, innen: p(20, 16), senkrecht: p(14, 12))
                    .transition(.opacity)
                } else if let name = startEndeHinweis {
                    HStack(alignment: .top, spacing: 12) {
                        EinfuehrungMarke(symbol: "info", farbe: EinfuehrungMarke.akzent, zeichen: EinfuehrungMarke.elfenbein, groesse: 32)
                        Text("Startet jetzt wieder auf der Startseite, nicht mehr direkt mit \(name). Du hast mehrere Favoriten.")
                            .font(.footnote).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .einfuehrungKarte(kartenRadius)
                    .transition(.opacity)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        }
        .animation(weniger ? nil : .easeInOut(duration: 0.6), value: favoriten.ids.count)
        .animation(weniger ? nil : .easeInOut(duration: 0.6), value: startEndeHinweis)
        .onChange(of: favoriten.ids.count) { alt, neu in
            // Von einem auf mehr Favoriten: „Nur … nutzen“ endet. Der Wert wird zurückgesetzt, sonst öffnete die App weiter dort (10-024).
            guard alt == 1, neu >= 2, !startetMit.isEmpty, let m = SpielKatalog.modul(startetMit) else { return }
            startetMit = ""
            let name = Startauswahl.anzeigename(m)
            startEndeHinweis = name
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(9))   // T-067: lang genug zum Lesen
                if startEndeHinweis == name { startEndeHinweis = nil }
            }
        }
    }

    // Seite 4
    fileprivate var tinteFreiwillig: some View {
        tinteSeite(3, "Noch zwei Dinge", "Beides ist freiwillig. Du kannst es jederzeit in den Einstellungen ändern.") {
            EinfuehrungMitteilungenKarte(text: "Partie erinnert dich an die Tagesaufgabe und an angefangene Partien.", status: mitteilungen) {
                Task { mitteilungen = await Mitteilungen.fragen(ruhe: false) }
            }
            let marke = p(54, 43), luecke = p(18, 14)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: luecke) {
                    EinfuehrungMarke(symbol: "trophy.fill", farbe: EinfuehrungMarke.gameCenter, groesse: marke)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Game Center").font(.system(size: sz(20, 17.5), weight: .bold)).foregroundStyle(Color.schrift)
                        Text("Bestenlisten und Erfolge von Apple. Ohne Game Center bleiben alle Ergebnisse nur auf deinem Gerät.")
                            .font(.system(size: sz(16, 14.5))).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
                    }
                }
                // feine Linie über der Zeile; auf dem iPad beginnen Linie und Zeile an der Textkante
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle().fill(Color.linie).frame(height: 1)
                    if kinder {
                        Text("Im Kinder-Modus ist Game Center aus.").font(.footnote).foregroundStyle(Color.schriftZweit).padding(.top, 14)
                    } else {
                        Toggle(isOn: Binding(get: { gameCenterAn }, set: { an in
                            gameCenterAn = an
                            if an { GameCenterBruecke.geteilt.anmelden() }
                        })) { Text("Game Center verwenden").font(.system(size: sz(16, 16), weight: .medium)).foregroundStyle(Color.schrift) }
                            .einstellungsSchalter()   // ST Stufe 1: an grün, aus grau (T-066)
                            .frame(minHeight: 44).padding(.top, p(10, 8))
                    }
                }
                .padding(.top, p(20, 14)).padding(.leading, groesse == .regular ? marke + luecke : 0)
            }
            .einfuehrungKarte(kartenRadius, innen: innen)
        }
    }
}

/// Auf dem iPad hält `iPadSpalte` die ganze Seite in einer Spalte; Tinte setzt die Breite je Seite selbst (Inhalt 640 pt, die Spielreihe läuft bis an den Rand).
struct EinfuehrungSpalte: ViewModifier {
    let tinte: Bool
    func body(content: Content) -> some View {
        if tinte { content } else { content.iPadSpalte() }
    }
}

/// Runde farbige Marke mit weißem Zeichen (Tinte-Einführung).
struct EinfuehrungMarke: View {
    let symbol: String
    var farbe: Color
    var zeichen: Color = .white
    var groesse: CGFloat = 36
    /// Akzentfarbe der Marken ohne Spielart-Farbe (Blitz, Glocke, Seite 1): Tintengrau #4A4D57 (Bauplan E 2d; Philipp 13.11.: kein Gold).
    /// Eine Stelle zum Ändern. Das Zeichen darin ist Elfenbein #FFFDF6.
    static var akzent: Color { Color(red: 0x4A / 255, green: 0x4D / 255, blue: 0x57 / 255) }
    static var elfenbein: Color { Color(red: 1, green: 0xFD / 255, blue: 0xF6 / 255) }
    /// Game Center: Blau #4B5FAE
    static var gameCenter: Color { Color(red: 0x4B / 255, green: 0x5F / 255, blue: 0xAE / 255) }
    var body: some View {
        Image(systemName: symbol).font(.system(size: groesse * 0.48, weight: .semibold)).foregroundStyle(zeichen)
            .frame(width: groesse, height: groesse).background(farbe, in: Circle()).accessibilityHidden(true)
    }
}

/// Weiße runde Karte: feiner Rand, weicher Schatten (Radius 22 pt iPhone, 26 pt iPad).
extension View {
    func einfuehrungKarte(_ radius: CGFloat, innen: CGFloat = 16, senkrecht: CGFloat? = nil) -> some View {
        self.padding(.horizontal, innen).padding(.vertical, senkrecht ?? innen).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.kartenGrund, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Color.linie, lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

/// Frage nach Mitteilungen als Karte: Seite 4 der Einführung und das Blatt „Was ist neu?“ (Tinte).
struct EinfuehrungMitteilungenKarte: View {
    let text: LocalizedStringKey
    let status: MitteilungsStatus
    var gesperrt = false
    let erlauben: () -> Void
    @Environment(\.horizontalSizeClass) private var groesse
    @ScaledMetric(relativeTo: .body) private var skala: CGFloat = 1

    private var ipad: Bool { groesse == .regular }
    private func sz(_ a: CGFloat, _ b: CGFloat) -> CGFloat { (ipad ? a : b) * min(skala, 1.3) }

    var body: some View {
        let marke: CGFloat = ipad ? 54 : 43, luecke: CGFloat = ipad ? 18 : 14
        VStack(alignment: .leading, spacing: ipad ? 20 : 16) {
            HStack(alignment: .top, spacing: luecke) {
                EinfuehrungMarke(symbol: "bell.fill", farbe: EinfuehrungMarke.akzent, zeichen: EinfuehrungMarke.elfenbein, groesse: marke)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Erinnerungen").font(.system(size: sz(20, 17.5), weight: .bold)).foregroundStyle(Color.schrift)
                    Text(text).font(.system(size: sz(16, 14.5))).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
                }
            }
            Group {
                switch status {
                case .offen:
                    // gefüllter dunkler Knopf; auf dem iPad so breit wie der Text plus 24 pt je Seite, an der Textkante, auf dem iPhone über die Kartenbreite
                    Button { erlauben() } label: {
                        Text("Mitteilungen erlauben").font(.system(size: sz(15.5, 15.5), weight: .semibold)).foregroundStyle(Color.seitenGrund)
                            .padding(.horizontal, 24).frame(height: 46).frame(maxWidth: ipad ? nil : .infinity)
                            .background(Color.schrift, in: Capsule())
                    }
                    .buttonStyle(.plain).disabled(gesperrt).opacity(gesperrt ? 0.4 : 1)
                case .erlaubt: Label("Mitteilungen erlaubt", systemImage: "checkmark.circle.fill").foregroundStyle(Color.schriftZweit)
                case .abgelehnt: Text("Nicht erlaubt. Änderbar in den iOS-Einstellungen.").font(.footnote).foregroundStyle(Color.schriftZweit)
                }
            }
            .padding(.leading, ipad ? marke + luecke : 0)
        }
        .einfuehrungKarte(ipad ? 26 : 22, innen: ipad ? 24 : 18)
    }
}

/// Die 26 Startspiele (Doku/START-SPIELE-1.0.md) für die Auswahl der Einführung.
@MainActor
enum Startauswahl {
    /// Grund-IDs in Anzeigereihenfolge (nach Spielart).
    static let grundIDs = [
        "solitaer", "maumau", "schwimmen", "elferraus", "romme", "mogeln", "siebzehnundvier", "herzensjagd",
        "yacht", "schocken", "10k", "maexchen", "chicago", "pokerwurf", "koenigsweg",
        "sudoku", "minensuche", "kakuro", "schiebepuzzle", "irrgang", "farbflut",
        "viererreihe", "rauswurf", "muehle",
        "galgenmaennchen",
        "wortpfeil",   // Kreuzworträtsel (26. Spiel, 10.11.2026)
    ]

    static var module: [any SpielModul] {
        grundIDs.compactMap { SpielKatalog.modul($0) }.filter { Modi.kinder ? !Modi.gesperrt.contains($0.id) : true }
    }

    static func anzeigename(_ m: any SpielModul) -> String {
        m.name
    }
}
