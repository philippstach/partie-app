// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(MultipeerConnectivity) && canImport(UIKit)
import MultipeerConnectivity
import UIKit

/// Ein Gerät, das der Scanner in der Nähe gefunden hat. Erkannt wird es an seiner eigenen Kennung (aus `discoveryInfo`),
/// nicht am Anzeigenamen: Zwei Geräte, die beide „iPad“ heißen, bleiben so zwei Einträge.
public struct FunkFund: Identifiable, Equatable {
    /// Kennung des Geräts; bei älteren Builds ohne Kennung der Anzeigename.
    public let id: String
    public let name: String
    /// `nil` bei älteren Builds (Fassung 1).
    public let kennung: String?
    /// Protokollfassung laut `discoveryInfo` (1 bei älteren Builds).
    public let version: Int
    public internal(set) var bekannt: Bool
    let peer: MCPeerID
}

/// Die Leitung selbst (MultipeerConnectivity): kein Server, kein Konto, verschlüsselt. Sie entscheidet nichts,
/// sondern meldet nur, was passiert. Entscheidungen (zusagen, wiederverbinden, Puls) trifft die `FunkZentrale`.
///
/// - Die eigene `MCPeerID` wird gespeichert und bei jedem Start wiederverwendet (keine Geister-Einträge).
/// - Für jeden Verbindungsversuch gibt es eine frische `MCSession`. Meldungen alter Sitzungen werden verworfen.
/// - Das Spielgerät trägt seine Kennung und die Protokollfassung in `discoveryInfo` ein.
@MainActor
final class FunkVerbindung: NSObject {
    enum Ereignis {
        case gefunden(FunkFund)
        case verloren(MCPeerID)
        case einladung(von: MCPeerID, kontext: Data?, antwort: (Bool) -> Void)
        case verbindet(MCPeerID)
        case verbunden(MCPeerID)
        case getrennt(MCPeerID)
        case daten(Data, von: MCPeerID)
        case funkGeht(Bool)
    }

    static let dienst = "partie-wuerfel"
    static let infoKennung = "k"
    static let infoVersion = "v"

    var ereignis: ((Ereignis) -> Void)?
    let ich: MCPeerID
    let kennung: String
    private(set) var sitzung: MCSession?
    private var werbung: MCNearbyServiceAdvertiser?
    private var suche: MCNearbyServiceBrowser?

    init(kennung: String) {
        self.kennung = kennung
        ich = Self.eigenerPeer()
        super.init()
    }

    var sucht: Bool { suche != nil }
    var wirbt: Bool { werbung != nil }

    // MARK: Sichtbar machen und suchen

    /// Spielgerät: sichtbar machen. Ein laufendes Werben wird neu gestartet (hilft nach dem Zurückkehren aus dem Hintergrund).
    func werben() {
        werbung?.stopAdvertisingPeer()
        let info = [Self.infoKennung: kennung, Self.infoVersion: String(FunkProtokoll.version)]
        let w = MCNearbyServiceAdvertiser(peer: ich, discoveryInfo: info, serviceType: Self.dienst)
        w.delegate = self
        w.startAdvertisingPeer()
        werbung = w
    }

    func werbenBeenden() { werbung?.stopAdvertisingPeer(); werbung?.delegate = nil; werbung = nil }

    /// Scanner: suchen. Ein laufendes Suchen wird neu gestartet; danach melden sich alle Geräte in der Nähe frisch.
    func suchen() {
        suche?.stopBrowsingForPeers()
        let s = MCNearbyServiceBrowser(peer: ich, serviceType: Self.dienst)
        s.delegate = self
        s.startBrowsingForPeers()
        suche = s
    }

    func suchenBeenden() { suche?.stopBrowsingForPeers(); suche?.delegate = nil; suche = nil }

    // MARK: Sitzungen

