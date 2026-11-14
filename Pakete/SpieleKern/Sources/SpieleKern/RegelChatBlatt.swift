// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

// KI-3 (Blatt 12, „Frag nach den Regeln“): Chat-Blatt, Knopf unten auf der Seite „Regeln“ und Menüzeile am Tisch.
// Alles erscheint nur, wenn das Spiel Regelwissen hat und `RegelChatStatus` es erlaubt (sonst `.hidden`: nichts sichtbar).
// Gestaltung: Tinte und Papier, Zeichen `text.bubble`, kein Gold, kein Glitzer. Klar und Salon nehmen die Flächen aus KlarGlas.

/// Einstieg aus dem laufenden Spiel (vom `SpielRahmen` gesetzt, nur wenn der Chat möglich ist): öffnet das Chat-Blatt.
private struct RegelFrageSchluessel: EnvironmentKey { static let defaultValue: (() -> Void)? = nil }
public extension EnvironmentValues {
    var regelFrage: (() -> Void)? {
        get { self[RegelFrageSchluessel.self] }
        set { self[RegelFrageSchluessel.self] = newValue }
    }
}

/// Zeile „Frag nach den Regeln“ für das „Mehr“-Menü eines Spiels, gleich unter „Hausregeln“ (ohne Hausregeln an erster Stelle),
/// vor „Neue Partie“: `RundKnopfMenue { FragNachDenRegelnMenuePunkt(); NeuePartieMenuePunkt(); … }`.
/// Außerhalb des `SpielRahmen` und ohne Apple Intelligence bleibt sie leer (keine Zeile, nichts Ausgegrautes).
public struct FragNachDenRegelnMenuePunkt: View {
    @Environment(\.regelFrage) private var regelFrage
    public init() {}
    public var body: some View {
        if let regelFrage {
            Button("Frag nach den Regeln", systemImage: "text.bubble") { regelFrage() }
        }
    }
}

/// Farben des Regel-Chats: Tinte nimmt die Papierfarben von Blatt 12, Klar und Salon ihre eigenen Flächen.
enum RegelChatFarben {
    @MainActor static var feld: Color {
        // Fund 78/79: im Dunkelmodus nicht mehr hellbeige (Schrift ist dort hell: weiß auf weiß), sondern dunkle Papierfläche
        Design.ist(.tinte) ? Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 1) : UIColor(red: 0xEF / 255, green: 0xEE / 255, blue: 0xE9 / 255, alpha: 1) }) : Color.appFlaeche
    }
}

/// Das Chat-Blatt. `RegelChatStatus` entscheidet, was gezeigt wird (Chat, „Apple Intelligence ist aus“, „Einen Moment noch“).
public struct RegelChatBlatt: View {
    let wissen: any RegelWissen
    @State private var status: RegelChatStatus
    @State private var sitzung: RegelChatSitzung
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var szene
    @FocusState private var fokus: Bool

