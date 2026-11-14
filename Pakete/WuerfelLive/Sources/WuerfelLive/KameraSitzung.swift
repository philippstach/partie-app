// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import AVFoundation
import CoreImage
import Observation
import os
import SwiftUI
import UIKit

/// Eine Zoomstufe der Kamera (Ultraweit, Weitwinkel, Tele).
public struct ZoomStufe: Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    let faktor: CGFloat
}

/// Kamera-Sitzung: liefert Bilder, wertet etwa 10-mal pro Sekunde auf einem Hintergrund-Thread aus.
/// Verfolgung: `WuerfelVerfolger` erkennt jeden Würfel von Bild zu Bild wieder (auch bei bewegter Kamera und anderem Abstand) und bildet je Würfel die Mehrheit der Werte.
/// Die Bilder bleiben im Arbeitsspeicher: nichts wird gespeichert oder gesendet – außer, der Spieler hat in den Einstellungen die „Lern-Aufnahme“ eingeschaltet (Testfunktion, aus):
/// Dann legt `bestaetige` das Standbild samt Rahmen und einigen Bildern davor im App-Ordner ab (`LernAufnahme`). Auch dann bleibt alles auf dem Gerät, bis der Spieler es teilt.
/// Ruhe: Aus Bildabweichung und Würfelbewegung wird „ruhig“ oder „wackelt“. Das steuert nur noch Auslöser und Zoom-Automatik; die Verfolgung läuft immer weiter.
/// Standbild: `aufnehmen()` merkt den Wunsch und löst beim nächsten ruhigen Bild aus (spätestens nach ca. 5 s); `neuAufnehmen()` geht zurück zum Live-Bild.
/// Automatik: Ist das Ergebnis länger unsicher, probiert die Sitzung die anderen Zoomstufen (virtuelle Kamera: 0,5× / 1× / Tele) und behält die beste.
/// Das Probieren bleibt unsichtbar: Währenddessen steht das letzte Bild mit den letzten Ergebnissen still.
/// Tempo (W4, 13.11.2026): Kamera in 1920 × 1080 (wo möglich). Sind Würfel verfolgt, wird meist nur ihr Bereich abgesucht,
/// etwa jede sechste Auswertung das ganze Bild (neue Würfel). Helligkeit wird gemessen, `dunkel` schlägt die Taschenlampe vor.
@MainActor @Observable
public final class LiveWuerfel {
    public enum Zustand { case bereit, verweigert, keineKamera, laeuft }
    public private(set) var zustand: Zustand = .bereit
    public private(set) var wuerfel: [AngezeigterWuerfel] = []
    /// Aufgenommenes Standbild (`nil` = Live-Bild).
    public private(set) var standbild: UIImage?
    /// `true`: Auslöser gedrückt, wartet auf ein ruhiges Bild.
    public private(set) var aufnahmeLaeuft = false
    /// Kamera und Würfel stehen ruhig (grün) bzw. wackeln (orange).
    public private(set) var ruhig = false
    /// Letztes Bild, das während der Zoom-Automatik über dem Live-Bild steht (damit das Umschalten nicht zu sehen ist).
    public private(set) var eingefroren: UIImage?
    public private(set) var zoomStufen: [ZoomStufe] = []
    public private(set) var zoomIndex = 0
    /// Obergrenze der Würfelzahl (z. B. 5 in Yacht): Sieht die Erkennung mehr, zählen nur die sichersten.
    public var hoechstens: Int?
    public var automatik = true { didSet { if automatik, oldValue != automatik { sucher.setze(zoomIndex) } } }

    /// Das Bild ist zu dunkel für eine gute Erkennung (Hinweis „Mehr Licht“, Knopf für die Taschenlampe). Mit Verzögerung, damit es nicht flackert.
    public private(set) var dunkel = false
    /// Mittlere Helligkeit des Bildes (0…1), geglättet.
    public private(set) var helligkeit: Double = 0.5
    /// Die Kamera hat eine Taschenlampe, die gerade eingeschaltet werden kann.
    public private(set) var lampeVerfuegbar = false
    public private(set) var lampeAn = false
    /// Rechenzeit der Erkennung je Bild in Millisekunden (geglättet), zum Vergleichen vorher/nachher.
    public private(set) var rechenzeit: Double = 0
    /// Anteil der Auswertungen, die nur den Würfelbereich abgesucht haben (geglättet, 0…1).
    public private(set) var bereichsAnteil: Double = 0

