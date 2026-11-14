// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Designwechsel (KlarGlas 2.17): Startseite eines Spiels in den Designs Tinte und Salon. In „Klar & Glas“ baut der
// Spielrahmen seine Startseite wie bisher aus `StartTitel`, `SpielBild` und Karten; dieser Baustein wird dort nicht benutzt.
// Der Rahmen liefert nur Inhalte (Name, Untertitel, Statistik-Werte) und zwei Plätze: `extras` (Tisch-Modus, Würfelwahl)
// und `knoepfe` (Fortsetzen, Letzte Runde, Neues Spiel). Aufbau, Farben und Schrift stehen hier.

#if canImport(UIKit)

public struct SpielStartSeite<Extras: View, Knoepfe: View>: View {
    let name: Text
    let untertitel: Text
    let spielart: Text?
    let farbe: Color?
    let miniatur: Miniatur?
    let statistikTitel: Text
    let werte: [StatistikZeile.Wert]
    let zurueckTitel: Text
    let zurueck: () -> Void
    let regeln: () -> Void
    let extras: Extras
    let knoepfe: Knoepfe
    /// 2.27 (F-AWS-K-038): Spielname in einer Zeile halten (Salon verkleinert statt mitten im Wort zu brechen), für Namen aus einem Wort.
    var nameEinzeilig = false
    @Environment(\.designArt) private var art
    /// 2.37 (A-002/A-004/A-008): Schriftgröße der Bedienungshilfen. Dann liegen die Knöpfe am Ende der Seite statt als feste Leiste.
    @Environment(\.dynamicTypeSize) private var schrift

    /// Spielname einzeilig (Salon): `SpielStartSeite(…).nameEinzeilig(!name.contains(" "))`.
    public func nameEinzeilig(_ an: Bool = true) -> Self { var k = self; k.nameEinzeilig = an; return k }

    /// `spielart`, `farbe`, `miniatur`: Name, Fläche und Miniatur der Spielart (ohne Angabe entfallen Punkt und Bild).
    public init(name: Text, untertitel: Text, spielart: Text? = nil, farbe: Color? = nil, miniatur: Miniatur? = nil,
                statistikTitel: Text, werte: [StatistikZeile.Wert], zurueckTitel: Text,
                zurueck: @escaping () -> Void, regeln: @escaping () -> Void,
                @ViewBuilder extras: () -> Extras, @ViewBuilder knoepfe: () -> Knoepfe) {
        self.name = name; self.untertitel = untertitel; self.spielart = spielart; self.farbe = farbe; self.miniatur = miniatur
        self.statistikTitel = statistikTitel; self.werte = werte; self.zurueckTitel = zurueckTitel
        self.zurueck = zurueck; self.regeln = regeln; self.extras = extras(); self.knoepfe = knoepfe()
    }

