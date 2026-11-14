// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – „Neues Spiel“ (Konzept 3.4 „Neues Spiel“): EIN Blatt mit Schließen oben rechts, Titel `.title2` fett links,
// Karten für Spieler, Stufe, Varianten, Regeln (mit Section-Label), unten EIN Hauptknopf „Los geht's“.
// Keine Chips unter dem Knopf, keine Navigationsseite. Apps ohne Fragen zeigen nur die Stufe, die letzte ist vorgewählt.

/// Ein Spieler in der Spielerliste (Name, Art, Spielerfarbe, Avatar). Die App hält das Feld `[SpielerEintrag]` und speichert es.
public struct SpielerEintrag: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    /// `SpielerArt.id`, z. B. „mensch“, „computer“
    public var art: String
    public var farbeHex: UInt32?
    /// Spielerfarbe direkt als `Color` (2.7, Wunsch 15), z. B. die Sitzfarbe aus einem Brett-Theme. Hat Vorrang vor `farbeHex`.
    public var farbe: Color?
    /// Avatar-Zeichen (Emoji) im Kreis statt der Initiale (2.7, Wunsch 15). Welche Avatare es gibt, ist Spielinhalt der App.
    public var symbol: String?
    /// Foto der Person als Bilddaten (2.12); hat in der Spielerliste Vorrang vor `symbol`.
    public var bild: Data?

    public init(id: UUID = UUID(), name: String, art: String = "mensch", farbeHex: UInt32? = nil,
                farbe: Color? = nil, symbol: String? = nil, bild: Data? = nil) {
        self.id = id; self.name = name; self.art = art; self.farbeHex = farbeHex; self.farbe = farbe; self.symbol = symbol; self.bild = bild
    }
}

#if canImport(UIKit)

public extension SpielerEintrag {
    /// Farbe für die Anzeige: `farbe`, sonst `farbeHex` als `Color`.
    var anzeigeFarbe: Color? { farbe ?? farbeHex.map { Color(hex: $0) } }
}

/// Wählbare Spielerart (Mensch, Computer leicht/schwer …). Hat eine App nur eine Art, bleibt das Menü aus.
public struct SpielerArt: Identifiable, Equatable {
    public let id: String
    public let name: LocalizedStringKey
    public let symbol: String

    public init(id: String, name: LocalizedStringKey, symbol: String = "person.fill") {
        self.id = id; self.name = name; self.symbol = symbol
    }

    public static func == (a: SpielerArt, b: SpielerArt) -> Bool { a.id == b.id }
}

/// Das Blatt „Neues Spiel“. Als `.sheet` zeigen; `formSheet()` und Griff sind eingebaut. Inhalt: `NeuesSpielKarte`, `StufenWahl`,
/// `SpielerListe` in einer Karte, weitere Karten der App. `losAktiv: false` sperrt den Hauptknopf (z. B. zu wenige Spieler).
public struct NeuesSpielBlatt<Inhalt: View>: View {
    let titel: Text
    let losTitel: Text
    let losAktiv: Bool
    /// Meldung, wenn jemand bei gesperrtem Knopf tippt (fehlende Pflichtfelder). Ohne Angabe: allgemeiner Text.
    let losHinweis: Text
    /// Derselbe Hinweis als Zeichenkette für die VoiceOver-Ansage (2.26).
    let hinweisAnsage: String
    let schliessen: () -> Void
    let los: () -> Void
    let inhalt: Inhalt
    @State private var inhaltHoehe: CGFloat = 0
    @State private var hinweisSichtbar = false
    @State private var tastaturSichtbar = false   // Build-12-Fund S2-013: mit Tastatur ganz hoch, sonst wird das Blatt auf ein Drittel gequetscht
    @Environment(\.designArt) private var art
    @Environment(\.dynamicTypeSize) private var schrift

