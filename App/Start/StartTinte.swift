// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Startseite im Design „Tinte“. Design-Runde 3 (Leitbild „Spieltisch“): oben Datum, Suche, Zahnrad (Einstellungen) und der eigene
/// Spieler; Titel; eine Filzkarte (Weiterspielen, bei mehreren offenen Partien als Stapel zum Wischen, oder „Was spielen wir heute?“); „Deine Spiele“ als Kacheln mit Material;
/// Spielarten zum Aufklappen; „Außerdem“ als gefasste Gruppe. Unten fest der Hauptknopf „Neue Partie“.
/// Daten und Aktionen kommen aus `StartModell` (eine Logik für alle Designs); alle bisherigen Ziele bleiben erreichbar.
struct StartTinte: View {
    let m: StartModell
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(StatistikDienst.self) private var statistik
    @Environment(Favoriten.self) private var favoriten
    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar
    @Environment(\.dynamicTypeSize) private var schriftGroesse

    private var bearbeiten: Bool { m.bearbeiten.wrappedValue }
    /// Aufgeklappte Spielarten, mehrere gleichzeitig (SA-1).
    @State private var offen: Set<Gattung> = []
    /// Zählt Tipps auf das Zahnrad (dreht es weiter).
    @State private var zahnrad = 0
    @Environment(\.accessibilityReduceMotion) private var wenigerBewegung

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
            ScrollView {
                inhalt(quer: geo.size.width >= 900)
                .padding(.horizontal, rand)
                .padding(.top, 8)
                .padding(.bottom, Design.Abstand.l)
                // iPad (Blatt 6): keine schmale Spalte, die Seite nutzt die Breite; iPhone und schmale Fenster wie bisher.
                .frame(maxWidth: breit == .regular ? .infinity : Theme.wideColumnWidth).frame(maxWidth: .infinity)
            }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                StartFuss(titel: "Neue Partie", schmal: breit == .regular) { m.zeigen(.sammlung()) }
            }
            .background(Color.seitenGrund.ignoresSafeArea())
        }
    }

    // MARK: Inhalt (einspaltig wie bisher; iPad breit: zwei Spalten)

    @Environment(\.horizontalSizeClass) private var breit
    /// Seitenrand der Startseite: iPad (breite Größenklasse) 40 pt, sonst der übliche Rand. Die Wischreihen laufen bis an den Bildschirmrand.
    private var rand: CGFloat { breit == .regular ? 40 : Theme.seitenRand }

    /// iPhone und schmale Fenster: eine Spalte, wie bisher. Breite Größenklasse und mindestens 900 pt Platz: links Kopf, Titel, Zuletzt, Heute und
    /// Deine Spiele, rechts Kapitel und Außerdem.
    @ViewBuilder private func inhalt(quer: Bool) -> some View {
        if breit == .regular {
            if quer {
                // Quer (ab 900 pt): zwei Spalten; die Favoriten haben darunter eine eigene Zeile über die ganze Breite,
                // damit keine Wischreihe an der Spaltengrenze endet.
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 48) {
                        VStack(alignment: .leading, spacing: 0) { links(zweispaltig: true) }.frame(maxWidth: .infinity, alignment: .topLeading)
                        VStack(alignment: .leading, spacing: 0) { rechts }.frame(maxWidth: 420, alignment: .topLeading).padding(.top, 8)
                    }
                    favoritenReihe
                }
            } else {
                einspaltig
            }
        } else {
            einspaltig
        }
    }

    private var einspaltig: some View { VStack(alignment: .leading, spacing: 0) { links(zweispaltig: false); favoritenReihe; rechts } }

    @ViewBuilder private func links(zweispaltig: Bool) -> some View {
                    kopf
                    titel
                    if stapel.count > 1 {
                        offenStapel(randSichtbar: !zweispaltig)
                            .padding(.top, Design.Abstand.l)
                    } else if let erstes = m.weiterspielen.first {
                        filzKarte(label: erstes.id == tagesId ? Text("Weiterspielen · Tagesaufgabe") : Text("Weiterspielen"), name: Text(verbatim: erstes.name), farbe: erstes.gattung.farbe.color,
                                  miniatur: SpielMiniaturen.art(erstes), symbol: "play.fill") { m.fortsetzen(erstes.id) }
                            .padding(.top, Design.Abstand.l)
                    } else {
                        filzKarte(label: Text("Neue Runde"), name: Text("Was spielen wir heute?"), farbe: nil,
                                  miniatur: nil, symbol: "magnifyingglass") { m.zeigen(.suche) }
                            .padding(.top, Design.Abstand.l)
                            .accessibilityHint(Text("Öffnet die Suche"))
                    }
                    zuletztHeute
    }

    /// „Zuletzt“ und „Heute“: bei breiter Größenklasse nebeneinander (zwei gleich breite Spalten), gibt es nur eins von beiden, über die ganze Breite.
    @ViewBuilder private var zuletztHeute: some View {
        let hatZuletzt = m.weiterspielen.count > 1
        let hatHeute = (tagesId != nil && !tagesOben) || m.turnier != nil
        if breit == .regular, hatZuletzt, hatHeute {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 0) { zuletztAbschnitt }.frame(maxWidth: .infinity, alignment: .topLeading)
                VStack(alignment: .leading, spacing: 0) { heuteAbschnitt }.frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            if hatZuletzt { zuletztAbschnitt }
            if hatHeute { heuteAbschnitt }
        }
    }

    @ViewBuilder private var zuletztAbschnitt: some View {
                abschnitt("Zuletzt")
                ForEach(Array(m.weiterspielen.dropFirst()), id: \.id) { w in
                    // Kein Spiel doppelt: Ist es zugleich die Tagesaufgabe, steht das hier in der Zeile (der Abschnitt „Heute“ entfällt dafür).
                    zeile(punkt: w.gattung.farbe.color, zeichen: w.gattung.zeichen, name: Text(verbatim: w.name),
                          zusatz: w.id == tagesId ? Text("Tagesaufgabe · weiter") : Text("weiter")) { m.fortsetzen(w.id) }
                }
    }

    @ViewBuilder private var heuteAbschnitt: some View {
                abschnitt("Heute")
                if !tagesOben, m.tagesaufgabe, let t = Tagesaufgabe.spiel(am: Date()) {
                    let fertig = Tagesaufgabe.geschafft(am: Date(), statistik)
                    zeile(punkt: t.gattung.farbe.color, zeichen: t.gattung.zeichen, name: Text(verbatim: t.name),
                          zusatz: fertig ? Text("Tagesaufgabe · geschafft") : Text("Tagesaufgabe")) { m.oeffnen(t.id) }
                }
                if let t = m.turnier {
                    zeile(punkt: Color.schrift, zeichen: "trophy", name: t.art == .duell ? Text("Duell") : Text("Spieleabend"),
                          zusatz: t.fertig ? Text("Ergebnis ansehen") : Text("Runde \(t.gespielteRunden + 1) von \(t.runden.count)")) { m.zeigen(.turnier) }
                }
    }

    /// „Favoriten“ als eigener Block (bei zwei Spalten über die ganze Breite unter den Spalten).
    @ViewBuilder private var favoritenReihe: some View {
            abschnitt("Favoriten", wort: bearbeiten ? "Fertig" : "Ändern") { withAnimation { m.bearbeiten.wrappedValue.toggle() } }
            if m.kacheln.isEmpty && !bearbeiten {
                leereFavoriten
            }
            if bearbeiten {
                ForEach(m.kacheln, id: \.id) { k in spielZeile(k) }
            } else if !m.kacheln.isEmpty {
                kachelReihe
            }
            if bearbeiten {
                zeile(punkt: nil, zeichen: nil, name: Text("Spiel hinzufügen"), zusatz: Text(verbatim: "+")) { m.zeigen(.hinzufuegen) }
            }
    }

    @ViewBuilder private var rechts: some View {
                    abschnitt("Spielarten")
                    ForEach(m.spielarten, id: \.self) { g in spielart(g) }
                    zeile(punkt: Color.schrift, zeichen: "square.grid.2x2", name: Text("Alle Spiele"),
                          zusatz: Text(verbatim: "\(SpielKatalog.sichtbar.count)")) { m.zeigen(.sammlung()) }
                    abschnitt("Außerdem")
                    ausserdem
    }

    /// Leere Favoriten: kurze Erklärung und ein Knopf zur Auswahl, dazu drei Vorschläge zum Antippen (Design-Runde 3, R10).
    private var leereFavoriten: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Text("Noch keine Favoriten. Wähle die Spiele, die du oft spielst; sie liegen dann hier ganz vorn.")
                .font(.subheadline).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
            UmbruchZeile(abstand: 8, zeilenAbstand: 8) {
                ForEach(Array(SpielKatalog.sichtbar.prefix(3)), id: \.id) { spiel in
                    chip(Text(verbatim: spiel.name), betont: false) { m.oeffnen(spiel.id) }
                }
                chip(Text("Favoriten wählen"), betont: true) { m.zeigen(.hinzufuegen) }
            }
        }
        .padding(.vertical, Design.Abstand.m)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// „Außerdem“ als gefasste Gruppe (Karte mit runden Ecken), damit der Bereich unten klar abgegrenzt ist.
    private var ausserdem: some View {
        VStack(alignment: .leading, spacing: 0) { ausserdemZeilen }
            .padding(.horizontal, Design.Abstand.l).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.kartenGrund))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.linie, lineWidth: 1))
            .padding(.top, Design.Abstand.m)
    }

    @ViewBuilder private var ausserdemZeilen: some View {
                    let s = statistik.summe(ich: spieler.ich?.id)
                    zeile(punkt: nil, zeichen: nil, name: Text("Spieler"), zusatz: Text(verbatim: "\(spieler.menschen.count)")) { m.zeigen(.spieler) }
                    zeile(punkt: nil, zeichen: nil, name: Text("Statistik"), zusatz: Text("\(s.partien) Partien · \(s.siege) Siege")) { m.zeigen(.statistik) }
                    if m.turnier == nil {
                        zeile(punkt: nil, zeichen: nil, name: Text("Spieleabend"), zusatz: Text("mehrere Spiele, eine Wertung")) { m.zeigen(.turnier) }
                    }
                    zeile(punkt: nil, zeichen: nil, name: Text("Zufälliges Spiel"), zusatz: nil) { m.zeigen(.zufall) }
                    zeile(punkt: nil, zeichen: nil, name: Text("Glossar"), zusatz: nil, linie: false) { m.zeigen(.glossar) }
    }

    // MARK: Kopf

    /// Datum kursiv links; rechts Suche, Zahnrad (Einstellungen) und der eigene Spieler als runde Knöpfe.
    private var kopf: some View {
        HStack(alignment: .center, spacing: Design.Abstand.s) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(Design.Schrift.serif(18, relativ: .body, kursiv: true)).foregroundStyle(Color.schriftZweit)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            kopfKnopf(symbol: "magnifyingglass", beschriftung: "Spiel suchen", betont: false) { m.zeigen(.suche) }
            kopfKnopf(symbol: "gearshape.fill", beschriftung: "Einstellungen", betont: true, drehung: Double(zahnrad) * 60) {
                if wenigerBewegung { zahnrad += 1 } else { withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { zahnrad += 1 } }
                m.zeigen(.einstellungen)
            }
            if let ich = spieler.ich {
                Button { m.zeigen(.spieler) } label: {
                    SpielerBildKreis(ich, groesse: 40).frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize).contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Spieler"))
            }
        }
        .frame(minHeight: Theme.tapSize)
        .onAppear {
            // Das Zahnrad dreht sich beim Erscheinen einmal ein Stück: Es soll nach einem Knopf aussehen, nicht nach einem Bild.
            guard zahnrad == 0, !wenigerBewegung else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.5).delay(0.35)) { zahnrad = 1 }
        }
    }

    /// Runder Knopf im Kopf. `betont`: gefüllt in Filz-Violett mit hellem Zeichen (Zahnrad), sonst Kartengrund mit Linie.
    private func kopfKnopf(symbol: String, beschriftung: LocalizedStringKey, betont: Bool, drehung: Double = 0, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
                .foregroundStyle(betont ? Tisch.elfenbein : Color.schrift)
                .rotationEffect(.degrees(drehung))
                .frame(width: 40, height: 40)
                .background {
                    if betont {
                        Circle().fill(LinearGradient(colors: [Tisch.violett, Tisch.violett.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                            .shadow(color: Tisch.violett.opacity(0.45), radius: 6, x: 0, y: 3)
                    } else {
                        Circle().fill(Color.kartenGrund).overlay(Circle().strokeBorder(Color.linie, lineWidth: 1))
                    }
                }
                .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(beschriftung))
    }

    /// Id des Spiels der heutigen Tagesaufgabe (nil, wenn die Tagesaufgabe nicht gezeigt wird).
    private var tagesId: String? { m.tagesaufgabe ? Tagesaufgabe.spiel(am: Date())?.id : nil }
    /// Die Tagesaufgabe steht schon oben (Filzkarte „Weiterspielen“ oder „Zuletzt“): dann kein zweiter Eintrag unter „Heute“.
    private var tagesOben: Bool { tagesId.map { id in m.weiterspielen.contains { $0.id == id } || stapel.contains { $0.id == id } } ?? false }

    private var titel: some View {
        // Ohne angelegte Spieler steht keine „0 Spieler“ in der Grußzeile.
        StartTitel("Partie", gruss: spieler.menschen.isEmpty
                   ? String(localized: "\(Gruss.text()). \(SpielKatalog.sichtbar.count) Spiele.")
                   : String(localized: "\(Gruss.text()). \(SpielKatalog.sichtbar.count) Spiele, \(spieler.menschen.count) Spieler."))
            .padding(.top, 6)
    }

    // MARK: Filzkarte, Kacheln, Spielarten (Design-Runde 3)

    // MARK: Stapel der offenen Partien (Wunsch Philipp, 13.11.)

    /// Offene Partien für den Stapel: bis zu sechs aus dem Modell, sonst die drei von „Weiterspielen“.
    private var stapel: [any SpielModul] { m.offen.isEmpty ? m.weiterspielen : m.offen }
    /// Vorn liegende Kachel des Stapels (Spiel-ID). Springt zurück auf die erste, wenn sich die Reihenfolge ändert (nach einer Partie).
    @State private var stapelStelle: String?

    /// Die Kachel „Weiterspielen“ als Stapel aller offenen Partien zum Wischen nach rechts und links. Jede Kachel ist so groß wie die
    /// eine Kachel bisher; am Seitenrand schaut die nächste hervor, Punkte oben in der Kachel zeigen die Stelle. Je Spiel gibt es
    /// eine offene Partie, die zuletzt gespielte liegt vorn. Mit nur einer offenen Partie bleibt es bei der einen Kachel wie bisher.
    /// Die Liste „Zuletzt“ darunter bleibt (Philipp: „erstmal mit Zuletzt bleibt“).
    private func offenStapel(randSichtbar: Bool) -> some View {
        let partien = stapel
        return ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 13) {
                ForEach(Array(partien.enumerated()), id: \.element.id) { i, w in
                    filzKarte(label: w.id == tagesId ? Text("Weiterspielen · Tagesaufgabe") : Text("Weiterspielen"), name: Text(verbatim: w.name),
                              farbe: w.gattung.farbe.color, miniatur: SpielMiniaturen.art(w), symbol: "play.fill",
                              stelle: i, von: partien.count) { m.fortsetzen(w.id) }
                        .containerRelativeFrame(.horizontal)
                        .accessibilityValue(Text("\(i + 1) von \(partien.count)"))
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $stapelStelle)
        .scrollIndicators(.hidden)
        // Die Nachbarkachel schaut im Seitenrand hervor und wird erst vom Bildschirmrand angeschnitten (iPhone, iPad hoch).
        // Nur im zweispaltigen Aufbau (iPad quer) bleibt sie in ihrer Spalte, sonst läge sie über der rechten Spalte.
        .scrollClipDisabled(randSichtbar)
        .onChange(of: partien.map { $0.id }) { _, neu in stapelStelle = neu.first }
    }

    /// Punkte des Stapels oben links in der Kachel: je offene Partie einer, die eigene Stelle voll und breiter.
    private func stapelPunkte(_ stelle: Int, von anzahl: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<anzahl, id: \.self) { i in
                Capsule().fill(Tisch.elfenbein.opacity(i == stelle ? 1 : 0.42)).frame(width: i == stelle ? 15 : 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    /// Große Karte auf Filz: kleines Label, Name in Serifenschrift, rechts ein heller runder Knopf; dahinter die Miniatur des Spiels.
    /// `stelle` und `von`: Platz der Kachel im Stapel der offenen Partien (Punkte oben links), nur bei mehr als einer.
    private func filzKarte(label: Text, name: Text, farbe: Color?, miniatur: Miniatur?, symbol: String, stelle: Int = 0, von: Int = 1, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            ZStack(alignment: .bottomLeading) {
                TischGrund(farbe)
                if let miniatur, let farbe {
                    MiniaturAnsicht(miniatur, farbe: farbe, groesse: 1.0)   // T-069: kleiner und oben rechts über dem Knopf, damit das Etikett („Weiterspielen · Tagesaufgabe“) nicht darunter läuft
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(.trailing, Design.Abstand.l).padding(.top, 14).opacity(0.9)
                        .accessibilityHidden(true)
                }
                HStack(alignment: .bottom, spacing: Design.Abstand.m) {
                    VStack(alignment: .leading, spacing: 4) {
                        label.font(.caption.weight(.semibold)).kerning(1.4).foregroundStyle(Tisch.elfenbein.opacity(0.8)).textCase(.uppercase)
                            // Große Schrift (Punkt 3): Etikett bleibt einzeilig und wächst nicht über „xxxLarge“; kein Wort wird getrennt.
                            .lineLimit(1).minimumScaleFactor(0.5).allowsTightening(true)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        name.font(Design.Schrift.serif(26, gewicht: .bold, relativ: .title)).foregroundStyle(Tisch.elfenbein)
                            .lineLimit(2).minimumScaleFactor(0.7).multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: symbol).font(.body.weight(.bold)).foregroundStyle(Tisch.auge)
                        .frame(width: 48, height: 48).background(Circle().fill(Tisch.elfenbein))
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                        .accessibilityHidden(true)
                }
                .padding(Design.Abstand.l)
            }
            .frame(minHeight: 148)
            .overlay(alignment: .topLeading) { if von > 1 { stapelPunkte(stelle, von: von).padding(17) } }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// „Deine Spiele“ als Kacheln in einer Reihe zum Wischen: oben Filz in der Spielart-Farbe mit Miniatur, darunter Name und Spielerzahl.
    private var kachelReihe: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Design.Abstand.m) {
                ForEach(m.kacheln, id: \.id) { k in kachel(k) }
            }
            .padding(.horizontal, rand).padding(.vertical, Design.Abstand.m)
        }
        .padding(.horizontal, -rand)   // die Reihe läuft bis an den Bildschirmrand
    }

    private func kachel(_ k: any SpielModul) -> some View {
        Button { m.oeffnen(k.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    TischGrund(k.gattung.farbe.color)
                    MiniaturAnsicht(SpielMiniaturen.art(k), farbe: k.gattung.farbe.color, groesse: 1.25).accessibilityHidden(true)
                }
                .frame(width: 136, height: 92)
                VStack(alignment: .leading, spacing: 2) {
                    KachelName(name: k.name)
                    Text(verbatim: SpielZeilen.spielerText(k)).font(.caption).foregroundStyle(Color.schriftZweit).lineLimit(1).minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(width: 136, alignment: .leading)
            }
            .background(Color.kartenGrund)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.linie, lineWidth: 1))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button("Von der Startseite entfernen", systemImage: "minus.circle", role: .destructive) { withAnimation { m.layout.entfernen(k.id) } }
        }
    }

    /// Eine Spielart zum Aufklappen: Zeile mit Farbpunkt, Name und Anzahl; aufgeklappt die Spiele als Zeilen untereinander.
    @ViewBuilder private func spielart(_ g: Gattung) -> some View {
        let auf = offen.contains(g)
        Button {
            func umschalten() { if auf { offen.remove(g) } else { offen.insert(g) } }
            if wenigerBewegung { umschalten() } else { withAnimation(.snappy(duration: 0.22)) { umschalten() } }
        } label: {
            HStack(spacing: Design.Abstand.m) {
                if farbenUnterscheidbar {
                    Image(systemName: g.zeichen).font(.caption.weight(.bold)).foregroundStyle(Color.schrift).frame(width: 18)
                } else {
                    Circle().fill(g.farbe.color).frame(width: 10, height: 10)
                }
                Text(g.name).font(Design.Schrift.name).foregroundStyle(Color.schrift).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                Text(verbatim: "\(m.anzahl(g))").font(.footnote.monospacedDigit()).foregroundStyle(Color.schriftZweit)
                Image(systemName: "chevron.down").font(.footnote.weight(.semibold)).foregroundStyle(Color.schriftZweit)
                    .rotationEffect(.degrees(auf ? 180 : 0)).accessibilityHidden(true)
            }
            .frame(minHeight: 50)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(auf ? Text("aufgeklappt") : Text("zugeklappt"))
        if auf {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(SpielKatalog.sichtbar.filter { $0.gattung == g }, id: \.id) { spiel in
                    Button { m.oeffnen(spiel.id) } label: {
                        Text(verbatim: spiel.name)
                            .font(Design.Schrift.serif(18, gewicht: .medium, relativ: .body))
                            .foregroundStyle(Color.schrift)
                            .lineLimit(schriftGroesse.isAccessibilitySize ? 2 : 1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, (farbenUnterscheidbar ? 18 : 10) + Design.Abstand.m + 14)
            .padding(.bottom, Design.Abstand.s)
        }
        ZeilenLinie()
    }

    private func chip(_ text: Text, betont: Bool, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            text.font(.subheadline.weight(betont ? .semibold : .regular)).foregroundStyle(betont ? Color.seitenGrund : Color.schrift)
                .lineLimit(1)
                .padding(.horizontal, 14).frame(minHeight: 40)
                .background(Capsule().fill(betont ? Color.schrift : Color.kartenGrund))
                .overlay(Capsule().strokeBorder(betont ? Color.clear : Color.linie, lineWidth: 1))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: Abschnitte und Zeilen

    /// Abschnitts-Label mit Tinte-Linie darunter; optional rechts ein unterstrichenes Wort (z. B. „anpassen“).
    private func abschnitt(_ titel: LocalizedStringKey, wort: LocalizedStringKey? = nil, aktion: (() -> Void)? = nil) -> some View {
        HStack(alignment: .lastTextBaseline) {
            Text(titel).designLabel().accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let wort, let aktion {
                Button(action: aktion) {
                    Text(wort).font(.footnote.weight(.semibold)).foregroundStyle(Color.schrift).unterstrichen(1)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // Punkt 3: „Ändern“ nicht größer als die Spielnamen
                        .frame(minHeight: Theme.tapSize, alignment: .bottom).contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, wort == nil ? 22 : 0).padding(.bottom, 6)
        .linieUnten(stark: true)
    }

    /// Eine Zeile des Verzeichnisses: Tintenpunkt in der Spielart-Farbe, Name in Serifenschrift, Zusatz rechts.
    private func zeile(punkt: Color?, zeichen: String?, name: Text, zusatz: Text?, linie: Bool = true, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: Design.Abstand.m) {
                if let punkt {
                    if farbenUnterscheidbar, let zeichen {
                        Image(systemName: zeichen).font(.caption.weight(.bold)).foregroundStyle(Color.schrift).frame(width: 18)
                    } else {
                        Circle().fill(punkt).frame(width: 10, height: 10)
                    }
                }
                name.font(Design.Schrift.name).foregroundStyle(Color.schrift).lineLimit(schriftGroesse.isAccessibilitySize ? 2 : 1).minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                // N-013: bei großer Schrift zwei Zeilen statt „Würfel · 1–4 Spie…“
                zusatz?.font(.footnote.monospacedDigit()).foregroundStyle(Color.schriftZweit).multilineTextAlignment(.trailing).lineLimit(schriftGroesse.isAccessibilitySize ? 3 : 1).minimumScaleFactor(0.7)
                    // Punkt 3: „weiter“ und Zusätze werden nie größer als die Spielnamen.
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .frame(minHeight: 50)
            .overlay(alignment: .bottom) { if linie { ZeilenLinie() } }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// Zeile eines Spiels aus „Deine Spiele“; beim Anpassen mit Griff und Knöpfen zum Verschieben und Entfernen.
    private func spielZeile(_ k: any SpielModul) -> some View {
        HStack(spacing: 0) {
            if bearbeiten {
                Image(systemName: "line.3.horizontal").font(.body).foregroundStyle(Color.schriftBlass)
                    .frame(width: 32, height: Theme.tapSize).accessibilityHidden(true)
            }
            zeile(punkt: k.gattung.farbe.color, zeichen: k.gattung.zeichen, name: Text(verbatim: k.name),
                  zusatz: bearbeiten ? nil : Text(verbatim: "\(k.gattung.anzeigeName) · \(SpielZeilen.spielerText(k))"), linie: false) {
                if !bearbeiten { m.oeffnen(k.id) }
            }
            if bearbeiten { StartAnpassenKnoepfe(id: k.id, layout: m.layout) }
        }
        .linieUnten()
        .draggable(k.id)
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            withAnimation { m.layout.verschieben(id, vor: k.id) }; return true
        }
        .contextMenu {
            Button("Von der Startseite entfernen", systemImage: "minus.circle", role: .destructive) { withAnimation { m.layout.entfernen(k.id) } }
        }
    }
}


/// Name auf einer Spielkachel: reserviert immer die Höhe einer Zeile in voller Schrift. Wird ein langer Name verkleinert
/// („Viererreihe“, „Minensuche“), bleibt die Kachel trotzdem gleich hoch wie die anderen.
struct KachelName: View {
    let name: String
    /// Fund 1: Mit Wert zeigt jeder Name dieselbe Schriftgröße (verkleinert um diesen Faktor, ohne je Name zu schrumpfen).
    var festeSkala: CGFloat? = nil
    var body: some View {
        if let f = festeSkala {
            Text(verbatim: "Wg").font(Design.Schrift.name).lineLimit(1).hidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    Text(verbatim: name).font(Design.Schrift.name).foregroundStyle(Color.schrift).lineLimit(1).fixedSize()
                        .scaleEffect(f, anchor: .leading)
                }
                .accessibilityRepresentation { Text(verbatim: name) }
        } else { standard }
    }
    private var standard: some View {
        Text(verbatim: "Wg").font(Design.Schrift.name).lineLimit(1).hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                Text(verbatim: name).font(Design.Schrift.name).foregroundStyle(Color.schrift).lineLimit(1).minimumScaleFactor(0.7)
            }
            .accessibilityRepresentation { Text(verbatim: name) }
    }
}