    public var body: some View {
        Group {
            if art == .salon { salon } else { tinte }
        }
        .background(Color.seitenGrund.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            // 2.37 (A-002/A-004/A-008): Die feste Leiste nimmt ihren Platz unten weg (safeAreaInset). Bei Schriftgrößen der
            // Bedienungshilfen ist sie aber bis zu 180 pt hoch; dann verdeckte sie beim Öffnen Würfelwahl, Tageskalender und
            // Hausregeln, obwohl der Inhalt darunter scrollen konnte. Dort gibt es deshalb keine feste Leiste: die Knöpfe
            // stehen als letzter Block im Inhalt (`knopfBlock`), nichts liegt mehr unter ihnen.
            if !schrift.isAccessibilitySize {
                VStack(spacing: art == .salon ? 0 : Design.Abstand.s) { knoepfe }
                    .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8).padding(.top, 8)
                    .frame(maxWidth: Theme.wideColumnWidth)
                    .frame(maxWidth: .infinity)
                    .background(Color.seitenGrund)
            }
        }
    }

    /// 2.37: Die Knöpfe im Fluss der Seite (nur bei Schriftgrößen der Bedienungshilfen), unter allen Karten.
    @ViewBuilder private var knopfBlock: some View {
        if schrift.isAccessibilitySize {
            VStack(spacing: art == .salon ? 0 : Design.Abstand.s) { knoepfe }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        }
    }

    /// Statistik als Zeilen: Label links, Zahl in Serifenschrift rechts (Salon: große Zahlen).
    private var statistik: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: statistikTitel).padding(.bottom, art == .salon ? 6 : 0)
            ForEach(werte) { w in DesignWertZeile(label: Text(w.name), wert: Text(verbatim: w.zahl)) }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Tinte

    /// Kopfzeile „‹ Sammlung“ und „Regeln“ als Wörter, Titel in der Titel-Rolle, Untertitel kursiv, Zeile mit Tintenpunkt
    /// und Spielart, Statistik als Zeilen, darunter die Formularzeilen (Tisch-Modus, Würfelwahl).
    private var tinte: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    wort(Text(verbatim: "‹ ") + zurueckTitel, beschriftung: zurueckTitel, aktion: zurueck)
                    Spacer(minLength: 8)
                    wort(Text("Regeln", bundle: .module), beschriftung: Text("Regeln", bundle: .module), aktion: regeln)
                }
                .frame(minHeight: Theme.tapSize)
                StartTitel(titel: name, untertitel: untertitel).einzeilig(nameEinzeilig).padding(.top, 6)
                if spielart != nil || miniatur != nil {
                    HStack(spacing: Design.Abstand.m) {
                        if let farbe { Circle().fill(farbe).frame(width: 10, height: 10).accessibilityHidden(true) }
                        spielart?.font(Design.Schrift.name).foregroundStyle(Color.schrift)
                        Spacer(minLength: 8)
                        if let miniatur { MiniaturAnsicht(miniatur, farbe: farbe ?? Color.schrift, groesse: 1.1, strich: true) }
                    }
                    .frame(minHeight: 64)
                    .linieUnten(stark: true)
                    .padding(.top, 14)
                }
                statistik.padding(.top, 16)
                VStack(alignment: .leading, spacing: 0) { extras }.padding(.top, 8)
                knopfBlock
            }
            .padding(.horizontal, Theme.seitenRand).padding(.bottom, 24)
            .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
        }
    }

    private func wort(_ text: Text, beschriftung: Text, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            text.font(.body.weight(.semibold)).foregroundStyle(Color.schrift).unterstrichen(1)
                .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityLabel(beschriftung)
    }

    // MARK: Salon

    /// Fläche und Schrift des Farbblocks: die Spielart-Farbe (für die kleinen Labels so weit nötig abgedunkelt), sonst die Hülle.
    private var block: (flaeche: Color, schrift: Color) {
        if let f = Design.spielFarben { return (f.flaecheFuerKleineSchrift, f.aufFlaeche) }
        return (Color.hinweisFlaecheHuelle, Design.werte.aufHuelleFlaeche.color)
    }

    /// Obere Seitenhälfte als Farbblock in der Spielart-Farbe: Labels „← SAMMLUNG“ und „REGELN“, Spielart, der Spielname als
    /// Schlagzeile (bis zwei Zeilen, schrumpft), Untertitel kursiv; die Miniatur groß und angeschnitten an der rechten unteren
    /// Kante. Darunter auf Creme die Statistik als Linien-Zeilen mit großen Zahlen.
    private var salon: some View {
        let b = block
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        label(Text(verbatim: "← ") + zurueckTitel, beschriftung: zurueckTitel, aktion: zurueck)
                        Spacer(minLength: 8)
                        label(Text("Regeln", bundle: .module), beschriftung: Text("Regeln", bundle: .module), aktion: regeln)
                    }
                    .frame(minHeight: Theme.tapSize)
                    spielart?.designLabel(b.schrift).opacity(0.85).padding(.top, 14)
                    StartTitel(titel: name, untertitel: untertitel).einzeilig(nameEinzeilig)
                        .environment(\.startTitelFarbe, b.schrift)
                        .padding(.top, 6)
                        .padding(.trailing, miniatur == nil ? 0 : 36)
                }
                .foregroundStyle(b.schrift)
                .padding(.horizontal, Theme.seitenRand).padding(.top, 8).padding(.bottom, 56)
                .frame(maxWidth: Theme.wideColumnWidth)
                .frame(minHeight: 300, alignment: .top)
                .overlay(alignment: .bottomTrailing) {
                    // an der Kante der Spalte (nicht des Bildschirms): auf dem iPhone ist die Spalte so breit wie der Bildschirm
                    if let miniatur {
                        MiniaturAnsicht(miniatur, farbe: farbe ?? b.flaeche, groesse: 2.6)
                            .rotationEffect(.degrees(-6))
                            .offset(x: 34, y: 34)   // angeschnitten am rechten Rand der Spalte, überlappt die Unterkante des Blocks
                    }
                }
                .frame(maxWidth: .infinity)
                .background(b.flaeche)
                .zIndex(1)
                VStack(alignment: .leading, spacing: 0) {
                    statistik.padding(.top, 48)
                    VStack(alignment: .leading, spacing: 0) { extras }.padding(.top, 8)
                    knopfBlock
                }
                .padding(.horizontal, Theme.seitenRand).padding(.bottom, 24)
                .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
            }
        }
        // Die Blockfarbe läuft bis unter die Statusleiste.
        .background(alignment: .top) { b.flaeche.frame(height: 0).ignoresSafeArea(edges: .top) }
    }

    private func label(_ text: Text, beschriftung: Text, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            text.font(Design.Schrift.text(13, gewicht: .bold, relativ: .footnote, hoechstens: 1.25)).tracking(1.6).textCase(.uppercase)
                .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityLabel(beschriftung)
    }
}

#endif