    /// Stand der Nahprüfung nach einem Tipp auf eine Stelle im Standbild.
    public enum Nachpruefung: Equatable {
        case ruht
        /// Prüft gerade die Umgebung dieser Stelle (normiert 0…1).
        case laeuft(CGPoint)
        /// An der angetippten Stelle wurde kein Würfel gefunden.
        case nichts
        /// Ein Würfel wurde ergänzt (seine Nummer).
        case gefunden(Int)
    }
    public private(set) var nachpruefung: Nachpruefung = .ruht

    /// Lern-Aufnahme an (Testfunktion): Die Kamera hält die letzten Bilder bereit, `bestaetige` speichert sie. Vor `starten()` setzen.
    public var lernAufnahme = false {
        didSet {
            guard lernAufnahme != oldValue else { return }
            puffer.lernRing = lernAufnahme ? LernRing() : nil
        }
    }
    /// Wie viele Würfe seit dem Öffnen der Seite gespeichert wurden.
    public private(set) var lernGespeichert = 0
    // Für den aktuellen Wurf: Was der Spieler geändert hat (Nummer des Würfels → Wert vor der ersten Änderung), entfernte Funde, ergänzte Würfel.
    private var lernAlteWerte: [Int: Int] = [:]
    private var lernEntfernt: [LernFund] = []
    private var lernErgaenzt: [Int: LernErgaenzung] = [:]
    private var lernTipp: CGPoint?
    private var lernUeblich: Double?
    private var lernBereitsGespeichert = false

    let sitzung = AVCaptureSession()
    private let erkennung: WuerfelErkennung
    private let ausgabe = AVCaptureVideoDataOutput()
    private let arbeit = DispatchQueue(label: "partie.wuerfel.live", qos: .userInitiated)
    private let puffer: Puffer
    private var verfolger = WuerfelVerfolger()
    private var geraet: AVCaptureDevice?
    private var sucher = ZoomSucher(stufen: 1, start: 0)
    private var leereFolge = 0
    private var ruheFilter = RuheFilter()
    private var letztesBild: CGImage?
    private var wartezeit = 0
    private var einschwingZaehler = 0
    // Zählt die Auswertungen mit (zur Altersbestimmung des letzten sicheren Ergebnisses).
    private var auswertungNr = 0
    // Letztes ruhiges Ergebnis, bei dem alle Würfel sicher waren: mit Bild und Verfolgung, damit Rahmen und Bild zusammenpassen.
    private var sicherer: (verfolger: WuerfelVerfolger, bild: CGImage, nr: Int)?
    // So viele Auswertungen (ca. 2 s) darf das letzte sichere Ergebnis alt sein, damit es beim Auslösen noch gilt.
    private let sichererFrist = 20
    private var dunkelFolge = 0
    private var hellFolge = 0
    #if DEBUG
    private let protokoll = Logger(subsystem: "de.philippstach.partie", category: "WuerfelLive")
    #endif

    public init(erkennung: WuerfelErkennung = StandardErkennung.aktuell) {
        puffer = Puffer(erkennung: erkennung)
        self.erkennung = erkennung
    }

    public static var verfuegbar: Bool { AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil }

