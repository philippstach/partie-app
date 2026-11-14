// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(MultipeerConnectivity) && canImport(UIKit)
import MultipeerConnectivity
import Observation
import UIKit

/// Eine Funkverbindung für die ganze App (Würfelscanner ↔ Spielgerät). Sie gehört keiner Seite: Seiten starten sie,
/// zeigen ihren Zustand und melden sich als Empfänger an, beenden sie aber nicht beim Schließen.
///
/// - Einmal koppeln, danach von selbst: Beide Geräte merken sich das Gegenüber als „bekanntes Gerät“ (zufällige Kennung).
///   Bekannte Geräte verbinden sich ohne Rückfrage; der Scanner lädt sie von selbst ein, sobald er sie sieht.
/// - Wiederverbinden: Nach einem Abbruch versucht es der Scanner nach 1, 2, 4, 8 … Sekunden wieder, höchstens zwei Minuten,
///   mit frischer Sitzung je Versuch. Beim Zurückkehren in die App sofort.
/// - Zweiwege-Protokoll (Fassung 2): `hallo`, `lage`, `quittung`, `wurf`, `stand`, `puls`, `tschuess`.
///   Drei verpasste Pulse heißen „unterbrochen“. Unbekannte Nachrichten werden überlesen.
/// - Übertragen werden nur Augen und Spielstand, nie Bilder.
@MainActor @Observable
public final class FunkZentrale {
    public typealias Rolle = FunkHallo.Rolle

    /// Die eine Zentrale der App.
    public static let shared = FunkZentrale()

    /// Wie lange eine Einladung offen bleibt.
    public static let einladungsDauer: TimeInterval = 30
    /// So lange wird ein Wurf aufgehoben, der ankam, als gerade kein Spiel bereit war.
    public static let wartenderWurfDauer: TimeInterval = 30

    /// Eine Anfrage eines unbekannten Scanners am Spielgerät. Sie gilt, bis zugesagt, abgelehnt oder die Einladung abgelaufen ist.
    public struct Anfrage: Identifiable {
        public let id = UUID()
        public let name: String
        public let kennung: String?
        fileprivate let antwort: (Bool) -> Void
        public func zusagen() { antwort(true) }
        public func ablehnen() { antwort(false) }
    }

    // MARK: Zustand (zum Anzeigen)

    /// `nil`: Funk ist aus.
    public private(set) var rolle: Rolle?
    public private(set) var zustand: FunkZustand = .aus
    /// Scanner: Spielgeräte in der Nähe.
    public private(set) var gefunden: [FunkFund] = []
    /// Spielgerät: offene Anfrage eines unbekannten Scanners.
    public private(set) var anfrage: Anfrage?
    public private(set) var bekannte: [BekanntesGeraet] = []
    /// Kennung des verbundenen (oder zuletzt verbundenen) Gegenübers.
    public private(set) var gegenueberKennung: String?
    /// Fassung des Protokolls beim Gegenüber (1, solange kein `hallo` kam).
    public private(set) var gegenueberVersion = 1
    /// `false`, wenn Suchen oder Sichtbarmachen nicht starten konnte (lokales Netzwerk verweigert, WLAN/Bluetooth aus).
    public private(set) var funkGeht = true
    /// Seit wann gesucht wird, ohne etwas zu finden (für den Hinweis „Beide Geräte brauchen WLAN oder Bluetooth“).
    public private(set) var suchtSeit: Date?

    /// Scanner: zuletzt gemeldete Lage des Spielgeräts.
    public private(set) var lage: FunkLage?
    /// Scanner: zuletzt angekommene Quittung.
    public private(set) var letzteQuittung: FunkQuittung?
    /// Scanner: Würfe, die noch keine Quittung haben.
    public var offeneWuerfe: Int { ausgang.offen.count }
    /// Scanner: so viele Würfe wurden in dieser Verbindung geschickt.
    public private(set) var gesendet = 0

