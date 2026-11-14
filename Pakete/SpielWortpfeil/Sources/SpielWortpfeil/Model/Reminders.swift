// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import UserNotifications

enum ReminderPermission: Sendable { case notDetermined, denied, allowed }

/// Lokale Erinnerung ans Tagesrätsel (nur nach Zustimmung, offline, ohne Konto).
protocol ReminderScheduling: Sendable {
    func permission() async -> ReminderPermission
    func requestPermission() async -> Bool
    /// Ersetzt alle geplanten Erinnerungen durch diese Zeitpunkte
    func replaceAll(with dates: [DateComponents]) async
}

enum ReminderPlan {
    /// Zeitpunkte der nächsten `days` Tage um `hour:minute`. Heute entfällt, wenn schon gelöst oder die Uhrzeit vorbei ist.
    static func dates(now: Date, hour: Int, minute: Int, solvedToday: Bool, days: Int = 7,
                      calendar: Calendar = .current) -> [DateComponents] {
        var out: [DateComponents] = []
        let today = calendar.startOfDay(for: now)
        for i in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: i, to: today),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
            if i == 0 && (solvedToday || fire <= now) { continue }
            out.append(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire))
        }
        return out
    }
}

struct SystemReminders: ReminderScheduling {
    private let prefix = "tagesraetsel-"

    func permission() async -> ReminderPermission {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .allowed
        }
    }

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func replaceAll(with dates: [DateComponents]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        let d = UserDefaults.standard
        if d.bool(forKey: "ruheModus") { return }
        // Einstellungen der Hülle: Mitteilungen insgesamt und Tagesrätsel-Erinnerung (Standard: an)
        if (d.object(forKey: "mitteilungenAn") as? Bool) == false || (d.object(forKey: "mitteilungTagesraetsel") as? Bool) == false { return }   // Ruhe-Modus der Hülle: keine neuen Mitteilungen
        for (i, comps) in dates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Rätsel des Tages")
            content.body = String(localized: "Dein Tagesrätsel wartet – eine Runde?")
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "\(prefix)\(i)", content: content, trigger: trigger))
        }
    }
}