    @MainActor public init(wissen: any RegelWissen, zug: String? = nil) {
        self.wissen = wissen
        _status = State(initialValue: RegelChatEinstieg.status(spielID: wissen.spielID, wissen: wissen))
        // Ohne Modell (Hinweisbilder „aus“/„lädt“) bleibt die Attrappe nur Platzhalter; gefragt wird dann nie.
        // Das Spiel kann ein eigenes Modell mitbringen (10k: mit Rechen-Werkzeugen), sonst Apples Modell oder die Attrappe.
        let modell = wissen.sprachmodell() ?? RegelChatEinstieg.sprachmodell() ?? RegelChatAttrappe()
        _sitzung = State(initialValue: RegelChatSitzung(wissen: wissen, modell: modell, zug: zug, grenzen: wissen.chatGrenzen))
    }

    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        inhalt
                        Color.clear.frame(height: 1).id("ende")
                    }
                    .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: sitzung.nachrichten.count) { _, _ in nachUnten(proxy) }
                .onChange(of: sitzung.beschaeftigt) { _, _ in nachUnten(proxy) }
            }
            .background(Color.seitenGrund)
            .navigationTitle("Frag nach den Regeln").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
            .safeAreaInset(edge: .bottom, spacing: 0) { eingabe }
        }
        .presentationDetents([.large])
        .onAppear { sitzung.vorwaermen() }
        // Nach „Einstellungen“ oder wenn das Modell fertig geladen ist: Zustand neu lesen
        .onChange(of: szene) { _, neu in if neu == .active { status = RegelChatEinstieg.status(spielID: wissen.spielID, wissen: wissen) } }
    }

    private func nachUnten(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("ende", anchor: .bottom) }
    }

    // MARK: Inhalt

    @ViewBuilder private var inhalt: some View {
        switch status {
        case .notEnabled: hinweisKasten(titel: "Apple Intelligence ist aus", mitKnopf: true)
        case .notReady: hinweisKasten(titel: "Einen Moment noch", mitKnopf: false)
        default:
            if sitzung.nachrichten.isEmpty { leer } else { verlauf }
        }
    }

    private var leer: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(einleitung).font(.system(size: 16)).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
            if !wissen.beispielfragen.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Zum Beispiel").font(.system(size: 11.5, weight: .semibold)).tracking(1.4).textCase(.uppercase)
                        .foregroundStyle(Color.schriftZweit)
                    Rectangle().fill(Color.accentText).frame(height: 1.5).padding(.top, 6)
                    ForEach(Array(wissen.beispielfragen.prefix(3).enumerated()), id: \.offset) { _, frage in
                        Button { stellen(frage) } label: {
                            HStack {
                                Text(verbatim: frage).font(.system(size: 15.5, weight: .medium)).multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Color.schriftZweit)
                            }
                            .foregroundStyle(Color.schrift).padding(.vertical, 14).frame(minHeight: Theme.tapSize)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { Rectangle().fill(Color.linie).frame(height: 1) }
                    }
                }
            }
        }
    }

    /// Absatz oben im leeren Blatt; der Satz zu den Hausregeln nur bei Spielen, deren eingestellte Regeln der Chat kennt.
    private var einleitung: String {
        wissen.aktiveRegeln.isEmpty
            ? String(localized: "Stell eine Frage zu \(wissen.name), so wie ihr gerade spielt. Die Antwort kommt von Apple Intelligence, auf dem Gerät und ohne Internet.")
            : String(localized: "Stell eine Frage zu \(wissen.name), so wie ihr gerade spielt. Eure Hausregeln zählen mit. Die Antwort kommt von Apple Intelligence, auf dem Gerät und ohne Internet.")
    }

    private var verlauf: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(sitzung.nachrichten) { nachricht in
                if nachricht.vonSpieler { frage(nachricht.text) } else { antwort(nachricht) }
            }
            if sitzung.beschaeftigt {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("Ich schaue in den Regeln nach …").font(.system(size: 15)).foregroundStyle(Color.schriftZweit)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func frage(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 40)
            Text(verbatim: text).font(.system(size: 16)).foregroundStyle(Color.schrift)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .frame(maxWidth: 270, alignment: .leading)
                .background(RegelChatFarben.feld, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 6, topTrailingRadius: 20, style: .continuous))
        }
    }

    private func antwort(_ n: RegelChatSitzung.Nachricht) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle().fill(n.istFehler ? Color.schriftZweit : Color.accentText).frame(width: 2)
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: n.text).font(Design.Schrift.serif(18.5, relativ: .body)).foregroundStyle(Color.schrift)
                    .fixedSize(horizontal: false, vertical: true)
                if let quelle = n.quellen.first {
                    Label {
                        Text(verbatim: String(localized: "Aus den Regeln").uppercased() + " · " + quelle.uppercased())
                    } icon: { Image(systemName: "book") }
                    .font(.system(size: 11.5, weight: .semibold)).tracking(0.8).foregroundStyle(Color.schriftZweit)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func hinweisKasten(titel: LocalizedStringKey, mitKnopf: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titel).font(Design.Schrift.serif(21, gewicht: .bold, relativ: .title3)).foregroundStyle(Color.schrift)
            Text(mitKnopf ? aus : laedt).font(.system(size: 15)).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
            if mitKnopf {
                Button { Self.einstellungenOeffnen() } label: {
                    Text("Einstellungen öffnen").font(.system(size: 15.5, weight: .semibold)).foregroundStyle(Color.schrift)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(Capsule().strokeBorder(Color.accentText, lineWidth: 1.5))
                }
                .buttonStyle(.plain).padding(.top, 4)
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.accentText, lineWidth: 1.5))
        .accessibilityElement(children: .contain)
    }

    private var aus: String {
        UIDevice.current.userInterfaceIdiom == .pad
            ? String(localized: "Für Regel-Fragen braucht die App Apple Intelligence. Du schaltest es in den Einstellungen deines iPads ein.")
            : String(localized: "Für Regel-Fragen braucht die App Apple Intelligence. Du schaltest es in den Einstellungen deines iPhones ein.")
    }
    private var laedt: String { String(localized: "Das Sprachmodell wird noch geladen. Versuch es gleich noch einmal.") }

    private static func einstellungenOeffnen() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    // MARK: Eingabe

    private var eingabe: some View {
        VStack(spacing: 10) {
            Text("Antworten können falsch sein. Es gelten die Regeln.").font(.system(size: 12.5)).foregroundStyle(Color.schriftZweit)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                TextField("Frage zu den Regeln", text: $text)
                    .font(.system(size: 16)).foregroundStyle(Color.schrift).focused($fokus).submitLabel(.send).onSubmit { senden() }
                    .padding(.horizontal, 18).frame(minHeight: 48)
                    .background(RegelChatFarben.feld, in: Capsule())
                Button { senden() } label: {
                    Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.seitenGrund)
                        .frame(width: 48, height: 48).background(Color.schrift, in: Circle())
                }
                .buttonStyle(.plain).accessibilityLabel(Text("Senden"))
                .disabled(!kannSenden)
            }
        }
        .opacity(status.kannFragen ? 1 : 0.45)
        .disabled(!status.kannFragen)
        .padding(.horizontal, 22).padding(.top, 10).padding(.bottom, 12)
        .background(Color.seitenGrund)
    }

    private var kannSenden: Bool {
        status.kannFragen && !sitzung.beschaeftigt && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func senden() {
        guard kannSenden else { return }
        stellen(text)
        text = ""
    }

    private func stellen(_ frage: String) {
        guard status.kannFragen else { return }
        let s = sitzung
        Task { await s.frage(frage) }
    }
}