    /// Spielgerät: was der Scanner gerade sieht.
    public private(set) var stand: FunkStand?
    /// Spielgerät: Augen des letzten angekommenen Wurfs.
    public private(set) var letzterWurf: [Int]?
    /// Bildausschnitte des zuletzt angekommenen Wurfs (gleiche Reihenfolge wie `letzterWurf`; leer, wenn der Scanner keine mitschickt).
    public private(set) var letzteBilder: [Data] = []
    /// Spielgerät: `true`, solange ein Spiel als Empfänger angemeldet ist.
    public var hatEmpfaenger: Bool { !empfaenger.isEmpty }

    // MARK: Innen

    @ObservationIgnored private var leitung: FunkVerbindung?
    private let speicher: UserDefaults
    private let eigeneKennung: String
    @ObservationIgnored private var bekannteListe: BekannteGeraete
    @ObservationIgnored private var empfang = WurfEmpfang()
    @ObservationIgnored private var ausgang = WurfAusgang()
    @ObservationIgnored private var waechter = PulsWaechter()
    @ObservationIgnored private var plan = WiederverbindePlan()
    @ObservationIgnored private var pulsAufgabe: Task<Void, Never>?
    @ObservationIgnored private var wiederAufgabe: Task<Void, Never>?
    @ObservationIgnored private var einladungsAufgabe: Task<Void, Never>?
    @ObservationIgnored private var anfrageAufgabe: Task<Void, Never>?
    /// Peer, mit dem gerade verbunden ist oder eingeladen wurde.
    @ObservationIgnored private var aktuellerPeer: MCPeerID?
    @ObservationIgnored private var gegenueberName: String?
    /// Am Spielgerät: Kennung aus dem `hallo` der Einladung, je Peer.
    @ObservationIgnored private var einladungsHallo: [MCPeerID: FunkHallo] = [:]
    /// Kennungen, die von Hand getrennt wurden: Kein automatisches Einladen, bis der Nutzer sie selbst wieder wählt.
    @ObservationIgnored private var vonHandGetrennt: Set<String> = []
    @ObservationIgnored private var eingeladenUm: Date?
    @ObservationIgnored private var empfaenger: [(id: UUID, handler: ([Int]) -> Void)] = []
    @ObservationIgnored private var wartenderWurf: (augen: [Int], bilder: [Data], um: Date)?
    @ObservationIgnored private var eigeneLage = FunkLage(bereit: false)
    @ObservationIgnored private var beobachter: [NSObjectProtocol] = []
    @ObservationIgnored private var imHintergrund = false

    init(speicher: UserDefaults = .standard) {
        self.speicher = speicher
        eigeneKennung = EigeneKennung.lesen(speicher)
        bekannteListe = BekannteGeraete.laden(speicher)
        bekannte = bekannteListe.liste
        beobachteApp()
    }

    // MARK: Starten und beenden

    /// Startet den Funk in einer Rolle. Läuft er schon in dieser Rolle, passiert nichts; in der anderen Rolle wird vorher beendet.
    public func starten(als neueRolle: Rolle) {
        if rolle == neueRolle, leitung != nil { return }
        if rolle != nil { beenden() }
        rolle = neueRolle
        let l = FunkVerbindung(kennung: eigeneKennung)
        l.ereignis = { [weak self] e in self?.verarbeite(e) }
        leitung = l
        funkGeht = true
        zustand = .sucht
        suchtSeit = Date()
        switch neueRolle {
        case .spielgeraet: l.werben()
        case .scanner: l.suchen()
        }
        pulsStarten()
    }

    /// Beendet den Funk ganz (Abschied ans Gegenüber, kein Wiederverbinden).
    public func beenden() {
        sende(.tschuess)
        pulsAufgabe?.cancel(); pulsAufgabe = nil
        wiederAufgabe?.cancel(); wiederAufgabe = nil
        einladungsAufgabe?.cancel(); einladungsAufgabe = nil
        anfrageAufgabe?.cancel(); anfrageAufgabe = nil
        anfrage?.ablehnen()
        leitung?.ereignis = nil
        leitung?.allesBeenden()
        leitung = nil
        rolle = nil
        zustand = .aus
        gefunden = []; anfrage = nil; aktuellerPeer = nil; gegenueberName = nil; gegenueberKennung = nil; gegenueberVersion = 1
        einladungsHallo = [:]; lage = nil; stand = nil; letzteQuittung = nil; gesendet = 0
        ausgang.leeren(); waechter.zuruecksetzen(); plan.zuruecksetzen(); suchtSeit = nil
    }

