// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

// Die Bausteine des Spieltischs (Einblendungen, Angebots-Blatt, Spielerkarte, Tafel, Verlauf). Die frühere Gesamtansicht `GameView`
// der Einzel-App ist entfernt; in der Sammlung setzt `NeuSpielView` diese Bausteine zusammen.

/// Niete- und Stechen-Einblendung. Auf dem iPhone über dem ganzen Spiel, auf dem iPad nur über dem Tisch
/// (nicht über der Tafel, SPEC-1.1 §3).
struct TischEinblendungen: View {
    @Environment(GameStore.self) private var store
    let game: GameState

    var body: some View {
        ZStack {
            if let notice = store.nieteNotice {
                NieteOverlay(notice: notice, game: game,
                             onCorrect: game.settings.diceMode == .real && !notice.dice.isEmpty && store.canUndo
                                ? { withAnimation { store.undo() } } : nil) { store.nieteNotice = nil }
                    .transition(.opacity)
                    // VoiceOver: nur die Einblendung, Zwei-Finger-Wischen schließt sie
                    .accessibilityAddTraits(.isModal)
                    .accessibilityAction(.escape) { store.nieteNotice = nil }
                    // Schließt sich selbst (vorläufig 3 s, mit Strafe 4 s); mit VoiceOver erst nach der Ansage
                    .task(id: notice) {
                        await NieteOverlay.waitBeforeClosing(penalty: notice.penalty > 0)
                        if !Task.isCancelled, store.nieteNotice == notice { store.nieteNotice = nil }
                    }
            } else if let tb = store.tiebreakNotice {
                TiebreakOverlay(tiebreak: tb, game: game) { store.tiebreakNotice = nil }
                    .transition(.opacity)
                    .accessibilityAddTraits(.isModal)
                    .accessibilityAction(.escape) { store.tiebreakNotice = nil }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.nieteNotice)
        .animation(.easeInOut(duration: 0.2), value: store.tiebreakNotice)
    }
}

// MARK: - Übernehmen

/// „Würfel übernehmen?“ als halbhohe Karte: angebotene Würfel, Punkte, Warnung, zwei Knöpfe.
struct OfferSheet: View {
    let offer: InheritOffer
    let game: GameState
    let onAccept: () -> Void
    let onDecline: () -> Void
    /// iPad (Größenklasse des Spiels, nicht des Blatts – ein Formblatt meldet innen „compact“)
    var wide = false

    var body: some View {
        // Build 11: Passt der Inhalt nicht (kleines iPhone, große Schrift), scrollt er –
        // vorher waren Titel und „Nicht übernehmen“ abgeschnitten
        ViewThatFits(in: .vertical) {
            inhalt
            ScrollView { inhalt }
        }
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
        .modifier(FittedFormSheet(wide: wide))
    }