    public func starten() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else { zustand = .verweigert; return }
        default: zustand = .verweigert; return
        }
        guard Self.verfuegbar, einrichten() else { zustand = .keineKamera; return }
        liveAnschliessen()
        let s = sitzung
        arbeit.async { if !s.isRunning { s.startRunning() } }
        zustand = .laeuft
    }

    #if DEBUG
    /// Nur zum Testen im Simulator (keine Kamera): lädt ein Bild aus einer Datei, liest es einmal und zeigt es als Standbild.
    public func ladeTestbild(pfad: String) {
        guard let bild = UIImage(contentsOfFile: pfad), let cg = bild.cgImage else { return }
        zustand = .laeuft
        verfolger = .einzelbild(seitenverhaeltnis: Double(cg.width) / Double(max(cg.height, 1)))
        let gesehen = GesehenerWuerfel.dieSichersten((try? erkennung.erkenne(in: cg)) ?? [], hoechstens: hoechstens)
        wuerfel = verfolger.verarbeite(gesehen)
        letztesBild = cg
        standbild = UIImage(cgImage: cg)
    }
    #endif

    public func stoppen() {
        puffer.ergebnis = nil
        puffer.verfolgt = []
        lampe(false)
        let s = sitzung
        arbeit.async { if s.isRunning { s.stopRunning() } }
        if zustand == .laeuft { zustand = .bereit }
    }

    private func liveAnschliessen() {
        puffer.verfolgt = []
        puffer.ergebnis = { [weak self] a in
            Task { @MainActor in self?.neueAuswertung(a) }
        }
    }

    private func neueAuswertung(_ a: Puffer.Auswertung) {
        guard standbild == nil else { return }
        let bild = a.bild, bildBewegung = a.bewegung
        let gesehen = GesehenerWuerfel.dieSichersten(a.gesehen, hoechstens: hoechstens)
        letztesBild = bild
        verfolger.seitenverhaeltnis = Double(bild.width) / Double(max(bild.height, 1))
        verfolger.verarbeite(gesehen)
        // Die nächste Auswertung sucht vor allem dort, wo jetzt Würfel verfolgt werden.
        puffer.verfolgt = verfolger.anzeige.map(\.rahmen)
        messwerte(a)
        // 0,15 Würfelkanten Weg je Auswertung entsprechen der Schwelle 0,03 der Bildabweichung.
        ruhig = ruheFilter.beobachte(bewegung: max(bildBewegung, (verfolger.bewegung ?? 0) * 0.2))
        if eingefroren == nil { wuerfel = verfolger.anzeige }
        auswertungNr += 1
        if eingefroren == nil, ruhig, wuerfel.allesSicher { sicherer = (verfolger, bild, auswertungNr) }
        if aufnahmeLaeuft { ausloesenPruefen(bild, gesehen); return }
        guard automatik, zoomStufen.count > 1 else { return }
        if eingefroren != nil, !sucher.sondiert {   // Probe vorbei: nach kurzem Einschwingen wieder das Live-Bild zeigen
            einschwingZaehler -= 1
            if einschwingZaehler <= 0 { eingefroren = nil; wuerfel = verfolger.anzeige }
        }
        guard ruhig else { return }   // beim Wackeln wird nichts umgeschaltet
        if wuerfel.isEmpty {   // leerer Tisch: erst nach ca. 5 s anfangen, andere Stufen zu probieren
            leereFolge += 1
            if leereFolge < 50 { return }
        } else { leereFolge = 0 }
        let punkte = wuerfel.reduce(0) { $0 + ($1.sicher ? 3 : 1) }
        // Ist schon ein Würfel sicher erkannt, taugt die Stufe: dann wird nicht probiert (ein Probieren verwirft alle Spuren).
        let genug = verfolger.anzeige.allesSicher || (!sucher.sondiert && wuerfel.contains(where: \.sicher))
        if let n = sucher.beobachte(punkte: punkte, allesSicher: genug) { zoomAnwenden(n, unsichtbar: true) }
    }

    // MARK: Licht und Messwerte

    private func messwerte(_ a: Puffer.Auswertung) {
        rechenzeit = rechenzeit == 0 ? a.rechenzeit : 0.9 * rechenzeit + 0.1 * a.rechenzeit
        bereichsAnteil = 0.9 * bereichsAnteil + 0.1 * (a.nurBereich ? 1 : 0)
        helligkeit = 0.8 * helligkeit + 0.2 * a.helligkeit
        // Dunkel: Bild dunkel oder die Kamera muss das Signal schon stark verstärken (dann rauscht es und die Augen verschwimmen).
        var verstaerkt = false
        if let g = geraet { verstaerkt = g.iso >= 0.75 * g.activeFormat.maxISO }
        let zuDunkel = helligkeit < 0.22 || verstaerkt
        let hellGenug = helligkeit > 0.3 && !verstaerkt
        if zuDunkel { dunkelFolge += 1; hellFolge = 0 } else if hellGenug { hellFolge += 1; dunkelFolge = 0 }
        if !dunkel, dunkelFolge >= 15 { dunkel = true }   // ca. 1,5 s
        if dunkel, hellFolge >= 15 { dunkel = false }
        if let g = geraet { lampeVerfuegbar = g.hasTorch && g.isTorchAvailable }
        #if DEBUG
        if auswertungNr % 20 == 0 {
            let text = String(format: "Würfel: %.0f ms je Bild, nur Bereich %.0f %%, Helligkeit %.2f, %d×%d", rechenzeit, bereichsAnteil * 100, helligkeit, a.bild.width, a.bild.height)
            protokoll.debug("\(text, privacy: .public)")
        }
        #endif
    }

    /// Taschenlampe ein- oder ausschalten (z. B. Knopf bei `dunkel`). Geht beim Verlassen der Kamera-Seite aus; nach „Neu scannen“ wieder an.
    public func lampe(_ an: Bool) {
        guard let g = geraet, g.hasTorch else { lampeAn = false; return }
        guard an != lampeAn || an != (g.torchMode == .on) else { return }
        guard (try? g.lockForConfiguration()) != nil else { return }
        if an, g.isTorchAvailable {
            // Nicht ganz hell: Volle Stärke spiegelt auf glänzenden Würfeln und überstrahlt die Augen.
            try? g.setTorchModeOn(level: min(0.6, AVCaptureDevice.maxAvailableTorchLevel))
            lampeAn = g.torchMode == .on
        } else {
            g.torchMode = .off
            lampeAn = false
        }
        g.unlockForConfiguration()
    }

    // MARK: Standbild

    /// Merkt den Auslöser-Druck: Das Foto entsteht beim nächsten ruhigen Bild (der Druck selbst wackelt die Kamera).
    public func aufnehmen() {
        guard standbild == nil, !aufnahmeLaeuft else { return }
        aufnahmeLaeuft = true
        wartezeit = 0
        if eingefroren != nil { eingefroren = nil; wuerfel = verfolger.anzeige }
    }

    /// Ruhig und alles sicher erkannt – oder nach der Wartezeit – wird das aktuelle Bild zum Standbild.
    private func ausloesenPruefen(_ bild: CGImage, _ gesehen: [GesehenerWuerfel]) {
        wartezeit += 1
        let sicher = !wuerfel.isEmpty && wuerfel.allesSicher
        guard (ruhig && (sicher || wartezeit >= 20)) || wartezeit >= 50 else { return }
        let s = sitzung
        arbeit.async { if s.isRunning { s.stopRunning() } }
        puffer.ergebnis = nil
        if !(ruhig && sicher), let z = sicherer, auswertungNr - z.nr <= sichererFrist {
            // Das Auslösen wackelt: Das zuletzt sichere Ergebnis (mit seinem Bild) gilt, nicht das verwackelte Bild.
            verfolger = z.verfolger
            wuerfel = verfolger.anzeige
            standbild = UIImage(cgImage: z.bild)
            aufnahmeLaeuft = false
            return
        }
        if !(ruhig && sicher) {
            // Keine stabile Erkennung: eine Auswertung genügt, im Standbild gilt alles als sicher (korrigierbar per Tipp).
            verfolger = .einzelbild(seitenverhaeltnis: Double(bild.width) / Double(max(bild.height, 1)))
            wuerfel = verfolger.verarbeite(gesehen)
        }
        standbild = UIImage(cgImage: bild)
        aufnahmeLaeuft = false
    }

    /// Kleine JPEG-Ausschnitte der angezeigten Würfel aus dem letzten Bild (für den Funk: Spielgerät zeigt sie zum Prüfen).
    /// Je Würfel ein Quadrat von `kante` Pixeln; gleiche Reihenfolge wie `liste`. Ohne Bild: leer.
    public func ausschnitte(von liste: [AngezeigterWuerfel], kante: Int = 96, qualitaet: Double = 0.6) -> [Data] {
        guard let bild = letztesBild, !liste.isEmpty else { return [] }
        let b = Double(bild.width), h = Double(bild.height)
        var aus: [Data] = []
        for w in liste {
            // Quadrat um die Mitte des Rahmens, etwas größer als der Würfel, im Bild gehalten.
            let seite = min(max(w.rahmen.width * b, w.rahmen.height * h) * 1.15, min(b, h))
            let x = min(max(w.rahmen.midX * b - seite / 2, 0), b - seite)
            let y = min(max(w.rahmen.midY * h - seite / 2, 0), h - seite)
            guard seite >= 4, let teil = bild.cropping(to: CGRect(x: x, y: y, width: seite, height: seite).integral),
                  let ctx = CGContext(data: nil, width: kante, height: kante, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else { return [] }
            ctx.interpolationQuality = .medium
            ctx.draw(teil, in: CGRect(x: 0, y: 0, width: kante, height: kante))
            guard let klein = ctx.makeImage(), let d = LernAufnahme.jpeg(von: klein, qualitaet: qualitaet) else { return [] }
            aus.append(d)
        }
        return aus
    }

    /// Hält das Bild sofort an (ohne auf Ruhe zu warten): Die erkannten Würfel bleiben stehen und lassen sich in Ruhe prüfen und ändern.
    public func anhalten() {
        guard standbild == nil, let bild = letztesBild else { return }
        let s = sitzung
        arbeit.async { if s.isRunning { s.stopRunning() } }
        puffer.ergebnis = nil
        eingefroren = nil; aufnahmeLaeuft = false
        if !verfolger.anzeige.allesSicher, let z = sicherer, auswertungNr - z.nr <= sichererFrist {
            // Das Antippen wackelt: Das zuletzt sichere Ergebnis (mit seinem Bild) gilt.
            verfolger = z.verfolger
            wuerfel = verfolger.anzeige
            standbild = UIImage(cgImage: z.bild)
            return
        }
        wuerfel = verfolger.anzeige
        standbild = UIImage(cgImage: bild)
    }

    /// Entfernt einen Fund, der kein Würfel ist (nur im angehaltenen Bild sinnvoll).
    public func entferne(id: Int) {
        if lernAufnahme, let w = wuerfel.first(where: { $0.id == id }), standbild != nil {
            lernEntfernt.append(LernFund(augen: w.augen, x: Double(w.rahmen.minX), y: Double(w.rahmen.minY),
                                         breite: Double(w.rahmen.width), hoehe: Double(w.rahmen.height), sicherheit: w.sicher ? 1 : 0.5))
        }
        verfolger.entferne(id: id)
        wuerfel = verfolger.anzeige
    }

    /// Ein Würfel fehlt: Die Umgebung der angetippten Stelle (normiert 0…1) wird im Standbild noch einmal geprüft – ausgeschnitten,
    /// vergrößert und mit niedrigerer Schwelle. Im Live-Bild hält der Tipp zuerst an. Ein Fund wird als bestätigter Würfel ergänzt.
    public func pruefe(bei punkt: CGPoint) {
        if standbild == nil { anhalten() }
        guard let bild = standbild?.cgImage else { return }
        if case .laeuft = nachpruefung { return }
        nachpruefung = .laeuft(punkt)
        lernTipp = punkt
        let kanten = wuerfel.map { Double(max($0.rahmen.width * CGFloat(bild.width), $0.rahmen.height * CGFloat(bild.height))) }.sorted()
        let ueblich = kanten.isEmpty ? nil : kanten[kanten.count / 2] / Double(min(bild.width, bild.height))
        lernUeblich = ueblich
        let e = erkennung
        arbeit.async { [weak self] in
            let w = try? e.erkenneNah(in: bild, um: punkt, ueblicheKante: ueblich)
            Task { @MainActor in self?.nahErgebnis(w) }
        }
    }

    private func nahErgebnis(_ w: GesehenerWuerfel?) {
        guard standbild != nil else { nachpruefung = .ruht; return }   // inzwischen „Neu scannen“
        guard let w else { nachpruefung = .nichts; return }
        let schonDa = Set(wuerfel.map(\.id))
        let id = verfolger.fuegeHinzu(w)
        if !schonDa.contains(id) {
            lernErgaenzt[id] = LernErgaenzung(tipp: lernTipp ?? CGPoint(x: w.rahmen.midX, y: w.rahmen.midY), ueblicheKante: lernUeblich, erkannt: w.rahmen)
        }
        wuerfel = verfolger.anzeige
        nachpruefung = .gefunden(id)
    }

    public func neuAufnehmen() {
        nachpruefung = .ruht
        standbild = nil; aufnahmeLaeuft = false; eingefroren = nil; ruhig = false
        verfolger = WuerfelVerfolger(); wuerfel = []; leereFolge = 0; ruheFilter.zuruecksetzen()
        sicherer = nil
        lernNeu()
        liveAnschliessen()
        let s = sitzung
        // Mit dem Anhalten stoppt die Kamera und mit ihr die Lampe: nach dem Neustart wieder einschalten.
        let lampeWieder = lampeAn
        lampeAn = false
        arbeit.async { [weak self] in
            if !s.isRunning { s.startRunning() }
            if lampeWieder { Task { @MainActor in self?.lampe(true) } }
        }
    }

    // MARK: Korrektur

    public func korrigiere(id: Int, auf wert: Int) {
        if lernAlteWerte[id] == nil, let w = wuerfel.first(where: { $0.id == id }) { lernAlteWerte[id] = w.augen }
        verfolger.korrigiere(id: id, auf: wert)
        wuerfel = verfolger.anzeige
    }

    public func festhalten(id: Int) {
        verfolger.festhalten(id: id)
        wuerfel = verfolger.anzeige
    }

    public func zuruecksetzen() { verfolger.zuruecksetzen(); wuerfel = [] }

    // MARK: Lern-Aufnahme

    private func lernNeu() {
        lernAlteWerte = [:]; lernEntfernt = []; lernErgaenzt = [:]; lernTipp = nil; lernUeblich = nil; lernBereitsGespeichert = false
        puffer.lernRing?.leeren()
    }

    /// Der Wurf ist bestätigt („Übernehmen“, im Ausprobieren „Neu scannen“ oder Verlassen der Seite): Mit eingeschalteter Lern-Aufnahme werden
    /// Standbild, Rahmen, bestätigte Augen und die Bilder davor gespeichert. Ein Wurf wird nur einmal gespeichert. Ohne Würfel oder bei
    /// ausgeschalteter Lern-Aufnahme passiert nichts.
    public func bestaetige(erwartet: Int? = nil) {
        guard lernAufnahme, !lernBereitsGespeichert, !wuerfel.isEmpty else { return }
        guard let bild = standbild?.cgImage ?? letztesBild, let jpeg = LernAufnahme.jpeg(von: bild) else { return }
        lernBereitsGespeichert = true
        let liste = wuerfel.map { w -> LernWuerfel in
            let alt = lernAlteWerte[w.id]
            var r = LernRahmen(x: Double(w.rahmen.minX), y: Double(w.rahmen.minY), breite: Double(w.rahmen.width), hoehe: Double(w.rahmen.height))
            var erkannt: LernRahmen?
            // Ergänzter Würfel: Rahmen aus Tippunkt und üblicher Würfelgröße schätzen, der Rahmen des Nah-Finders bleibt zusätzlich erhalten.
            if let e = lernErgaenzt[w.id] {
                erkannt = LernRahmen(x: Double(e.erkannt.minX), y: Double(e.erkannt.minY), breite: Double(e.erkannt.width), hoehe: Double(e.erkannt.height))
                r = LernAufnahme.geschaetzterRahmen(e, breite: bild.width, hoehe: bild.height)
            }
            return LernWuerfel(id: w.id, augen: w.augen, x: r.x, y: r.y, breite: r.breite, hoehe: r.hoehe, sicher: w.sicher,
                               korrigiertVon: alt != nil && alt != w.augen ? alt : nil, ergaenzt: lernErgaenzt[w.id] != nil,
                               geschaetzt: lernErgaenzt[w.id] != nil, erkannterRahmen: erkannt)
        }
        let korrigiert = liste.contains { $0.korrigiertVon != nil || $0.ergaenzt } || !lernEntfernt.isEmpty
        let kennung = LernAufnahme.neueKennung(korrigiert: korrigiert)
        let wurf = LernWurf(id: kennung.id, zeit: kennung.iso, breite: bild.width, hoehe: bild.height, erwartet: erwartet,
                            korrigiert: korrigiert, wuerfel: liste, falscheFunde: lernEntfernt, geraet: UIDevice.current.model,
                            zoomFaktor: geraet.map { Double($0.videoZoomFactor) }, zoomStufe: zoomStufen.indices.contains(zoomIndex) ? zoomStufen[zoomIndex].name : nil,
                            zoomAutomatik: automatik)
        let vorher = puffer.lernRing?.alle() ?? []
        let name = kennung.ordnerName
        Task { [weak self] in
            let ok = await Task.detached(priority: .utility) { (try? LernAufnahme.speichere(wurf: wurf, ordnerName: name, standbild: jpeg, vorher: vorher)) != nil }.value
            if ok { self?.lernGespeichert += 1 } else { self?.lernBereitsGespeichert = false }
        }
    }

    // MARK: Zoom

    /// Von Hand gewählte Stufe (schaltet die Automatik aus).
    public func waehleZoom(_ index: Int) {
        automatik = false
        eingefroren = nil
        sucher.setze(index)
        zoomAnwenden(index, spurenBehalten: true)
    }

    /// `unsichtbar`: Automatik. Das letzte Bild und die letzten Ergebnisse bleiben stehen, bis die Probe beendet ist.
    /// `spurenBehalten`: von Hand gewählt. Die Würfel behalten Nummer und Wert, ihre Lage wird auf den neuen Ausschnitt umgerechnet.
    private func zoomAnwenden(_ index: Int, unsichtbar: Bool = false, spurenBehalten: Bool = false) {
        guard let g = geraet, zoomStufen.indices.contains(index) else { return }
        zoomIndex = index
        sicherer = nil   // ein Bild mit anderem Zoom passt nicht mehr zu den neuen Würfelspuren (und zu keinem Standbild)
        let vorher = g.videoZoomFactor
        if (try? g.lockForConfiguration()) != nil {
            g.videoZoomFactor = min(max(zoomStufen[index].faktor, g.minAvailableVideoZoomFactor), g.maxAvailableVideoZoomFactor)
            g.unlockForConfiguration()
        }
        ruheFilter.zuruecksetzen(); ruhig = false
        if spurenBehalten, vorher > 0 {
            verfolger.zoome(um: Double(g.videoZoomFactor / vorher))
            wuerfel = verfolger.anzeige
            puffer.verfolgt = []   // neuer Ausschnitt: einmal das ganze Bild absuchen
            return
        }
        verfolger.zuruecksetzen()   // Automatik probiert Stufen unabhängig voneinander: jede fängt neu an
        puffer.verfolgt = []
        if unsichtbar, let bild = letztesBild {
            if eingefroren == nil { eingefroren = UIImage(cgImage: bild) }
            einschwingZaehler = 10
        } else {
            wuerfel = []
        }
    }

    /// Stufen der besten Rückkamera. Virtuelle Geräte (Triple/Dual) schalten die Objektive über den Zoomfaktor um:
    /// 1,0 = Ultraweit (0,5×), erster Umschaltfaktor = Weitwinkel (1×), zweiter = Tele.
    static func stufen(fuer g: AVCaptureDevice) -> (stufen: [ZoomStufe], start: Int) {
        let sw = g.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat(truncating: $0) }
        var liste: [(String, CGFloat)] = []
        var weit = 0
        switch g.deviceType {
        case .builtInTripleCamera where sw.count >= 2:
            liste = [("0,5×", g.minAvailableVideoZoomFactor), ("1×", sw[0]), ("\(Int((sw[1] / sw[0]).rounded()))×", sw[1])]; weit = 1
        case .builtInDualWideCamera where sw.count >= 1:
            liste = [("0,5×", g.minAvailableVideoZoomFactor), ("1×", sw[0])]; weit = 1
        case .builtInDualCamera where sw.count >= 1:
            liste = [("1×", g.minAvailableVideoZoomFactor), ("\(Int((sw[0]).rounded()))×", sw[0])]
        default:
            liste = [("1×", 1)]
        }
        let ok = liste.filter { $0.1 <= g.maxAvailableVideoZoomFactor }
        return (ok.enumerated().map { ZoomStufe(id: $0.offset, name: $0.element.0, faktor: $0.element.1) }, min(weit, max(0, ok.count - 1)))
    }

    private var eingerichtet = false
    private func einrichten() -> Bool {
        if eingerichtet { return true }
        let suche = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
                                                     mediaType: .video, position: .back)
        guard let g = suche.devices.first, let eingang = try? AVCaptureDeviceInput(device: g) else { return false }
        sitzung.beginConfiguration()
        // 1080p: mehr Pixel je Würfel für das Augen-Netz (bei 720p bleiben einem kleinen Würfel rund 43 Pixel Kante).
        // Der Finder sieht dank der Bereichssuche trotzdem kaum mehr Rechenarbeit. Geht 1080p nicht, bleibt es bei 720p.
        sitzung.sessionPreset = sitzung.canSetSessionPreset(.hd1920x1080) ? .hd1920x1080 : .hd1280x720
        guard sitzung.canAddInput(eingang), sitzung.canAddOutput(ausgabe) else { sitzung.commitConfiguration(); return false }
        sitzung.addInput(eingang)
        ausgabe.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        ausgabe.alwaysDiscardsLateVideoFrames = true
        ausgabe.setSampleBufferDelegate(puffer, queue: arbeit)
        sitzung.addOutput(ausgabe)
        if let v = ausgabe.connection(with: .video), v.isVideoRotationAngleSupported(90) { v.videoRotationAngle = 90 }   // Hochformat
        sitzung.commitConfiguration()
        geraet = g
        lampeVerfuegbar = g.hasTorch && g.isTorchAvailable
        let (st, start) = Self.stufen(fuer: g)
        zoomStufen = st
        sucher = ZoomSucher(stufen: st.count, start: start, geduld: 24, probeLaenge: 15, einschwingen: 5)
        zoomAnwenden(start)
        eingerichtet = true
        return true
    }
}