    /// Trennt auf Wunsch des Nutzers. Der Funk läuft weiter, das Gegenüber wird aber nicht von selbst wieder eingeladen.
    public func trennen() {
        if let k = gegenueberKennung { vonHandGetrennt.insert(k) }
        sende(.tschuess)
        wiederAufgabe?.cancel(); wiederAufgabe = nil
        einladungsAufgabe?.cancel(); einladungsAufgabe = nil
        leitung?.trennen()
        let name = gegenueberName
        verbindungWeg()
        zustand = .getrennt(name: name, grund: .vonHand)
        neuSuchen()
    }

    // MARK: Scanner

    /// Scanner: Spielgerät einladen. Bekannte Spielgeräte sagen von selbst zu, unbekannte fragen nach.
    public func verbinde(mit fund: FunkFund) {
        guard rolle == .scanner, let leitung else { return }
        if let k = fund.kennung { vonHandGetrennt.remove(k) }
        wiederAufgabe?.cancel(); wiederAufgabe = nil
        plan.zuruecksetzen()
        einladen(fund, leitung: leitung)
    }

    /// Scanner: Wurf schicken. Er bleibt aufgehoben, bis das Spielgerät ihn quittiert, und geht nach dem Wiederverbinden nochmal raus.
    public func sende(_ wurf: FunkWurf) {
        guard rolle == .scanner else { return }
        ausgang.gesendet(wurf)
        gesendet += 1
        sende(.wurf(wurf))
    }

    /// Scanner: was die Kamera gerade sieht. Unzuverlässig verschickt, weil es oft kommt und nur der neueste Stand zählt.
    public func sendeStand(_ s: FunkStand) {
        guard rolle == .scanner else { return }
        sende(.stand(s), zuverlaessig: false)
    }

    // MARK: Spielgerät

    /// Spielgerät: meldet sich als Empfänger für Würfe an. Der zuletzt angemeldete bekommt die Würfe.
    /// Kam kurz vorher ein Wurf an, als niemand bereit war, bekommt ihn der neue Empfänger sofort.
    public func empfangeWuerfe(_ id: UUID, _ handler: @escaping ([Int]) -> Void) {
        empfaenger.removeAll { $0.id == id }
        empfaenger.append((id, handler))
        if let w = wartenderWurf, Date().timeIntervalSince(w.um) <= FunkZentrale.wartenderWurfDauer {
            // Erst nach dem Erscheinen der Seite ausliefern, sonst schließt ein Blatt schon während es aufgeht.
            Task { @MainActor [weak self] in
                guard let self, self.empfaenger.last?.id == id else { return }
                self.letzteBilder = w.bilder
                handler(w.augen)
            }
        }
        wartenderWurf = nil
        lageGeaendert()
    }

    /// Spielgerät: Empfänger abmelden (z. B. wenn ein Blatt schließt). Die Verbindung bleibt.
    public func beendeEmpfang(_ id: UUID) {
        empfaenger.removeAll { $0.id == id }
        lageGeaendert()
    }

    /// Spielgerät: Spielname, wer dran ist und wie viele Würfel erwartet werden. Geht sofort und nach jedem Verbinden an den Scanner.
    public func meldeLage(_ l: FunkLage) {
        eigeneLage = l
        lageGeaendert()
    }

    // MARK: Bekannte Geräte

    public func vergiss(_ kennung: String) {
        bekannteListe.vergiss(kennung)
        bekannteGesichert()
        if gegenueberKennung == kennung { trennen() }
    }

    public func vergissAlle() {
        bekannteListe.vergissAlle()
        bekannteGesichert()
    }

    // MARK: Ereignisse der Leitung

