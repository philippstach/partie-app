// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Einstellungen (Konzept 3.4 „Einstellungen“): EIN Formular mit fünf Gruppen in fester Reihenfolge,
// Gruppenkacheln aus diesem Baustein, „Darstellung“ als Menü, darunter „App-Farbe“ (Baukasten `AkzentAuswahl`, E8).
// Schalter in Systemgrün (E1), keine Unterseiten für Gruppen, keine Suche (E7).

#if canImport(UIKit)

/// Gruppen der Einstellungen in fester Reihenfolge (Handbuch A.9). Jede Gruppe: Symbol, Titel, Farbe der Kachel.
public enum EinstellungsGruppe: String, CaseIterable, Identifiable {
    case spiel, aussehen, tonHaptik, daten, ueber

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .spiel: "gamecontroller.fill"
        case .aussehen: "paintbrush.fill"
        case .tonHaptik: "speaker.wave.2.fill"
        case .daten: "chart.bar.fill"
        case .ueber: "info.circle.fill"
        }
    }

    public var titel: Text {
        switch self {
        case .spiel: Text("Spiel", bundle: .module)
        case .aussehen: Text("Aussehen", bundle: .module)
        case .tonHaptik: Text("Ton & Haptik", bundle: .module)
        case .daten: Text("Daten & Statistik", bundle: .module)
        case .ueber: Text("Über", bundle: .module)
        }
    }

    /// Farbe der Symbolkachel: „Spiel“ in der App-Farbe, die übrigen System-Farben.
    public var farbe: Color {
        switch self {
        case .spiel: Color.appFlaeche
        case .aussehen: .indigo
        case .tonHaptik: .pink
        case .daten: .teal
        case .ueber: .gray
        }
    }
}

/// Kopfzeile einer Einstellungsgruppe: farbige Symbolkachel + Titel. Als `Section`-Header benutzen.
public struct EinstellungsKopf: View {
    let gruppe: EinstellungsGruppe

    public init(gruppe: EinstellungsGruppe) { self.gruppe = gruppe }

    @Environment(\.designArt) private var art

    public var body: some View {
        if art == .klar {
            klar
        } else {
            // Tinte und Salon: keine Symbolkachel, nur das Label
            gruppe.titel.designLabel().accessibilityAddTraits(.isHeader)
        }
    }

    private var klar: some View {
        Label {
            gruppe.titel.font(.footnote.weight(.semibold)).textCase(.uppercase).foregroundStyle(.secondary)
        } icon: {
            Image(systemName: gruppe.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(gruppe.farbe, in: .rect(cornerRadius: 6))
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// Zeile „Darstellung“ (System/Hell/Dunkel) – erste Zeile in „Aussehen“, überall gleich.
public struct DarstellungsAuswahl: View {
    @Binding var darstellung: Darstellung

    @Environment(\.designArt) private var art
    @Environment(\.dynamicTypeSize) private var schriftGroesse

    public init(darstellung: Binding<Darstellung>) { _darstellung = darstellung }

    public var body: some View {
        // Menü statt Picker: der Wert rechts zeichnet in der App-Farbe (`Color.appFlaeche`) und wechselt sofort mit der Wahl;
        // der System-Picker übernimmt die Fensterfarbe erst nach einem Neustart.
        Menu {
            Picker(selection: $darstellung) {
                ForEach(Darstellung.allCases) { Text(verbatim: $0.name).tag($0) }
            } label: {
                Text("Darstellung", bundle: .module)
            }
        } label: {
            // 2.45: Nur in Tinte bei Schriftgrößen der Bedienungshilfen steht der Wert UNTER der Bezeichnung; Klar und Salon unverändert (Philipp 13.11.).
            let wertUnten = art == .tinte && schriftGroesse.isAccessibilitySize
            let aufbau = wertUnten ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 6))
            aufbau {
                Text("Darstellung", bundle: .module).foregroundStyle(.primary)
                if !wertUnten { Spacer(minLength: 8) }
                HStack(spacing: 6) {
                    Text(verbatim: darstellung.name).foregroundStyle(Color.accentText)
                    Image(systemName: "chevron.up.chevron.down").font(.footnote.weight(.semibold)).foregroundStyle(Color.accentText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.primary)   // Build-12-Fund S2-033: Beschriftung primär, nur der Wert in lesbarer Akzentfarbe (accentText statt appFlaeche)
            .contentShape(.rect)
        }
        .accessibilityLabel(Text("Darstellung", bundle: .module))
        .accessibilityValue(Text(verbatim: darstellung.name))
    }
}

/// Schalter in Systemgrün (E1, Baustein-Wunsch 3). Die Apps setzen die App-Farbe als Wurzel-Tint, dadurch färbt sich
/// jeder `Toggle` mit. Dieser Stil setzt nur die Schalter zurück auf Systemgrün; Picker, Menüs und Links bleiben in App-Farbe.
public struct SchalterStil: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        SchalterZeile(configuration: configuration, farbe: Color(.systemGreen))   // 2.40 F21-006: kein zweiter Toggle
    }
}

/// 2.40 F21-006: Zeile „Beschriftung – Schalter“ als EIN Element für VoiceOver. Vorher bauten `SchalterStil` und `BlattSchalterStil`
/// einen zweiten `Toggle` um das Label; im Bedienungshilfen-Baum lagen dann je Zeile ein benannter und ein namenloser Schalter.
/// Der sichtbare Schalter ist hier nur Grafik und Tippfläche; Name, Zustand und Aktion trägt die ganze Zeile.
/// 2.41: Schalter als reine Grafik (51 × 31 pt wie der System-Schalter), ohne eigenes Bedienelement.
struct SchalterGrafik: View {
    let an: Bool
    let farbe: Color

    var body: some View {
        // 2.50 Blatt 24b: In Tinte die Maße des neuen Systemschalters (Spur 63 × 28, länglicher Knopf 37 × 24, 2 pt Rand).
        let tinte = Design.art == .tinte
        Capsule()
            .fill(an ? farbe : Color(.systemGray4))
            .frame(width: tinte ? 63 : 51, height: tinte ? 28 : 31)
            .overlay(alignment: an ? .trailing : .leading) {
                Group {
                    if tinte { Capsule().fill(.white).frame(width: 37, height: 24) }
                    else { Circle().fill(.white) }
                }
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1).padding(2)
            }
            .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize)
            .contentShape(.rect)
    }
}