/// Zeigt an, dass weiter außen schon eine Leiste „Frag nach den Regeln“ sitzt (Spiele mit eigener Regelseite würden sonst zwei bekommen).
private struct RegelFrageLeisteSchluessel: EnvironmentKey { static let defaultValue = false }
private extension EnvironmentValues {
    var regelFrageLeisteDa: Bool {
        get { self[RegelFrageLeisteSchluessel.self] }
        set { self[RegelFrageLeisteSchluessel.self] = newValue }
    }
}

/// Unten fest auf der Seite „Regeln“: umrandete Kapsel „Frag nach den Regeln“ mit Zeile „Apple Intelligence · auf dem Gerät, ohne Internet“.
/// Ohne Chat-Möglichkeit (Status `.hidden`) bleibt die Seite unverändert.
private struct RegelFrageLeiste: ViewModifier {
    let spielID: String
    let wissen: (any RegelWissen)?
    @State private var offen = false
    @State private var status: RegelChatStatus = .hidden
    @Environment(\.scenePhase) private var szene
    @Environment(\.regelFrageLeisteDa) private var schonDa

    @ViewBuilder func body(content: Content) -> some View {
        if schonDa { content } else { leiste(content) }
    }

    private func leiste(_ content: Content) -> some View {
        content
            .environment(\.regelFrageLeisteDa, true)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if status.zeigtEinstieg {
                    VStack(spacing: 9) {
                        Button { offen = true } label: {
                            Label("Frag nach den Regeln", systemImage: "text.bubble")
                                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.schrift)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .overlay(Capsule().strokeBorder(Color.accentText, lineWidth: 1.5))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        Text("Apple Intelligence · auf dem Gerät, ohne Internet").font(.system(size: 12.5)).foregroundStyle(Color.schriftZweit)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.seitenGrund)
                    .overlay(alignment: .top) { Rectangle().fill(Color.linie).frame(height: 1) }
                }
            }
            .onAppear { aktualisieren() }
            .onChange(of: szene) { _, neu in if neu == .active { aktualisieren() } }
            .sheet(isPresented: $offen) {
                if let w = wissen ?? RegelWissenKatalog.wissen(fuer: spielID) { RegelChatBlatt(wissen: w) }
            }
    }

    private func aktualisieren() { status = RegelChatEinstieg.status(spielID: spielID, wissen: wissen) }
}

public extension View {
    /// Knopf „Frag nach den Regeln“ unten auf einer Regelseite (nur mit Chat-Möglichkeit sichtbar). Sitzt weiter außen schon
    /// eine solche Leiste (der `SpielRahmen` setzt sie um eigene Regelseiten), bleibt es bei einer.
    func regelFrageLeiste(spielID: String, wissen: (any RegelWissen)? = nil) -> some View {
        modifier(RegelFrageLeiste(spielID: spielID, wissen: wissen))
    }
}
#endif
