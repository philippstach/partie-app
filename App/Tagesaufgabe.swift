// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Tagesaufgabe: Jeden Tag ein anderes Spiel, eine Partie genügt. Der Ruhe-Modus und der Kinder-Modus schalten sie ab.
@MainActor
enum Tagesaufgabe {
    /// Das Spiel des Tages (für alle Geräte gleich, wechselt um Mitternacht).
    static func spiel(am tag: Date) -> (any SpielModul)? {
        let alle = SpielKatalog.spielbar.sorted { $0.id < $1.id }
        guard !alle.isEmpty else { return nil }
        let nr = Int(Calendar.current.startOfDay(for: tag).timeIntervalSinceReferenceDate / 86_400)
        return alle[(((nr &* 7919 &+ 13) % alle.count) + alle.count) % alle.count]
    }

    static func geschafft(am tag: Date, _ statistik: StatistikDienst) -> Bool {
        guard let m = spiel(am: tag) else { return false }
        return statistik.ereignisse.contains { $0.spiel == m.id && Calendar.current.isDate($0.datum, inSameDayAs: tag) }
    }

    /// Aufeinanderfolgende Tage mit geschaffter Aufgabe. Heute zählt mit, ist aber noch offen kein Bruch.
    static func serie(_ statistik: StatistikDienst, heute: Date = Date()) -> Int {
        let kal = Calendar.current
        var tag = heute, n = 0
        if !geschafft(am: tag, statistik) { tag = kal.date(byAdding: .day, value: -1, to: tag) ?? tag }
        while geschafft(am: tag, statistik), n < 365 {
            n += 1
            tag = kal.date(byAdding: .day, value: -1, to: tag) ?? tag
        }
        return n
    }
}

/// Karte auf der Startseite.
struct TagesaufgabeKarte: View {
    let oeffnen: (String) -> Void
    @Environment(StatistikDienst.self) private var statistik
    @Environment(\.dynamicTypeSize) private var schrift

    var body: some View {
        if let m = Tagesaufgabe.spiel(am: Date()) {
            let fertig = Tagesaufgabe.geschafft(am: Date(), statistik)
            let serie = Tagesaufgabe.serie(statistik)
            Button { oeffnen(m.id) } label: {
                (schrift.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Design.Abstand.s)) : AnyLayout(HStackLayout(spacing: Design.Abstand.m))) {
                    Image(systemName: fertig ? "checkmark.circle.fill" : "calendar.badge.clock")
                        .font(.title2).foregroundStyle(.white).frame(minWidth: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tagesaufgabe").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
                        Text(fertig ? "Geschafft! Morgen gibt es eine neue." : "Spiele heute eine Partie \(m.name)")
                            .font(.subheadline.weight(.medium)).foregroundStyle(.white).multilineTextAlignment(.leading)
                        if serie >= 2 { Text("Serie: \(serie) Tage").font(.caption).foregroundStyle(.white.opacity(0.8)) }
                    }
                    if !schrift.isAccessibilitySize {
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(14).frame(maxWidth: .infinity)
                .background(.white.opacity(0.14), in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(fertig ? Text("") : Text("Öffnet das Spiel"))
        }
    }
}

/// Schalter „Tagesaufgabe“ für die Einstellungen. Im Ruhe-Modus und im Kinder-Modus ist die Funktion automatisch aus; der Schalter ist dann gesperrt.
struct TagesaufgabeSchalter: View {
    @AppStorage(Modi.tagesaufgabeKey) private var an = true
    @AppStorage(Modi.kinderKey) private var kinder = false
    @AppStorage(Modi.ruheKey) private var ruhe = false

    private var gesperrt: Bool { ruhe || kinder }

    var body: some View {
        Toggle(isOn: Binding(get: { Tagesaufgabe.sichtbar(ruhe: ruhe, kinder: kinder, an: an) }, set: { an = $0 })) {
            // wie bei Game Center (Fund sp-10): ein Stapel in voller Breite, nicht zwei lose Texte nebeneinander
            VStack(alignment: .leading, spacing: 2) {
                Text("Tagesaufgabe")
                Text(gesperrt ? "Im Ruhe-Modus und im Kinder-Modus ist die Tagesaufgabe aus." : "Zeigt auf der Startseite jeden Tag ein anderes Spiel zum Spielen.")
                    .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(gesperrt)
    }
}
