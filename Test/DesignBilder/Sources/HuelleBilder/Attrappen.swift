// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

// Attrappen für die Bildaufnahme (Designwechsel F.1): Die Dateien aus App/Start (per Verweis in diesem Ordner) sind die
// echten Ansichten der App. Was sie aus der Hülle brauchen (Spielkatalog, Startlayout, Favoriten …), steht hier in einer
// kleinen Fassung mit Beispieldaten, damit die Seiten ohne die ganze App gezeichnet werden können.

struct AttrappeModul: SpielModul {
    let id: String
    let name: String
    let gattung: Gattung
    let symbol: String
    let spielerzahl: ClosedRange<Int>
    var farbe: AkzentFarbeWert { gattung.farbe }
    func start(_ umgebung: SpielUmgebung) -> AnyView { AnyView(EmptyView()) }
}

@MainActor
enum SpielKatalog {
    static let spielbar: [any SpielModul] = [
        AttrappeModul(id: "yacht", name: "Yacht", gattung: .wuerfel, symbol: "dice.fill", spielerzahl: 1...4),
        AttrappeModul(id: "sudoku", name: "Sudoku", gattung: .raetsel, symbol: "square.grid.3x3.fill", spielerzahl: 1...1),
        AttrappeModul(id: "schwimmen", name: "Schwimmen", gattung: .karten, symbol: "suit.heart.fill", spielerzahl: 2...6),
        AttrappeModul(id: "rauswurf", name: "Rauswurf", gattung: .brett, symbol: "circle.grid.cross.fill", spielerzahl: 2...4),
        AttrappeModul(id: "solitaer", name: "Solitär", gattung: .karten, symbol: "suit.spade.fill", spielerzahl: 1...1),
        AttrappeModul(id: "wortpfeil", name: "Wortpfeil", gattung: .wort, symbol: "textformat.abc", spielerzahl: 1...1),
        AttrappeModul(id: "wolkenhuepfer", name: "Wolkenhüpfer", gattung: .arcade, symbol: "cloud.fill", spielerzahl: 1...1),
        AttrappeModul(id: "viererreihe", name: "Viererreihe", gattung: .brett, symbol: "circle.grid.3x3.fill", spielerzahl: 2...2),
    ]
    static var sichtbar: [any SpielModul] { spielbar }
    static var alleModule: [any SpielModul] { spielbar }
    static func modul(_ id: String?) -> (any SpielModul)? { spielbar.first { $0.id == id } }
    /// Wie in der App (`App/PartieApp.swift`): frühere Kennung → Speicherkennung, damit `SpielMetadaten.info` die Zeile findet.
    nonisolated static let frueher: [String: String] = [
        "yacht": "yacht-neu", "schocken": "schocken-neu", "rauswurf": "rauswurf-neu", "sudoku": "sudoku-neu",
        "viererreihe": "viererreihe-neu", "galgenmaennchen": "galgenmaennchen-neu", "solitaer": "solitaer-neu",
        "10k": "10k-neu", "fuchsjagd": "fuchsjagd-neu", "elferraus": "elferraus-neu", "maumau": "maumau-neu",
        "schwimmen": "schwimmen-neu",
    ]
    nonisolated static func kennung(_ id: String) -> String { frueher[id] ?? id }
}

@Observable @MainActor
final class StartLayout {
    var ids: [String] = ["yacht", "schwimmen", "rauswurf", "sudoku", "solitaer"]
    func entfernen(_ id: String) { ids.removeAll { $0 == id } }
    func verschiebe(_ id: String, um schritte: Int) {}
    func verschieben(_ id: String, vor ziel: String) {}
}

@Observable @MainActor
final class Favoriten {
    var ids: [String] = ["yacht", "sudoku"]
    func enthaelt(_ id: String) -> Bool { ids.contains(id) }
}

@MainActor
enum Tagesaufgabe {
    static func spiel(am tag: Date) -> (any SpielModul)? { SpielKatalog.modul("sudoku") }
    static func geschafft(am tag: Date, _ statistik: StatistikDienst) -> Bool { false }
}

struct SammlungStart {
    enum Filter: Equatable { case alle, favoriten, gattung(Gattung), liste(UUID) }
}

enum Huelle {
    static var flaeche: Color { Design.werte.huelleFlaeche.color }
}

/// Beispieldaten und fertige Szenen für die Tests.
@MainActor
public enum HuelleSzenen {
    public static let verzeichnis: SpielerVerzeichnis = {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        for n in ["Anna", "Clara", "Ben", "Dana"] { v.anlegen(name: n) }
        return v
    }()
    public static let statistik: StatistikDienst = {
        let s = StatistikDienst(ablage: SpeicherAblage())
        for i in 0..<48 { s.melden(PartieErgebnis(spiel: "yacht", teilnehmer: [.init(spielerID: verzeichnis.ich?.id, name: "Anna", platz: i % 2 + 1, punkte: 200 + i)])) }
        let ben = verzeichnis.alle.first { $0.name == "Ben" }
        for (i, spiel) in ["schwimmen", "rauswurf", "sudoku", "yacht", "schwimmen", "viererreihe", "yacht", "rauswurf"].enumerated() {
            s.melden(PartieErgebnis(spiel: spiel, teilnehmer: [.init(spielerID: verzeichnis.ich?.id, name: "Anna", platz: i % 3 == 0 ? 2 : 1, punkte: 90 + i * 7),
                                                              .init(spielerID: ben?.id, name: "Ben", platz: i % 3 == 0 ? 1 : 2, punkte: 80 + i * 5)]))
        }
        return s
    }()

