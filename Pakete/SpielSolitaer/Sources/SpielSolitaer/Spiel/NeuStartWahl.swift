// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Design-Runde 3 (Tinte, R1): Die Wahl des Spiels steht auf der Spielseite des Rahmens statt auf einer eigenen Seite danach.
/// Der eine Knopf „Spielen“ startet, was hier gewählt ist. Die Wahl liegt als Text unter `schluessel`: ein Modus-Schlüssel
/// („klondike3“, „spider2“, „freecell“ …) oder „daily:<Spiel>“ für das Tagesspiel; `NeuWurzel` holt sie beim Start ab.
/// Die Ansicht liegt außerhalb von `NeuWurzel` und kennt dessen Modell nicht, darum arbeitet sie nur über UserDefaults.
/// In den anderen Designs bleibt sie leer.
struct NeuStartWahl: View {
    static let schluessel = "solitaer-neu.start"
    @AppStorage("solitaer-neu.start") private var start = ""
    @State private var tagesArt = GameKind.klondike
    @Environment(\.designArt) private var art

    private var tagesArten: [GameKind] { GameKind.available.filter { DealCatalog.shared.dailySeed(for: .now, kind: $0, level: nil) != nil } }
    private var gewaehlteArt: GameKind? { start.hasPrefix("daily:") ? nil : AppModel.mode(forKey: start).kind }
    private var gewaehlterModus: GameMode { AppModel.mode(forKey: start) }

    var body: some View {
        if art == .tinte {
            VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                tagesZeile
                ForEach(GameKind.available, id: \.self) { kind in spielZeile(kind) }
            }
            .onAppear {
                // jede Spielseite beginnt mit dem zuletzt gespielten Spiel
                start = UserDefaults.standard.string(forKey: "lastModeKey") ?? GameMode.klondike(1).key
            }
        }
    }

    private func zeichen(_ gewaehlt: Bool) -> some View {
        Image(systemName: gewaehlt ? "checkmark.circle.fill" : "circle").font(.title2)
            .foregroundStyle(gewaehlt ? Color.schrift : Color.schriftZweit).accessibilityHidden(true)
    }

    private var tagesZeile: some View {
        let gewaehlt = start.hasPrefix("daily:")
        return VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Button { start = gewaehlt ? (UserDefaults.standard.string(forKey: "lastModeKey") ?? "klondike1") : "daily:\(tagesArt.rawValue)" } label: {
                HStack(spacing: Design.Abstand.m) {
                    zeichen(gewaehlt)
                    Label("Tagesspiel", systemImage: "calendar").font(.headline).foregroundStyle(Color.schrift)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(gewaehlt ? [.isButton, .isSelected] : .isButton)
            if gewaehlt {
                Picker("Spiel", selection: $tagesArt) { ForEach(tagesArten, id: \.self) { Text(verbatim: $0.title).tag($0) } }
                    .pickerStyle(.menu).labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: tagesArt) { _, neu in start = "daily:\(neu.rawValue)" }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func spielZeile(_ kind: GameKind) -> some View {
        let gewaehlt = gewaehlteArt == kind
        return VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Button { start = Self.schluessel(fuer: kind) } label: {
                HStack(spacing: Design.Abstand.m) {
                    zeichen(gewaehlt)
                    VStack(alignment: .leading, spacing: 2) {
                        Label(LocalizedStringKey(kind.title), systemImage: kind.symbol).font(.headline).foregroundStyle(Color.schrift)
                        Text(verbatim: Self.kurz(Self.modus(fuer: kind))).font(.footnote).foregroundStyle(Color.schriftZweit)
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(gewaehlt ? [.isButton, .isSelected] : .isButton)
            if gewaehlt, kind.options.count > 1 {
                Picker(LocalizedStringKey(kind.title), selection: Binding(get: { gewaehlterModus.option }, set: { start = Self.modus(kind, $0).key })) {
                    ForEach(kind.options, id: \.self) { Text(verbatim: Self.kurz(Self.modus(kind, $0))).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private static func modus(_ kind: GameKind, _ option: Int) -> GameMode {
        switch kind {
        case .klondike: .klondike(option)
        case .spider: .spider(option)
        case .freecell: .freecell
        case .pyramid: .pyramid
        case .tripeaks: .tripeaks
        case .golf: .golf
        case .yukon: .yukon
        }
    }

    /// Der zuletzt benutzte Modus des Spiels (Zieh-Art, Spinnen-Farben).
    private static func modus(fuer kind: GameKind) -> GameMode {
        let d = UserDefaults.standard
        switch kind {
        case .klondike: return .klondike(d.object(forKey: "drawCount") as? Int ?? 1)
        case .spider: return .spider(d.object(forKey: "spiderColors") as? Int ?? 2)
        default: return modus(kind, 0)
        }
    }

    private static func schluessel(fuer kind: GameKind) -> String { modus(fuer: kind).key }

    private static func kurz(_ m: GameMode) -> String {
        switch m.kind {
        case .klondike: m.option == 3 ? String(localized: "3 Karten") : String(localized: "1 Karte")
        case .spider: m.option == 1 ? String(localized: "1 Farbe") : String(localized: "\(m.option) Farben")
        case .freecell: String(localized: "4 Zellen")
        case .pyramid: String(localized: "Summe 13")
        case .tripeaks: String(localized: "3 Gipfel")
        case .golf: String(localized: "Eins höher oder tiefer")
        case .yukon: String(localized: "Jede offene Karte zieht mit")
        }
    }
}
