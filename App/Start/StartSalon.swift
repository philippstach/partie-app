// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Startseite im Design „Salon“: eine Magazinseite (Entwürfe S4 hell, DD dunkel). Obere Hälfte ein Farbblock in Terrakotta
/// mit Gruß als Schlagzeile und der Frage „Wer ist dabei?“; an der unteren Kante des Blocks, halb überlappend, die Porträts
/// der zuletzt gespielten Personen. Antippen wählt eine Person an oder ab: die Runde. Darunter auf Creme nummerierte
/// Vorschläge für diese Runde, die Spielarten als farbige Kapitälchen und unten fest der Rechteck-Knopf „Neue Partie →“.
struct StartSalon: View {
    let m: StartModell
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(StatistikDienst.self) private var statistik
    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar
    @Environment(\.dynamicTypeSize) private var schriftGroesse
    @Environment(\.horizontalSizeClass) private var breit
    @State private var runde = AktuelleRunde.laden()

    private var bearbeiten: Bool { m.bearbeiten.wrappedValue }
    /// Höchstens fünf Porträts, dann „+“.
    private var personen: [Spieler] { Array(spieler.zuletztGespielt.prefix(5)) }
    /// Gewählte Personen in der Reihenfolge der Auswahl (nur solche, die es noch gibt).
    private var gewaehlt: [Spieler] { runde.compactMap { id in spieler.menschen.first { $0.id == id } } }

    /// Vorschläge: zuerst offene Partien, dann die eigenen Spiele, die zur Größe der Runde passen. Höchstens sechs.
    private var vorschlaege: [(modul: any SpielModul, weiter: Bool)] {
        let n = gewaehlt.count
        var liste: [(modul: any SpielModul, weiter: Bool)] = m.weiterspielen.map { ($0, true) }
        for k in m.kacheln where !liste.contains(where: { $0.modul.id == k.id }) {
            if bearbeiten || n == 0 || k.spielerzahl.contains(n) { liste.append((k, false)) }
        }
        return bearbeiten ? liste : Array(liste.prefix(6))
    }
    private var passende: Int {
        let n = gewaehlt.count
        return SpielKatalog.sichtbar.filter { n == 0 || $0.spielerzahl.contains(n) }.count
    }

