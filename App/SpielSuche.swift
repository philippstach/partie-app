// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import SpieleKern

/// Suche in der Sammlung: Stichwortsuche (immer) und KI-Suche mit Apple Intelligence (auf dem Gerät, falls verfügbar).
@MainActor
enum SpielSuche {
    private static func normiert(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
    }

    /// Trefferliste nach Stichwörtern in Name, Stichworten, Kurztext, Kategorie und Land (beste zuerst).
    static func stichwort(_ text: String, in module: [any SpielModul]) -> [any SpielModul] {
        let tokens = normiert(text).split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 2 }
        guard !tokens.isEmpty else { return module }
        func punkte(_ m: any SpielModul) -> Int {
            let i = SpielMetadaten.info(m.id)
            let name = normiert(m.name), land = normiert(i.land), kurz = normiert(i.kurz), kat = normiert(m.gattung.anzeigeName)
            let st = (i.stichworte + SpielMetadaten.uebersetzt(m.id, gattung: m.gattung)).map(normiert)   // C-005: auch englisch/spanisch/französisch
            var p = 0
            for t in tokens {
                if name.contains(t) { p += 6 }
                if st.contains(where: { $0.contains(t) }) { p += 4 }
                if kat.contains(t) { p += 3 }
                if land.contains(t) { p += 3 }
                if kurz.contains(t) { p += 1 }
            }
            return p
        }
        return module.map { ($0, punkte($0)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.map(\.0)
    }

    /// Ist Apple Intelligence mit dem Sprachmodell bereit?
    static var kiVerfuegbar: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return SystemLanguageModel.default.availability == .available }
        #endif
        return false
    }

    // MARK: KI-Suche

    /// Eine Katalogzeile für die KI, bewusst knapp: Das Apple-Sprachmodell hat nur etwa 4 000 Token Platz, und jedes Token kostet Zeit.
    /// Statt der langen Kurzregel stehen die Stichworte da (Vergleichsnamen wie „Mensch ärgere dich nicht“, „Uno“, „Tetris“ und Stimmung wie „bluffen“).
    /// Normal: `id|Name|Spielart|Land|Spieler|Stichworte`; Wunschmodus zusätzlich Dauer und Anspruch statt Land.
    static func katalogZeile(_ m: any SpielModul, wunsch: Bool) -> String {
        let i = SpielMetadaten.info(m.id)
        let spieler = m.spielerzahl.lowerBound == m.spielerzahl.upperBound ? "\(m.spielerzahl.lowerBound)" : "\(m.spielerzahl.lowerBound)–\(m.spielerzahl.upperBound)"
        let st = i.stichworte.prefix(6).joined(separator: ", ")
        if wunsch {
            return "\(m.id)|\(m.name)|\(m.gattung.anzeigeName)|\(spieler)|\(WasSpielenWirBlatt.minuten(m)) Min.|\(WasSpielenWirBlatt.anspruch(m).rawValue)|\(st)"
        }
        return "\(m.id)|\(m.name)|\(m.gattung.anzeigeName)|\(i.land)|\(spieler)|\(st)"
    }

    private static var katalogCache: [String: String] = [:]
    /// Der Katalogtext ändert sich nur, wenn sich die Spieleliste ändert; deshalb wird er je Liste einmal gebaut.
    static func katalog(_ module: [any SpielModul], wunsch: Bool) -> String {
        let schluessel = (wunsch ? "w:" : "n:") + module.map(\.id).joined(separator: ",")
        if let k = katalogCache[schluessel] { return k }
        let k = module.map { katalogZeile($0, wunsch: wunsch) }.joined(separator: "\n")
        if katalogCache.count > 12 { katalogCache.removeAll() }
        katalogCache[schluessel] = k
        return k
    }

    static func anweisung(katalog: String, wunsch: Bool) -> String {
        if wunsch {
            return """
            Du bist Spieleberater für einen Spieleabend. Die Person beschreibt in eigenen Worten, worauf sie Lust hat (Spielart, Spielerzahl,
            Tempo, wie viel Denken, Stimmung). Wähle ausschließlich Spiele aus dem KATALOG unten
            (Format: id|Name|Spielart|Spieler|Dauer|Anspruch|Stichworte). Die Stichworte nennen bekannte Vergleichsspiele und die Stimmung des Spiels.
            Beachte die Spielerzahl genau: ein Spiel passt nur, wenn die gewünschte Zahl innerhalb seiner Spanne liegt.
            „Nicht schnell“ oder „gemütlich“ heißt eher 20 Minuten oder mehr; „wenig Denken“ heißt Anspruch leicht.
            Gib nur ids zurück, die im Katalog stehen, die besten zuerst, höchstens fünf. Erfinde keine Spiele. Passt nichts, gib eine leere Liste zurück.
            KATALOG:
            \(katalog)
            """
        }
        return """
        Du hilfst, in einer Spielesammlung das passende Spiel zu finden. Wähle ausschließlich Spiele aus dem KATALOG unten
        (Format: id|Name|Spielart|Land|Spieler|Stichworte). Die Stichworte nennen bekannte Vergleichsspiele (etwa „uno“, „tetris“, „mensch ärgere dich nicht“)
        und die Stimmung des Spiels (etwa „bluffen“, „allein“, „kinder“). Die Person nennt ein Spiel, eine Spielart oder beschreibt, worauf sie Lust hat.
        Gib nur ids zurück, die im Katalog stehen, die besten zuerst, höchstens fünf. Erfinde keine Spiele. Passt nichts, gib eine leere Liste zurück.
        KATALOG:
        \(katalog)
        """
    }

    /// Merkt sich fertige KI-Antworten (nur im Arbeitsspeicher): Dieselbe Frage zur selben Spieleliste kommt sofort, ohne das Modell zu fragen.
    private static var antwortCache: [String: [String]] = [:]
    private static var antwortReihenfolge: [String] = []
    private static func cacheSchluessel(_ text: String, _ module: [any SpielModul], _ wunsch: Bool) -> String {
        let t = normiert(text).split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
        return (wunsch ? "w|" : "n|") + t + "|" + module.map(\.id).joined(separator: ",")
    }
    private static func merken(_ schluessel: String, _ ids: [String]) {
        if antwortCache[schluessel] == nil { antwortReihenfolge.append(schluessel) }
        antwortCache[schluessel] = ids
        while antwortReihenfolge.count > 40 { antwortCache[antwortReihenfolge.removeFirst()] = nil }
    }

    /// Wenige gute Kandidaten per Stichwortsuche: Notbehelf, wenn der volle Katalog nicht ins Modell passt.
    static func vorfilter(_ text: String, in module: [any SpielModul], hoechstens: Int = 15) -> [any SpielModul] {
        let treffer = stichwort(text, in: module)
        return treffer.count == module.count ? [] : Array(treffer.prefix(hoechstens))
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static var aufgewaermt: (anweisung: String, session: LanguageModelSession)?
    #endif

    /// Lädt das Sprachmodell schon vor, während die Person noch tippt (sonst dauert die erste Antwort deutlich länger).
    static func aufwaermen(in module: [any SpielModul], wunsch: Bool = false) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else { return }
            let a = anweisung(katalog: katalog(module, wunsch: wunsch), wunsch: wunsch)
            if aufgewaermt?.anweisung == a { return }
            let s = LanguageModelSession(instructions: a)
            s.prewarm()
            aufgewaermt = (a, s)
        }
        #endif
    }

    /// Findet Spiele anhand einer freien Beschreibung („ich will würfeln und bluffen, mit Freunden“). `nil` = KI nicht verfügbar oder fehlgeschlagen.
    /// `wunsch`: Der Text beschreibt eine Stimmung oder Runde („Würfelspiel zu viert, gemütlich, wenig Denken“) statt eines
    /// bestimmten Spiels; der Katalog bekommt dann Dauer und Anspruch, die Anweisung passt dazu.
    /// Schneller als zuvor: knapper Katalog (passt sicher in den Kontext), vorgewärmtes Modell, feste Antwortlänge, gleiche Frage kommt aus dem Zwischenspeicher.
    static func ki(_ beschreibung: String, in module: [any SpielModul], wunsch: Bool = false) async -> [any SpielModul]? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else { return nil }
            let bekannt = Dictionary(module.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            func umsetzen(_ ids: [String]) -> [any SpielModul] {
                var gesehen = Set<String>()
                return ids.compactMap { id in gesehen.insert(id).inserted ? bekannt[id] : nil }
            }
            let schluessel = cacheSchluessel(beschreibung, module, wunsch)
            if let ids = antwortCache[schluessel] { return umsetzen(ids) }
            func fragen(_ liste: [any SpielModul]) async throws -> [String] {
                let a = anweisung(katalog: katalog(liste, wunsch: wunsch), wunsch: wunsch)
                let session: LanguageModelSession
                if let w = aufgewaermt, w.anweisung == a { session = w.session; aufgewaermt = nil } else { session = LanguageModelSession(instructions: a) }
                let antwort = try await session.respond(to: beschreibung, generating: KISpielTreffer.self,
                                                        options: GenerationOptions(sampling: .greedy, maximumResponseTokens: 160))
                return antwort.content.ids
            }
            do {
                let ids = try await fragen(module)
                let r = umsetzen(ids)
                merken(schluessel, r.map(\.id))
                return r
            } catch {
                // Meist „Kontext zu groß“: noch einmal mit wenigen Stichwort-Kandidaten versuchen.
                if Task.isCancelled { return nil }
                let wenige = vorfilter(beschreibung, in: module)
                guard !wenige.isEmpty, wenige.count < module.count else { return nil }
                guard let ids = try? await fragen(wenige) else { return nil }
                let r = umsetzen(ids)
                merken(schluessel, r.map(\.id))
                return r
            }
        }
        #endif
        return nil
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct KISpielTreffer {
    @Guide(description: "Die ids der passenden Spiele aus dem Katalog, das beste zuerst, höchstens fünf", .maximumCount(5))
    var ids: [String]
}
#endif