    /// Blatt so hoch wie der Inhalt (Wunsch 7), ziehbar bis ganz hoch. Vor der ersten Messung halb hoch.
    private var detents: Set<PresentationDetent> {
        if tastaturSichtbar || schrift.isAccessibilitySize { return [.large] }   // 2.22 G-002/N-018: bei größter Schrift ganz hoch, nie ein zu niedriges Blatt
        guard inhaltHoehe > 0 else { return [.medium, .large] }
        let rahmen = 12 + Theme.tapSize + 2 * Theme.kartenAbstand + Theme.hauptKnopfHoehe + 8 + 20
        return [.height(inhaltHoehe + rahmen), .large]
    }

    public init(titel: LocalizedStringKey? = nil, losTitel: LocalizedStringKey? = nil, losAktiv: Bool = true,
                losHinweis: LocalizedStringKey? = nil, losHinweisAnsage: String? = nil,
                schliessen: @escaping () -> Void, los: @escaping () -> Void, @ViewBuilder inhalt: () -> Inhalt) {
        self.titel = titel.map { Text($0) } ?? Text("Neues Spiel", bundle: .module)
        self.losTitel = losTitel.map { Text($0) } ?? Text("Los geht's", bundle: .module)
        self.losHinweis = losHinweis.map { Text($0) } ?? Text("Bitte zuerst alle Pflichtfelder ausfüllen.", bundle: .module)
        self.hinweisAnsage = losHinweisAnsage ?? String(localized: "Bitte zuerst alle Pflichtfelder ausfüllen.", bundle: .module)
        self.losAktiv = losAktiv; self.schliessen = schliessen; self.los = los; self.inhalt = inhalt()
    }

    public var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            HStack(alignment: .center) {
                // Tinte: Titel in Serifenschrift (Formularblatt). Salon: Titel als Schlagzeile.
                titel.font(art == .klar ? .title2.weight(.bold)
                           : Design.Schrift.serif(art == .salon ? 40 : 34, gewicht: art == .salon ? .bold : .medium, relativ: .title, hoechstens: 1.2))
                    .tracking(art == .klar ? 0 : (art == .salon ? -1.2 : -0.7))
                    .lineLimit(art == .klar ? nil : 2).minimumScaleFactor(art == .klar ? 1 : 0.6)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                RundKnopf(symbol: "xmark", beschriftungText: Text("Schließen", bundle: .module), klein: true, aktion: schliessen)
            }
            .padding(.top, 12)
            ScrollView {
                VStack(spacing: art == .klar ? Theme.kartenAbstand : Design.Abstand.xs) { inhalt }
                    .toggleStyle(BlattSchalterStil())   // Tinte und Salon: Varianten als Kästchen; klar: Schalter wie bisher
                    .padding(.bottom, Theme.seitenRand)   // Wunsch 10 (2.4): Inhalt endet 16 pt über dem Knopf, letzte Karte nicht angeschnitten
                    .background(GeometryReader { g in Color.clear.preference(key: InhaltHoehe.self, value: g.size.height) })
                // 2.37 A-005: Bei Bedienungshilfe-Schrift steht „Los geht's“ am Ende des Inhalts, nichts liegt darunter.
                if schrift.isAccessibilitySize { losBereich.padding(.bottom, 8) }
            }
            .onPreferenceChange(InhaltHoehe.self) { inhaltHoehe = $0 }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(schrift.isAccessibilitySize ? .visible : .hidden)
            .scrollIndicatorsFlash(onAppear: true)
            .scrollDismissesKeyboard(.interactively)
            if !schrift.isAccessibilitySize { losBereich }
        }
        // 2.26 G-002/N-018: Das ganze Blatt wächst gleichmäßig bis accessibility2 (wie die Knöpfe seit 2.25); vorher blieben
        // Spielerzeilen bei xxxLarge stehen, während Überschriften, Chips und Warntexte bis accessibility5 wuchsen.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .padding(.horizontal, Theme.seitenRand)
        .padding(.bottom, 8)
        .iPadSpalte()
        .background(Color.seitenGrund)
        .designWurzel()
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in tastaturSichtbar = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in tastaturSichtbar = false }
        .presentationDragIndicator(.hidden)
        .presentationDetents(detents)
        .formSheet()
    }
}

