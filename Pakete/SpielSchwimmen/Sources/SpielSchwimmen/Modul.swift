// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Schwimmen : die eine Fassung des Spiels in der Sammlung.
/// Hausregeln (`SchwimmenRegeln`), Punktemodus, Tausch-Vorschau und ein Spielbildschirm, der die Resthöhe nutzt.
@MainActor
public struct SchwimmenModul: SpielModul {
    public init() {}
    public static let kennung = "schwimmen-neu"
    public let id = SchwimmenModul.kennung
    public let name = "Schwimmen"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "figure.pool.swim"
    public let spielerzahl = 2...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "31 Punkte, drei Karten", farbe: farbe, spieler: 2...6, computerErlaubt: true,
                            regeln: "Jeder hat drei Karten, drei liegen offen in der Mitte. Du tauschst eine Karte, alle drei, schiebst oder klopfst. Zählt nur die Farbe mit der höchsten Summe (Ass 11, Bild 10); drei gleiche Karten sind 30,5, 31 beendet die Runde sofort. Nach dem Klopfen ist jeder noch einmal dran. Die niedrigste Hand verliert ein Leben; wer bei null Leben noch einmal verliert, ist raus. Wer übrig bleibt, gewinnt. Hausregeln stellst du vor dem Start im Blatt „Neues Spiel“ oder im Menü „Mehr“ ein: Leben, Feuer, 33 mit drei Assen, Schieben-Limit, Wert von drei Gleichen und den Punktemodus (Summe über mehrere Runden).",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SchwimmenNeuSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { _ in SchwimmenOptionen() }   // 1.0 (M1): Hausregeln schon vor dem Start
        .mitZiel("Sammle in einer Farbe möglichst nah an 31 Punkte. Wer die niedrigste Hand hat, verliert ein Leben; wer übrig bleibt, gewinnt.")
        .mitZielSchrittNeu(.ziel("Sammle in einer Farbe möglichst nah an 31 Punkte. Wer die niedrigste Hand hat, verliert ein Leben; wer übrig bleibt, gewinnt. Schwimmen ist ein schnelles Spiel für 2 bis 6 Personen. Jede Person hat drei Karten, in der Mitte liegen drei zum Tauschen."))   // B25: neue deutsche Anleitung (RegelTexteNeu), die alte bleibt für alle anderen Sprachen
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "suit.heart", titel: "Beste Farbe", text: "Es zählt nur die Farbe mit der höchsten Summe. Das Ass zählt 11, Bilder und die 10 je 10, die anderen Karten ihren Wert. Herz Ass, Herz König und Herz 7 sind also 28. Drei gleiche Karten, zum Beispiel drei Neunen, zählen 30,5.", figuren: ["A♥", "K♥", "7♥"], bewegt: nil),
            .figuren(symbol: "arrow.triangle.swap", titel: "Karten tauschen", text: "Bist du dran, tauschst du eine Karte mit dem Tisch oder alle drei auf einmal. Tippe eine Hand- und eine Tischkarte an: Du siehst vorher, was der Tausch bringt. Willst du nichts tauschen, schiebst du. Schieben alle, kommen drei neue Karten auf den Tisch.", figuren: ["🂡", "🂱", "🂻"], bewegt: 0),
            .figuren(symbol: "hand.raised", titel: "Klopfen", text: "Bist du zufrieden, klopfst du. Dann ist jede andere Person noch genau einmal dran, und danach wird gezählt. Klopfen darfst du schon im ersten Zug. Ein guter Moment ist, wenn du 27 oder mehr hast.", figuren: ["✊", "🚪"], bewegt: 0),
            .figuren(symbol: "flame", titel: "Feuer", text: "Hat jemand nach einem Tausch genau 31, also Ass und zwei Zehnerkarten in einer Farbe, ist das Feuer: Die Runde endet sofort, und alle anderen verlieren ein Leben.", figuren: ["A♣", "K♣", "D♣", "🔥"], bewegt: nil),
            .figuren(symbol: "heart", titel: "Leben", text: "Nach jeder Runde verliert die niedrigste Hand ein Leben. Du startest mit drei. Hast du keins mehr, schwimmst du. Verlierst du dann noch einmal, bist du raus. Wer als Letzter übrig bleibt, gewinnt.", figuren: ["❤️", "❤️", "❤️", "🏊"], bewegt: nil),
            .figuren(symbol: "slider.horizontal.3", titel: "Hausregeln", text: "Unter „Hausregeln“ stellst du vor dem Start ein: vier Leben, Feuer aus, 33 mit drei Assen, Schieben nur einmal, drei Gleiche als 30 oder die Spielart „Punkte (5 Runden)“ ohne Leben. „Tipp“ zeigt dir den besten Tausch. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["⚙️", "💡"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "arrow.left.arrow.right", titel: "Karten tauschen", text: "Tippe eine Handkarte und eine Tischkarte an: Du siehst vorher, was der Tausch bringt.", figuren: ["🂡", "🂱", "🂻"], bewegt: 0),
            .figuren(symbol: "plus", titel: "Beste Farbe", text: "Es zählt nur die Farbe mit der höchsten Summe. Ass 11, Bilder 10, drei Gleiche 30,5, 31 beendet die Runde.", figuren: ["♠️", "♠️", "♠️"], bewegt: nil),
            .figuren(symbol: "heart.fill", titel: "Leben", text: "Die niedrigste Hand verliert ein Leben. Wer übrig bleibt, gewinnt.", figuren: ["❤️", "❤️", "❤️"], bewegt: nil),
        ])))
    }
}
#endif

