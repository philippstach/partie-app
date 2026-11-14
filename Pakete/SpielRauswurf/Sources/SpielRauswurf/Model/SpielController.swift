// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
import UIKit

/// Emoji-Blase am Avatar eines Computers (1,2 s): 😤 wenn er rausfliegt, 😎 wenn er rauswirft.
struct Blase: Equatable {
    var emoji: String
    var id: Int
}

/// Banner oben auf dem Brett, optional mit zwei Avataren.
struct SpielBanner: Equatable, Hashable {
    struct Seite: Equatable, Hashable { var avatar: String; var sitz: Int }
    var text: String
    var links: Seite?
    var rechts: Seite?
}

/// Spielt die Oberfläche eines Spiels: Würfelanimation, hüpfende Figuren, Rauswurf, Computer-Züge mit Tempo.
/// Der Spielstand selbst liegt im `GameStore` (Logik ohne UI). Hier steht nur, was man sieht.
@MainActor
@Observable
final class SpielController {
    let store: GameStore
    let prefs: AppPreferences

    /// Brett-Darstellung (hinkt während einer Animation dem Spielstand hinterher).
    var anzeige: Lage?
    var wuerfelt = false
    /// „Gib das iPhone an Clara 👉“ (2 s), wenn nach einem Menschen ein anderer Mensch dran ist
    var weitergebenText: String?
    /// Sieger-Moment: Index des Siegers, solange gefeiert wird (Brett dimmt, Siegerfiguren leuchten, Konfetti)
    var feiert: Int?
    /// Das Ende-Bild ist sichtbar (nach dem Sieger-Moment)
    var endeSichtbar = false
    /// Zählt jeden Wurf mit; löst das (endliche) Wackeln des Würfels aus
    var wurfZaehler = 0
    /// Echter Würfel: zuletzt eingetippte Zahl, 3 Sekunden lang als „Eingetippt: 4 · Ändern“ sichtbar
    var eingetippt: Int?
    /// Löst das kurze „Plopp“ des Würfels nach einer Eingabe aus
    var plopp = 0
    var wuerfelFlaeche: Int?
    /// Zuletzt gezeigte Augenzahl (bleibt stehen, bis neu gewürfelt wird).
    var letzteAugen: Int?
    var vorne: FigurID?
    var banner: SpielBanner?
    /// Große Einblendung „X fängt an“ in der Mitte des Spielfelds (nur beim Start einer frischen Partie)
    var startEinblendung: SpielBanner?
    /// Emoji-Blasen je Spieler-Index
    var blasen: [Int: Blase] = [:]
    /// Zug geht an einen Menschen: sein Avatar pulsiert kurz
    var uebergabe: (spieler: Int, zaehler: Int)?
    var geist: Geist?
    var effekte = BrettEffekte()
    var beschaeftigt = false
    var keinZug = false
    /// „Schneller“: schnelles Tempo, bis wieder ein Mensch dran ist.
    var schnell = false
    /// Für VoiceOver: wird angesagt, sobald sich der Text ändert.
    var ansage = ""
    /// Demo: Animationen und Computer-Züge anhalten.
    var angehalten = false

    @ObservationIgnored private var treiber: Task<Void, Never>?
    @ObservationIgnored private var zaehler = 0
    @ObservationIgnored private var eingabeMarke = 0
    /// Wie viele abgeschlossene Spielzüge schon auf Reaktionen geprüft sind, und die letzte eigene Blase je Spieler
    @ObservationIgnored private var reaktionsStand = 0
    @ObservationIgnored private var letzteReaktion: [Int: String] = [:]

    init(store: GameStore, prefs: AppPreferences) {
        self.store = store
        self.prefs = prefs
    }

    var zustand: Spielzustand? { store.zustand }
    var bewegungReduziert: Bool { !prefs.animationen || UIAccessibility.isReduceMotionEnabled }

    var lage: Lage { anzeige ?? zustand?.lage ?? .neu(sitze: [0, 2]) }

    // MARK: Start und Ende

