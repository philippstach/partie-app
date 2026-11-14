// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielerleiste mit Zählwerk: je Person Name, Gesamt und Zuwachs des letzten Zugs (+350 grün, Niete rot).
/// Das Gesamt rollt beim Schreiben hoch, der Zuwachs blendet ein, bei einer Niete wackelt die Kachel kurz.
/// Bis vier Personen eine Reihe, ab fünf zwei Reihen mit kleinerer Schrift; der Zuwachs bleibt sichtbar.
struct NeuSpielerLeiste: View {
    let game: GameState
    var aufTipp: () -> Void = {}
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var zweireihig: Bool { game.players.count > 4 }

    /// Große Tinte-Runde, Punkt 6: runde Leiste mit Bild und Spielerfarbe (bis sechs Personen), sonst die bisherige Leiste.
    static func tinte(_ game: GameState) -> Bool { Tisch.aktiv && game.players.count <= 6 }

    var body: some View {
        if Self.tinte(game) { tinteLeiste } else { bisherigeLeiste }
    }

    private var tinteLeiste: some View {
        SpielerLeiste(eintraege: game.players.indices.map { i in
            .init(id: "\(i)", name: game.players[i].name, farbe: Spieler.farbe(i), wert: Theme.points(game.players[i].score))
        }, aktiv: game.finished ? nil : "\(game.current)")
        .contentShape(.rect)
        .onTapGesture(perform: aufTipp)
        // F21-012: ein Element für die ganze Leiste (der Zug steht schon auf der Zugkarte)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(game.players.map { "\($0.name) \(Theme.points($0.score))" }.joined(separator: ", ")))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Zeigt Punktestand und Verlauf")
    }

    @ViewBuilder private var bisherigeLeiste: some View {
        let reihen = zweireihig ? stride(from: 0, to: game.players.count, by: 4).map { Array(game.players.indices[$0..<min($0 + 4, game.players.count)]) }
                                : [Array(game.players.indices)]
        VStack(spacing: Design.Abstand.xs) {
            ForEach(Array(reihen.enumerated()), id: \.offset) { _, reihe in
                HStack(spacing: Design.Abstand.xs) {
                    ForEach(reihe, id: \.self) { i in kachel(i) }
                    // Letzte Reihe auffüllen, damit alle Kacheln gleich breit bleiben
                    if zweireihig { ForEach(0..<(4 - reihe.count), id: \.self) { _ in Color.clear.frame(maxWidth: .infinity) } }
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .tischFlaeche(16)
        .contentShape(.rect)
        .onTapGesture(perform: aufTipp)
        // F21-012: ein Element für die ganze Leiste statt Name und Punkte je Kachel einzeln (der Zug steht schon auf der Zugkarte)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(game.players.map { "\($0.name) \(Theme.points($0.score))" }.joined(separator: ", ")))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Zeigt Punktestand und Verlauf")
    }

    private func kachel(_ i: Int) -> some View {
        let p = game.players[i]
        let aktiv = i == game.current && !game.finished
        let z = NeuLogik.zuwachs(game, player: i)
        let klein = zweireihig || typeSize.isAccessibilitySize
        return VStack(spacing: 1) {
            HStack(spacing: 3) {
                Text(p.avatar).font(klein ? .caption : .subheadline)
                Text(p.name).font(.caption.weight(aktiv ? .bold : .regular)).lineLimit(1).minimumScaleFactor(0.6)
            }
            Text(Theme.points(p.score))
                .font(.system(klein ? .subheadline : .headline, design: Design.zahlDesign, weight: .heavy))
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
                .foregroundStyle(p.score < 0 ? .red : .primary)
                .contentTransition(.numericText(value: Double(p.score)))
                .animation(reduceMotion ? nil : .snappy(duration: 0.8), value: p.score)
            zuwachsText(z)
                .font(.caption2.weight(.bold))
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(minHeight: 14)
                .id(p.turns)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.4), value: p.turns)
        }
        .padding(.vertical, 5).padding(.horizontal, 3)
        .frame(maxWidth: .infinity)
        .background(aktiv ? p.color.opacity(0.18) : .clear, in: .rect(cornerRadius: Design.Ecke.feld))
        .overlay(RoundedRectangle(cornerRadius: Design.Ecke.feld).strokeBorder(aktiv ? p.color.opacity(0.7) : .clear, lineWidth: 1.5))
        .keyframeAnimator(initialValue: CGFloat(0), trigger: reduceMotion ? 0 : p.nieten) { v, x in v.offset(x: x) } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(7, duration: 0.06)
                CubicKeyframe(-7, duration: 0.09)
                CubicKeyframe(5, duration: 0.08)
                CubicKeyframe(-3, duration: 0.07)
                CubicKeyframe(0, duration: 0.06)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.sprechtext(name: p.name, punkte: p.score, zelle: z, amZug: aktiv))
    }

    @ViewBuilder
    private func zuwachsText(_ z: NeuZelle) -> some View {
        switch z {
        case .leer: Text(verbatim: " ")
        case .punkte(let n): Text(verbatim: "+\(Theme.points(n))").foregroundStyle(Color.meldungGruen)
        case .niete: Text("Niete").foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.meldungRot)
        case .strafe(let n): Text(verbatim: "−\(Theme.points(n))").foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.meldungRot)
        }
    }

    static func sprechtext(name: String, punkte: Int, zelle: NeuZelle, amZug: Bool) -> Text {
        var t = Text("\(name), \(Theme.points(punkte)) Punkte")
        switch zelle {
        case .leer: break
        case .punkte(let n): t = t + Text(", zuletzt plus \(Theme.points(n))")
        case .niete: t = t + Text(", zuletzt Niete")
        case .strafe(let n): t = t + Text(", zuletzt Strafe minus \(Theme.points(n))")
        }
        if amZug { t = t + Text(", am Zug") }
        return t
    }
}
