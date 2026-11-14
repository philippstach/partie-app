// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import CloudKit
import SpieleKern

/// E7: Ablage der Gerätesicherungen in der privaten CloudKit-Datenbank des Nutzers (kein eigener Server).
/// Je Gerät ein Datensatz „Sicherung“ in der Zone „Partie“; abgefragt wird über die Änderungsliste der Zone, dafür braucht das Schema
/// keine zusätzlichen Indizes. Der Container wird erst beim ersten Zugriff angelegt, also nur, wenn der Nutzer den Abgleich einschaltet.
final class CloudKitSpeicher: AbgleichSpeicher, @unchecked Sendable {
    static let containerKennung = "iCloud.de.philippstach.partie"
    private static let zone = CKRecordZone.ID(zoneName: "Partie", ownerName: CKCurrentUserDefaultName)
    private static let satzTyp = "Sicherung"

    private var container: CKContainer { CKContainer(identifier: Self.containerKennung) }
    private var datenbank: CKDatabase { container.privateCloudDatabase }

    func kontoVerfuegbar() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    func hochladen(geraet: String, daten: Data) async throws {
        _ = try await datenbank.modifyRecordZones(saving: [CKRecordZone(zoneID: Self.zone)], deleting: [])
        let datei = FileManager.default.temporaryDirectory.appendingPathComponent("abgleich-\(geraet).json")
        try daten.write(to: datei, options: .atomic)
        defer { try? FileManager.default.removeItem(at: datei) }
        let satz = CKRecord(recordType: Self.satzTyp, recordID: CKRecord.ID(recordName: geraet, zoneID: Self.zone))
        satz["daten"] = CKAsset(fileURL: datei)
        satz["geaendert"] = Date()
        let ergebnis = try await datenbank.modifyRecords(saving: [satz], deleting: [], savePolicy: .allKeys)
        for (_, r) in ergebnis.saveResults { _ = try r.get() }
    }

    func loeschen(geraet: String) async throws {
        _ = try await datenbank.modifyRecords(saving: [], deleting: [CKRecord.ID(recordName: geraet, zoneID: Self.zone)])
    }

    func laden(ausser geraet: String) async throws -> [Data] {
        var token: CKServerChangeToken?
        var ergebnisse: [Data] = []
        do {
            while true {
                let antwort = try await datenbank.recordZoneChanges(inZoneWith: Self.zone, since: token)
                for (id, r) in antwort.modificationResultsByID where id.recordName != geraet {
                    if let satz = try? r.get().record, let url = (satz["daten"] as? CKAsset)?.fileURL, let d = try? Data(contentsOf: url) { ergebnisse.append(d) }
                }
                token = antwort.changeToken
                if !antwort.moreComing { break }
            }
        } catch let e as CKError where e.code == .zoneNotFound {
            return []   // noch kein anderes Gerät hat etwas abgelegt
        }
        return ergebnisse
    }
}
