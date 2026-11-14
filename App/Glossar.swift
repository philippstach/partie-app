// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Glossar der Spielbegriffe (H3): Was heißt Pasch, Stich, Trumpf, Schlagzwang …? Nach Spielart gruppiert, mit Suche.
/// Erreichbar aus den Einstellungen (Gruppe Spiel) und aus dem Würfel-Menü der Startseite.
struct GlossarBlatt: View {
    @Environment(\.dismiss) private var dismiss
    @State private var suche = ""

    struct Begriff: Identifiable { let id: String; let text: String; let spielart: Gattung?; var spiele: [String] = [] }

    static let begriffe: [Begriff] = [
        // Allgemein
        .init(id: "Partie", text: "Ein vollständiges Spiel vom Start bis zum Ende. Partie zählt jede beendete Runde in der Statistik.", spielart: nil),
        .init(id: "Zug", text: "Eine Aktion, die ein Spieler macht, wenn er an der Reihe ist: eine Karte legen, einen Stein setzen, würfeln.", spielart: nil),
        .init(id: "Runde", text: "Einmal reihum: Jeder Spieler war genau einmal am Zug. Viele Spiele zählen Punkte je Runde.", spielart: nil),
        .init(id: "Bluffen", text: "Etwas behaupten, was nicht stimmt, damit die anderen falsch reagieren. Erlaubt in Mäxchen und Mogeln.", spielart: nil, spiele: ["maexchen", "mogeln"]),
        .init(id: "Anzweifeln", text: "Die Behauptung des Vorgängers nicht glauben. Wer recht hat, gewinnt die Runde, wer falsch liegt, verliert sie.", spielart: nil),
        .init(id: "Computerstufe", text: "Stärke des Computergegners: leicht, mittel, schwer. Du wählst sie, bevor du eine Partie startest.", spielart: nil),
        .init(id: "Weiterspielen", text: "Eine unterbrochene Partie später fortsetzen. Die Karte oben auf der Startseite führt direkt hinein.", spielart: nil),
        // Karten
        .init(id: "Stich", text: "Alle Karten einer Runde zusammen. Die höchste Karte (oder der Trumpf) gewinnt den Stich.", spielart: .karten, spiele: ["brisca", "herzensjagd", "truco"]),
        .init(id: "Trumpf", text: "Eine Farbe, die in dieser Partie alle anderen Farben schlägt, egal wie hoch die Karte ist.", spielart: .karten, spiele: ["brisca"]),
        .init(id: "Farbe (Karten)", text: "Kreuz, Pik, Herz, Karo – im spanischen Blatt Münzen, Kelche, Schwerter, Stäbe. Nicht die Druckfarbe.", spielart: .karten),
        .init(id: "Bedienen", text: "Eine Karte der angespielten Farbe legen, wenn man eine hat. In Stichspielen meist Pflicht.", spielart: .karten, spiele: ["herzensjagd"]),
        .init(id: "Ablegen", text: "Eine passende Karte auf den offenen Stapel legen, um die eigene Hand loszuwerden (Mau-Mau).", spielart: .karten, spiele: ["maumau"]),
        .init(id: "Folge", text: "Mehrere Karten derselben Farbe in Reihe, zum Beispiel 7-8-9 (Rommé).", spielart: .karten, spiele: ["romme"]),
        .init(id: "Satz", text: "Drei oder vier Karten gleichen Werts in verschiedenen Farben, zum Beispiel drei Damen.", spielart: .karten, spiele: ["romme"]),
        .init(id: "Joker", text: "Karte, die jede andere ersetzen darf.", spielart: .karten, spiele: ["romme"]),
        .init(id: "Klopfen", text: "Beim Schwimmen: ansagen, dass die letzte Runde läuft. Danach ist jeder noch einmal dran.", spielart: .karten, spiele: ["schwimmen"]),
        .init(id: "Schieben", text: "Beim Schwimmen: keine Karte tauschen und an den Nächsten weitergeben.", spielart: .karten, spiele: ["schwimmen"]),
        .init(id: "Patience", text: "Kartenspiel für eine Person; Solitär ist die bekannteste Form.", spielart: .karten, spiele: ["solitaer"]),
        .init(id: "Tableau", text: "Die ausgelegten Kartenreihen beim Solitär, auf denen abwechselnd Rot und Schwarz absteigend angelegt wird.", spielart: .karten, spiele: ["solitaer"]),
        .init(id: "Escoba", text: "Beim Escoba: alle Karten vom Tisch auf einmal nehmen, indem sie zusammen 15 ergeben. Gibt einen Extrapunkt.", spielart: .karten, spiele: ["escoba"]),
        .init(id: "Envido", text: "Beim Truco: Wette auf die höchste Punktsumme zweier Karten gleicher Farbe in der Hand.", spielart: .karten, spiele: ["truco"]),
        // Würfel
        .init(id: "Pasch", text: "Mehrere Würfel zeigen dieselbe Zahl: Zweierpasch, Dreierpasch, Vierlinge.", spielart: .wuerfel, spiele: ["yacht", "10k", "pokerwurf"]),
        .init(id: "Straße", text: "Aufeinanderfolgende Augen, zum Beispiel 1-2-3-4-5 (kleine Straße) oder 2-3-4-5-6 (große Straße).", spielart: .wuerfel, spiele: ["yacht", "10k"]),
        .init(id: "Full House", text: "Drei gleiche und zwei gleiche Würfel, zum Beispiel 4-4-4-2-2.", spielart: .wuerfel, spiele: ["yacht", "pokerwurf"]),
        .init(id: "Niete", text: "Ein Wurf ohne zählende Würfel. Bei Zehntausend sind dann alle Punkte der Runde weg.", spielart: .wuerfel, spiele: ["10k", "schweinerei"]),
        .init(id: "Sichern", text: "Die bisher gesammelten Punkte der Runde gutschreiben lassen, statt weiter zu riskieren.", spielart: .wuerfel, spiele: ["10k", "schweinerei"]),
        .init(id: "Becher", text: "Würfelbecher: Würfel verdeckt werfen, damit die anderen das Ergebnis nicht sehen (Mäxchen, Schocken).", spielart: .wuerfel, spiele: ["maexchen", "schocken"]),
        .init(id: "Mäxchen", text: "Beim Mäxchen der höchste Wurf: eine 2 und eine 1. Schlägt alles.", spielart: .wuerfel, spiele: ["maexchen"]),
        .init(id: "Schock", text: "Beim Schocken ein Wurf mit zwei Einsen; „Schock aus“ (drei Einsen) beendet die Runde sofort.", spielart: .wuerfel, spiele: ["schocken"]),
        .init(id: "Deckel", text: "Strafmarken beim Schocken. Wer am Ende alle Deckel hat, verliert.", spielart: .wuerfel, spiele: ["schocken"]),
        // Fund 53: Fachwörter, die im Schocken-Spiel ohne Erklärung stehen
        .init(id: "Stock", text: "Der Vorrat an Deckeln in der Mitte. Der Verlierer einer Runde nimmt seine Deckel zuerst von dort.", spielart: .wuerfel, spiele: ["schocken"]),
        .init(id: "Vorleger", text: "Wer in einer Runde zuerst würfelt. Wie oft er würfelt (höchstens dreimal), dürfen danach alle anderen auch.", spielart: .wuerfel, spiele: ["schocken"]),
        .init(id: "Hälfte", text: "Ein Teil der Partie: Sie endet, wenn jemand alle Deckel hat, der verliert die Hälfte. Nach zwei Hälften folgt das Finale.", spielart: .wuerfel, spiele: ["schocken"]),
        .init(id: "Draußen", text: "Würfel, die du nach einem Wurf herausgelegt hast. Sie bleiben liegen, nur die übrigen würfelst du noch einmal.", spielart: .wuerfel, spiele: ["schocken"]),
        .init(id: "Echte Würfel", text: "Statt die App würfeln zu lassen, würfelst du am Tisch und tippst die Augen ein. Umschaltbar vor dem Spiel.", spielart: .wuerfel),
        // Brett
        .init(id: "Schlagen", text: "Einen gegnerischen Stein vom Brett nehmen, meist indem man auf sein Feld zieht oder über ihn springt.", spielart: .brett, spiele: ["dame", "schach", "rauswurf"]),
        .init(id: "Schlagzwang", text: "Wer schlagen kann, muss schlagen. Gilt beim Dame-Spiel.", spielart: .brett, spiele: ["dame"]),
        .init(id: "Dame (Figur)", text: "Beim Dame-Spiel ein Stein, der die letzte Reihe erreicht hat und danach in beide Richtungen zieht.", spielart: .brett, spiele: ["dame"]),
        .init(id: "Mühle", text: "Drei eigene Steine in einer Reihe. Wer eine Mühle schließt, nimmt einen gegnerischen Stein.", spielart: .brett, spiele: ["muehle"]),
        .init(id: "Matt", text: "Der König steht im Schach und kann nicht mehr entkommen. Die Partie ist zu Ende.", spielart: .brett, spiele: ["schach"]),
        .init(id: "Patt", text: "Der Spieler am Zug hat keinen erlaubten Zug, steht aber nicht im Schach. Unentschieden.", spielart: .brett, spiele: ["schach"]),
        .init(id: "Rochade", text: "Sonderzug beim Schach: König und Turm wechseln gleichzeitig die Plätze, um den König zu sichern.", spielart: .brett, spiele: ["schach"]),
        .init(id: "Säen", text: "Bei Kalaha und Oware: die Steine einer Mulde einzeln reihum in die folgenden Mulden verteilen.", spielart: .brett, spiele: ["kalaha", "oware"]),
        .init(id: "Haus", text: "Zielfelder, in die die eigenen Figuren gebracht werden müssen (Rauswurf).", spielart: .brett, spiele: ["rauswurf"]),
        .init(id: "Rauswerfen", text: "Eine gegnerische Figur zurück auf den Start schicken, indem man ihr Feld betritt.", spielart: .brett, spiele: ["rauswurf"]),
        .init(id: "Wenden", text: "Beim Wendespiel: eingeschlossene gegnerische Steine umdrehen, damit sie die eigene Farbe zeigen.", spielart: .brett, spiele: ["wendespiel"]),
        .init(id: "Sprungkette", text: "Mehrere Sprünge hintereinander in einem Zug (Halma, Dame).", spielart: .brett, spiele: ["halma", "dame"]),
        // Rätsel
        .init(id: "Notizen", text: "Kleine Ziffern als Gedächtnisstütze, welche Zahlen in einem Feld noch möglich sind (Sudoku, Kakuro).", spielart: .raetsel, spiele: ["sudoku", "kakuro"]),
        .init(id: "Tipp", text: "Die App zeigt den nächsten sicheren Schritt. Kostet nichts, wird aber gezählt.", spielart: .raetsel),
        .init(id: "Hinweiszahl", text: "Zahl im Feld, die einen Hinweis gibt: bei der Minensuche, wie viele Minen in den Nachbarfeldern liegen, bei Kakuro, welche Summe die Ziffern ergeben.", spielart: .raetsel, spiele: ["minensuche", "kakuro"]),
        .init(id: "Markieren", text: "Ein Feld als Mine oder als sicher kennzeichnen, ohne es aufzudecken.", spielart: .raetsel, spiele: ["minensuche"]),
        .init(id: "Tagesrätsel", text: "Jeden Tag dasselbe Rätsel für alle. Die Serie zählt, wie viele Tage in Folge du gelöst hast.", spielart: .raetsel),
        // Wort
        .init(id: "Pfeilrätsel", text: "Kreuzworträtsel, bei dem die Fragen im Gitter stehen und ein Pfeil die Richtung der Antwort zeigt.", spielart: .wort, spiele: ["wortpfeil"]),
        .init(id: "Kategorie", text: "Bei Stadt, Land, Fluss eine Spalte wie Tier oder Beruf, zu der ein Wort mit dem Buchstaben gesucht wird.", spielart: .wort, spiele: ["stadtlandfluss"]),
        // Arcade
        .init(id: "Rekord", text: "Höchste je erreichte Punktzahl in einem Arcade-Spiel. Steht auf der Startseite des Spiels.", spielart: .arcade),
        .init(id: "Leben", text: "Wie oft du noch verlieren darfst, bevor die Partie endet.", spielart: .arcade),
        .init(id: "Reihe auflösen", text: "Beim Steinfall: eine volle Zeile verschwindet und bringt Punkte.", spielart: .arcade, spiele: ["steinfall"]),
    ]