    private func verarbeite(_ e: FunkVerbindung.Ereignis) {
        switch e {
        case .funkGeht(let geht):
            funkGeht = geht
        case .gefunden(var f):
            f.bekannt = bekannteListe.kennt(f.kennung)
            gefunden.removeAll { $0.id == f.id || $0.peer == f.peer }
            gefunden.append(f)
            suchtSeit = nil
            vielleichtVonSelbstEinladen(f)
        case .verloren(let p):
            gefunden.removeAll { $0.peer == p }
        case .einladung(let von, let kontext, let antwort):
            einladungBekommen(von: von, kontext: kontext, antwort: antwort)
        case .verbindet:
            break
        case .verbunden(let p):
            verbunden(mit: p)
        case .getrennt(let p):
            getrennt(von: p)
        case .daten(let d, _):
            angekommen(d)
        }
    }

    private func verbunden(mit p: MCPeerID) {
        einladungsAufgabe?.cancel(); einladungsAufgabe = nil
        wiederAufgabe?.cancel(); wiederAufgabe = nil
        plan.zuruecksetzen()
        aktuellerPeer = p
        gegenueberVersion = 1
        if let h = einladungsHallo[p] { gegenueberKennung = h.kennung; gegenueberVersion = h.version }
        if rolle == .scanner, let f = gefunden.first(where: { $0.peer == p }) {
            if let k = f.kennung { gegenueberKennung = k }
            gegenueberVersion = f.version
        }
        gegenueberName = p.displayName
        if let k = gegenueberKennung { bekannteListe.merke(kennung: k, name: p.displayName); bekannteGesichert(); vonHandGetrennt.remove(k) }
        waechter.lebenszeichen()
        zustand = .verbunden(name: p.displayName)
        suchtSeit = nil
        // Erst vorstellen, dann je nach Rolle die Lage schicken oder liegengebliebene Würfe nachreichen.
        sende(.hallo(FunkHallo(kennung: eigeneKennung, name: leitung?.ich.displayName ?? "", rolle: rolle ?? .scanner)))
        if rolle == .spielgeraet { sende(.lage(aktuelleLage)) }
        if rolle == .scanner { for w in ausgang.offen { sende(.wurf(w)) } }
        empfang.neueVerbindung()
    }

    private func getrennt(von p: MCPeerID) {
        // Eine Einladung ist gescheitert (abgelehnt oder abgelaufen).
        if case .wartetAufZusage(let name) = zustand {
            einladungsAufgabe?.cancel(); einladungsAufgabe = nil
            let schnell = eingeladenUm.map { Date().timeIntervalSince($0) < FunkZentrale.einladungsDauer - 2 } ?? false
            if plan.laeuft { wiederverbinden(name: name); return }
            leitung?.trennen()
            zustand = .getrennt(name: name, grund: schnell ? .abgelehnt : .keineAntwort)
            aktuellerPeer = nil
            return
        }
        guard p == aktuellerPeer else { return }
        abgerissen()
    }

    /// Die Verbindung ist ohne Absicht weg (Funkloch, Hintergrund, Puls ausgeblieben).
    private func abgerissen() {
        let name = gegenueberName ?? aktuellerPeer?.displayName ?? ""
        einladungsAufgabe?.cancel(); einladungsAufgabe = nil
        leitung?.trennen()
        waechter.zuruecksetzen()
        switch rolle {
        case .scanner:
            wiederverbinden(name: name)
        case .spielgeraet:
            // Das Spielgerät bleibt sichtbar; der Scanner meldet sich von selbst wieder und wird als bekanntes Gerät ohne Rückfrage angenommen.
            zustand = .unterbrochen(name: name, versuch: 0)
            leitung?.werben()
            warteAufScanner(name: name)
        case nil:
            break
        }
    }

    /// Bei Absicht (Trennen, Tschüss) oder nach dem Aufgeben: alles zum Gegenüber vergessen außer der Liste der bekannten Geräte.
    private func verbindungWeg() {
        aktuellerPeer = nil
        waechter.zuruecksetzen()
        lage = nil; stand = nil
        ausgang.leeren()
        gesendet = 0
    }

