// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Regeln: je Spiel eine kurze Seite mit gezeichnetem Beispiel und den Überschriften „Ziel“, „So geht’s“, „Tipp“
struct RulesDetailView: View {
    @Environment(AppModel.self) private var app
    @State private var choice: GameKind?

    private var kind: GameKind { choice ?? app.session.mode.kind }

    @State private var springen: String?

    /// Bauplan RS / Blatt 29: eine Regelseite für alle Spiele. Kopf: Auswahl der sieben Spielarten und das Beispielbild; die Auswahl springt zum Abschnitt.
    var body: some View {
        if let q = RegelLeseKatalog.quelle(fuer: "solitaer") {
            RegelLeseAnsicht(quelle: q, spielName: "Solitär", spielID: "solitaer", wissen: nil, springeZu: $springen) {
                VStack(spacing: Design.Abstand.l) {
                    GameKindCapsules(selection: Binding(get: { kind }, set: { choice = $0; springen = abschnittsTitel($0) }))
                    example
                }
            }
        } else { alteSeite }
    }

    private func abschnittsTitel(_ k: GameKind) -> String {
        switch k {
        case .klondike: "Klondike"
        case .spider: "Spider"
        case .freecell: "FreeCell"
        case .pyramid: "Pyramide"
        case .tripeaks: "TriPeaks"
        case .golf: "Golf"
        case .yukon: "Yukon"
        }
    }