    /// Begriffe und Erklärungen stehen deutsch im Code und werden zur Laufzeit über den Katalog übersetzt (en/es/fr).
    static func uebersetzt(_ s: String) -> String { String(localized: String.LocalizationValue(s)) }

    /// T-9: Nur Begriffe der freigegebenen Spiele (`SpielKatalog.spielbar`, normal die 26). Allgemeine Begriffe ohne Spielliste bleiben immer;
    /// sonst muss mindestens eines der genannten Spiele spielbar sein. Die Texte bleiben im Code, nur die Anzeige wird gefiltert.
    static func freigegeben(_ b: Begriff) -> Bool {
        b.spiele.isEmpty || b.spiele.contains { id in SpielKatalog.spielbar.contains { $0.id == SpielKatalog.kennung(id) } }
    }

    private var treffer: [Begriff] {
        let t = suche.trimmingCharacters(in: .whitespaces)
        let sichtbar = Self.begriffe.filter(Self.freigegeben)
        guard !t.isEmpty else { return sichtbar }
        return sichtbar.filter { Self.uebersetzt($0.id).localizedCaseInsensitiveContains(t) || Self.uebersetzt($0.text).localizedCaseInsensitiveContains(t) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                    HStack(spacing: Design.Abstand.s) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Begriff suchen", text: $suche)
                        if !suche.isEmpty { Button { suche = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain).frame(minWidth: 44, minHeight: 44).contentShape(.rect).accessibilityLabel("Suche löschen") }
                    }
                    .padding(.horizontal, 12).frame(minHeight: 44)
                    .background(Color.kartenGrund, in: .rect(cornerRadius: Theme.feldRadius))
                    if treffer.isEmpty { Text("Kein Begriff gefunden.").font(.subheadline).foregroundStyle(.secondary).card() }
                    gruppe(nil, titel: Text("Allgemein"), farbe: .secondary)
                    ForEach(SpielZeilen.spielarten, id: \.self) { g in gruppe(g, titel: Text(g.name), farbe: g.farbe.color) }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Glossar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }   // Fund 23/26/76: überall dasselbe runde Schließen-Kreuz statt Textknopf „Fertig“
        }
    }

    @ViewBuilder
    private func gruppe(_ g: Gattung?, titel: Text, farbe: Color) -> some View {
        let liste = treffer.filter { $0.spielart == g }
        if !liste.isEmpty {
            SpielartLabel(text: titel, farbe: farbe).padding(.top, 6)
            VStack(alignment: .leading, spacing: 14) {
                ForEach(liste) { b in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: Self.uebersetzt(b.id)).font(.headline)
                        Text(verbatim: Self.uebersetzt(b.text)).font(.subheadline).foregroundStyle(.secondary)
                        let namen = b.spiele.compactMap { id in SpielKatalog.spielbar.first { $0.id == SpielKatalog.kennung(id) }?.name }   // T-9: nur Spiele, die es gibt
                        if !namen.isEmpty { Text(verbatim: namen.joined(separator: " · ")).font(.caption).foregroundStyle(Color.accentText) }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .card()
        }
    }
}