    private func angekommen(_ daten: Data) {
        guard let n = FunkNachricht.lies(daten) else { return }
        waechter.lebenszeichen()
        switch n {
        case .hallo(let h):
            gegenueberKennung = h.kennung
            gegenueberName = h.name.isEmpty ? gegenueberName : h.name
            gegenueberVersion = h.version
            bekannteListe.merke(kennung: h.kennung, name: gegenueberName ?? h.name)
            bekannteGesichert()
        case .wurf(let w):
            guard rolle == .spielgeraet else { return }
            wurfAngekommen(w)
        case .quittung(let q):
            guard rolle == .scanner else { return }
            ausgang.quittiert(q)
            letzteQuittung = q
        case .lage(let l):
            guard rolle == .scanner else { return }
            lage = l
        case .stand(let s):
            guard rolle == .spielgeraet else { return }
            stand = s
        case .tschuess:
            if let k = gegenueberKennung { vonHandGetrennt.insert(k) }
            let name = gegenueberName
            wiederAufgabe?.cancel(); wiederAufgabe = nil
            leitung?.trennen()
            verbindungWeg()
            zustand = .getrennt(name: name, grund: .vomGegenueber)
            neuSuchen()
        case .puls, .unbekannt:
            break
        }
    }

    private func wurfAngekommen(_ w: FunkWurf) {
        // Fassung 1 kennt keine Quittung; dann wird keine geschickt.
        let quittieren = gegenueberVersion >= 2
        switch empfang.pruefe(w) {
        case .neu(let augen):
            letzterWurf = augen
            letzteBilder = w.bilder ?? []
            if let ziel = empfaenger.last {
                ziel.handler(augen)
                if quittieren { sende(.quittung(FunkQuittung(folge: w.folge, lauf: w.lauf, grund: .angenommen))) }
            } else {
                wartenderWurf = (augen, w.bilder ?? [], Date())
                if quittieren { sende(.quittung(FunkQuittung(folge: w.folge, lauf: w.lauf, grund: .keinEmpfaenger))) }
            }
        case .doppelt:
            if quittieren { sende(.quittung(FunkQuittung(folge: w.folge, lauf: w.lauf, grund: .doppelt))) }
        case .ungueltig:
            if quittieren { sende(.quittung(FunkQuittung(folge: w.folge, lauf: w.lauf, grund: .ungueltig))) }
        }
    }

    // MARK: Einladen und Zusagen

    private func einladen(_ f: FunkFund, leitung: FunkVerbindung) {
        let hallo = FunkNachricht.hallo(FunkHallo(kennung: eigeneKennung, name: leitung.ich.displayName, rolle: .scanner)).kodiert()
        aktuellerPeer = f.peer
        gegenueberName = f.name
        if let k = f.kennung { gegenueberKennung = k }
        eingeladenUm = Date()
        if !plan.laeuft { zustand = .wartetAufZusage(name: f.name) }
        leitung.lade(f.peer, kontext: hallo, timeout: FunkZentrale.einladungsDauer)
        // Sicherheitsnetz: Meldet MultipeerConnectivity nach Ablauf nichts, gilt die Einladung als gescheitert.
        einladungsAufgabe?.cancel()
        let peer = f.peer
        einladungsAufgabe = Task { [weak self] in
            try? await Task.sleep(for: .seconds(FunkZentrale.einladungsDauer + 3))
            guard !Task.isCancelled, let self, self.aktuellerPeer == peer, !self.zustand.istVerbunden else { return }
            self.getrennt(von: peer)
        }
    }

