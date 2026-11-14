// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Anleitung zum Durchwischen für „Galgenmännchen“ (Design-Runde 5, Blatt 14): fünf Seiten, der ausführliche Regeltext bleibt hinter „Alle Regeln lesen“.
/// Die Zahlen stammen aus dem Spielkern: acht Ballons (`Game.maxMistakes`), zwei Hinweise (`Game.maxHints`), vier in „Kinderleicht“
/// (`Game.kidsMaxHints`), ein falscher Lösungsversuch kostet zwei Ballons (`Game.solvePenalty`), drei Leben in „Überleben“.
/// Auf dem Filz (Tinte) ist alles Elfenbein; in Klar und Salon bleibt die Bühne in der App-Farbe wie bei den anderen Anleitungen.
@MainActor
enum GalgenAnleitung {
    // MARK: Farben

    private static var hell: Color { Tisch.aktiv ? Tisch.elfenbein : Color.accentText }
    private static var tasteFlaeche: Color { Tisch.aktiv ? Tisch.elfenbein : Color(.systemBackground) }
    private static var tasteSchrift: Color { Tisch.aktiv ? Tisch.auge : Color.accentText }

    // MARK: Bausteine

    /// Acht Ballons in einer Reihe; die ersten `platzt` sind geplatzt (nur noch gestrichelt).
    private static func ballons(platzt: Int, wippen p: Double = 0, aktiv: Bool = false) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<8, id: \.self) { i in
                ZStack {
                    if i >= 8 - platzt {
                        Ellipse().strokeBorder(hell.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    } else {
                        Ellipse().fill(hell)
                    }
                }
                .frame(width: 20, height: 24)
                .offset(y: aktiv ? 3 * sin((p + Double(i) * 0.11) * .pi * 2) : 0)
            }
        }
        .accessibilityHidden(true)
    }

    /// Wort auf Strichen: ein Leerzeichen im Text („_“) bleibt eine offene Stelle.
    private static func wort(_ buchstaben: [String], neu: Int? = nil, p: Double = 1) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(buchstaben.enumerated()), id: \.offset) { i, b in
                VStack(spacing: 3) {
                    Text(verbatim: b == "_" ? " " : b)
                        .font(Design.Schrift.serif(28, gewicht: .bold, relativ: .title))
                        .foregroundStyle(hell)
                        .scaleEffect(neu == i ? 1 + 0.25 * sin(p * .pi) : 1)
                        .frame(height: 34)
                    Rectangle().fill(hell).frame(width: 24, height: 2)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// Eine Taste der Bildschirmtastatur; `verbraucht` = schon geraten (blass).
    private static func taste(_ b: String, verbraucht: Bool = false, gedrueckt: Bool = false) -> some View {
        Text(verbatim: b)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(tasteSchrift)
            .frame(width: 34, height: 34)
            .background(tasteFlaeche, in: .rect(cornerRadius: 8))
            .opacity(verbraucht ? 0.4 : 1)
            .overlay { if gedrueckt { RoundedRectangle(cornerRadius: 8).strokeBorder(hell, lineWidth: 2).padding(-3) } }
            .scaleEffect(gedrueckt ? 0.92 : 1)
            .accessibilityHidden(true)
    }

    /// Knopf „Lösen“ oder „Hinweis“ wie im Spiel: umrandete Kapsel mit Zeichen.
    private static func knopf(_ titel: LocalizedStringKey, symbol: String, gedrueckt: Bool = false) -> some View {
        Label(titel, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(gedrueckt ? tasteSchrift : hell)
            .padding(.horizontal, 16).frame(height: 38)
            .background(gedrueckt ? tasteFlaeche : Color.clear, in: .capsule)
            .overlay(Capsule().strokeBorder(hell, lineWidth: 1.5))
            .accessibilityHidden(true)
    }

    /// Kleines Schild der Spielarten (Seite 5).
    private static func schild(_ inhalt: Text, sichtbar: Double) -> some View {
        inhalt
            .font(.footnote.weight(.semibold))
            .foregroundStyle(hell)
            .padding(.horizontal, 12).frame(height: 30)
            .background(hell.opacity(0.22), in: .capsule)
            .opacity(0.35 + 0.65 * sichtbar)
            .accessibilityHidden(true)
    }

    // MARK: Seiten

    /// Seite 1 („Ziel“) ersetzt die Standardseite mit der Fahne (`SpielRahmen.mitZielSchritt`).
    static let ziel = AnleitungSchritt(symbol: "flag.checkered", titel: "Ziel",
                                       text: "Ein Wort ist gesucht. Finde es, bevor der letzte von acht Ballons platzt.") { p, aktiv in
        VStack(spacing: 26) {
            ballons(platzt: 0, wippen: p, aktiv: aktiv)
            wort(["B", "_", "L", "L", "_", "_"])
        }
    }

    /// Seiten 2 bis 5.
    static let schritte: [AnleitungSchritt] = [
        // 2: Der Finger tippt O; das O erscheint an der Stelle im Wort.
        AnleitungSchritt(symbol: "hand.tap.fill", titel: "Buchstaben raten",
                         text: "Tippe einen Buchstaben. Steckt er im Wort, erscheint er an allen Stellen.",
                         geste: .tippen(UnitPoint(x: 0.5 + 0.5 * 42 / 340, y: 0.66))) { p, aktiv in
            let da = !aktiv || p > 0.55
            VStack(spacing: 24) {
                wort(["B", "_", "L", "L", da ? "O" : "_", "_"], neu: da ? 4 : nil, p: anleitungAbschnitt(p, von: 0.55, bis: 0.9))
                HStack(spacing: 8) {
                    taste("L", verbraucht: true)
                    taste("M"); taste("N")
                    taste("O", gedrueckt: aktiv && p > 0.4 && p < 0.6)
                    taste("P"); taste("Q")
                }
            }
        },
        // 3: Drei falsche Buchstaben, drei Ballons sind geplatzt.
        AnleitungSchritt(symbol: "balloon.fill", titel: "Acht Ballons",
                         text: "Jeder falsche Buchstabe lässt einen Ballon platzen. Platzt der achte, ist das Wort verloren.") { p, aktiv in
            let n = aktiv ? min(3, Int(p * 4.5)) : 3
            VStack(spacing: 28) {
                ballons(platzt: n)
                HStack(spacing: 8) {
                    ForEach(Array(["X", "Q", "Z"].enumerated()), id: \.offset) { i, b in
                        taste(b, verbraucht: true).opacity(n > i ? 1 : 0.0)
                    }
                }
            }
        },
        // 4: Der Finger tippt „Hinweis“; ein Buchstabe wird aufgedeckt.
        AnleitungSchritt(symbol: "lightbulb.fill", titel: "Hinweis und Lösen",
                         text: "Ein Hinweis deckt einen Buchstaben auf. Du hast zwei, in „Kinderleicht“ vier. Mit „Lösen“ rätst du das ganze Wort. Ein falscher Versuch kostet zwei Ballons.",
                         geste: .tippen(UnitPoint(x: 0.68, y: 0.65))) { p, aktiv in
            let da = !aktiv || p > 0.55
            VStack(spacing: 22) {
                wort(["B", da ? "A" : "_", "L", "L", "O", "_"], neu: da ? 1 : nil, p: anleitungAbschnitt(p, von: 0.55, bis: 0.9))
                HStack(spacing: 12) {
                    knopf("Lösen", symbol: "text.cursor")
                    knopf("Hinweis", symbol: "lightbulb", gedrueckt: aktiv && p > 0.4 && p < 0.6)
                }
            }
        },
        // 5: Die Spielarten als kleine Schilder.
        AnleitungSchritt(symbol: "person.2.fill", titel: "Allein oder zu mehreren",
                         text: "Allein wählst du Kategorie und Stufe, das Wort des Tages oder „Überleben“ mit drei Leben. Zu mehreren rät reihum einer. Das Wort zieht die App, oder der Spieler nach ihm denkt es sich aus.", geste: .keine) { p, aktiv in
            let s: (Int) -> Double = { i in aktiv ? anleitungAbschnitt(p, von: Double(i) * 0.12, bis: Double(i) * 0.12 + 0.3) : 1 }
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    schild(Text("Wort des Tages"), sichtbar: s(0))
                    schild(Text("Überleben") + Text(verbatim: " ♥ ♥ ♥"), sichtbar: s(1))
                }
                HStack(spacing: 8) {
                    schild(Text("Tiere · leicht"), sichtbar: s(2))
                    schild(Text("Party: reihum"), sichtbar: s(3))
                }
            }
        },
    ]

    // MARK: Neue Texte (Build 25, nur Deutsch; Bühnen wie bisher)

    private static func buehneZiel(_ p: Double, _ aktiv: Bool) -> some View {
        VStack(spacing: 26) {
            ballons(platzt: 0, wippen: p, aktiv: aktiv)
            wort(["B", "_", "L", "L", "_", "_"])
        }
    }

    private static func buehneSchilder(_ p: Double, _ aktiv: Bool, party: Bool) -> some View {
        let s: (Int) -> Double = { i in aktiv ? anleitungAbschnitt(p, von: Double(i) * 0.12, bis: Double(i) * 0.12 + 0.3) : 1 }
        return VStack(spacing: 10) {
            if party {
                HStack(spacing: 8) {
                    schild(Text("Tiere · leicht"), sichtbar: s(0))
                    schild(Text("Party: reihum"), sichtbar: s(1))
                }
            } else {
                HStack(spacing: 8) {
                    schild(Text("Wort des Tages"), sichtbar: s(0))
                    schild(Text("Überleben") + Text(verbatim: " ♥ ♥ ♥"), sichtbar: s(1))
                }
                schild(Text("Tiere · leicht"), sichtbar: s(2))
            }
        }
    }

    static let zielNeu = AnleitungSchritt(symbol: "flag.checkered", titel: "Ziel",
        text: "Ein Wort ist gesucht. Du siehst nur Striche, für jeden Buchstaben einen. Finde das Wort, bevor der letzte von acht Ballons platzt. Du kannst allein spielen, jeden Tag das Wort des Tages lösen oder mit zwei bis vier Leuten Party spielen.") { p, aktiv in
        buehneZiel(p, aktiv)
    }

    /// Seiten 2 bis 6 mit den neuen Texten; die Bühnen sind die der alten Seiten.
    static let schritteNeu: [AnleitungSchritt] = {
        [
            AnleitungSchritt(symbol: "hand.tap.fill", titel: "Buchstaben raten",
                text: "Tippe einen Buchstaben. Steckt er im Wort, erscheint er an allen Stellen. Einen Buchstaben, den du schon getippt hast, kannst du nicht noch einmal verlieren. Leerzeichen und Bindestriche stehen von Anfang an da. Ä, Ö und Ü haben eigene Tasten.",
                geste: .tippen(UnitPoint(x: 0.5 + 0.5 * 42 / 340, y: 0.66))) { p, aktiv in
                let da = !aktiv || p > 0.55
                VStack(spacing: 24) {
                    wort(["B", "_", "L", "L", da ? "O" : "_", "_"], neu: da ? 4 : nil, p: anleitungAbschnitt(p, von: 0.55, bis: 0.9))
                    HStack(spacing: 8) {
                        taste("L", verbraucht: true)
                        taste("M"); taste("N")
                        taste("O", gedrueckt: aktiv && p > 0.4 && p < 0.6)
                        taste("P"); taste("Q")
                    }
                }
            },
            AnleitungSchritt(symbol: "balloon.fill", titel: "Acht Ballons",
                text: "Jeder falsche Buchstabe lässt einen Ballon platzen. Platzt der achte, ist das Wort verloren und die App zeigt es dir. Stehen alle Buchstaben, hast du gewonnen.") { p, aktiv in
                let n = aktiv ? min(3, Int(p * 4.5)) : 3
                VStack(spacing: 28) {
                    ballons(platzt: n)
                    HStack(spacing: 8) {
                        ForEach(Array(["X", "Q", "Z"].enumerated()), id: \.offset) { i, b in
                            taste(b, verbraucht: true).opacity(n > i ? 1 : 0.0)
                        }
                    }
                }
            },
            AnleitungSchritt(symbol: "lightbulb.fill", titel: "Hinweis und Lösen",
                text: "Ein Hinweis deckt einen Buchstaben auf, du wählst einen beliebigen, den ersten oder einen Vokal. Du hast zwei, in „Kinderleicht“ vier. Sie kosten keinen Ballon. Mit „Lösen“ rätst du das ganze Wort. Richtig gewinnt sofort, ein falscher Versuch kostet zwei Ballons.",
                geste: .tippen(UnitPoint(x: 0.68, y: 0.65))) { p, aktiv in
                let da = !aktiv || p > 0.55
                VStack(spacing: 22) {
                    wort(["B", da ? "A" : "_", "L", "L", "O", "_"], neu: da ? 1 : nil, p: anleitungAbschnitt(p, von: 0.55, bis: 0.9))
                    HStack(spacing: 12) {
                        knopf("Lösen", symbol: "text.cursor")
                        knopf("Hinweis", symbol: "lightbulb", gedrueckt: aktiv && p > 0.4 && p < 0.6)
                    }
                }
            },
            AnleitungSchritt(symbol: "person.fill", titel: "Allein spielen",
                text: "Im freien Spiel wählst du Sprache, Thema und Stufe. Das Wort des Tages ist für alle gleich, du hast einen Versuch. Bei „Überleben“ startest du mit drei Leben, die Wörter werden schwerer. Löst du ein Wort fast fehlerfrei und ohne Hinweis, bekommst du ein Leben zurück.", geste: .keine) { p, aktiv in
                buehneSchilder(p, aktiv, party: false)
            },
            AnleitungSchritt(symbol: "person.2.fill", titel: "Party",
                text: "Zu zweit bis zu viert rät reihum einer. Das Wort denkt sich der Nächste aus, während der Rater wegschaut, oder die App zieht eins. Wer rät und gewinnt, bekommt Punkte für jeden übrigen Ballon. Scheitert er, bekommt der Wortgeber drei Punkte. Wer am Ende die meisten hat, gewinnt.", geste: .keine) { p, aktiv in
                buehneSchilder(p, aktiv, party: true)
            },
        ]
    }()
}
#endif
