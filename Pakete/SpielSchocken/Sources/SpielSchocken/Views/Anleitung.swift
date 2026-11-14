// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Regeln-Blatt: animierte Anleitung zum Durchwischen, die ausführlichen Regeln dahinter (`RulesDetailView`).
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        AnleitungBlatt(titel: "Schocken", schritte: Self.schritte, fertig: { dismiss() }) { RulesDetailView() }
    }

    // Bühnen als Funktionen, damit alte und neue Seiten (Build 25, nur Deutsch) dieselben Bilder zeigen
    @ViewBuilder static func buehneWuerfeln(_ p: Double, _ aktiv: Bool) -> some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { i in
                let haelt = i == 0 && p > 0.5
                let rollt = aktiv && !haelt && p < 0.85
                AnleitungWuerfel(augen: haelt ? 1 : (rollt ? ((Int(p * 14) + i * 3) % 6) + 1 : [1, 4, 2][i]), groesse: 58, gehalten: haelt)
                    .offset(y: haelt ? -18 : (rollt ? CGFloat(sin(p * 28 + Double(i))) * 4 : 0))
            }
        }
    }

    @ViewBuilder static func buehneDeckel(_ p: Double) -> some View {
        GeometryReader { g in
            let s = anleitungAbschnitt(p, von: 0.25, bis: 0.75)
            HStack(spacing: Design.Abstand.xs) { AnleitungWuerfel(augen: 6, groesse: 30); AnleitungWuerfel(augen: 6, groesse: 30); AnleitungWuerfel(augen: 6, groesse: 30) }
                .position(x: g.size.width * 0.28, y: g.size.height * 0.3)
            HStack(spacing: Design.Abstand.xs) { AnleitungWuerfel(augen: 4, groesse: 30); AnleitungWuerfel(augen: 3, groesse: 30); AnleitungWuerfel(augen: 2, groesse: 30) }
                .position(x: g.size.width * 0.72, y: g.size.height * 0.3)
            ForEach(0..<3, id: \.self) { k in
                Circle().fill(Color.appFlaeche).frame(width: 24, height: 24)
                    .position(x: g.size.width * (0.28 + 0.44 * s) + CGFloat(k) * 8, y: g.size.height * 0.72)
            }
        }
    }

    @ViewBuilder static func buehneVerlieren(_ p: Double) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<13, id: \.self) { i in
                Circle().fill(Double(i) < p * 13 ? Color.appFlaeche : Color.appFlaeche.opacity(0.25)).frame(width: 18, height: 18)
            }
        }
    }

    static let schritte: [AnleitungSchritt] = [
        AnleitungSchritt.ziel("Würfle besser als die anderen, damit du keine Deckel bekommst. Wer zwei Hälften oder das Finale verliert, verliert die Partie."),
        AnleitungSchritt(symbol: "dice", titel: "Würfeln",
                         text: "Ihr würfelt reihum mit drei Würfeln, bis zu dreimal. Einsen (mit der Hausregel „Beliebig“ jeden Würfel) kannst du herauslegen und nur die übrigen neu werfen.",
                         geste: .keine) { p, aktiv in Self.buehneWuerfeln(p, aktiv) },
        AnleitungSchritt(symbol: "circle.hexagongrid.fill", titel: "Deckel verteilen",
                         text: "Wer am schlechtesten würfelt, verliert die Runde und bekommt Deckel – so viele, wie der beste Wurf wert ist.",
                         geste: .keine) { p, _ in Self.buehneDeckel(p) },
        AnleitungSchritt(symbol: "flag.checkered", titel: "Wer alle Deckel hat, verliert",
                         text: "Wer am Ende einer Hälfte alle Deckel hat, verliert diese Hälfte. Wer zwei Hälften oder das Finale verliert, verliert die Partie.",
                         geste: .keine) { p, _ in Self.buehneVerlieren(p) },
    ]

    // Neue Anleitung (nur Deutsch, Build 25): Texte aus plan/regeln-neu/schocken/anleitung.md
    static let schritteNeu: [AnleitungSchritt] = [
        AnleitungSchritt(symbol: "dice", titel: "Würfeln",
                         text: "Du hast bis zu drei Würfe. Nach jedem Wurf entscheidest du: „Stehen lassen“ oder „Weiter würfeln“. Vorher darfst du Einsen herauslegen, indem du sie antippst. Sie bleiben liegen und zählen mit. Mindestens ein Würfel muss neu geworfen werden. Mit der Hausregel „Beliebig“ darfst du jeden Würfel herauslegen.",
                         geste: .keine) { p, aktiv in Self.buehneWuerfeln(p, aktiv) },
        AnleitungSchritt.figuren(symbol: "person.fill.checkmark", titel: "Der Vorleger",
                                 text: "Wer die Runde beginnt, ist der Vorleger. So oft er würfelt, so oft dürfen alle anderen höchstens. Lässt er nach dem ersten Wurf stehen, habt ihr alle nur einen Wurf. Ein guter erster Wurf setzt die anderen also unter Druck. Die nächste Runde beginnt, wer die letzte verloren hat.",
                                 figuren: ["🎲", "→", "1️⃣", "🎲", "→", "1️⃣"], bewegt: 0),
        AnleitungSchritt.figuren(symbol: "arrow.uturn.down", titel: "Sechsen umdrehen",
                                 text: "Hast du zwei Sechsen geworfen, darfst du eine davon zur Eins umdrehen. Bei drei Sechsen sogar zwei. Die Einsen bleiben draußen liegen, den Rest wirfst du neu. Tippe dafür „Sechsen umdrehen“. Eine einzelne Sechs darfst du nicht umdrehen. So kommst du leichter an einen Schock.",
                                 figuren: ["⚅", "⚅", "⚂"], bewegt: 1),
        AnleitungSchritt.figuren(symbol: "list.number", titel: "Die besten Würfe",
                                 text: "Vom besten zum schwächsten: Schock aus (drei Einsen) gibt alle Deckel. Ein Schock (zwei Einsen und eine Zahl) gibt so viele Deckel wie der dritte Würfel. Ein General (drei gleiche) gibt 3, eine Straße (wie 4-5-6) gibt 2, jede andere Zahl 1. General und Straße zählen nur, wenn alle drei Würfel zusammen gefallen sind. Die ganze Tabelle steht unter „Alle Regeln lesen“.",
                                 figuren: ["⚀⚀⚀", "⚀⚀⚅", "⚄⚄⚄", "⚃⚄⚅"], bewegt: nil),
        AnleitungSchritt(symbol: "circle.stack", titel: "Deckel verteilen",
                         text: "Haben alle gewürfelt, bekommt der schlechteste Wurf Deckel, so viele, wie der beste Wurf wert ist. Zuerst kommen sie aus dem Stock in der Mitte. Ist der Stock leer, gibt der Gewinner der Runde seine eigenen Deckel ab. Wer dann keine Deckel mehr hat, ist für diese Hälfte raus und sicher.",
                         geste: .keine) { p, _ in Self.buehneDeckel(p) },
        AnleitungSchritt(symbol: "flag.checkered", titel: "Hälften und Finale",
                         text: "Wer alle Deckel hat, verliert die Hälfte. Bei Schock aus geht das sofort. Dann kommt Hälfte 2. Verliert jemand beide Hälften, hat er die Partie verloren. Sonst spielen die beiden Verlierer ein Finale, nur die zwei gegeneinander. Wer das Finale verliert, verliert die Partie.",
                         geste: .keine) { p, _ in Self.buehneVerlieren(p) },
        AnleitungSchritt.figuren(symbol: "slider.horizontal.3", titel: "Hausregeln und Hilfen",
                                 text: "Unter „Mehr“ → „Hausregeln ändern“ stellst du vor dem ersten Wurf ein, wie ihr spielt, etwa mit Jule (4-2-1) oder nur einer Hälfte. „Tipp“ rät dir, ob Stehen oder Weiterwürfeln besser ist. Im Verlauf siehst du jede Runde. Mit echten Würfeln tippst du die Ergebnisse ein. Alles Weitere steht unter „Alle Regeln lesen“.",
                                 figuren: ["⚙️", "💡", "📜"], bewegt: nil),
    ]
}
