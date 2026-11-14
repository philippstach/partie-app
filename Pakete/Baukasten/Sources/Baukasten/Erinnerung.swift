// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import UserNotifications

/// Tägliche Erinnerung an das Tagesrätsel (lokale Mitteilung, kein Server, kein Push).
public struct ErinnerungsKonfiguration: Sendable {
    public var titel: String      // z. B. "Dein Tagesrätsel wartet"
    public var text: String
    public var standardStunde = 18
    public init(titel: String, text: String, standardStunde: Int = 18) { self.titel = titel; self.text = text; self.standardStunde = standardStunde }
}

public enum ErinnerungsPlan {
    /// Die nächsten `tage` Termine zur gewünschten Uhrzeit. Ist das heutige Rätsel schon gelöst oder die Uhrzeit vorbei, beginnt der Plan morgen.
    /// Einzeltermine statt Wiederholung, damit ein gelöstes Rätsel heute nicht mehr erinnert wird (bei jedem Start/Lösen neu planen).
    public static func termine(ab jetzt: Date, stunde: Int, minute: Int, heuteErledigt: Bool, tage: Int = 7, kalender: Calendar = .current) -> [Date] {
        var ergebnis: [Date] = []
        for offset in 0..<(tage + 1) {
            guard let tag = kalender.date(byAdding: .day, value: offset, to: jetzt),
                  let termin = kalender.date(bySettingHour: stunde, minute: minute, second: 0, of: tag) else { continue }
            if termin <= jetzt || (offset == 0 && heuteErledigt) { continue }
            ergebnis.append(termin)
            if ergebnis.count == tage { break }
        }
        return ergebnis
    }
}

@Observable
@MainActor
public final class ErinnerungsDienst {
    enum Schluessel { static let an = "baukasten.erinnerung.an"; static let minuten = "baukasten.erinnerung.minuten" }
    private let speicher: WerteSpeicher
    private let konfig: ErinnerungsKonfiguration
    private let kennung = "baukasten.tagesraetsel."

    public private(set) var verweigert = false
    public var an: Bool { speicher.object(forKey: Schluessel.an) as? Bool ?? false }
    public var minutenSeitMitternacht: Int { speicher.object(forKey: Schluessel.minuten) as? Int ?? konfig.standardStunde * 60 }

    public init(konfig: ErinnerungsKonfiguration, speicher: WerteSpeicher = UserDefaults.standard) { self.konfig = konfig; self.speicher = speicher }

    /// Erst aufrufen, wenn die Person den Schalter selbst einschaltet (nie beim Start). Fragt dabei einmal um Erlaubnis.
    public func einschalten(heuteErledigt: Bool) async {
        let ok = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        verweigert = !ok
        speicher.set(ok, forKey: Schluessel.an)
        if ok { await planen(heuteErledigt: heuteErledigt) }
    }

    public func ausschalten() async {
        speicher.set(false, forKey: Schluessel.an)
        await entfernen()
    }

    public func setzeUhrzeit(minuten: Int, heuteErledigt: Bool) async {
        speicher.set(minuten, forKey: Schluessel.minuten)
        await planen(heuteErledigt: heuteErledigt)
    }

    /// Beim Start und nach dem Lösen des Tagesrätsels aufrufen.
    public func planen(heuteErledigt: Bool) async {
        await entfernen()
        guard an else { return }
        let zentrum = UNUserNotificationCenter.current()
        let m = minutenSeitMitternacht
        for termin in ErinnerungsPlan.termine(ab: Date(), stunde: m / 60, minute: m % 60, heuteErledigt: heuteErledigt) {
            let inhalt = UNMutableNotificationContent()
            inhalt.title = konfig.titel; inhalt.body = konfig.text; inhalt.sound = .default
            let komponenten = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: termin)
            let anfrage = UNNotificationRequest(identifier: kennung + "\(Int(termin.timeIntervalSince1970))", content: inhalt,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: komponenten, repeats: false))
            try? await zentrum.add(anfrage)
        }
    }

    private func entfernen() async {
        let zentrum = UNUserNotificationCenter.current()
        let offen = await zentrum.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(kennung) }
        zentrum.removePendingNotificationRequests(withIdentifiers: offen)
    }
}

/// Einstellungs-Zeile „Tägliche Erinnerung“ mit Uhrzeit (Gruppe „Spiel“ oder „Mitteilungen“ der App).
public struct ErinnerungsZeile: View {
    @Bindable var dienst: ErinnerungsDienst
    let heuteErledigt: Bool
    @State private var an = false
    @State private var zeit = Date()

    public init(dienst: ErinnerungsDienst, heuteErledigt: Bool) { self.dienst = dienst; self.heuteErledigt = heuteErledigt }

    public var body: some View {
        Section {
            Toggle(isOn: $an) { Text("Tägliche Erinnerung", bundle: .module) }
            if an {
                DatePicker(selection: $zeit, displayedComponents: .hourAndMinute) { Text("Uhrzeit", bundle: .module) }
            }
        } footer: {
            if dienst.verweigert {
                Text("Mitteilungen sind für diese App ausgeschaltet. Du kannst sie in den iOS-Einstellungen erlauben.", bundle: .module)
            } else {
                Text("Eine Mitteilung pro Tag, nur wenn das Tagesrätsel noch offen ist. Keine Werbung.", bundle: .module)
            }
        }
        .onAppear {
            an = dienst.an
            zeit = Calendar.current.date(bySettingHour: dienst.minutenSeitMitternacht / 60, minute: dienst.minutenSeitMitternacht % 60, second: 0, of: Date()) ?? Date()
        }
        .onChange(of: an) { _, neu in
            Task {
                if neu { await dienst.einschalten(heuteErledigt: heuteErledigt); an = dienst.an } else { await dienst.ausschalten() }
            }
        }
        .onChange(of: zeit) { _, neu in
            let k = Calendar.current.dateComponents([.hour, .minute], from: neu)
            Task { await dienst.setzeUhrzeit(minuten: (k.hour ?? 18) * 60 + (k.minute ?? 0), heuteErledigt: heuteErledigt) }
        }
    }
}