    private var inhalt: some View {
        let from = game.players[offer.from]
        let me = game.players[game.current]
        return VStack(spacing: 14) {
            Text("Würfel übernehmen?")
                .font(.title2.weight(.bold))
                .padding(.top, 8)
            Text("\(me.avatar) \(me.name), \(from.name) bietet dir an:")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("+\(Theme.points(offer.points))")
                .font(.system(.largeTitle, design: Design.zahlDesign).weight(.heavy))
                .foregroundStyle(.tint)

            // Rausgelegt (gesperrt, zählt schon) und offen (würfelst du neu)
            HStack(spacing: Design.Abstand.s) {
                ForEach(offer.dice.indices, id: \.self) { i in
                    DieView(value: offer.dice[i], state: offer.kept[i] ? .locked : .unknown, size: 46)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(diceText)

            Text(diceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if game.penaltyThreatened(game.current) {
                Label("2 Nieten in Folge – bei der nächsten Niete −\(Theme.points(game.settings.penalty))", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // iPhone: Knöpfe unten im Sheet. iPad: Formblatt passt sich dem Inhalt an, ohne Lücke.
            if !wide {
                Spacer(minLength: 0)
            }

            VStack(spacing: 10) {
                Button(action: onAccept) {
                    Text("Übernehmen").frame(maxWidth: .infinity)
                }
                .hauptKnopf()
                .keyboardShortcut(wide ? KeyboardShortcut(.return, modifiers: []) : nil)

                Button(action: onDecline) {
                    Text("Nicht übernehmen").frame(maxWidth: .infinity)
                }
                .zweitKnopf()
                .keyboardShortcut(wide ? KeyboardShortcut(.escape, modifiers: []) : nil)
            }
            .controlSize(.large)
            .font(.headline)
        }
        .padding()
    }

    private var diceText: String {
        let open = offer.openCount
        var text = offer.allOut
            ? String(localized: "Alle \(offer.dice.count) Würfel sind frei – eine Straße zählt dabei nicht.")
            : (open == 1 ? String(localized: "1 Würfel ist offen, die würfelst du neu.") : String(localized: "\(open) Würfel sind offen, die würfelst du neu."))
        text += String(localized: " Bei einer Niete ist alles weg.")
        return text
    }
}

// MARK: - Aktueller Spieler

struct CurrentPlayerCard: View {
    let game: GameState
    /// Spieltisch: Punkte dieses Zugs groß in der Kopfzeile (SPEC-1.1 §3)
    var zugPunkte: Int? = nil
    @Environment(\.tischGross) private var tischGross
    @ScaledMetric(relativeTo: .largeTitle) private var nameGroesse: CGFloat = 34
    @ScaledMetric(relativeTo: .largeTitle) private var zahlGroesse: CGFloat = 44

    var body: some View {
        let p = game.players[game.current]
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            if tischGross {
                tischZeile(p)
            } else {
            ViewThatFits(in: .horizontal) {
                row(p)
                VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                    HStack(spacing: 10) { avatar(p); name(p) }
                    Text("\(Theme.points(p.score)) von \(Theme.points(game.settings.goal))")
                        .font(.system(.body, design: Design.zahlDesign, weight: .semibold))
                        .monospacedDigit()
                }
            }
            }
            ProgressView(value: Double(min(max(p.score, 0), game.settings.goal)), total: Double(game.settings.goal))
                .tint(p.color)
            if let from = game.finalRoundFrom, !game.finished, game.tiebreak == nil, game.players.indices.contains(from) {
                Label("Schlussrunde: \(game.players[from].name) hat das Ziel erreicht – die Runde wird zu Ende gespielt.", systemImage: "flag.checkered")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            if game.penaltyThreatened(game.current) {
                Label("2 Nieten in Folge – bei der nächsten Niete −\(Theme.points(game.settings.penalty))", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [p.color.opacity(0.22), p.color.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: Design.Ecke.karte)
        )
        .overlay(RoundedRectangle(cornerRadius: Design.Ecke.karte).strokeBorder(p.color.opacity(0.35)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Jetzt am Zug: \(p.name), \(Theme.points(p.score)) von \(Theme.points(game.settings.goal)) Punkten")
        .modifier(PlayerDetailTap(player: game.current))
    }

    /// „Gesamt 0 · Ziel 10.000“ bzw. „Gesamt 1.950 · noch 8.050 bis 10.000“ (Build 10)
    static func gesamtText(score: Int, goal: Int) -> String {
        score == 0
            ? String(localized: "Gesamt 0 · Ziel \(Theme.points(goal))")
            : String(localized: "Gesamt \(Theme.points(score)) · noch \(Theme.points(max(goal - score, 0))) bis \(Theme.points(goal))")
    }

    /// iPad breit: Avatar, Name und Zugpunkte groß, darunter klein Gesamtstand und Rest bis zum Ziel
    private func tischZeile(_ p: Player) -> some View {
        HStack(alignment: .center, spacing: Design.Abstand.l) {
            Text(p.avatar).font(.system(size: nameGroesse * 1.4))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
            VStack(alignment: .leading, spacing: 2) {
                Text("AM ZUG")
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text(p.name)
                    .font(.system(size: nameGroesse, weight: .heavy, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .foregroundStyle(p.textColor)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .minimumScaleFactor(0.6)
                Text(CurrentPlayerCard.gesamtText(score: p.score, goal: game.settings.goal))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            if let zugPunkte {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Theme.points(zugPunkte))
                        .font(.system(size: zahlGroesse, weight: .heavy, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                        .monospacedDigit()
                        .foregroundStyle(.tint)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: zugPunkte)
                    Text("in diesem Zug")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .fixedSize()
            }
        }
    }

    private func row(_ p: Player) -> some View {
        HStack(spacing: 10) {
            avatar(p)
            VStack(alignment: .leading, spacing: 0) {
                Text("JETZT AM ZUG")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                name(p)
            }
            Spacer(minLength: 8)
            score(p)
        }
    }

    private func avatar(_ p: Player) -> some View {
        Text(p.avatar).font(.title)
    }

    private func name(_ p: Player) -> some View {
        Text(p.name)
            .font(.system(.title2, design: Design.zahlDesign, weight: .heavy))
            .foregroundStyle(p.textColor)
            .lineLimit(1).minimumScaleFactor(0.7)
            .minimumScaleFactor(0.7)
    }

    private func score(_ p: Player) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(Theme.points(p.score))
                .font(.system(.title3, design: Design.zahlDesign, weight: .bold))
                .monospacedDigit()
            Text("von \(Theme.points(game.settings.goal))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
    }
}

// MARK: - Punktetabelle

struct Scoreboard: View {
    let game: GameState
    /// iPad hoch: Personen als Kacheln im Raster statt Zeilen (SPEC-1.1 §3)
    var raster = false
    @Environment(\.tischGross) private var tischGross
    /// Spieltisch: „Tabelle | Verlauf“ als Schalter in der Tafel statt eigenem Blatt
    @State private var zeigeVerlauf = false

    var body: some View {
        // Krone nur für einen alleinigen Spitzenreiter
        let top = game.players.map(\.score).max() ?? 0
        let leaders = game.players.indices.filter { game.players[$0].score == top }
        let leader = leaders.count == 1 ? leaders.first : nil
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionLabel("Punktestand")
                if tischGross, !game.log.isEmpty {
                    Spacer()
                    Picker("Ansicht", selection: $zeigeVerlauf) {
                        Text("Tabelle").tag(false)
                        Text("Verlauf").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }
            .padding(.bottom, 8)
            if tischGross && zeigeVerlauf && !game.log.isEmpty {
                ScoreChart(game: game, height: raster ? 220 : 300)
            } else if raster {
                rasterAnsicht(leader: leader)
            } else {
            ForEach(game.players.indices, id: \.self) { i in
                let p = game.players[i]
                HStack(spacing: tischGross ? 14 : 10) {
                    Text(p.avatar).font(tischGross ? .largeTitle : .title3)
                    Text(p.name + (i == leader && p.score > 0 ? " 👑" : ""))
                        .font(tischGross ? .title2 : .body)
                        .fontWeight(i == game.current ? .bold : .regular)
                        .foregroundStyle(i == game.current ? p.textColor : .primary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .minimumScaleFactor(0.7)
                    if game.penaltyThreatened(i) {
                        Label("−\(Theme.points(game.settings.penalty)) droht", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2.weight(.bold))
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(.red, in: .circle)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(0..<3) { d in
                            Circle()
                                .fill(d < p.streak ? Color(.systemRed) : .clear)
                                .strokeBorder(d < p.streak ? Color(.systemRed) : Color.primary.opacity(0.2))
                                .frame(width: tischGross ? 11 : 7, height: tischGross ? 11 : 7)
                        }
                    }
                    .accessibilityHidden(true)
                    Text(Theme.points(p.score))
                        .font(.system(tischGross ? .title : .body, design: Design.zahlDesign, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(p.score < 0 ? .red : .primary)
                        .fixedSize()
                        .frame(minWidth: tischGross ? 110 : 64, alignment: .trailing)
                        .contentTransition(.numericText())
                }
                .padding(.vertical, tischGross ? 12 : 8)
                .padding(.horizontal, tischGross ? 12 : 8)
                .background(i == game.current ? p.color.opacity(0.08) : .clear, in: .rect(cornerRadius: 10))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowLabel(p, index: i, leader: leader))
                .modifier(PlayerDetailTap(player: i))
            }
            }
            // Legende zu den roten Punkten, sobald jemand eine Niete hat
            if game.settings.penalty > 0, game.tiebreak == nil, game.players.contains(where: { $0.streak > 0 }) {
                HStack(spacing: Design.Abstand.xs) {
                    legendDots(1)
                    Text("= Niete in Folge · bei")
                    legendDots(3)
                    Text("gibt es −\(Theme.points(game.settings.penalty))")
                }
                    .font(.caption)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
            }
        }
        .card()
        .animation(.default, value: game.players.map(\.score))
    }

    /// Kacheln: bei 2–3 Personen eine Zeile mit großen Karten, sonst 2 Spalten (SPEC-1.1 §3)
    private func rasterAnsicht(leader: Int?) -> some View {
        let n = game.players.count
        let spalten = Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.m), count: n <= 3 ? n : 2)
        return LazyVGrid(columns: spalten, spacing: Design.Abstand.m) {
            ForEach(game.players.indices, id: \.self) { i in
                let p = game.players[i]
                HStack(spacing: Design.Abstand.m) {
                    Text(p.avatar).font(.largeTitle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name + (i == leader && p.score > 0 ? " 👑" : ""))
                            .font(.title3.weight(i == game.current ? .bold : .medium))
                            .foregroundStyle(i == game.current ? p.textColor : .primary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .minimumScaleFactor(0.6)
                        HStack(spacing: Design.Abstand.xs) {
                            ForEach(0..<3) { d in
                                Circle()
                                    .fill(d < p.streak ? Color(.systemRed) : .clear)
                                    .strokeBorder(d < p.streak ? Color(.systemRed) : Color.primary.opacity(0.2))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .accessibilityHidden(true)
                    }
                    Spacer(minLength: 4)
                    Text(Theme.points(p.score))
                        .font(.system(n <= 3 ? .largeTitle : .title, design: Design.zahlDesign, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(p.score < 0 ? .red : .primary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                }
                .padding(14)
                .background(i == game.current ? p.color.opacity(0.14) : Color(.tertiarySystemFill).opacity(0.5),
                            in: .rect(cornerRadius: 16))
                .overlay {
                    if i == game.current {
                        RoundedRectangle(cornerRadius: 16).strokeBorder(p.color.opacity(0.6), lineWidth: 2)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowLabel(p, index: i, leader: leader))
                .modifier(PlayerDetailTap(player: i))
            }
        }
    }

    private func legendDots(_ n: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<n, id: \.self) { _ in Circle().fill(.red).frame(width: 7, height: 7) }
        }
    }

    /// z. B. „Anna, 1.200 Punkte, führt, 2 Nieten in Folge, Strafe droht, am Zug“
    private func rowLabel(_ p: Player, index i: Int, leader: Int?) -> String {
        var parts = [p.name, String(localized: "\(Theme.points(p.score)) Punkte")]
        if i == leader && p.score > 0 { parts.append("führt") }
        if p.streak > 0 { parts.append(p.streak == 1 ? String(localized: "1 Niete in Folge") : String(localized: "\(p.streak) Nieten in Folge")) }
        if game.penaltyThreatened(i) { parts.append(String(localized: "bei der nächsten Niete −\(Theme.points(game.settings.penalty))")) }
        if i == game.current { parts.append(String(localized: "am Zug")) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Verlauf

struct HistoryCard: View {
    let game: GameState
    /// Anzahl der letzten Züge; `nil` = alle
    var limit: Int? = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(verbatim: limit == nil ? String(localized: "Alle Züge") : String(localized: "Letzte Züge")).padding(.bottom, 2)
            ForEach(game.log.suffix(limit ?? game.log.count).reversed()) { r in
                let p = game.players[r.player]
                HStack {
                    Text("\(p.avatar) \(p.name)").foregroundStyle(.secondary)
                    Spacer()
                    if r.penalty > 0 {
                        Text("−\(Theme.points(r.penalty)) Strafe").foregroundStyle(.red).fontWeight(.semibold)
                    } else if r.points == 0 {
                        Text("Niete").foregroundStyle(.secondary)
                    } else {
                        Text("+\(Theme.points(r.points))").foregroundStyle(.tint).fontWeight(.semibold)
                    }
                }
                .font(.subheadline)
            }
        }
        .card()
    }
}

// MARK: - Einblendungen

struct TiebreakCard: View {
    let game: GameState
    let tiebreak: Tiebreak

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Label(tiebreak.round == 1 ? String(localized: "STECHEN") : String(localized: "STECHEN · RUNDE \(tiebreak.round)"), systemImage: "flag.2.crossed.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tint)
            ForEach(Array(tiebreak.players.enumerated()), id: \.offset) { pos, i in
                let p = game.players[i]
                HStack {
                    Text("\(p.avatar) \(p.name)")
                        .fontWeight(i == game.current ? .bold : .regular)
                    Spacer()
                    if pos < tiebreak.points.count {
                        Text(tiebreak.points[pos] == 0 ? String(localized: "Niete") : "+\(Theme.points(tiebreak.points[pos]))")
                            .foregroundStyle(tiebreak.points[pos] == 0 ? .secondary : Color.accentColor)
                    } else {
                        Text(i == game.current ? String(localized: "am Zug") : String(localized: "wartet")).foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
            Text("Wer in dieser Runde die meisten Punkte macht, gewinnt. Keine Strafe im Stechen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}

struct TiebreakOverlay: View {
    let tiebreak: Tiebreak
    let game: GameState
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Rectangle().fill(Color(.systemBackground).opacity(0.88)).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("⚔️").font(.system(size: 64))   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                Text("Stechen!")
                    .font(.system(.largeTitle, design: Design.zahlDesign).weight(.heavy))
                Text(tiebreak.round == 1
                     ? String(localized: "Gleichstand nach der letzten Runde.")
                     : String(localized: "Wieder gleich – Stechrunde \(tiebreak.round)."))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 18) {
                    ForEach(tiebreak.players, id: \.self) { i in
                        VStack(spacing: Design.Abstand.xs) {
                            Text(game.players[i].avatar).font(.largeTitle)
                            Text(game.players[i].name)
                                .font(.headline)
                                .foregroundStyle(game.players[i].textColor)
                        }
                    }
                }
                Text("Alle haben je einen Zug. Wer die meisten Punkte macht, gewinnt.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button(action: onDismiss) {
                    Text("Los geht’s").frame(maxWidth: .infinity)
                }
                .hauptKnopf()
                .controlSize(.large)
                .padding(.top, 8)
            }
            .padding(28)
            .frame(maxWidth: 420)
        }
    }
}

/// Kurzer Hinweis, wer dran ist – nicht modal, kein Tippen nötig.
/// „Neuer persönlicher Rekord: bester Zug 2.350!“
struct RecordBanner: View {
    let player: Player
    let notice: RecordNotice

    var body: some View {
        HStack(spacing: 10) {
            Text("🏆").font(.title2)
            VStack(alignment: .leading, spacing: 0) {
                Text("NEUER PERSÖNLICHER REKORD").font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(.secondary)
                Text("\(player.avatar) \(player.name): bester Zug \(Theme.points(notice.points))!")
                    .font(.system(.subheadline, design: Design.zahlDesign, weight: .bold))
                    .foregroundStyle(player.textColor)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .minimumScaleFactor(0.8)
                Text("bisher \(Theme.points(notice.previous))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .toast()
        .padding(.horizontal)
        .allowsHitTesting(false)
        .accessibilityHidden(true)   // wird per Ansage vorgelesen
    }
}

struct NextPlayerBanner: View {
    let player: Player

    var body: some View {
        HStack(spacing: 10) {
            Text(player.avatar).font(.title)
            VStack(alignment: .leading, spacing: 0) {
                Text("JETZT AM ZUG").font(.caption2.weight(.semibold)).tracking(1.5).foregroundStyle(.secondary)
                Text(player.name)
                    .font(.system(.title3, design: Design.zahlDesign, weight: .heavy))
                    .foregroundStyle(player.textColor)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .toast()
        .padding(.top, 8)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

struct NieteOverlay: View {
    let notice: NieteNotice
    let game: GameState
    /// Echte Würfel: falsch eingegebenen Wurf zurücknehmen und neu eingeben
    var onCorrect: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shakeTrigger = 0
    @State private var progress: CGFloat = 1
    let onDismiss: () -> Void

    /// Wartezeit, bis sich die Einblendung selbst schließt.
    static func displayDuration(penalty: Bool) -> Duration { penalty ? .seconds(4) : .seconds(3) }

    static func waitBeforeClosing(penalty: Bool) async {
        if UIAccessibility.isVoiceOverRunning {
            // Ansage abwarten (höchstens 12 s), dann noch einen Moment stehen lassen
            let finished = NotificationCenter.default.notifications(named: UIAccessibility.announcementDidFinishNotification)
            let timeout = Task { try? await Task.sleep(for: .seconds(12)) }
            await withTaskGroup(of: Void.self) { group in
                group.addTask { for await _ in finished { break } }
                group.addTask { await timeout.value }
                await group.next()
                group.cancelAll()
            }
            timeout.cancel()
            try? await Task.sleep(for: .seconds(2))
        } else {
            try? await Task.sleep(for: displayDuration(penalty: penalty))
        }
    }

    var body: some View {
        ZStack {
            Rectangle().fill(Color(.systemBackground).opacity(0.88)).ignoresSafeArea()
                // Tipp daneben schließt sofort
                .onTapGesture(perform: onDismiss)
            VStack(spacing: 14) {
                Text(notice.penalty > 0 && notice.dice.isEmpty ? "⚠️" : "💀").font(.system(size: 64))   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                Text(notice.dice.isEmpty ? String(localized: "Strafe!") : String(localized: "Niete!"))
                    .font(.system(.largeTitle, design: Design.zahlDesign).weight(.heavy))

                if !notice.dice.isEmpty {
                    HStack(spacing: Design.Abstand.s) {
                        ForEach(notice.dice.indices, id: \.self) { i in
                            DieView(value: notice.dice[i], state: notice.locked[i] ? .locked : .free, size: notice.dice.count > 5 ? 42 : 48)
                        }
                    }
                    // Kurzes Kopfschütteln der Würfel (nicht bei „Bewegung reduzieren“)
                    .phaseAnimator(reduceMotion ? [0.0] : [0.0, -12, 12, -8, 8, -3, 0], trigger: shakeTrigger) { view, x in
                        view.offset(x: x)
                    } animation: { _ in .easeInOut(duration: 0.06) }
                    .onAppear { shakeTrigger += 1 }
                    Text(notice.lostPoints > 0
                         ? String(localized: "Kein Würfel bringt Punkte – \(Theme.points(notice.lostPoints)) Punkte sind weg.")
                         : String(localized: "Kein Würfel bringt Punkte."))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                if notice.penalty > 0 {
                    Text("\(game.players[notice.player].name) hat 3× in Folge nichts geschafft: −\(Theme.points(notice.penalty)) Punkte.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }

                Button(action: onDismiss) {
                    Text(game.finished ? String(localized: "Weiter") : String(localized: "Weiter zu \(game.players[game.current].name)"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(HauptKnopfStil())
                .tint(.red)
                .controlSize(.large)
                .padding(.top, 8)
                .overlay(alignment: .bottom) { countdown }

                if let onCorrect {
                    Button("Falsch eingegeben? Wurf korrigieren", systemImage: "arrow.uturn.backward", action: onCorrect)
                        .font(.footnote)
                }
            }
            .padding(28)
            .frame(maxWidth: 400)
            .contentShape(.rect)
            .onTapGesture(perform: onDismiss)
        }
        // VoiceOver (Build 11): Niete sofort ansagen; eine Strafe erst nach dem „Fail“-Ton
        .task {
            guard UIAccessibility.isVoiceOverRunning else { return }
            UIAccessibility.post(notification: .announcement,
                                 argument: VoiceOverText.niete(verloren: notice.lostPoints, strafe: 0))
            guard notice.penalty > 0 else { return }
            try? await Task.sleep(for: .seconds(GameStore.failDelay + 1.2))
            UIAccessibility.post(notification: .announcement,
                                 argument: String(localized: "Strafe: minus \(Theme.points(notice.penalty)) Punkte"))
        }
    }

    /// Dünner Balken unter „Weiter“, der bis zum automatischen Schließen abläuft
    @ViewBuilder private var countdown: some View {
        if !UIAccessibility.isVoiceOverRunning {
            GeometryReader { geo in
                Capsule()
                    .fill(.white.opacity(0.6))
                    .frame(width: geo.size.width * progress, height: 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 3)
            .padding(.horizontal, 14)
            .padding(.bottom, 5)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                let seconds = Double(Self.displayDuration(penalty: notice.penalty > 0).components.seconds)
                withAnimation(.linear(duration: seconds)) { progress = 0 }
            }
        }
    }
}

/// iPad: Formblatt nur so hoch wie der Inhalt (ab iOS 18). iPhone und ältere Systeme unverändert.
private struct FittedFormSheet: ViewModifier {
    let wide: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    @ViewBuilder
    func body(content: Content) -> some View {
        if wide {
            if #available(iOS 18.0, *) {
                content.presentationSizing(.form.fitted(horizontal: false, vertical: true))
            } else {
                content
            }
        } else {
            // iPhone: halbhoch wie bisher (Detents würden auf dem iPad die angepasste Höhe überstimmen)
            // Große Schrift: gleich volle Höhe (Build 11)
            content.presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        }
    }
}
