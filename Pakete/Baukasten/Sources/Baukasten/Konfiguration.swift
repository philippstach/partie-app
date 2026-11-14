// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// Alles, was eine App dem Baukasten sagen muss. Eine Zeile pro Feld, damit alle Apps gleich eingebunden werden.
public struct BaukastenKonfiguration {
    public var appName: String
    public var links: AppLinks
    public var standardAkzent: AkzentFarbe
    public var trinkgeld: [TrinkgeldStufe]          // leer = kein Trinkgeld (Voreinstellung, bis der Vertrag für kostenpflichtige Apps aktiv ist)
    public var kinderApp = false                    // true = kein Trinkgeld, keine Bewertung, keine Querverweise
    public var gameCenter: GameCenterKonfiguration? // nil = aus
    public var erinnerung: ErinnerungsKonfiguration? // nur Apps mit Tagesrätsel

    public init(appName: String, links: AppLinks, standardAkzent: AkzentFarbe,
                trinkgeld: [TrinkgeldStufe] = [], kinderApp: Bool = false,
                gameCenter: GameCenterKonfiguration? = nil, erinnerung: ErinnerungsKonfiguration? = nil) {
        self.erinnerung = erinnerung
        self.appName = appName; self.links = links; self.standardAkzent = standardAkzent
        self.trinkgeld = trinkgeld; self.kinderApp = kinderApp; self.gameCenter = gameCenter
    }
}

/// Gruppe „Über“ der Einstellungen (Handbuch A.9) in fester Reihenfolge: Unterstützen, Bewerten, Mehr von mir, Über mich, Links, Version.
/// Wird als Inhalt eines `Form` verwendet; die Kopfzeile „Über“ setzt die App mit `EinstellungsKopf`.
public struct BaukastenUeberGruppe: View {
    let konfig: BaukastenKonfiguration
    let trinkgeldLager: TrinkgeldLager?
    @Environment(\.openURL) private var openURL

    public init(konfig: BaukastenKonfiguration, trinkgeldLager: TrinkgeldLager?) {
        self.konfig = konfig; self.trinkgeldLager = trinkgeldLager
    }

    public var body: some View {
        if let lager = trinkgeldLager, !konfig.kinderApp, !konfig.trinkgeld.isEmpty {
            TrinkgeldAbschnitt(lager: lager, stufen: konfig.trinkgeld)
        }
        Section {
            if !konfig.kinderApp, let url = konfig.links.bewertenURL {
                Button { openURL(url) } label: { Label { Text("App bewerten", bundle: .module) } icon: { Image(systemName: "star") } }
            }
            if let url = konfig.links.storeURL {
                ShareLink(item: url, message: Text("Probier mal diese App aus:", bundle: .module)) {
                    Label { Text("App empfehlen", bundle: .module) } icon: { Image(systemName: "square.and.arrow.up") }
                }
            }
            UeberMichZeile(UeberMichInhalt.philipp)
        }
        MehrVonMirAbschnitt(aktuell: konfig.links.key, kinderApp: konfig.kinderApp)
        Section {
            Link(destination: konfig.links.support) { Text("Hilfe & Support", bundle: .module) }
            Link(destination: konfig.links.datenschutz) { HStack { Text("Datenschutz", bundle: .module); Spacer(); Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).accessibilityHidden(true) } }
            Link(destination: konfig.links.impressum) { HStack { Text("Impressum", bundle: .module); Spacer(); Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).accessibilityHidden(true) } }
            LabeledContent { Text("\(AppInfo.version) (\(AppInfo.build))").monospacedDigit() } label: { Text("Version", bundle: .module) }
        }
    }
}