/// Nimmt die Kamerabilder auf dem Hintergrund-Thread entgegen und lässt höchstens alle 0,1 s eines auswerten.
/// Sind Würfel verfolgt, wird meist nur ihr Bereich abgesucht; das ganze Bild alle `ganzAlle` Auswertungen,
/// sofort nach einer Bereichssuche mit weniger Funden als Spuren und immer, wenn nichts verfolgt wird.
final class Puffer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    struct Auswertung {
        var gesehen: [GesehenerWuerfel]
        /// Bildabweichung zum vorigen Bild (0…1).
        var bewegung: Double
        var bild: CGImage
        /// Mittlere Helligkeit (0…1).
        var helligkeit: Double
        /// Rechenzeit der Erkennung in Millisekunden.
        var rechenzeit: Double
        /// `true`: nur der Bereich um die verfolgten Würfel wurde abgesucht.
        var nurBereich: Bool
    }

    private let erkennung: WuerfelErkennung
    private let ci = CIContext()
    private let schloss = NSLock()
    private var letzte = Date.distantPast
    private var _ergebnis: ((Auswertung) -> Void)?
    private var _verfolgt: [CGRect] = []
    private var messer = RuheMesser()
    private var seitGanz = 0
    private var zuWenig = false
    private var _lernRing: LernRing?
    private var lernNummer = 0
    /// Ring der letzten Bilder für die Lern-Aufnahme (`nil`: aus, dann wird nichts kodiert).
    var lernRing: LernRing? {
        get { schloss.withLock { _lernRing } } set { schloss.withLock { _lernRing = newValue } }
    }
    /// Spätestens nach so vielen Auswertungen (ca. 0,6 s) wird wieder das ganze Bild abgesucht, damit neue Würfel auftauchen.
    static let ganzAlle = 6
    var ergebnis: ((Auswertung) -> Void)? {
        get { schloss.withLock { _ergebnis } } set { schloss.withLock { _ergebnis = newValue } }
    }
    /// Rahmen der gerade verfolgten Würfel (normiert), vom Hauptthread nach jeder Auswertung gesetzt. Leer: ganzes Bild absuchen.
    var verfolgt: [CGRect] {
        get { schloss.withLock { _verfolgt } } set { schloss.withLock { _verfolgt = newValue } }
    }
    init(erkennung: WuerfelErkennung) { self.erkennung = erkennung }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let jetzt = Date()
        guard jetzt.timeIntervalSince(letzte) >= 0.1, let px = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        letzte = jetzt
        let bild = CIImage(cvPixelBuffer: px)
        guard let cg = ci.createCGImage(bild, from: bild.extent) else { return }
        let mini = RuheMesser.miniatur(cg)
        let bewegung = messer.bewegung(mini)
        let helligkeit = mini.isEmpty ? 0.5 : Double(mini.reduce(0) { $0 + Int($1) }) / Double(mini.count) / 255
        let spuren = verfolgt
        // Starke Bewegung: Die Würfel können den Bereich verlassen haben, also ganz suchen.
        let ganz = spuren.isEmpty || zuWenig || seitGanz + 1 >= Self.ganzAlle || bewegung > 0.12
        seitGanz = ganz ? 0 : seitGanz + 1
        let start = DispatchTime.now().uptimeNanoseconds
        let gesehen = (try? erkennung.erkenne(in: cg, verfolgt: spuren, ganzesBild: ganz)) ?? []
        let ms = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
        zuWenig = !ganz && gesehen.count < spuren.count
        if let ring = lernRing {
            lernNummer += 1
            if lernNummer % LernAufnahme.ringAbstand == 0, let jpeg = LernAufnahme.jpeg(von: cg) {
                ring.merke(LernRingBild(jpeg: jpeg, funde: gesehen, zeit: jetzt, seitenverhaeltnis: Double(cg.width) / Double(max(cg.height, 1))))
            }
        }
        ergebnis?(Auswertung(gesehen: gesehen, bewegung: bewegung, bild: cg, helligkeit: helligkeit, rechenzeit: ms, nurBereich: !ganz))
    }
}

struct KameraVorschau: UIViewRepresentable {
    let sitzung: AVCaptureSession
    func makeUIView(context: Context) -> Ansicht {
        let v = Ansicht()
        v.schicht.session = sitzung
        v.schicht.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ v: Ansicht, context: Context) {}
    final class Ansicht: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var schicht: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
#endif
