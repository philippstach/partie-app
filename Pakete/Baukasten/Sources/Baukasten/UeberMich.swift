// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// Inhalt von „Über mich“. Kommt einmal zentral von Philipp; bis dahin ist `UeberMichInhalt.philipp` nil,
/// und der Eintrag erscheint nirgends (kein Platzhaltertext in einer eingereichten App).
public struct UeberMichInhalt: Sendable {
    public let name: String
    public let texte: [String: String]    // Sprachcode → Klartext (de, en, es, fr); Rückfall en
    public let kontaktMail: String?
    public let webseite: URL?

    public init(name: String, texte: [String: String], kontaktMail: String? = nil, webseite: URL? = nil) {
        self.name = name; self.texte = texte; self.kontaktMail = kontaktMail; self.webseite = webseite
    }

    public init(name: String, text: String, kontaktMail: String? = nil, webseite: URL? = nil) {
        self.init(name: name, texte: ["en": text], kontaktMail: kontaktMail, webseite: webseite)
    }

    public func text(sprache: String = Locale.current.language.languageCode?.identifier ?? "en") -> String {
        texte[sprache] ?? texte["en"] ?? ""
    }

    public var istVollstaendig: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && ["de", "en", "es", "fr"].allSatisfy { (texte[$0] ?? "").count >= 40 }
    }

    /// Text von Claude geschrieben, von Philipp am 03.11.2026 freigegeben. `freigegeben = false` blendet ihn überall aus.
    public static let freigegeben = true
    public static var philipp: UeberMichInhalt? { freigegeben ? entwurf : nil }

    public static let entwurf = UeberMichInhalt(name: "Philipp Stach", texte: [
        "de": """
        Hallo, ich bin Philipp. Ich entwickle Spiele-Apps in Deutschland: Klassiker wie Sudoku, Würfel- und Kartenspiele, die man einfach öffnen und spielen kann.

        Alle meine Apps sind ruhig gestaltet, haben keine Fremdwerbung und kein Tracking und brauchen kein Konto. Deine Spielstände bleiben auf deinem Gerät.

        Mich hat die Werbung und das Tracking in all den kleinen Mini-Apps einfach gestört. Deshalb mache ich es anders, und es macht mir Spaß, kostenlose Spiele für alle zur Verfügung zu stellen.

        Der Quelltext meiner Apps ist offen: Du kannst ihn auf GitHub lesen, prüfen und verbessern.

        Fehler gefunden oder eine Idee? Über „Hilfe & Support“ kannst du mir schreiben. Ich freue mich über jede Rückmeldung.
        """,
        "en": """
        Hi, I'm Philipp. I make game apps in Germany: classics like sudoku, dice and card games that you can simply open and play.

        All my apps have a calm design, no third-party ads, no tracking, and need no account. Your progress stays on your device.

        The ads and tracking in all those little mini apps simply bothered me. So I do it differently, and I enjoy making free games available for everyone.

        The source code of my apps is open: you can read, check and improve it on GitHub.

        Found a bug or have an idea? You can write to me via "Help & support". I'm happy about every piece of feedback.
        """,
        "es": """
        Hola, soy Philipp. Desarrollo apps de juegos en Alemania: clásicos como sudoku, juegos de dados y de cartas que simplemente abres y juegas.

        Todas mis apps tienen un diseño tranquilo, no tienen publicidad de terceros ni rastreo y no necesitan cuenta. Tu progreso se queda en tu dispositivo.

        Me molestaban la publicidad y el rastreo en todas esas miniapps. Por eso lo hago de otra manera, y disfruto ofreciendo juegos gratuitos para todos.

        El código fuente de mis apps es abierto: puedes leerlo, revisarlo y mejorarlo en GitHub.

        ¿Has encontrado un error o tienes una idea? Puedes escribirme desde «Ayuda y soporte». Agradezco cada comentario.
        """,
        "fr": """
        Bonjour, je suis Philipp. Je crée des applications de jeux en Allemagne : des classiques comme le sudoku, des jeux de dés et de cartes que l'on ouvre et auxquels on joue simplement.

        Toutes mes applications ont un design calme, aucune publicité de tiers, aucun suivi, et ne demandent pas de compte. Tes parties restent sur ton appareil.

        La publicité et le suivi dans toutes ces petites applications m'ont simplement dérangé. Alors je fais autrement, et j'ai plaisir à proposer des jeux gratuits pour tous.

        Le code source de mes applications est ouvert : tu peux le lire, le vérifier et l'améliorer sur GitHub.

        Un bug ou une idée ? Tu peux m'écrire via « Aide et assistance ». Chaque retour me fait plaisir.
        """,
    ])
}

public struct UeberMichZeile: View {
    let inhalt: UeberMichInhalt
    public init?(_ inhalt: UeberMichInhalt?) {
        guard let inhalt, inhalt.istVollstaendig else { return nil }
        self.inhalt = inhalt
    }

    public var body: some View {
        NavigationLink {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(inhalt.name).font(.title.bold())
                    Text(inhalt.text())
                    if let mail = inhalt.kontaktMail, let url = URL(string: "mailto:\(mail)") {
                        Link(destination: url) { Label { Text("Kontakt", bundle: .module) } icon: { Image(systemName: "envelope") } }
                    }
                    if let web = inhalt.webseite {
                        Link(destination: web) { Label { Text("Webseite", bundle: .module) } icon: { Image(systemName: "safari") } }
                    }
                }
                .padding()
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(Text("Über mich", bundle: .module))
        } label: {
            Text("Über mich", bundle: .module)
        }
    }
}
