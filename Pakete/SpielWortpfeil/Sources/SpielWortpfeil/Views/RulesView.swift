// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

struct RulesDetailView: View {
    @Environment(\.dismiss) private var dismiss

    /// Das Mini-Rätsel aus `Shared/regeltests/spiel.json`
    static let example = Puzzle(
        id: "T-MINI", stufe: "leicht", breite: 5, hoehe: 7,
        gitter: ["-#-#-", "#OMA-", "-P-S-", "#ART-", "E----", "I----", "S----"],
        fragen: [
            Clue(zeile: 0, spalte: 1, richtung: "unten", text: "Großvater"),
            Clue(zeile: 0, spalte: 3, richtung: "unten", text: "Teil des Baumes"),
            Clue(zeile: 1, spalte: 0, richtung: "rechts", text: "Großmutter"),
            Clue(zeile: 3, spalte: 0, richtung: "rechts", text: "Weise, Sorte"),
            Clue(zeile: 3, spalte: 0, richtung: "unten", text: "Gefrorenes Wasser"),
        ])

    /// Bauplan RS / Blatt 29: eine Regelseite für alle Spiele. Kopf: das gezeichnete Beispiel (OMA, EIS) in einem Beispiel-Kasten.
    var body: some View {
        if let q = RegelLeseKatalog.quelle(fuer: "wortpfeil") {
            RegelLeseAnsicht(quelle: q, spielName: "Kreuzworträtsel", spielID: "wortpfeil", wissen: nil) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beispiel").font(.caption2.weight(.semibold)).tracking(1.2).textCase(.uppercase).foregroundStyle(Color.schriftZweit)
                    GridView(data: .solved(Self.example), cell: 44).frame(maxWidth: .infinity)
                    Text("Beispiel: „Großmutter“ läuft nach rechts und ergibt OMA, „Gefrorenes Wasser“ läuft nach unten und ergibt EIS.")
                        .font(.footnote).foregroundStyle(Color.schriftZweit)
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.kartenGrund, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.linie, lineWidth: 1))
            }
        } else { alteSeite }
    }

    private var alteSeite: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Abstand.m) {
                    rule("Ziel", "Ein Schwedenrätsel hat keine Zahlen: Die Fragen stehen in Feldern mitten im Gitter. Der Pfeil zeigt, wohin das Wort läuft. Fülle alle Buchstabenfelder richtig aus. Es gibt keinen Zeitdruck und keine Strafen.")
                    VStack(spacing: Design.Abstand.s) {
                        GridView(data: .solved(Self.example), cell: 44)
                            .frame(maxWidth: .infinity)
                        Text("Beispiel: „Großmutter“ läuft nach rechts und ergibt OMA, „Gefrorenes Wasser“ läuft nach unten und ergibt EIS.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .card()
                    rule("Eintragen", "Tippe ein Feld oder eine Frage an. Das Wort wird markiert, die ganze Frage steht unten in der Leiste. Tippst du dasselbe Feld nochmal, wechselt die Richtung. Mit den Pfeilen in der Leiste springst du zur nächsten Frage.")
                    rule("Sprache", "Alle Rätsel und Fragen sind auf Deutsch. Übersetzt sind nur die Texte der App.")
                    rule("Umlaute", "Wie in der Zeitschrift: Ein Feld, ein Buchstabe. Ä wird AE, Ö wird OE, Ü wird UE, ß wird SS. Die Tasten Ä, Ö und Ü tragen zwei Felder ein; ß gibt es per langem Druck auf S.")
                    rule("Hilfen", "„Aufdecken“ zeigt den Buchstaben im markierten Feld, langes Drücken das ganze Wort. „Wort prüfen“ und „Alles prüfen“ färben falsche Buchstaben rot. Aufdecken und Prüfen zählen jedes Mal als Hilfe, auch wenn nichts falsch ist: Wer ganz ohne löst, bekommt einen Stern. In den Einstellungen kannst du Fehler auch sofort zeigen lassen.")
                    rule("Rätsel des Tages", "Jeden Tag gibt es ein neues Rätsel. Löst du es an mehreren Tagen hintereinander, wächst deine Serie. Vergangene Tage kannst du unter „Archiv und Zeiten“ im Kalender nachspielen; sie zählen nicht zur Serie.")
                }
                .padding(16)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(Color.papier)
            .tint(Color.kwAkzent)
            .navigationTitle("Regeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } }   // Fund 23/26/76: überall dasselbe runde Schließen-Kreuz statt Textknopf „Fertig“
            }
        }
    }

    private func rule(_ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(title)
            Text(text).font(.body)
        }
        .card()
    }
}
#endif