    var body: some View {
        GeometryReader { geo in
            // iPad quer (breite Größenklasse, Fenster breiter als hoch): niedrigerer Block, damit die Liste mehr Platz hat. iPhone und iPad hoch bleiben.
            let blockHoehe = breit == .regular && geo.size.width > geo.size.height ? min(geo.size.height * 0.30, 250) : min(geo.size.height * 0.44, 380)
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        block(hoehe: blockHoehe, oben: geo.safeAreaInsets.top)
                        unten
                            .padding(.horizontal, Theme.seitenRand)
                            .padding(.top, 52)
                            .padding(.bottom, Design.Abstand.l)
                            .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    StartFuss(titel: "Neue Partie") { m.zeigen(.sammlung(spielerzahl: gewaehlt.count)) }
                }
                .ignoresSafeArea(edges: .top)
                .background(Color.seitenGrund.ignoresSafeArea())
            }
        }
        .onChange(of: spieler.alle) { _, _ in runde = AktuelleRunde.bereinigt(runde, vorhanden: spieler.menschen.map(\.id)); AktuelleRunde.speichern(runde) }
    }

    // MARK: Farbblock

    /// Fläche des Blocks: Terrakotta, für das kleine Label so weit nötig abgedunkelt (Kontrastregel, Wert aus der Design-Ebene).
    private var blockFarbe: Color { Color.hinweisFlaecheHuelle }

    private func block(hoehe: CGFloat, oben: CGFloat) -> some View {
        let schrift = Design.werte.aufHuelleFlaeche.color
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(verbatim: "Partie · \(Date.now.formatted(.dateTime.weekday(.wide)))")
                    .designLabel(schrift)
                Spacer(minLength: 8)
                // N-025: Zugang zu den Einstellungen auch im Salon (wie „Ich“ in Tinte); dort lässt sich das Design wieder wechseln
                Button { m.zeigen(.einstellungen) } label: {
                    Text("Ich").font(Design.Schrift.text(14, gewicht: .bold, relativ: .subheadline, hoechstens: 1.25))
                        .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize, alignment: .trailing).contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Einstellungen"))
                Button { m.zeigen(.suche) } label: {
                    Text("Suchen").font(Design.Schrift.text(14, gewicht: .bold, relativ: .subheadline, hoechstens: 1.25))
                        .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize, alignment: .trailing).contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Spiel suchen"))
            }
            .frame(minHeight: Theme.tapSize)
            Spacer(minLength: 8)
            StartTitel(titel: Text(verbatim: Self.schlagzeile(Gruss.text())), untertitel: Text("Wer ist dabei?"))
                .environment(\.startTitelFarbe, schrift)
            Spacer(minLength: 46)   // Platz für die überlappenden Porträts
        }
        .foregroundStyle(schrift)
        .padding(.horizontal, Theme.seitenRand)
        .padding(.top, oben + 8)
        .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
        .frame(height: hoehe + oben)
        .background(blockFarbe)
        .overlay(alignment: .bottomLeading) {
            portraets
                .padding(.horizontal, Theme.seitenRand)
                .frame(maxWidth: Theme.wideColumnWidth, alignment: .leading).frame(maxWidth: .infinity)
                .offset(y: 34)
        }
        .zIndex(1)
    }

    /// „Guten Abend“ wird zur zweizeiligen Schlagzeile „Guten\nAbend.“ (ein einzelnes Wort bleibt einzeilig).
    static func schlagzeile(_ gruss: String) -> String {
        let teile = gruss.split(separator: " ", maxSplits: 1).map(String.init)
        return (teile.count == 2 ? "\(teile[0])\n\(teile[1])" : gruss) + "."
    }

    /// Porträts der zuletzt gespielten Personen (68 pt, Creme-Rand 4 pt, 14 pt überlappt). Antippen wählt an oder ab;
    /// abgewählt: 45 % Deckkraft und Linie statt Creme-Rand. „+“ öffnet die Spielerseite.
    private var portraets: some View {
        HStack(spacing: -14) {
            ForEach(personen) { p in
                let an = runde.contains(p.id)
                Button { umschalten(p.id) } label: {
                    SpielerBildKreis(p, groesse: 68)
                        .overlay { Circle().strokeBorder(an ? Color.seitenGrund : Color.linie, lineWidth: 4) }
                        .opacity(an || runde.isEmpty ? 1 : 0.45)
                        .background(Color.seitenGrund, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: p.name))
                .accessibilityValue(an ? Text("dabei") : Text("nicht dabei"))
                .accessibilityAddTraits(an ? [.isButton, .isSelected] : .isButton)
            }
            Button { m.zeigen(.spieler) } label: {
                Text(verbatim: "+").font(.system(size: 28, weight: .medium, design: .serif)).foregroundStyle(Color.schriftZweit)
                    .frame(width: 68, height: 68)
                    .background(Color.seitenGrund, in: Circle())
                    .overlay { Circle().strokeBorder(Color.linie, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Spieler"))
        }
    }

    private func umschalten(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if let i = runde.firstIndex(of: id) { runde.remove(at: i) } else { runde.append(id) }
        }
        AktuelleRunde.speichern(runde)
    }

    // MARK: Untere Hälfte

    /// Label über den Vorschlägen: „Für euch drei“, eine Person „Für dich“, niemand gewählt „Deine Spiele“.
    private var vorschlagTitel: Text {
        switch gewaehlt.count {
        case 0: Text("Deine Spiele")
        case 1: Text("Für dich")
        case 2: Text("Für euch zwei")
        case 3: Text("Für euch drei")
        case 4: Text("Für euch vier")
        case 5: Text("Für euch fünf")
        default: Text("Für euch alle")
        }
    }

    private var unten: some View {
        VStack(alignment: .leading, spacing: 0) {
            vorschlagTitel.designLabel().accessibilityAddTraits(.isHeader)
            if vorschlaege.isEmpty {
                Text(gewaehlt.isEmpty ? "Noch keine Spiele hier. Tippe auf „Anpassen“ oder öffne „Neue Partie“." : "Für diese Runde liegt noch kein Spiel auf deiner Startseite. „Neue Partie“ zeigt alle passenden.")
                    .font(.subheadline).foregroundStyle(Color.schriftZweit).padding(.vertical, 14)
            }
            ForEach(Array(vorschlaege.enumerated()), id: \.element.modul.id) { i, v in
                spielZeile(nummer: i + 1, v.modul, weiter: v.weiter)
            }
            if bearbeiten {
                zeile(nummer: "+", titel: Text("Spiel hinzufügen"), kursiv: true, zusatz: nil) { m.zeigen(.hinzufuegen) }
            } else {
                zeile(nummer: "··", titel: Text("Alle \(passende) Spiele"), kursiv: true, zusatz: Text(verbatim: "→")) {
                    m.zeigen(.sammlung(spielerzahl: gewaehlt.count))
                }
                zeile(nummer: "··", titel: Text("Was spielen wir?"), kursiv: true, zusatz: Text("drei Fragen")) { m.zeigen(.suche) }
                if m.tagesaufgabe, let t = Tagesaufgabe.spiel(am: Date()) {
                    let fertig = Tagesaufgabe.geschafft(am: Date(), statistik)
                    zeile(nummer: "··", titel: Text(verbatim: t.name), kursiv: false,
                          zusatz: fertig ? Text("Tagesaufgabe\ngeschafft") : Text("Tagesaufgabe\nheute")) { m.oeffnen(t.id) }
                }
                if let t = m.turnier {
                    zeile(nummer: "··", titel: t.art == .duell ? Text("Duell") : Text("Spieleabend"), kursiv: false,
                          zusatz: t.fertig ? Text("Ergebnis\nansehen") : Text("Runde \(t.gespielteRunden + 1)\nvon \(t.runden.count)")) { m.zeigen(.turnier) }
                }
            }
            kapitaelchen.padding(.top, 22)
        }
    }

    /// Nummerierte Zeile: „01 Yacht   weiter · Runde 7“.
    private func zeile(nummer: String, titel: Text, kursiv: Bool, zusatz: Text?, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: Design.Abstand.l) {
                Text(verbatim: nummer).font(Design.Schrift.serif(22, gewicht: .light, relativ: .title3)).monospacedDigit()
                    .foregroundStyle(Color.schriftZweit).frame(width: 36, alignment: .leading)
                titel.font(kursiv ? Design.Schrift.neben : Design.Schrift.name).tracking(kursiv ? 0 : -0.4)
                    .foregroundStyle(Color.schrift).lineLimit(schriftGroesse.isAccessibilitySize ? 2 : 1).minimumScaleFactor(0.6)
                Spacer(minLength: 8)
                zusatz?.font(.caption.weight(.semibold)).foregroundStyle(Color.schriftZweit)
                    .multilineTextAlignment(.trailing).lineLimit(schriftGroesse.isAccessibilitySize ? 3 : 1).minimumScaleFactor(0.7).layoutPriority(-1)   // K-020: eine Zeile statt Umbruch
            }
            .frame(minHeight: 60)
            .linieUnten()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func spielZeile(nummer: Int, _ k: any SpielModul, weiter: Bool) -> some View {
        HStack(spacing: 0) {
            zeile(nummer: String(format: "%02d", nummer), titel: Text(verbatim: k.name), kursiv: false,
                  zusatz: bearbeiten ? nil : (weiter ? Text("weiter") : Text(verbatim: "\(k.gattung.anzeigeName) · \(String(localized: "\(WasSpielenWirBlatt.minuten(k)) Min"))"))) {
                if !bearbeiten { if weiter { m.fortsetzen(k.id) } else { m.oeffnen(k.id) } }
            }
            if bearbeiten, !weiter { StartAnpassenKnoepfe(id: k.id, layout: m.layout).linieUnten() }
        }
        .contextMenu {
            if !weiter {
                Button("Von der Startseite entfernen", systemImage: "minus.circle", role: .destructive) { withAnimation { m.layout.entfernen(k.id) } }
            }
        }
    }

    /// Spielarten als farbige Kapitälchen mit Anzahl („KARTEN 19  WÜRFEL 11 …“), dazu die Wege in die Hülle.
    private var kapitaelchen: some View {
        UmbruchZeile(abstand: 16, zeilenAbstand: 0) {
            ForEach(m.spielarten, id: \.self) { g in
                wort(Text(verbatim: "\(g.anzeigeName) \(m.anzahl(g))"), farbe: g.farbe.textFarbe, zeichen: farbenUnterscheidbar ? g.zeichen : nil) {
                    m.zeigen(.sammlung(filter: .gattung(g), spielerzahl: 0))
                }
            }
            wort(Text("Statistik")) { m.zeigen(.statistik) }
            wort(Text("Ich"), beschriftung: Text("Einstellungen")) { m.zeigen(.einstellungen) }
            wort(bearbeiten ? Text("Fertig") : Text("Anpassen"), unterstrichen: bearbeiten) { withAnimation { m.bearbeiten.wrappedValue.toggle() } }
            wort(Text("Zufall"), beschriftung: Text("Zufälliges Spiel")) { m.zeigen(.zufall) }
            if m.turnier == nil { wort(Text("Spieleabend")) { m.zeigen(.turnier) } }
            wort(Text("Glossar")) { m.zeigen(.glossar) }
        }
    }

    private func wort(_ text: Text, farbe: Color? = nil, zeichen: String? = nil, beschriftung: Text? = nil, unterstrichen: Bool = false,
                      aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: Design.Abstand.xs) {
                if let zeichen { Image(systemName: zeichen).font(.caption2.weight(.bold)) }
                text.font(Design.Schrift.label).tracking(Design.Schrift.labelSperrung).textCase(.uppercase)
            }
            .foregroundStyle(farbe ?? Color.schrift)
            .unterstrichen(2, farbe: unterstrichen ? Color.schrift : Color.clear)
            .frame(minHeight: Theme.tapSize)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityLabel(beschriftung ?? text)
    }
}