#if canImport(UIKit)
/// 1.0 (M1): Hausregeln schon im Blatt „Neues Spiel“ (vorher nur im Menü der laufenden Partie, das bleibt).
/// Gespeichert unter demselben Schlüssel, den die Partie beim Start liest.
struct SchwimmenOptionen: View {
    @State private var regeln = SchwimmenNeuSpiel.gespeicherteRegeln
    @State private var blatt = false

    private var zusammenfassung: String {
        let r = regeln
        return [
            r.modus == .leben ? String(localized: "\(r.leben) Leben") : String(localized: "Punkte, \(r.runden) Runden"),
            r.feuerSofort ? String(localized: "31 beendet sofort") : String(localized: "31 zählt nur beim Klopfen"),
            r.dreiAssen33 ? String(localized: "Drei Asse = 33") : String(localized: "Drei Gleiche = \(SwNamen.zahl(r.dreiGleiche))"),
            r.schiebenLimit.map { String(localized: "Schieben höchstens \($0)×") } ?? String(localized: "Schieben beliebig oft"),
        ].joined(separator: " · ")
    }

    private func aendern<T>(_ pfad: WritableKeyPath<SchwimmenRegeln, T>) -> Binding<T> {
        Binding(get: { regeln[keyPath: pfad] }, set: { neu in regeln[keyPath: pfad] = neu })
    }

    var body: some View {
        Button { blatt = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Hausregeln", systemImage: "slider.horizontal.3").font(.headline).foregroundStyle(Color.accentText)
                    Text(verbatim: zusammenfassung).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .card()
        .accessibilityHint(Text("Öffnet die Hausregeln"))
        .sheet(isPresented: $blatt) {
            NavigationStack {
                Form {
                    Section {
                        Picker("Spielart", selection: aendern(\.modus)) {
                            Text("Leben").tag(SwModus.leben)
                            Text("Punkte (5 Runden)").tag(SwModus.punkte)
                        }
                        if regeln.modus == .leben {
                            Picker("Leben", selection: aendern(\.leben)) { Text("3 Leben").tag(3); Text("4 Leben").tag(4) }
                        }
                    }
                    Section {
                        Toggle("31 beendet die Runde sofort", isOn: aendern(\.feuerSofort))
                        Toggle("33 mit drei Assen", isOn: aendern(\.dreiAssen33))
                        Picker("Schieben", selection: Binding(get: { regeln.schiebenLimit ?? 0 }, set: { n in regeln.schiebenLimit = n == 0 ? nil : n })) {
                            Text("Beliebig oft").tag(0); Text("Höchstens einmal").tag(1)
                        }
                        Picker("Drei Gleiche", selection: aendern(\.dreiGleiche)) { Text("30,5 Punkte").tag(30.5); Text("30 Punkte").tag(30.0) }
                    }
                    Section {
                        Button("Standard wiederherstellen") { regeln = .standard }
                    }
                }
                .einstellungsSchalter()   // Design-Runde 3: SchalterZeile statt System-UISwitch (wie bei Schocken)
                .navigationTitle("Hausregeln")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { blatt = false } } }
            }
            .presentationDetents([.large])
        }
        .onChange(of: regeln) { _, neu in
            if let d = try? JSONEncoder().encode(neu) { UserDefaults.standard.set(d, forKey: SchwimmenNeuSpiel.schluessel) }
        }
        .onAppear { regeln = SchwimmenNeuSpiel.gespeicherteRegeln }
    }
}
#endif