    /// Scanner: Ein bekanntes Spielgerät taucht auf. Ohne Verbindung (oder beim Wiederverbinden) wird es von selbst eingeladen.
    private func vielleichtVonSelbstEinladen(_ f: FunkFund) {
        guard rolle == .scanner, let leitung, f.bekannt, let k = f.kennung, !vonHandGetrennt.contains(k) else { return }
        switch zustand {
        case .sucht, .getrennt:
            // Mehrere bekannte Geräte gleichzeitig: Das zuletzt benutzte gewinnt, die anderen erscheinen nur in der Liste.
            let besterBekannter = bekannteListe.liste.first { b in gefunden.contains { $0.kennung == b.kennung } }
            guard besterBekannter?.kennung == k else { return }
            plan.zuruecksetzen()
            einladen(f, leitung: leitung)
        case .unterbrochen:
            // Das gesuchte Gerät ist wieder da: nicht auf den nächsten Takt warten.
            guard k == gegenueberKennung, wiederAufgabe != nil else { return }
            wiederAufgabe?.cancel(); wiederAufgabe = nil
            einladen(f, leitung: leitung)
        case .aus, .wartetAufZusage, .verbunden:
            break
        }
    }

    private func einladungBekommen(von peer: MCPeerID, kontext: Data?, antwort: @escaping (Bool) -> Void) {
        guard rolle == .spielgeraet else { antwort(false); return }
        var hallo: FunkHallo?
        if let kontext, case .hallo(let h)? = FunkNachricht.lies(kontext) { hallo = h }
        if let hallo { einladungsHallo[peer] = hallo }
        // Bekannter Scanner: ohne Rückfrage annehmen (auch beim Wiederverbinden).
        if let hallo, hallo.rolle == .scanner, bekannteListe.kennt(hallo.kennung) {
            anfrage = nil
            wiederAufgabe?.cancel(); wiederAufgabe = nil
            antwort(true)
            return
        }
        // Unbekannt: nachfragen. Eine ältere offene Anfrage wird abgelehnt.
        anfrage?.ablehnen()
        let name = hallo.map(\.name).flatMap { $0.isEmpty ? nil : $0 } ?? peer.displayName
        let a = Anfrage(name: name, kennung: hallo?.kennung) { [weak self] ja in
            antwort(ja)
            self?.anfrage = nil
            self?.anfrageAufgabe?.cancel()
        }
        anfrage = a
        anfrageAufgabe?.cancel()
        let id = a.id
        anfrageAufgabe = Task { [weak self] in
            try? await Task.sleep(for: .seconds(FunkZentrale.einladungsDauer))
            guard !Task.isCancelled, let self, self.anfrage?.id == id else { return }
            self.anfrage?.ablehnen()
        }
    }

    // MARK: Wiederverbinden

    private func wiederverbinden(name: String) {
        guard rolle == .scanner else { return }
        guard let warten = plan.naechsteWartezeit() else {
            // Aufgegeben: Verbindung gilt als getrennt, Suche läuft weiter. Taucht das Gerät wieder auf, wird es von selbst eingeladen.
            plan.zuruecksetzen()
            verbindungWeg()
            zustand = .getrennt(name: name, grund: .aufgegeben)
            neuSuchen()
            return
        }
        zustand = .unterbrochen(name: name, versuch: plan.versuch)
        wiederAufgabe?.cancel()
        let kennung = gegenueberKennung
        let altName = gegenueberName
        wiederAufgabe = Task { [weak self] in
            try? await Task.sleep(for: .seconds(warten))
            guard !Task.isCancelled, let self, let leitung = self.leitung else { return }
            self.wiederAufgabe = nil
            if let f = self.gefunden.first(where: { ($0.kennung != nil && $0.kennung == kennung) || (kennung == nil && $0.name == altName) }) {
                self.einladen(f, leitung: leitung)
            } else {
                // Noch nicht wieder gesehen: Suche neu anstoßen und beim nächsten Takt nochmal schauen.
                self.gefunden = []
                leitung.suchen()
                self.wiederverbinden(name: name)
            }
        }
    }

    /// Spielgerät: wartet nach einem Abbruch höchstens zwei Minuten auf den Scanner, dann gilt die Verbindung als getrennt.
    private func warteAufScanner(name: String) {
        wiederAufgabe?.cancel()
        wiederAufgabe = Task { [weak self] in
            try? await Task.sleep(for: .seconds(WiederverbindePlan().dauer))
            guard !Task.isCancelled, let self, case .unterbrochen = self.zustand else { return }
            self.verbindungWeg()
            self.zustand = .getrennt(name: name, grund: .aufgegeben)
        }
    }