    static func modell(weiter: Bool, bearbeiten: Bool = false) -> StartModell {
        let layout = StartLayout()
        return StartModell(kacheln: layout.ids.compactMap { SpielKatalog.modul($0) },
                           weiterspielen: weiter ? [SpielKatalog.modul("yacht")!] : [], layout: layout, bearbeiten: .constant(bearbeiten),
                           tagesaufgabe: true, turnier: nil, oeffnen: { _ in }, zeigen: { _ in })
    }

    /// Startseite mit mehreren offenen Partien: In Tinte wird die Kachel „Weiterspielen“ zum Stapel zum Wischen, „Zuletzt“ bleibt darunter.
    static func modellStapel(_ ids: [String] = ["schwimmen", "rauswurf", "solitaer", "sudoku"]) -> StartModell {
        let layout = StartLayout()
        let offen = ids.compactMap { SpielKatalog.modul($0) }
        return StartModell(kacheln: layout.ids.compactMap { SpielKatalog.modul($0) },
                           weiterspielen: Array(offen.prefix(3)), layout: layout, bearbeiten: .constant(false),
                           tagesaufgabe: true, turnier: nil, oeffnen: { _ in }, zeigen: { _ in }, offen: offen)
    }

    private static func umgebung<V: View>(_ v: V) -> some View {
        v.environment(verzeichnis).environment(statistik).environment(Favoriten())
    }

    /// Die Runde für den Salon-Start: die ersten drei Personen sind gewählt.
    public static func rundeWaehlen() {
        AktuelleRunde.speichern(Array(verzeichnis.zuletztGespielt.prefix(3).map(\.id)))
    }

    /// Die Zeilen der Einstellungen-Übersicht (Kacheln wie in `EinstellungenSeite.zeile`).
    public static var einstellungsZeilen: some View {
        let zeilen: [(String, Color, String, String)] = [
            ("gamecontroller.fill", .blue, "Spielen", "Töne, Haptik, Würfel, Game Center"),
            ("paintbrush.fill", .indigo, "Start und Aussehen", "Beim Öffnen, Darstellung, Sprache, App-Symbol"),
            ("moon.zzz.fill", .purple, "Familie und Ruhe", "Kinder-Modus, Ruhe-Modus, Mitteilungen"),
            ("externaldrive.fill", .teal, "Daten und Sicherung", "Gespeicherte Daten, iCloud, Sicherung, Statistik"),
            ("questionmark.circle.fill", .gray, "Hilfe und Über", "Einführung, Glossar, Open Source, Version"),
        ]
        return umgebung(VStack(spacing: 0) {
            ForEach(zeilen, id: \.2) { z in
                HStack(spacing: Design.Abstand.m) {
                    EinstellungsKachel(symbol: z.0, farbe: z.1)
                    VStack(alignment: .leading, spacing: 2) { Text(z.2); Text(z.3).font(.footnote).foregroundStyle(.secondary) }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                }
                .padding(.vertical, 12).padding(.horizontal, Theme.seitenRand).background(Color.kartenGrund).linieUnten()
            }
            Spacer(minLength: 0)
        }.background(Color.seitenGrund))
    }
    public static var statistikSeite: some View { umgebung(StatistikSeite()) }
    public static var spielerSeite: some View { umgebung(SpielerSeite()) }
    public static var suche: some View { umgebung(SpielSucheBlatt(waehlen: { _ in })) }
    public static var glossar: some View { umgebung(GlossarBlatt()) }
    public static var startTinte: some View { umgebung(StartTinte(m: modell(weiter: true))) }
    public static var startSalon: some View { umgebung(StartSalon(m: modell(weiter: true))) }
    /// Tinte-Start mit vier offenen Partien (Stapel zum Wischen, „Zuletzt“ mit zwei Zeilen).
    public static var startTinteStapel: some View { umgebung(StartTinte(m: modellStapel())) }
    /// Salon-Start mit denselben Daten: zeigt weiter nur die drei aus `weiterspielen`, der Stapel gilt dort nicht.
    public static var startSalonStapel: some View { umgebung(StartSalon(m: modellStapel())) }
    public static var spielerKopf: some View {
        umgebung(VStack(spacing: Theme.kartenAbstand) { SpielerSeitenKopf(); Spacer() }.padding(Theme.seitenRand))
    }
    public static func einfuehrung(_ nummer: Int) -> some View {
        let seiten: [(String?, LocalizedStringKey, LocalizedStringKey)] = [
            ("square.grid.2x2", "Willkommen bei Partie", "25 Spiele für Familie, Freunde und dich allein. Karten, Würfel, Rätsel und mehr, alles in einer App. Wischen, um loszulegen."),
            (nil, "Für jeden etwas", "Die Farbe zeigt die Spielart. Beim ersten Mal erklärt sich jedes Spiel selbst."),
        ]
        let s = seiten[nummer % seiten.count]
        return umgebung(VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Design.Abstand.l) {
                EinfuehrungKopfNeu(nummer: nummer, anzahl: 4, symbol: s.0, titel: s.1, text: s.2, rand: Theme.seitenRand).padding(.horizontal, Theme.seitenRand)
                if nummer == 1 { EinfuehrungSpielarten().padding(.horizontal, Theme.seitenRand) }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            EinfuehrungPunkte(seite: nummer, anzahl: 4).padding(.top, 10)
            Button("Weiter") {}.hauptKnopf().padding(.horizontal, Theme.seitenRand).padding(.vertical, 16)
        })
    }
}

struct SchliessenKnopf: View {   // Attrappe: wie App/KinderSchutz.swift
    @Environment(\.dismiss) private var dismiss
    var body: some View { Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel(Text("Schließen")) }   // Catalyst-Leiste zeichnet das Kreuz weiß, Tint ohne Wirkung
}
#endif
