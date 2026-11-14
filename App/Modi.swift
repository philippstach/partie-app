// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import UserNotifications
import SpieleKern

/// Kinder-Modus und Ruhe-Modus der Hülle. Beide Schalter liegen in `UserDefaults` (`@AppStorage` in den Ansichten).
enum Modi {
    static let kinderKey = "kinderModus"
    static let ruheKey = "ruheModus"
    static let gesperrtKey = "kinderGesperrt"
    static let tagesaufgabeKey = "tagesaufgabeAn"

    /// Voreinstellung für den Kinder-Modus: Spiele um Bluffen, Einsatz und Glück bleiben für Erwachsene.
    static let standardGesperrt: Set<String> = ["pokerwurf", "schocken", "maexchen", "luegenwuerfel", "perudo", "chicago", "backgammon", "aceydeucey", "mogeln", "truco"]

    static var kinder: Bool { UserDefaults.standard.bool(forKey: kinderKey) }
    static var ruhe: Bool { UserDefaults.standard.bool(forKey: ruheKey) }

    /// Im Kinder-Modus ausgeblendete Spiele (ohne eigene Auswahl: die Voreinstellung).
    static var gesperrt: Set<String> {
        guard let s = UserDefaults.standard.string(forKey: gesperrtKey) else { return Set(standardGesperrt.map(SpielKatalog.kennung)) }
        return Set(s.split(separator: ",").map { SpielKatalog.kennung(String($0)) })
    }
    static func setzeGesperrt(_ ids: Set<String>) { UserDefaults.standard.set(ids.sorted().joined(separator: ","), forKey: gesperrtKey) }

    /// Darf dieses Spiel gerade geöffnet werden? Im Kinder-Modus nicht, wenn es gesperrt ist.
    static func erlaubt(_ id: String, kinder: Bool = Modi.kinder, gesperrt: Set<String> = Modi.gesperrt) -> Bool { !kinder || !gesperrt.map(SpielKatalog.kennung).contains(SpielKatalog.kennung(id)) }

    /// Wirkungen des Kinder-Modus außerhalb der App: Schnellaktionen, Widgets, Spotlight-Index. Nach jedem Umschalten oder Ändern der Auswahl aufrufen.
    @MainActor
    static func kinderWirkungenAnwenden(favoriten: [String]) {
        FavoritenAktionen.aktualisieren(favoriten)
        WidgetAbgleich.kinderModusAbgleichen()
        SpielSpotlight.aktualisieren()
    }

    /// Ruhe-Modus: keine Mitteilungen mehr (geplante werden entfernt).
    static func ruheAnwenden() {
        guard ruhe else { return }
        let z = UNUserNotificationCenter.current()
        z.removeAllPendingNotificationRequests()
        z.removeAllDeliveredNotifications()
    }
}

extension SpielKatalog {
    /// Spiele, die gerade angezeigt werden dürfen (Kinder-Modus blendet die gesperrten aus).
    static var sichtbar: [any SpielModul] {
        Modi.kinder ? spielbar.filter { !Modi.gesperrt.contains($0.id) } : spielbar
    }
}

/// Auswahl der Spiele, die im Kinder-Modus sichtbar bleiben.
struct KinderSpieleSeite: View {
    @AppStorage(Modi.gesperrtKey) private var gesperrtRaw = ""
    @State private var gesperrt = Modi.gesperrt
    @Environment(Favoriten.self) private var favoriten
    @State private var freigegeben = false

    var body: some View {
        Group {
            if freigegeben { liste } else {
                ContentUnavailableView {
                    Label("Gesperrt", systemImage: "lock")
                } description: {
                    Text("Die Auswahl ändern geht nur mit Face ID oder dem Gerätecode.")
                } actions: {
                    Button("Entsperren") { Task { freigegeben = await KinderSchutz.freigeben(grund: String(localized: "Spiele für Kinder ändern")) } }
                }
            }
        }
        .task { if !freigegeben { freigegeben = await KinderSchutz.freigeben(grund: String(localized: "Spiele für Kinder ändern")) } }
        .navigationTitle("Spiele für Kinder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var liste: some View {
        List {
            Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
            Section { } footer: { Text("Nur Spiele, deren Schalter an ist, sind im Kinder-Modus zu sehen. Suche, Zufall und „Was spielen wir?“ halten sich daran.") }
            ForEach(SpielZeilen.spielarten, id: \.self) { g in
                Section(g.anzeigeName) {
                    ForEach(SpielKatalog.spielbar.filter { $0.gattung == g }, id: \.id) { m in
                        Toggle(isOn: Binding(get: { !gesperrt.contains(m.id) }, set: { an in
                            if an { gesperrt.remove(m.id) } else { gesperrt.insert(m.id) }
                            Modi.setzeGesperrt(gesperrt); gesperrtRaw = gesperrt.sorted().joined(separator: ",")
                            Modi.kinderWirkungenAnwenden(favoriten: favoriten.ids)
                        })) { Text(verbatim: m.name) }
                    }
                }
            }
            }.designZeilen()
        }
        .designListe()
    }
}


// MARK: - Mitteilungen

enum MitteilungsStatus: Equatable { case offen, erlaubt, abgelehnt }

/// Schnittstelle zum Mitteilungszentrum (im Test ersetzbar).
protocol MitteilungsZentrale {
    func status() async -> MitteilungsStatus
    func anfragen() async -> Bool
}

struct SystemMitteilungen: MitteilungsZentrale {
    func status() async -> MitteilungsStatus {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .offen
        case .denied: .abgelehnt
        default: .erlaubt
        }
    }
    func anfragen() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}

enum Mitteilungen {
    /// Fragt höchstens einmal: nur wenn noch nicht entschieden und der Ruhe-Modus aus ist. Ein „Nein“ bleibt ein „Nein“
    /// (iOS fragt ohnehin nicht noch einmal; ändern geht danach nur in den iOS-Einstellungen).
    static func fragen(ruhe: Bool, zentrale: any MitteilungsZentrale = SystemMitteilungen()) async -> MitteilungsStatus {
        let jetzt = await zentrale.status()
        guard !ruhe, jetzt == .offen else { return jetzt }
        return await zentrale.anfragen() ? .erlaubt : .abgelehnt
    }
}
