// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import AppIntents
import CoreSpotlight
import UniformTypeIdentifiers
import SpieleKern

/// E2: Alle Spiele der Sammlung erscheinen in der Spotlight-Suche (Name, Spielart, Herkunft, Stichworte). Tippen öffnet das Spiel.
enum SpielSpotlight {
    private static let domain = "de.philippstach.partie.spiele"
    private static let stand = "partie.spotlight.stand"

    /// Indexiert die Spiele neu, wenn sich der Katalog geändert hat (Anzahl und Version als Stand), sonst nichts.
    /// Welche Spiele in den Index gehören: im Kinder-Modus ohne die gesperrten.
    static func indexIDs(alle: [String], kinder: Bool, gesperrt: Set<String>) -> [String] {
        kinder ? alle.filter { !gesperrt.contains($0) } : alle
    }

    /// Stand des Index: ändert sich mit Version, Anzahl, Sprache und der Auswahl des Kinder-Modus, dann wird neu indexiert.
    static func standSchluessel(version: String, ids: [String], sprache: String) -> String {
        "\(version)-\(ids.count)-\(sprache)-\(ids.sorted().joined(separator: ",").hashValueStabil)"
    }

    /// Beschreibung und Suchwörter eines Spiels (gleich für den klassischen Eintrag und den Eintrag als App-Entität).
    @MainActor
    static func inhalt(_ m: any SpielModul) -> (beschreibung: String, suchwoerter: [String]) {
        let info = SpielMetadaten.info(m.id)
        let beschreibung = [m.gattung.anzeigeName, SpielMetadaten.kurzText(m.id)].filter { !$0.isEmpty }.joined(separator: " · ")
        let woerter = [m.name, m.gattung.anzeigeName, info.land, "Spiel", "Partie"].filter { !$0.isEmpty } + info.stichworte + SpielMetadaten.uebersetzt(m.id, gattung: m.gattung)
        return (beschreibung, woerter)
    }

    /// Ab iOS 18 liegen die Spiele als App-Entitäten im Index (`IndexedEntity`): Siri und Spotlight kennen sie dann als „Spiel“
    /// und können sie in Kurzbefehlen und Apple Intelligence verwenden. Davor bleibt der klassische Eintrag je Spiel.
    static var alsEntitaet: Bool { if #available(iOS 18.0, *) { return true } else { return false } }

    @MainActor
    static func aktualisieren() {
        let erlaubt = Set(indexIDs(alle: SpielKatalog.alle.map(\.id), kinder: Modi.kinder, gesperrt: Modi.gesperrt))
        let module = SpielKatalog.alle.filter { erlaubt.contains($0.id) }
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let neu = standSchluessel(version: version, ids: module.map(\.id), sprache: Locale.current.identifier) + (alsEntitaet ? "-e" : "")
        guard UserDefaults.standard.string(forKey: stand) != neu else { return }
        let index = CSSearchableIndex.default()
        if #available(iOS 18.0, *) {
            let entitaeten = module.map { SpielEntitaet(modul: $0) }
            Task {
                do {
                    try await index.deleteSearchableItems(withDomainIdentifiers: [domain])   // alte klassische Einträge
                    try await index.deleteAppEntities(ofType: SpielEntitaet.self)   // auch gesperrte Spiele des Kinder-Modus verschwinden
                    try await index.indexAppEntities(entitaeten)
                    UserDefaults.standard.set(neu, forKey: stand)
                } catch { /* der nächste Start versucht es noch einmal */ }
            }
            return
        }
        let items: [CSSearchableItem] = module.map { m in
            let i = inhalt(m)
            let attr = CSSearchableItemAttributeSet(contentType: .content)
            attr.title = m.name
            attr.displayName = m.name
            attr.contentDescription = i.beschreibung
            attr.keywords = i.suchwoerter
            let item = CSSearchableItem(uniqueIdentifier: m.id, domainIdentifier: domain, attributeSet: attr)
            item.expirationDate = .distantFuture
            return item
        }
        index.deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in
            index.indexSearchableItems(items) { fehler in
                if fehler == nil { UserDefaults.standard.set(neu, forKey: stand) }
            }
        }
    }

    /// Spiel-ID aus einer Spotlight-Aktivität. Klassische Einträge tragen die ID selbst; bei Einträgen als App-Entität (iOS 18)
    /// kann der Bezeichner zusätzlich ein Präfix tragen, deshalb zählt auch ein Treffer am Ende nach „/“, „:“ oder „.“.
    @MainActor
    static func id(aus aktivitaet: NSUserActivity) -> String? {
        guard let roh = aktivitaet.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return nil }
        return id(ausBezeichner: roh)
    }

    @MainActor
    static func id(ausBezeichner roh: String, bekannt: @MainActor (String) -> Bool = { SpielKatalog.modul($0) != nil }) -> String? {
        if bekannt(roh) { return roh }
        let teile = roh.split(whereSeparator: { "/:.|".contains($0) }).map(String.init)
        for t in teile.reversed() where bekannt(t) { return t }
        return nil
    }
}

private extension String {
    /// Stabile Kurzprüfsumme (anders als `hashValue`, das bei jedem Start wechselt).
    var hashValueStabil: String {
        var h: UInt64 = 1469598103934665603
        for b in utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return String(h, radix: 16)
    }
}

/// Die Spiele als indizierte App-Entitäten (iOS 18): Titel, Beschreibung und Suchwörter wie beim klassischen Eintrag.
@available(iOS 18.0, *)
extension SpielEntitaet: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attr = CSSearchableItemAttributeSet(contentType: .content)
        attr.title = name
        attr.displayName = name
        attr.contentDescription = beschreibung
        attr.keywords = suchwoerter
        return attr
    }
}