extension NeuesSpielBlatt {
    /// 2.37 A-005: Hinweis bei gesperrtem Start und der Hauptknopf; unter dem Inhalt oder (Bedienungshilfe-Schrift) am Ende des Inhalts.
    @ViewBuilder private var losBereich: some View {
        if hinweisSichtbar && !losAktiv {
            Label { losHinweis.fixedSize(horizontal: false, vertical: true) } icon: { Image(systemName: "exclamationmark.circle.fill") }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        }
        // Gesperrt wird nur optisch (abgedunkelt): Tippen zeigt die Meldung, statt ins Leere zu gehen. VoiceOver nennt den Grund als Hinweis.
        Button(action: losTippen) { losTitel.lineLimit(1).minimumScaleFactor(0.7) }
            .hauptKnopf()
            .opacity(losAktiv ? 1 : 0.4)
            .accessibilityHint(losAktiv ? Text(verbatim: "") : losHinweis)
            .onChange(of: losAktiv) { _, aktiv in if aktiv { hinweisSichtbar = false } }
    }

    /// Aktiv: los. Gesperrt: Meldung zeigen (sichtbar, mit Haptik und VoiceOver-Ansage).
    fileprivate func losTippen() {
        if losAktiv {
            // 2.22 G-015: Tastatur zuerst schließen und erst nach ihrer Abwärtsbewegung starten. Sonst wechselt die Blatthöhe (Detents)
            // genau während des Schließens, und das Blatt blieb in einem Lauf über dem laufenden Spiel stehen.
            if tastaturSichtbar {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { los() }
            } else { los() }
            return
        }
        withAnimation(.easeOut(duration: 0.2)) { hinweisSichtbar = true }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        // 2.26 T-017: Die Meldung wird auch angesagt (vorher nur Haptik; der Kommentar oben versprach die Ansage schon)
        UIAccessibility.post(notification: .announcement, argument: hinweisAnsage)
    }
}

/// Schalter im Blatt „Neues Spiel“: in klar der Schalter des Systems (unverändert), in Tinte und Salon ein Kästchen.
struct BlattSchalterStil: ToggleStyle {
    @Environment(\.designArt) private var art

    func makeBody(configuration: Configuration) -> some View {
        if art == .klar {
            // 2.39 F21-006: Dieselbe Schalter-Instanz weitergeben statt einen zweiten Toggle zu bauen. Vorher lag im Bedienungshilfen-Baum
            // neben dem beschrifteten Schalter ein zweiter namenloser (der innere Toggle sah die für VoiceOver verborgenen Label-Texte).
            SchalterZeile(configuration: configuration)   // 2.40 F21-006: auch hier ein einziges Element (2.39 reichte am Gerät nicht)
        } else {
            KaestchenStil().makeBody(configuration: configuration)
        }
    }
}

/// Gemessene Inhaltshöhe (für `NeuesSpielBlatt.detents`).
struct InhaltHoehe: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Karte im Blatt „Neues Spiel“: Section-Label („SPIELER“, „VARIANTEN“, „REGELN“) + Inhalt.
public struct NeuesSpielKarte<Inhalt: View>: View {
    let titel: Text
    let inhalt: Inhalt

    public init(_ titel: LocalizedStringKey, @ViewBuilder inhalt: () -> Inhalt) {
        self.titel = Text(titel); self.inhalt = inhalt()
    }

    public init(titel: Text, @ViewBuilder inhalt: () -> Inhalt) {
        self.titel = titel; self.inhalt = inhalt()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: titel)
            inhalt
        }
        .card()
    }
}

/// Stufenwahl: Karte mit Section-Label „Stufe“, Chips (gewählt = App-Farbe, sonst grau) und Untertitel der gewählten Stufe
/// („7 × 9 Felder, 10 Minen“). Ersetzt Segmente, Stufen-Karten und lose Chips.
public struct StufenWahl<ID: Hashable>: View {
    public struct Stufe: Identifiable {
        public let id: ID
        public let name: LocalizedStringKey
        public let untertitel: String?
        public init(id: ID, name: LocalizedStringKey, untertitel: String? = nil) {
            self.id = id; self.name = name; self.untertitel = untertitel
        }
    }

