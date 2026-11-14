// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import UserNotifications
import KlarGlas
import Baukasten
import SpieleKern

/// Einleitung beim ersten Start und „Was ist neu?“ nach Updates: derselbe Bildschirm. Erklärt die App, stellt das Wichtigste ein
/// und fragt nach Mitteilungen.
struct EinfuehrungBlatt: View {
    /// true = App wurde aktualisiert („Was ist neu?“), false = erster Start.
    let update: Bool
    let fertig: () -> Void
    @AppStorage("darstellung") private var darstellungRaw = Darstellung.system.rawValue
    @AppStorage("toeneAn") private var toene = true
    @AppStorage("haptikAn") private var haptik = true
    @AppStorage(Modi.kinderKey) private var kinder = false
    @AppStorage(Modi.ruheKey) private var ruhe = false
    @State private var mitteilungen: MitteilungsStatus = .offen
    @Environment(Favoriten.self) private var favoriten
    @Environment(\.designArt) private var art

    static let neuInDieserVersion: [(symbol: String, text: LocalizedStringKey)] = [
        ("square.grid.2x2", "Neue Startseite: Lege deine Lieblingsspiele wie auf dem iPhone ab und ordne sie um. Alle anderen findest du unter „Alle Spiele“."),
        ("calendar.badge.clock", "Tagesaufgabe: jeden Tag ein anderes Spiel, eine Partie genügt."),
        ("hand.draw", "Wischen: Vom linken Rand zurück zur Startseite, vom rechten Rand wieder ins letzte Spiel."),
        ("figure.and.child.holdinghands", "Kinder-Modus: versteckt Spiele, die nicht für Kinder sind."),
        ("moon.zzz", "Ruhe-Modus: keine Mitteilungen, keine Tagesaufgabe."),
        ("person.crop.circle", "Spieler mit Foto: Lege Mitspielende einmal an und wähle sie in jedem Spiel."),
        ("book", "Anleitungen: Jedes Spiel erklärt sich beim ersten Mal zum Durchwischen."),
        ("chart.bar", "Statistik pro Spiel: Partien, Siege, Serie und Bestwert."),
        ("paintpalette", "Neue Spielfarben: Würfelspiele sind jetzt violett."),
        ("gearshape", "Einstellungen übersichtlicher sortiert, mit Erklärungen."),
    ]

    var body: some View {
        if update { updateBlatt } else { EinfuehrungSeiten(fertig: fertig) }
    }

    private var updateBlatt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                Text(update ? "Was ist neu?" : "Willkommen bei Partie")
                    .font(Design.ist(.klar) ? .largeTitle.bold() : Design.Schrift.schlagzeileSchrift(Design.Schrift.skaliert(Design.ist(.salon) ? 52 : 40, .largeTitle, hoechstens: 1.2)))
                    .padding(.top, 24).accessibilityAddTraits(.isHeader)
                Text(update ? "Das hat sich seit deinem letzten Besuch geändert." : "\(SpielKatalog.standardModule.count) Spiele für Familie, Freunde und dich allein. Hier das Wichtigste in einer Minute.")
                    .foregroundStyle(.secondary)

                if update {
                    kopf("Neu")
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(Self.neuInDieserVersion.enumerated()), id: \.offset) { _, n in
                            Label { Text(n.text).fixedSize(horizontal: false, vertical: true) } icon: { Image(systemName: n.symbol).frame(width: 28).accessibilityHidden(true) }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).card()
                }

                kopf("So funktioniert es")
                VStack(alignment: .leading, spacing: 14) {
                    Label { Text("Tippe auf ein Spiel. Beim ersten Mal erklärt es sich selbst, die Regeln stehen immer unter dem Buch-Symbol.") } icon: { Image(systemName: "hand.tap").frame(width: 28).accessibilityHidden(true) }
                    Label { Text("Mitspielende legst du einmal unter „Spieler“ an. Danach stehen sie in jedem Spiel bereit, und die Statistik zählt mit.") } icon: { Image(systemName: "person.2").frame(width: 28).accessibilityHidden(true) }
                    Label { Text("Die Farbe zeigt die Spielart: Karten, Würfel, Brett, Rätsel oder Wort.") } icon: { Image(systemName: "paintpalette").frame(width: 28).accessibilityHidden(true) }
                }.frame(maxWidth: .infinity, alignment: .leading).card()

                kopf("Gleich einstellen")
                VStack(spacing: Design.Abstand.xs) {
                    DarstellungsAuswahl(darstellung: Binding(get: { Darstellung(rawValue: darstellungRaw) ?? .system }, set: { darstellungRaw = $0.rawValue }))
                    Toggle("Töne", isOn: $toene).frame(minHeight: 44)
                    Toggle("Haptik", isOn: $haptik).frame(minHeight: 44)
                    Toggle(isOn: $kinder) { Text("Kinder-Modus"); Text("Versteckt Spiele, die nicht für Kinder sind. Welche, legst du in den Einstellungen fest.") }
                    Toggle(isOn: $ruhe) { Text("Ruhe-Modus"); Text("Keine Mitteilungen, keine Tagesaufgabe, keine „Neu“-Marken.") }
                }.card()

                kopf("Mitteilungen")
                if art == .tinte {
                    // Runde 5 (Paket E): dieselbe runde Karte wie auf Seite 4 der Einführung
                    EinfuehrungMitteilungenKarte(text: "Partie kann dich an Tagesrätsel und angefangene Partien erinnern. Das ist freiwillig und im Ruhe-Modus aus.", status: mitteilungen, gesperrt: ruhe) { fragen() }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Partie kann dich an Tagesrätsel und angefangene Partien erinnern. Das ist freiwillig und im Ruhe-Modus aus.").foregroundStyle(.secondary)
                        switch mitteilungen {
                        case .offen:
                            Button("Mitteilungen erlauben") { fragen() }.zweitKnopf().disabled(ruhe)
                        case .erlaubt: Label("Mitteilungen erlaubt", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
                        case .abgelehnt: Text("Nicht erlaubt – änderbar in den iOS-Einstellungen").foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).card()


                }

                Button(update ? "Weiter" : "Los geht’s") { fertig() }
                    .buttonStyle(HauptKnopfStil()).padding(.top, 8).padding(.bottom, 24)
            }
            .padding(.horizontal, Theme.seitenRand)
            .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
        }
        .background(Color.seitenGrund)
        .onChange(of: ruhe) { _, an in if an { Modi.ruheAnwenden() } }
        .onChange(of: kinder) { _, _ in Modi.kinderWirkungenAnwenden(favoriten: favoriten.ids) }
        .task { mitteilungen = await SystemMitteilungen().status() }
    }

    private func kopf(_ t: LocalizedStringKey) -> some View {
        Text(t).font(.footnote.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase).padding(.top, 8).accessibilityAddTraits(.isHeader)
    }

    private func fragen() {
        Task { mitteilungen = await Mitteilungen.fragen(ruhe: ruhe) }
    }
}

enum Version {
    static var aktuell: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1" }
}
