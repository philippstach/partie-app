// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

extension Cup {
    var color: Color {
        switch self {
        case .bronze: Theme.bronze
        case .silver: Theme.silver
        case .gold: Theme.cupGold
        }
    }

    var title: String {
        switch self {
        case .bronze: String(localized: "Bronze")
        case .silver: String(localized: "Silber")
        case .gold: String(localized: "Gold")
        }
    }
}

/// Pokal-Fortschritt als dünner Balken: „7/10 bis Bronze“ (Gold erreicht: „Goldpokal!“)
struct CupProgress: View {
    let cup: Cup?
    let crowns: Int
    let daysInMonth: Int

    private var target: Int {
        switch cup {
        case nil: Cup.bronzeCrowns
        case .bronze: Cup.silverCrowns
        default: daysInMonth
        }
    }
    private var goalName: String {
        switch cup {
        case nil: String(localized: "Bronze")
        case .bronze: String(localized: "Silber")
        default: String(localized: "Gold")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            if cup == .gold {
                Label("Goldpokal!", systemImage: "trophy.fill").font(.caption.weight(.semibold)).foregroundStyle(Color.appFarbe)
            } else {
                Text("\(crowns)/\(target) bis \(goalName)").font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.2))
                    Capsule().fill(Color.appFarbe).frame(width: geo.size.width * min(1, Double(crowns) / Double(max(1, cup == .gold ? crowns : target))))
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cup == .gold ? Text("Goldpokal erreicht") : Text("\(crowns) von \(target) Kronen bis \(goalName)"))
    }
}

/// Monatspokal: Symbol in Bronze, Silber oder Gold. Noch keiner: grauer Umriss mit „7/10“ bis zur nächsten Stufe.
struct CupView: View {
    let cup: Cup?
    let crowns: Int
    let daysInMonth: Int

    /// Nächstes Ziel in Kronen (10, 20, alle Tage)
    private var target: Int {
        switch cup {
        case nil: Cup.bronzeCrowns
        case .bronze: Cup.silverCrowns
        default: daysInMonth
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: cup == nil ? "trophy" : "trophy.fill")
                .font(.title3)
                .foregroundStyle(cup?.color ?? .secondary)
            if cup != .gold {
                Text(verbatim: "\(crowns)/\(target)")
                    .font(.system(.caption, design: Design.zahlDesign).weight(.semibold)).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cup.map { Text("Pokal \($0.title), \(crowns) Kronen") } ?? Text("Noch kein Pokal, \(crowns) von \(target) Kronen"))
    }
}