    private func neuSuchen() {
        guard let leitung else { return }
        switch rolle {
        case .scanner: gefunden = []; leitung.suchen(); suchtSeit = Date()
        case .spielgeraet: leitung.werben()
        case nil: break
        }
    }

    // MARK: Puls

    private func pulsStarten() {
        pulsAufgabe?.cancel()
        pulsAufgabe = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(FunkProtokoll.pulsAbstand))
                guard !Task.isCancelled, let self else { return }
                self.pulsTakt()
            }
        }
    }

    private func pulsTakt() {
        guard zustand.istVerbunden, !imHintergrund else { return }
        sende(.puls, zuverlaessig: true)
        // Gegenüber mit Fassung 1 schickt keinen Puls; dort zählt nur, was MultipeerConnectivity meldet.
        if gegenueberVersion >= 2, waechter.istStumm() { abgerissen() }
    }

    // MARK: App im Hintergrund

    private func beobachteApp() {
        let nc = NotificationCenter.default
        beobachter.append(nc.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.imHintergrund = true }
        })
        beobachter.append(nc.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.zurueckImVordergrund() }
        })
    }

    /// Zurück in der App: Suchen bzw. Sichtbarmachen neu starten und eine abgerissene Verbindung sofort neu aufbauen.
    private func zurueckImVordergrund() {
        imHintergrund = false
        guard let rolle, let leitung else { return }
        if zustand.istVerbunden, !(leitung.verbundenePeers.isEmpty) { waechter.lebenszeichen(); return }
        switch rolle {
        case .spielgeraet:
            leitung.werben()
            if zustand.istVerbunden { abgerissen() }
        case .scanner:
            leitung.suchen()
            gefunden = []
            if zustand.istVerbunden || zustand.istUnterbrochen {
                let name = gegenueberName ?? ""
                leitung.trennen()
                wiederAufgabe?.cancel(); wiederAufgabe = nil
                plan.zuruecksetzen()
                wiederverbinden(name: name)
            }
        }
    }

    // MARK: Hilfen

    private var aktuelleLage: FunkLage {
        FunkLage(spiel: eigeneLage.spiel, amZug: eigeneLage.amZug, erwartet: eigeneLage.erwartet, gehalten: eigeneLage.gehalten, bereit: hatEmpfaenger)
    }

    private func lageGeaendert() {
        guard rolle == .spielgeraet, zustand.istVerbunden else { return }
        sende(.lage(aktuelleLage))
    }

    private func bekannteGesichert() {
        bekannteListe.sichern(speicher)
        bekannte = bekannteListe.liste
        for i in gefunden.indices { gefunden[i].bekannt = bekannteListe.kennt(gefunden[i].kennung) }
    }

    @discardableResult
    private func sende(_ n: FunkNachricht, zuverlaessig: Bool = true) -> Bool {
        // An ein Gegenüber mit Fassung 1 geht nur der Wurf, und zwar im alten Format. Das `hallo` geht immer raus
        // (Fassung 1 kann es nicht lesen und überliest es), damit sich zwei neue Geräte gegenseitig erkennen.
        if gegenueberVersion < 2, n.art != "hallo" {
            guard case .wurf(let w) = n else { return false }
            guard let d = FunkZentrale.altesFormat(w) else { return false }
            return leitung?.sende(d, zuverlaessig: zuverlaessig) ?? false
        }
        guard let d = n.kodiert() else { return false }
        return leitung?.sende(d, zuverlaessig: zuverlaessig) ?? false
    }

    /// Fassung 1 liest `{"wurf":{"_0":{"folge":…,"augen":[…]}}}`.
    private static func altesFormat(_ w: FunkWurf) -> Data? {
        let o: [String: Any] = ["wurf": ["_0": ["folge": w.folge, "augen": w.augen]]]
        return try? JSONSerialization.data(withJSONObject: o)
    }
}
#endif