    /// Beim Öffnen des Spiel-Bildschirms: Anzeige angleichen und, falls ein Computer dran ist, weiterspielen.
    func starten() {
        #if DEBUG
        if demoEingefroren { return }
        #endif
        treiber?.cancel()
        beschaeftigt = false
        wuerfelt = false
        banner = nil
        startEinblendung = nil
        geist = nil
        keinZug = false
        schnell = false
        effekte = BrettEffekte()
        feiert = nil
        blasen = [:]
        weitergebenText = nil
        letzteReaktion = [:]
        reaktionsStand = zustand?.partie.verlauf.count ?? 0
        endeSichtbar = zustand?.phase == .vorbei          // war die Partie schon vorbei, gibt es keinen Sieger-Moment mehr
        anzeige = zustand?.lage
        letzteAugen = zustand?.partie.spielzug.augen
        if let z = zustand, z.partie.verlauf.isEmpty, z.partie.spielzug.augen == nil, z.partie.spielzug.wuerfe.isEmpty, z.phase != .vorbei {
            // frische Partie: Das Brett baut sich auf (400 ms), die Figuren hüpfen ins Haus, dann zeigt das Banner den Beginner
            treiber = Task { [weak self] in
                guard let self else { return }
                self.beschaeftigt = true
                await self.pause(.milliseconds(self.bewegungReduziert ? 100 : 750))
                // N-19: Der Beginner wird ausgelost – das Banner steht lange genug, damit man es liest, bevor ein Computer loslegt
                let dauer = self.bewegungReduziert ? 1.6 : 2.2
                self.zeigeBanner(L("beginner", z.aktuellerSpieler.name), dauer: dauer)
                let ev = SpielBanner(text: L("beginner", z.aktuellerSpieler.name), links: .init(avatar: z.aktuellerSpieler.avatar, sitz: z.aktuellerSpieler.sitz))
                withAnimation(.spring(duration: 0.35)) { self.startEinblendung = ev }
                self.ansage = L("beginner", z.aktuellerSpieler.name)
                await self.pause(.milliseconds(Int(dauer * 1000)))
                withAnimation(.easeOut(duration: 0.25)) { self.startEinblendung = nil }
                self.beschaeftigt = false
                await self.treibe(autoNachWurf: false)
            }
        } else {
            // Nach einem Neustart in „Wahl“ mit genau einem Zug: nach 400 ms von selbst ziehen (wie sonst auch).
            // Ausnahme echter Würfel: Das „Ändern“-Fenster fehlt, die App wartet auf einen Tipp.
            let wahl = zustand.map { $0.phase == .wahl && !$0.aktuellerSpieler.wuerfeltEcht } ?? false
            weiterspielen(auto: wahl)
        }
    }

    func anhalten() {
        treiber?.cancel()
        beschaeftigt = false
        wuerfelt = false
    }

    private func weiterspielen(auto: Bool) {
        treiber?.cancel()
        treiber = Task { [weak self] in await self?.treibe(autoNachWurf: auto) }
    }

    // MARK: Aktionen des Menschen

    func wuerfelnTippen() {
        guard !beschaeftigt, !angehalten, let z = zustand, z.phase == .vorWurf, !z.aktuellerSpieler.wuerfeltEcht else { return }
        weitergebenText = nil
        treiber?.cancel()
        treiber = Task { [weak self] in
            guard let self else { return }
            self.beschaeftigt = true
            await self.wurf(mensch: true)
            self.beschaeftigt = false
            await self.treibe(autoNachWurf: true)
        }
    }