    /// Legt für einen neuen Versuch eine frische Sitzung an und beendet die alte.
    @discardableResult
    func neueSitzung() -> MCSession {
        trennen()
        let s = MCSession(peer: ich, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        sitzung = s
        return s
    }

    func trennen() {
        sitzung?.delegate = nil
        sitzung?.disconnect()
        sitzung = nil
    }

    /// Scanner: lädt ein Spielgerät in eine frische Sitzung ein. `kontext` ist das `hallo` des Scanners.
    func lade(_ peer: MCPeerID, kontext: Data?, timeout: TimeInterval) {
        guard let suche else { return }
        let s = neueSitzung()
        suche.invitePeer(peer, to: s, withContext: kontext, timeout: timeout)
    }

    var verbundenePeers: [MCPeerID] { sitzung?.connectedPeers ?? [] }

    @discardableResult
    func sende(_ daten: Data, zuverlaessig: Bool = true) -> Bool {
        guard let sitzung, !sitzung.connectedPeers.isEmpty else { return false }
        do {
            try sitzung.send(daten, toPeers: sitzung.connectedPeers, with: zuverlaessig ? .reliable : .unreliable)
            return true
        } catch {
            return false
        }
    }

    func allesBeenden() { werbenBeenden(); suchenBeenden(); trennen() }

    // MARK: Gespeicherte Kennung

    private static let peerSchluessel = "wuerfelFunk.peerID"
    private static let peerNameSchluessel = "wuerfelFunk.peerName"

    /// Dieselbe `MCPeerID` wie beim letzten Start, solange der Gerätename gleich bleibt. Apple rät dazu,
    /// weil neu erzeugte IDs bei den anderen Geräten als zusätzliche Einträge auftauchen und Einladungen hängen lassen.
    static func eigenerPeer(_ d: UserDefaults = .standard) -> MCPeerID {
        let roh = String(UIDevice.current.name.prefix(40))
        let name = roh.isEmpty ? "Partie" : roh
        if d.string(forKey: peerNameSchluessel) == name, let daten = d.data(forKey: peerSchluessel),
           let p = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: daten) {
            return p
        }
        let p = MCPeerID(displayName: name)
        if let daten = try? NSKeyedArchiver.archivedData(withRootObject: p, requiringSecureCoding: true) {
            d.set(daten, forKey: peerSchluessel)
            d.set(name, forKey: peerNameSchluessel)
        }
        return p
    }

    // MARK: Meldungen

    fileprivate func melde(_ e: Ereignis) { ereignis?(e) }

    /// Meldungen einer Sitzung zählen nur, solange sie die aktuelle ist.
    fileprivate func istAktuell(_ s: MCSession) -> Bool { s === sitzung }
}

extension FunkVerbindung: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            guard self.istAktuell(session) else { return }
            switch state {
            case .connecting: self.melde(.verbindet(peerID))
            case .connected: self.melde(.verbunden(peerID))
            case .notConnected: self.melde(.getrennt(peerID))
            @unknown default: break
            }
        }
    }
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard self.istAktuell(session) else { return }
            self.melde(.daten(data, von: peerID))
        }
    }
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    /// Ohne eigene Zertifikate: jedes Zertifikat annehmen (Verschlüsselung bleibt an). Ohne diese Methode hängt die Verbindung bei manchen iOS-Fassungen.
    nonisolated func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

extension FunkVerbindung: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            var beantwortet = false
            self.melde(.einladung(von: peerID, kontext: context) { ja in
                guard !beantwortet else { return }
                beantwortet = true
                invitationHandler(ja, ja ? self.neueSitzung() : nil)
            })
        }
    }
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in self.melde(.funkGeht(false)) }
    }
}

extension FunkVerbindung: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let kennung = info?[FunkVerbindung.infoKennung]
        let version = info?[FunkVerbindung.infoVersion].flatMap(Int.init) ?? 1
        Task { @MainActor in
            guard peerID != self.ich else { return }
            self.melde(.funkGeht(true))
            self.melde(.gefunden(FunkFund(id: kennung ?? peerID.displayName, name: peerID.displayName, kennung: kennung, version: version, bekannt: false, peer: peerID)))
        }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in self.melde(.verloren(peerID)) }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in self.melde(.funkGeht(false)) }
    }
}
#endif