struct SchalterZeile: View {
    let configuration: ToggleStyleConfiguration
    var farbe: Color? = nil
    /// 2.49: Gesperrte Schalter (`.disabled`) sehen blass aus und lassen sich nicht umschalten.
    @Environment(\.isEnabled) private var aktiv

    var body: some View {
        HStack(spacing: Design.Abstand.m) {
            configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
                // 2.43 F21-006: Tippen auf Name/Erklärung schaltet einmal um; die Grafik schaltet selbst. Keine Geste auf der ganzen Zeile (sonst doppelt).
                .onTapGesture { guard aktiv else { return }; withAnimation(.snappy(duration: 0.2)) { configuration.isOn.toggle() } }
            // 2.41 F21-006: eigene Schalter-Grafik statt UISwitch – ein verborgener System-Toggle blieb am Gerät als namenloser Schalter im Baum.
            SchalterGrafik(an: configuration.isOn, farbe: farbe ?? Color.accentColor)
                .opacity(aktiv ? 1 : 0.45)
                .allowsHitTesting(aktiv)
                .onTapGesture { guard aktiv else { return }; withAnimation(.snappy(duration: 0.2)) { configuration.isOn.toggle() } }
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
        .accessibilityAction { if aktiv { configuration.isOn.toggle() } }
    }
}

/// Rundknopf „Schließen“ (klein, `xmark`) oben rechts im Einstellungen-Blatt – wie bei Neues Spiel und Sieger.
/// Auf das `Form` innerhalb des `NavigationStack` setzen; schließt das Blatt über `dismiss`.
struct EinstellungsSchliessen: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                RundKnopf(symbol: "xmark", beschriftungText: Text("Schließen", bundle: .module), klein: true) { dismiss() }
            }
        }
    }
}

/// `designListe()`: Formulare und Listen in Tinte und Salon auf dem Seitengrund des Designs statt auf dem Systemgrau.
/// Ohne Verzweigung der Ansicht (kein Neuaufbau beim Wechsel, die Liste behält ihre Position); in `klar` sind alle Werte neutral.
struct DesignListe: ViewModifier {
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(art == .klar ? .automatic : .hidden)
            .background(art == .klar ? Color.clear : Color.seitenGrund)
    }
}

/// `designZeilen()`: Zeilen einer Liste auf dem Kartengrund des Designs, Trennlinien in der Linienfarbe.
struct DesignZeilen: ViewModifier {
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        content
            .listRowBackground(art == .klar ? nil : Color.kartenGrund)
            .listRowSeparatorTint(art == .klar ? nil : Color.linie)
            .listSectionSeparatorTint(art == .klar ? nil : Color.linie)
    }
}

public extension View {
    /// Auf jedes `Form` und jede `List` setzen (Hülle und Spiele): in Tinte und Salon steht die Liste auf dem Seitengrund
    /// des Designs. In `klar` tut der Modifier nichts.
    func designListe() -> some View { modifier(DesignListe()) }

    /// Auf eine `Section` oder eine Gruppe von Zeilen in einer Liste setzen: Zeilengrund = Kartengrund des Designs.
    /// In `klar` tut der Modifier nichts.
    func designZeilen() -> some View { modifier(DesignZeilen()) }

    /// Schließen-Rundknopf oben rechts im Einstellungen-Blatt (2.2, Test-Chat S1).
    func einstellungsSchliessen() -> some View { modifier(EinstellungsSchliessen()) }

    /// Einmal auf das `Form` der Einstellungen setzen: alle Schalter darunter in Systemgrün (E1).
    /// Ersetzt `.tint(Color(.systemGreen))` an jedem einzelnen Toggle.
    func einstellungsSchalter() -> some View { toggleStyle(SchalterStil()) }
}

#endif