    private var alteSeite: some View {
        ScrollView {
            VStack(spacing: Design.Abstand.l) {
                GameKindCapsules(selection: Binding(get: { kind }, set: { choice = $0 }))

                example
                block("Ziel", goal)
                block("So geht’s", how)
                block("Tipp", tip)
                if kind == .klondike { block("Punkte", "Ablage → Spalte +5 · aufs Ziel +10 · Karte aufgedeckt +5 · vom Ziel zurück −15 · Stapel umdrehen −100 (bei 3 Karten −20). Punkte fallen nie unter 0.") }
                block("Lösbare Partien", "Jede lösbare Partie hat ein Computer vorab wirklich bis zum Sieg durchgespielt. Du kannst sie also immer gewinnen – den Weg musst du nur finden.")
            }
            .padding(16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color.seitenGrund)
        .navigationTitle("Regeln")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Texte

    private var goal: LocalizedStringKey {
        switch kind {
        case .klondike: "Lege alle Karten nach Farben sortiert von Ass bis König auf die vier Zielstapel oben."
        case .spider: "Räume alle Spalten ab: Eine vollständige Reihe von König bis Ass in einer Farbe wandert automatisch ab."
        case .freecell: "Lege alle Karten nach Farben von Ass bis König auf die vier Ziele oben rechts."
        case .pyramid: "Räume die Pyramide ab: Entferne Paare, die zusammen 13 ergeben. Ein König geht allein."
        case .tripeaks: "Bringe alle Karten der drei Gipfel auf die Ablage."
        case .golf: "Bringe alle 35 Karten der sieben Spalten auf die Ablage."
        case .yukon: "Lege alle Karten nach Farben von Ass bis König auf die vier Ziele. Alle Karten liegen von Anfang an in den Spalten – es gibt keinen Stapel."
        }
    }

    private var how: LocalizedStringKey {
        switch kind {
        case .klondike: "In den sieben Spalten legst du absteigend und abwechselnd rot und schwarz an – zum Beispiel die Herz-9 auf die Pik-10. Ganze passende Reihen darfst du gemeinsam verschieben, in eine leere Spalte nur einen König. Tippe auf den Stapel, um 1 oder 3 Karten aufzudecken; ist er leer, wird die Ablage wieder zum Stapel."
        case .spider: "Lege eine Karte auf eine um eins höhere – egal welche Farbe. Verschieben kannst du aber nur Reihen in derselben Farbe. Der Stapel legt auf jede Spalte eine Karte, aber nur, wenn keine Spalte leer ist."
        case .freecell: "Alle Karten liegen offen. Lege absteigend und abwechselnd rot und schwarz an. Die vier freien Zellen oben links parken je eine Karte. Mehrere Karten auf einmal gehen, solange genug Zellen und leere Spalten frei sind."
        case .pyramid: "Nur freie Karten zählen – keine andere Karte darf mehr auf ihnen liegen. Ass = 1, Bube = 11, Dame = 12. Tippe eine Karte an, dann ihren Partner (die 6 passt zur 7). Gibt es nur einen Partner, verschwindet das Paar sofort. Der Stapel deckt die nächste Ablagekarte auf; die Ablage darfst du zweimal umdrehen."
        case .tripeaks: "Eine freie Karte darf auf die Ablage, wenn sie genau einen Wert höher oder niedriger ist – König und Ass zählen als Nachbarn. Je länger deine Kette ohne Ziehen vom Stapel, desto mehr Punkte; ein geräumter Gipfel bringt einen Bonus."
        case .yukon: "Lege absteigend und abwechselnd rot und schwarz an. Der Kniff: Jede offene Karte darfst du samt allem, was darauf liegt, verschieben – die Karten darüber müssen keine Reihe bilden. Nur die unterste bewegte Karte muss passen. In eine leere Spalte geht nur ein König."
        case .golf: "Nur die oberste Karte jeder Spalte darf auf die Ablage, wenn sie genau einen Wert höher oder niedriger ist. König und Ass sind keine Nachbarn, und auf einen König geht nichts – dann hilft nur der Stapel. Der Stapel geht einmal durch. Punkte: die Karten, die beim Sieg im Stapel übrig bleiben."
        }
    }

    private var tip: LocalizedStringKey {
        switch kind {
        case .klondike: "Tippe eine Karte an, und sie springt an den besten Platz. Decke zuerst verdeckte Karten auf – das öffnet die meisten Möglichkeiten."
        case .spider: "Halte Reihen möglichst einfarbig und leere früh eine Spalte – sie ist dein wichtigster Spielraum."
        case .freecell: "Fast jede Partie ist lösbar. Lass die Zellen nicht zu früh volllaufen und leere lieber eine Spalte."
        case .pyramid: "Zieh nicht zu früh vom Stapel: Schau erst, welche Paare in der Pyramide schon gehen."
        case .tripeaks: "Plane die Kette voraus: Karten, die verdeckte Karten freilegen, kommen zuerst."
        case .yukon: "Decke zuerst verdeckte Karten auf: Verschiebe dafür ganze Stapel, auch ungeordnete. Tippst du eine tiefere offene Karte an, geht die ganze Gruppe."
        case .golf: "Alle Karten sind offen – plane die Kette: Spar dir den Stapel für Könige und Sackgassen auf."
        }
    }

    // MARK: Beispiel (2–3 Karten, im Code gezeichnet)

    private var example: some View {
        let w: CGFloat = 54
        func face(_ rank: Int, _ suit: Suit) -> some View { CardFaceView(face: CardFace(rank: rank, suit: suit), width: w, fourColor: app.prefs.fourColor) }
        return HStack(spacing: 18) {
            switch kind {
            case .klondike, .freecell:
                ZStack(alignment: .top) { face(10, .spades); face(9, .hearts).offset(y: 24) }.frame(width: w, height: w * 1.4 + 24)
            case .spider:
                ZStack(alignment: .top) { face(8, .spades); face(7, .spades).offset(y: 24) }.frame(width: w, height: w * 1.4 + 24)
            case .pyramid:
                HStack(spacing: 6) { face(6, .hearts); Text(verbatim: "+").font(.title2.bold()); face(7, .spades); Text(verbatim: "= 13").font(.title3.bold().monospacedDigit()) }
            case .yukon:
                ZStack(alignment: .top) { face(10, .spades); face(9, .hearts).offset(y: 24); face(4, .clubs).offset(y: 48) }.frame(width: w, height: w * 1.4 + 48)
            case .tripeaks, .golf:
                HStack(spacing: Design.Abstand.s) { face(7, .spades); Image(systemName: "arrow.right").font(.title3.bold()); face(8, .hearts) }
            }
        }
        .foregroundStyle(Color.appFarbe)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .designFlaeche(Theme.cardRadius)
        .accessibilityHidden(true)
    }

    private func block(_ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            SectionLabel(title)
            Text(text).font(.subheadline)
        }
        .card()
    }
}