    /// Echter Würfel: Die Zahl wird eingetippt und gilt sofort. Drei Sekunden bleibt „Ändern“ sichtbar; so lange wartet auch das automatische Ziehen.
    func eintippen(_ w: Int) {
        guard !beschaeftigt, !angehalten, let z = zustand, z.erwartetEingabe, (1 ... 6).contains(w) else { return }
        weitergebenText = nil
        treiber?.cancel()
        Sound.select.play()
        SpielHaptik.tap()
        store.eintippen(w)
        letzteAugen = w
        plopp += 1
        eingetippt = w
        ansage = L("a11y.echt.wert", w)
        if w == 6 { Sound.good.play() }
        // eigener Zähler: Effekte und Blasen erhöhen `zaehler` und würden sonst das Ausblenden (und damit das automatische Ziehen) verhindern
        eingabeMarke += 1
        let marke = eingabeMarke
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, self.eingabeMarke == marke else { return }
            self.eingetippt = nil
        }
        weiterspielen(auto: true)
    }

    func figurTippen(_ id: FigurID) {
        guard !beschaeftigt, !angehalten, let z = zustand else { return }
        guard z.phase == .wahl, let zug = z.zug(fuer: id) else {
            // nicht beweglich: kurz wackeln
            if z.phase == .wahl { effekt { $0.wackeln = Marke(id: id, zaehler: self.naechsterZaehler()) }; SpielHaptik.error() }
            return
        }
        geist = nil
        eingetippt = nil
        treiber?.cancel()
        treiber = Task { [weak self] in
            guard let self else { return }
            await self.ziehe(zug, mensch: true)
            await self.treibe(autoNachWurf: false)
        }
    }

    /// Vorschau: Geisterstein auf dem Zielfeld, solange die Figur gehalten wird.
    func vorschau(_ id: FigurID, aktiv: Bool) {
        guard aktiv, !beschaeftigt, let z = zustand, let zug = z.zug(fuer: id) else { geist = nil; return }
        geist = Geist(spieler: id.spieler, rel: zug.nach, schlaegt: zug.schlaegt != nil)
    }

    func zuruecknehmen() {
        guard !beschaeftigt, store.kannZuruecknehmen else { return }
        treiber?.cancel()
        store.zuruecknehmen()
        geist = nil
        banner = nil
        keinZug = false
        eingetippt = nil
        reaktionsStand = zustand?.partie.verlauf.count ?? 0
        anzeige = zustand?.lage
        letzteAugen = zustand?.partie.spielzug.augen
        SpielHaptik.tap()
        Sound.select.play()
    }

    /// Schnelles Tempo für den Rest der Computer-Runde.
    func schneller() { schnell = true }

    var kannZuruecknehmen: Bool { !beschaeftigt && store.kannZuruecknehmen }

    // MARK: Treiber

    /// Spielt weiter, bis ein Mensch etwas tun muss (oder die Partie vorbei ist).
    private func treibe(autoNachWurf: Bool) async {
        var auto = autoNachWurf
        while !Task.isCancelled, let z = zustand, !angehalten {
            switch z.phase {
            case .computer:
                beschaeftigt = true
                await computerSchritt(z)
                beschaeftigt = false
            case .verfallen:
                beschaeftigt = true
                await verfallen()
                beschaeftigt = false
            case .wahl:
                guard auto, prefs.autoZug, z.partie.spielzug.erlaubt.count == 1, let zug = z.partie.spielzug.erlaubt.first else { return }
                auto = false
                // Nach einer Eingabe bleibt „Ändern“ drei Sekunden offen; so lange wird nicht automatisch gezogen
                while eingetippt != nil, !Task.isCancelled { await pause(.milliseconds(100)) }
                guard !Task.isCancelled, zustand?.phase == .wahl else { return }
                beschaeftigt = true
                await pause(.milliseconds(400))
                guard !Task.isCancelled else { return }
                await ziehe(zug, mensch: true)
                beschaeftigt = false
            case .vorWurf:
                schnell = false
                anzeige = zustand?.lage
                return
            case .vorbei:
                schnell = false
                await partieEnde()
                return
            }
            auto = false
        }
        beschaeftigt = false
    }

    private func computerSchritt(_ z: Spielzustand) async {
        switch z.partie.spielzug.stand {
        case .vorWurf:
            await pause(tempo)
            guard !Task.isCancelled else { return }
            await wurf(mensch: false)
            // Verfällt der Wurf, zeigt `verfallen()` selbst „Kein Zug möglich“: keine doppelte Wartezeit
            if zustand?.phase != .verfallen { await pause(tempo) }
        case .wahl:
            let lage = z.lage, p = z.amZug, strategie = z.aktuellerSpieler.strategie, erlaubt = z.partie.spielzug.erlaubt, menschen = z.menschen
            let wahl = await Task.detached(priority: .userInitiated) { Computer.entscheide(strategie, lage, p, erlaubt, menschen: menschen) }.value
            guard !Task.isCancelled, zustand == z else { return }
            await ziehe(wahl, mensch: false)
        case .verfallen:
            await verfallen()
        default:
            break
        }
    }

    private func verfallen() async {
        // Echter Würfel: „Ändern“ bleibt drei Sekunden offen, auch wenn der Wurf keinen Zug erlaubt (Vertipper)
        while eingetippt != nil, !Task.isCancelled { await pause(.milliseconds(100)) }
        guard !Task.isCancelled else { return }
        keinZug = true
        Sound.none.play()
        ansage = L("hinweis.keinZug")
        // Ein Computer, der noch im Haus festsitzt, würfelt oft dreimal hintereinander: ihm genügt das eingestellte Tempo
        let dran = zustand?.aktuellerSpieler.istComputer == true
        await pause(dran ? max(.milliseconds(500), tempo) : .milliseconds(1000))
        guard !Task.isCancelled else { keinZug = false; return }
        keinZug = false
        let vorherAmZug = zustand?.amZug ?? 0
        store.verfallenWeiter()
        anzeige = zustand?.lage
        verarbeiteReaktionen()
        pruefeUebergabe(vorher: vorherAmZug)
        if let z = zustand, z.phase != .vorbei, z.partie.spielzug.stand == .vorWurf, z.partie.spielzug.wuerfe.isEmpty {
            ansage = L("a11y.zugEnde", z.aktuellerSpieler.name)
        }
    }

    // MARK: Würfeln

    private func wurf(mensch: Bool) async {
        guard let z = zustand else { return }
        let name = z.aktuellerSpieler.name
        Sound.roll.play()
        if mensch { SpielHaptik.tap() }
        if !bewegungReduziert {
            wurfZaehler += 1
            wuerfelt = true
            for _ in 0 ..< 7 {
                wuerfelFlaeche = Int.random(in: 1 ... 6)
                await pause(.milliseconds(65))
                if Task.isCancelled { wuerfelt = false; wuerfelFlaeche = nil; return }
            }
        }
        if mensch { store.wuerfeln() } else { await store.computerSchritt() }
        wuerfelt = false
        wuerfelFlaeche = nil
        letzteAugen = zustand?.partie.spielzug.augen
        if let w = letzteAugen {
            if w == 6 { Sound.good.play() }
            ansage = L("a11y.wurf", name, w)
        }
    }

    // MARK: Ziehen

    private func ziehe(_ zug: Zug, mensch: Bool) async {
        guard let vorher = zustand else { return }
        let name = vorher.aktuellerSpieler.name
        guard let b = mensch ? store.ziehe(zug) : store.computerZug(zug) else {
            anzeige = zustand?.lage
            return
        }
        await animiere(b, name: name, vorher: vorher, mensch: mensch)
    }

    private func animiere(_ b: Bewegung, name: String, vorher: Spielzustand, mensch: Bool) async {
        let p = b.spieler, k = b.figur, z = b.zug
        var a = anzeige ?? vorher.lage
        let id = FigurID(spieler: p, figur: k)
        vorne = id
        let reduziert = bewegungReduziert
        // Der Siegzug läuft in Zeitlupe
        let siegzug = zustand?.phase == .vorbei
        let tempoFaktor = siegzug ? 2.4 : ((schnell && !mensch) ? 0.5 : 1.0)

        if reduziert {
            withAnimation(.easeInOut(duration: 0.2)) { a.figuren[p][k] = z.nach; anzeige = a }
            await pause(.milliseconds(200))
        } else if z.von == Brettmass.haus {
            Sound.raus.play()
            SpielHaptik.tap(enabled: mensch)
            effekt { $0.hupf = Marke(id: id, zaehler: self.naechsterZaehler()) }
            withAnimation(.easeOut(duration: 0.3 * tempoFaktor)) { a.figuren[p][k] = 0; anzeige = a }
            await pause(.milliseconds(Int(300 * tempoFaktor)))
        } else {
            for rel in (z.von + 1) ... z.nach {
                guard !Task.isCancelled else { break }
                if mensch { Sound.step.play() }
                effekt { $0.hupf = Marke(id: id, zaehler: self.naechsterZaehler()) }
                withAnimation(.easeInOut(duration: 0.09 * tempoFaktor)) { a.figuren[p][k] = rel; anzeige = a }
                await pause(.milliseconds(Int(90 * tempoFaktor)))
            }
        }
        if Task.isCancelled { anzeige = zustand?.lage; vorne = nil; return }

        ansage = L("a11y.zug", name, k + 1, z.nach + 1)

        if let g = b.geschlagen, let opfer = vorher.spieler[safe: g.spieler] {
            let taeter = vorher.spieler[p]
            let opferID = FigurID(spieler: g.spieler, figur: g.figur)
            let aufprallPunkt = Brettgeometrie.punkt(sitz: vorher.lage.sitze[p], rel: z.nach, figur: k)
            // 1. Aufprall: dumpfer Schlag, kräftige Haptik, Ring und Staub am Schlagfeld, das Brett zittert, der Geschlagene zuckt
            Sound.aufprall.play()
            SpielHaptik.heavy()
            zeigeBanner(SpielBanner(text: L("banner.rauswurf", name, opfer.name),
                                    links: .init(avatar: taeter.avatar, sitz: taeter.sitz),
                                    rechts: .init(avatar: opfer.avatar, sitz: opfer.sitz)))
            ansage = L("a11y.rauswurf", name, opfer.name)
            if reduziert {
                Sound.rauswurf.play()
                withAnimation(.easeInOut(duration: 0.2)) { a.figuren[g.spieler][g.figur] = Brettmass.haus; anzeige = a }
                await pause(.milliseconds(300))
            } else {
                effekt {
                    $0.blitz = Blitz(punkt: aufprallPunkt, zaehler: self.naechsterZaehler())
                    $0.staub = StaubMarke(punkt: aufprallPunkt, sitz: vorher.lage.sitze[g.spieler], zaehler: self.naechsterZaehler())
                    $0.zittern += 1
                    $0.wackeln = Marke(id: opferID, zaehler: self.naechsterZaehler())
                }
                // 2. Stillstand beim Aufprall (120 ms), dann fliegt der Geschlagene mit Drehung im Bogen ins Haus
                await pause(.milliseconds(Int(120 * tempoFaktor)))
                Sound.rauswurf.play()
                effekt { $0.flug = Marke(id: opferID, zaehler: self.naechsterZaehler()) }
                withAnimation(.easeIn(duration: 0.45 * tempoFaktor)) { a.figuren[g.spieler][g.figur] = Brettmass.haus; anzeige = a }
                await pause(.milliseconds(Int(450 * tempoFaktor)))
            }
            // 3. Landung im Haus. Der Rauswurf ist der Höhepunkt: auch bei schnellen Computern kurz stehen lassen
            Sound.landung.play()
            SpielHaptik.tap()
            await pause(.milliseconds(Int(300 * tempoFaktor)))
        } else if z.nach >= Brettmass.zielErstes, z.von < Brettmass.zielErstes {
            Sound.ziel.play()
            SpielHaptik.tap(enabled: mensch)
            if !reduziert { effekt { $0.glanz = Marke(id: id, zaehler: self.naechsterZaehler()) } }
            zeigeBanner(L("banner.ziel", name))
            await pause(.milliseconds(reduziert ? 100 : 350))
        }
        anzeige = zustand?.lage
        vorne = nil
        letzteAugen = zustand?.partie.spielzug.augen ?? letzteAugen
        if let z = zustand, z.phase != .vorbei, z.amZug != vorher.amZug {
            ansage = L("a11y.zugEnde", z.aktuellerSpieler.name)
        }
        verarbeiteReaktionen()
        pruefeUebergabe(vorher: vorher.amZug)
    }

    /// Sieger-Moment: Brett dimmt, die Figuren des Siegers leuchten, Konfetti, Avatar groß, Jubel. Nach ca. 2 s (oder Tippen)
    /// kommt das Ende-Bild.
    private func partieEnde() async {
        guard let z = zustand, z.phase == .vorbei, let sieger = z.partie.platzierung.first else { return }
        anzeige = z.lage
        let derSieger = z.spieler[sieger]
        (derSieger.istComputer ? Sound.end : Sound.jubel).play()
        SpielHaptik.success()
        ansage = L("ende.sieger", derSieger.name)
        withAnimation(.easeInOut(duration: 0.4)) { feiert = sieger }
        // 2 s (bei Computern 1 s), eine entschiedene Serie 1 s länger; Tippen überspringt
        let schritte = (derSieger.istComputer ? 10 : 20) + (z.serieEntschieden ? 10 : 0)
        for _ in 0 ..< schritte where !endeSichtbar {
            await pause(.milliseconds(100))
            if Task.isCancelled { return }
        }
        withAnimation(bewegungReduziert ? .easeInOut(duration: 0.3) : .spring(duration: 0.45)) { endeSichtbar = true }
    }

    /// Antippen überspringt den Sieger-Moment.
    func siegerMomentUeberspringen() {
        withAnimation(bewegungReduziert ? .easeInOut(duration: 0.3) : .spring(duration: 0.45)) { endeSichtbar = true }
    }

    #if DEBUG
    /// Demo `capture`: Anzeige wird nicht zurückgesetzt.
    @ObservationIgnored var demoEingefroren = false

    /// Demo `capture`: der Augenblick des Rauswurfs, eingefroren (Ring, Staub, Banner, Opfer im Flug).
    func demoCapture(zug: Zug) {
        guard let z = zustand, let q = zug.schlaegt else { return }
        let p = z.amZug
        var a = z.lage
        guard let b = a.besetzer(feld(a.sitze[p], zug.nach)), b.spieler == q, let k = a.figuren[p].firstIndex(of: zug.von) else { return }
        a.figuren[p][k] = zug.nach
        anzeige = a
        angehalten = true
        demoEingefroren = true
        beschaeftigt = true
        letzteAugen = z.partie.spielzug.augen
        vorne = FigurID(spieler: p, figur: k)
        effekte.eingefroren[FigurID(spieler: b.spieler, figur: b.figur)] = 0.45
        let punkt = Brettgeometrie.punkt(sitz: a.sitze[p], rel: zug.nach, figur: k)
        effekte.blitz = Blitz(punkt: punkt, zaehler: 1)
        effekte.staub = StaubMarke(punkt: punkt, sitz: a.sitze[q], zaehler: 1)
        effekte.aufprallStand = 0.35
        banner = SpielBanner(text: L("banner.rauswurf", z.spieler[p].name, z.spieler[q].name),
                             links: .init(avatar: z.spieler[p].avatar, sitz: z.spieler[p].sitz),
                             rechts: .init(avatar: z.spieler[q].avatar, sitz: z.spieler[q].sitz))
        blasen[q] = Blase(emoji: "😤", id: 1)
    }

    /// Demo `sieg`: Der Sieger-Moment, eingefroren (ohne Weiterschalten zum Ende-Bild).
    func demoSieg() {
        guard let z = zustand, let sieger = z.partie.platzierung.first else { return }
        angehalten = true
        demoEingefroren = true
        anzeige = z.lage
        feiert = sieger
        endeSichtbar = false
        letzteAugen = nil
    }
    #endif

    // MARK: Hilfen

    /// T-090: Pause des Computers nach der globalen Einstellung „Tempo des Computers“ (die eigene `prefs.tempo` der Rauswurf-Einstellungen ist nirgends mehr einstellbar).
    private var tempo: Duration { schnell ? ComputerTempo.schnell.pause : ComputerTempo.global.pause }

    private func pause(_ d: Duration) async {
        if angehalten { return }
        try? await Task.sleep(for: d)
    }

    private func effekt(_ aendern: (inout BrettEffekte) -> Void) {
        var e = effekte
        aendern(&e)
        effekte = e
    }

    private func naechsterZaehler() -> Int { zaehler += 1; return zaehler }

    private func zeigeBanner(_ b: SpielBanner, dauer: Double = 1.5) {
        withAnimation(.spring(duration: 0.3)) { banner = b }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(dauer * 1000)))
            guard let self, self.banner == b else { return }
            withAnimation(.easeOut(duration: 0.25)) { self.banner = nil }
        }
    }

    private func zeigeBanner(_ text: String, dauer: Double = 1.5) { zeigeBanner(SpielBanner(text: text), dauer: dauer) }

    /// Emoji-Blase am Avatar eines Computers (1,2 s, höchstens eine je Avatar gleichzeitig). Bei Menschen und ohne Animationen keine.
    private func zeigeBlase(_ emoji: String, fuer spieler: Int) {
        guard !bewegungReduziert, let z = zustand, z.spieler[safe: spieler]?.istComputer == true else { return }
        let b = Blase(emoji: emoji, id: naechsterZaehler())
        blasen[spieler] = b
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1200))
            guard let self, self.blasen[spieler] == b else { return }
            self.blasen[spieler] = nil
        }
    }

    /// Reaktionen (SPEZ 7.4) für alle neu abgeschlossenen Spielzüge: einmal nach dem ganzen Spielzug aus Lage vorher und Würfen,
    /// nach der Zug- bzw. Rauswurf-Animation.
    private func verarbeiteReaktionen() {
        guard let z = zustand else { return }
        let v = z.partie.verlauf
        if reaktionsStand > v.count { reaktionsStand = v.count }
        while reaktionsStand < v.count {
            let i = reaktionsStand
            reaktionsStand += 1
            let vorher = i >= 1 ? Lage(sitze: z.lage.sitze, figuren: v[i - 1].figuren) : Lage.neu(sitze: z.lage.sitze, z.optionen)
            let r = Reaktionen.nachSpielzug(lageVorher: vorher, spieler: v[i].spieler, wuerfe: v[i].wuerfe, letzte: letzteReaktion)
            if let eigene = r[v[i].spieler] { letzteReaktion[v[i].spieler] = eigene }
            for (spieler, emoji) in r { zeigeBlase(emoji, fuer: spieler) }
        }
    }

    /// Wechselt der Zug zu einem Menschen, pulsiert sein Avatar und es gibt einen leichten Tap (keine Bestätigung nötig).
    private func pruefeUebergabe(vorher: Int) {
        guard let z = zustand, z.phase != .vorbei, z.amZug != vorher, !z.aktuellerSpieler.istComputer else { return }
        uebergabe = (z.amZug, naechsterZaehler())
        SpielHaptik.tap()
        // Zwei Menschen nacheinander: Hinweis, wohin das iPhone wandert (keine Sperre, der Würfel ist schon tippbar)
        if prefs.weitergeben, let davor = z.spieler[safe: vorher], !davor.istComputer {
            let text = L("hinweis.weitergeben", z.aktuellerSpieler.name)
            weitergebenText = text
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard let self, self.weitergebenText == text else { return }
                self.weitergebenText = nil
            }
        }
    }

    // MARK: Hinweiszeile

    /// Text unter dem Brett: sagt immer, was jetzt zu tun ist oder warum etwas geht oder nicht geht.
    var hinweis: String {
        guard let z = zustand else { return "" }
        let sp = z.partie.spielzug
        let name = z.aktuellerSpieler.name
        if z.phase == .vorbei { return L("hinweis.vorbei") }
        if let w = weitergebenText, z.phase == .vorWurf { return w }
        if keinZug { return L("hinweis.keinZug") }
        if beschaeftigt && !z.aktuellerSpieler.istComputer { return "" }
        if z.aktuellerSpieler.istComputer {
            if let n = z.versucheUebrig { return versuche(n) }
            return L("hinweis.computerKurz", name)
        }
        if z.erwartetEingabe, let n = z.versucheUebrig { return versuche(n) }
        switch z.phase {
        case .wahl:
            switch z.pflicht {
            case .raus: return L("hinweis.raus")
            case .startfeld: return L("hinweis.start")
            case .schlagen: return L("hinweis.schlagpflicht")
            case nil: return L("hinweis.waehlen")
            }
        case .verfallen:
            return L("hinweis.keinZug")
        default:
            if let n = z.versucheUebrig { return versuche(n) }
            if let letzter = sp.wuerfe.last, letzter.augen == 6, letzter.zug != nil { return L("hinweis.nochmal") }
            return L("hinweis.wuerfeln")
        }
    }

    private func versuche(_ n: Int) -> String {
        n == 1 ? L("hinweis.versuch1") : L("hinweis.versuche", n)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