    let titel: Text
    let stufen: [Stufe]
    @Binding var auswahl: ID
    @Environment(\.designArt) private var art

    public init(titel: LocalizedStringKey? = nil, stufen: [Stufe], auswahl: Binding<ID>) {
        self.titel = titel.map { Text($0) } ?? Text("Stufe", bundle: .module)
        self.stufen = stufen; _auswahl = auswahl
    }

    /// Bis drei Stufen eine Reihe, genau vier immer 2 × 2 (nie 3 + 1, Wunsch 8), mehr nach Platz.
    private var spalten: [GridItem] {
        switch stufen.count {
        case ...3: Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.s), count: max(stufen.count, 1))
        case 4: Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.s), count: 2)
        default: [GridItem(.adaptive(minimum: 88), spacing: Design.Abstand.s)]
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: titel)
            LazyVGrid(columns: spalten, spacing: Design.Abstand.s) {
                ForEach(stufen) { s in
                    let gewaehlt = s.id == auswahl
                    Button { auswahl = s.id } label: {
                        // 2.3: Das Label selbst ist 44 pt hoch (Accessibility-Frame = Tippfläche); die 36-pt-Kapsel liegt nur als
                        // Hintergrund darunter. Vorher (frame nach dem background) maß XCUITest das Label mit 42,2 pt.
                        // 2.5 (Wunsch 11): Schrift wächst nur bis xxxLarge, die Kapsel ist mindestens 36 pt und wächst mit dem Text
                        // (Label 44 pt minus 4 pt Rand oben und unten), statt fest 36 pt zu bleiben.
                        switch art {
                        case .klar:
                            Text(s.name)
                                .font(.subheadline.weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .padding(.horizontal, 10)
                                .foregroundStyle(gewaehlt ? Color.onAccent : Color.primary)
                                .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
                                .background {
                                    Capsule().fill(gewaehlt ? Color.appFlaeche : Color.feldGrund)
                                        .padding(.vertical, 4)
                                }
                                .contentShape(.rect)
                        case .tinte:
                            // Auswahl mit Kreis (Radio), Name daneben
                            HStack(spacing: Design.Abstand.s) {
                                AuswahlKreis(gewaehlt: gewaehlt)
                                Text(s.name).font(.body.weight(gewaehlt ? .semibold : .regular))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                    .foregroundStyle(Color.schrift)
                            }
                            .frame(maxWidth: .infinity, minHeight: Theme.tapSize, alignment: .leading)
                            .contentShape(.rect)
                        case .salon:
                            // Rechteck mit Rand, gewählt gefüllt
                            Text(s.name)
                                .font(Design.Schrift.text(14, gewicht: .bold, relativ: .subheadline, hoechstens: 1.25))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .padding(.horizontal, 10)
                                .foregroundStyle(gewaehlt ? Color.seitenGrund : Color.schrift)
                                .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
                                .background(gewaehlt ? Color.schrift : Color.clear)
                                .overlay { Rectangle().strokeBorder(Color.linieStark, lineWidth: 2) }
                                .contentShape(.rect)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(gewaehlt ? [.isSelected] : [])
                }
            }
            if let u = stufen.first(where: { $0.id == auswahl })?.untertitel {
                Text(verbatim: u).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

/// Spielerliste im Blatt „Neues Spiel“: Avatar, Name (editierbar), Art-Menü, Griff zum Umsortieren, Entfernen,
/// darunter „Spieler hinzufügen“. Die App hält das Feld, der Baustein ändert es über das Binding.
///
/// 2.7 (Wunsch 15): `avatarTippen` macht den Avatar antippbar (die App zeigt dann ihre eigene Avatar-Wahl, E.5);
/// `zusatz` ist ein kleiner Platz je Zeile vor dem Art-Menü, z. B. für die Würfelart. Er muss in eine 56-pt-Zeile passen:
/// ein Knopf oder Menü, höchstens etwa 60 pt breit – keine Texte, keine zweite Zeile.
public struct SpielerListe<Zusatz: View>: View {
    @Binding var spieler: [SpielerEintrag]
    let arten: [SpielerArt]
    let minimum: Int
    let maximum: Int
    let neuerName: (Int) -> String
    let farben: [UInt32]
    let avatarTippen: ((SpielerEintrag) -> Void)?
    let zusatz: (Binding<SpielerEintrag>) -> Zusatz
    @State private var zug: Zug? = nil
    @FocusState private var fokus: UUID?
    @Environment(\.designArt) private var art
    @Environment(\.dynamicTypeSize) private var schrift
    /// 2.26 G-002: Zeilenhöhe wächst mit der Schrift (56 pt bei Standardgröße, höchstens 96 pt), statt die Liste bei xxxLarge zu deckeln.
    @ScaledMetric(relativeTo: .body) private var zeilenSkaliert: CGFloat = 56

    private struct Zug { let id: UUID; let start: Int; var verschiebung: CGFloat }
    private var zeilenHoehe: CGFloat { min(max(zeilenSkaliert, 56), 96) }
    /// 2.45 (große Tinte-Runde, Punkt 2): Bei Schriftgrößen der Bedienungshilfen steht die Art (Mensch, Computer) als Wort in einer
    /// zweiten Zeile unter dem Namen. So bleibt der Name ganz lesbar, und die Art ist nicht nur ein Symbol.
    private var zweizeilig: Bool { art == .tinte && schrift.isAccessibilitySize && arten.count > 1 }   // nur Tinte (Philipp 13.11.: Klar/Salon unverändert)
    /// Höhe einer ganzen Zeile samt zweiter Zeile; der Griff zum Umsortieren rechnet damit.
    private var zeilenGesamt: CGFloat { zeilenHoehe + (zweizeilig ? Theme.tapSize : 0) }

    /// `farben`: Spielerfarben (Hex) in Reihenfolge; ein neuer Spieler bekommt die erste freie. `neuerName`: Name für Spieler n (1-basiert).
    /// Vorgabename „Spieler n“ (öffentlich, damit er als Standardwert dienen kann).
    public static func vorgabeName(_ n: Int) -> String {
        String(localized: "Spieler \(n)", bundle: .module, comment: "Vorgabename für einen neuen Spieler")
    }

    public init(spieler: Binding<[SpielerEintrag]>, arten: [SpielerArt] = [], minimum: Int = 2, maximum: Int = 6,
                farben: [UInt32] = [], neuerName: @escaping (Int) -> String = SpielerListe.vorgabeName,
                avatarTippen: ((SpielerEintrag) -> Void)? = nil,
                @ViewBuilder zusatz: @escaping (Binding<SpielerEintrag>) -> Zusatz) {
        _spieler = spieler; self.arten = arten; self.minimum = minimum; self.maximum = maximum
        self.farben = farben; self.neuerName = neuerName; self.avatarTippen = avatarTippen; self.zusatz = zusatz
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(spieler.enumerated()), id: \.element.id) { index, s in
                zeile(index: index, eintrag: s)
                    .zIndex(zug?.id == s.id ? 1 : 0)
                    .offset(y: versatz(index: index, id: s.id))
                if index < spieler.count - 1 || spieler.count < maximum {
                    if art == .klar { Divider() } else { ZeilenLinie() }
                }
            }
            if spieler.count < maximum {
                Button(action: hinzufuegen) {
                    Label { Text("Spieler hinzufügen", bundle: .module) } icon: { Image(systemName: art == .klar ? "plus.circle.fill" : "plus") }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentText)
                        .frame(maxWidth: .infinity, minHeight: Theme.tapSize, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        // 2.26 G-002: keine eigene Deckelung mehr (das Blatt deckelt bei accessibility2); die Zeilenhöhe wächst mit, der Griff rechnet mit ihr.
    }

    private func binding(_ id: UUID) -> Binding<SpielerEintrag>? {
        guard let i = spieler.firstIndex(where: { $0.id == id }) else { return nil }
        return $spieler[i]
    }

    @ViewBuilder
    private func zeile(index: Int, eintrag s: SpielerEintrag) -> some View {
        if let b = binding(s.id) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Design.Abstand.m) {
                if let avatarTippen {
                    Button { avatarTippen(s) } label: {
                        SpielerAvatar(name: s.name, farbe: s.anzeigeFarbe, symbol: s.symbol, bild: s.bild)
                            .frame(width: Theme.tapSize, height: Theme.tapSize)   // 44 pt Tippfläche um den 36-pt-Kreis
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, -4)
                    .accessibilityLabel(Text("Avatar wählen", bundle: .module))
                } else {
                    SpielerAvatar(name: s.name, farbe: s.anzeigeFarbe, symbol: s.symbol, bild: s.bild)
                }
                TextField(text: b.name) { Text("Name", bundle: .module) }
                    .font(.body)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($fokus, equals: s.id)
                    .accessibilityLabel(Text("Name", bundle: .module))   // B18 N-001: Namensfeld hat einen VoiceOver-Namen (auch bei leerem Feld)
                    .accessibilityValue(Text(verbatim: s.name))
                    .frame(maxWidth: .infinity)
                    // 2.26 M-008: Beim Antippen ist der vorbelegte Name markiert, Tippen ersetzt ihn (vorher „AnnaAnna“)
                    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { n in
                        guard let feld = n.object as? UITextField, let t = feld.text, !t.isEmpty, t == s.name else { return }
                        DispatchQueue.main.async { feld.selectAll(nil) }
                    }
                zusatz(b)
                    .frame(minHeight: Theme.tapSize)
                if arten.count > 1, !zweizeilig { artMenue(b, s) }
                if spieler.count > minimum {
                    Button { entfernen(s.id) } label: {
                        Image(systemName: "minus.circle")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: Theme.tapSize - 8, height: Theme.tapSize)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Spieler entfernen", bundle: .module))
                }
                if spieler.count > 1 {
                    Image(systemName: "line.3.horizontal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .frame(width: Theme.tapSize - 8, height: Theme.tapSize)
                        .contentShape(.rect)
                        .gesture(ziehen(id: s.id, index: index))
                        .accessibilityLabel(Text("Umsortieren", bundle: .module))
                        .accessibilityAction(named: Text("Nach oben", bundle: .module)) { verschiebe(s.id, um: -1) }
                        .accessibilityAction(named: Text("Nach unten", bundle: .module)) { verschiebe(s.id, um: 1) }
                }
            }
            .frame(height: zeilenHoehe)
            if zweizeilig {
                // bündig unter dem Namen (Avatar 36 pt plus Abstand)
                artMenue(b, s).padding(.leading, 36 + Design.Abstand.m).frame(height: Theme.tapSize, alignment: .leading)
            }
          }
        }
    }

    /// Menü „Art“ einer Zeile (Mensch, Computer). Steht neben dem Namen oder, bei großer Schrift, darunter.
    @ViewBuilder
    private func artMenue(_ b: Binding<SpielerEintrag>, _ s: SpielerEintrag) -> some View {
        Menu {
            Picker(selection: b.art) {
                ForEach(arten) { a in
                    Label { Text(a.name) } icon: { Image(systemName: a.symbol) }.tag(a.id)
                        // 2.38 F21-001: VoiceOver sagt bei der gewählten Art „ausgewählt“, bei der anderen nicht
                        .accessibilityAddTraits(a.id == s.art ? .isSelected : [])
                        .accessibilityRemoveTraits(a.id == s.art ? [] : .isSelected)
                }
            } label: { Text("Art", bundle: .module) }
        } label: {
            HStack(spacing: Design.Abstand.xs) {
                // 2.45 (nur Tinte): das Wort in der zweiten Zeile. Klar/Salon bei großer Schrift wie bisher nur das Symbol (2.26 G-002).
                if schrift.isAccessibilitySize && art != .tinte {
                    Image(systemName: arten.first { $0.id == s.art }?.symbol ?? "person.fill").font(.body.weight(.semibold))
                } else {
                    Text(arten.first { $0.id == s.art }?.name ?? "").font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                }
                Image(systemName: "chevron.up.chevron.down").font(.caption2.weight(.semibold))
            }
            .foregroundStyle(Color.accentText)
            .frame(minHeight: Theme.tapSize)
            .contentShape(.rect)
            .accessibilityHidden(true)   // 2.26 N-005: kein namenloser Knopf im Knopf; Name und Wert trägt das Menü selbst
        }
        .menuStyle(.button)   // 2.26 N-005: wie RundKnopfMenue (dort kommt der VoiceOver-Name an); vorher 68×42 ohne Namen
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Art", bundle: .module))
        .accessibilityValue(arten.first { $0.id == s.art }.map { Text($0.name) } ?? Text(verbatim: ""))   // 2.22 N-005: „Art, Mensch“ statt unbeschrifteter Knopf
        // 2.35 N-005: Am Gerät lag noch ein namenloser Knopf über dem Menü; VoiceOver bekommt eine schlichte Auswahl „Art“.
        .accessibilityRepresentation {
            Picker(selection: b.art) {
                ForEach(arten) { a in
                    Text(a.name).tag(a.id)
                        .accessibilityAddTraits(a.id == s.art ? .isSelected : [])   // 2.38 F21-001
                        .accessibilityRemoveTraits(a.id == s.art ? [] : .isSelected)
                }
            } label: { Text("Art", bundle: .module) }
        }
    }

    private func versatz(index: Int, id: UUID) -> CGFloat {
        guard let zug, zug.id == id else { return 0 }
        return zug.verschiebung - CGFloat(index - zug.start) * zeilenGesamt
    }

    private func ziehen(id: UUID, index: Int) -> some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .local)
            .onChanged { wert in
                if zug == nil { zug = Zug(id: id, start: index, verschiebung: 0); fokus = nil }
                zug?.verschiebung = wert.translation.height
                guard let zug, let aktuell = spieler.firstIndex(where: { $0.id == id }) else { return }
                let soll = min(max(zug.start + Int((zug.verschiebung / zeilenGesamt).rounded()), 0), spieler.count - 1)
                if soll != aktuell {
                    withAnimation(.snappy(duration: 0.2)) {
                        spieler.move(fromOffsets: IndexSet(integer: aktuell), toOffset: soll > aktuell ? soll + 1 : soll)
                    }
                }
            }
            .onEnded { _ in withAnimation(.snappy(duration: 0.2)) { zug = nil } }
    }

    private func verschiebe(_ id: UUID, um schritt: Int) {
        guard let i = spieler.firstIndex(where: { $0.id == id }) else { return }
        let ziel = i + schritt
        guard spieler.indices.contains(ziel) else { return }
        withAnimation { spieler.swapAt(i, ziel) }
    }

    private func entfernen(_ id: UUID) {
        withAnimation { spieler.removeAll { $0.id == id } }
    }

    private func hinzufuegen() {
        let belegt = Set(spieler.compactMap(\.farbeHex))
        let farbe = farben.first { !belegt.contains($0) }
        let neu = SpielerEintrag(name: neuerName(spieler.count + 1), art: arten.first?.id ?? "mensch", farbeHex: farbe)
        withAnimation { spieler.append(neu) }
        fokus = neu.id
    }
}

public extension SpielerListe where Zusatz == EmptyView {
    /// Spielerliste ohne Zusatz je Zeile (wie bis 2.6).
    init(spieler: Binding<[SpielerEintrag]>, arten: [SpielerArt] = [], minimum: Int = 2, maximum: Int = 6,
         farben: [UInt32] = [], neuerName: @escaping (Int) -> String = SpielerListe.vorgabeName,
         avatarTippen: ((SpielerEintrag) -> Void)? = nil) {
        self.init(spieler: spieler, arten: arten, minimum: minimum, maximum: maximum, farben: farben,
                  neuerName: neuerName, avatarTippen: avatarTippen) { _ in EmptyView() }
    }
}

#endif
