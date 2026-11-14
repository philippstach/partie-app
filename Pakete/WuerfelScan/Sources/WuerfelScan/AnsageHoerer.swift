// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import AVFoundation
import Observation
import Speech

/// Hört über das Mikrofon zu und liefert die angesagten Würfelaugen. Die Spracherkennung läuft auf dem Gerät:
/// Kann das Gerät das für die Sprache nicht, ist die Ansage nicht verfügbar (es wird nichts an einen Server geschickt).
/// Der Ton wird nicht gespeichert.
@MainActor @Observable
public final class AnsageHoerer {
    public enum Zustand: Equatable { case bereit, hoert, verweigert, nichtVerfuegbar }
    public private(set) var zustand: Zustand = .bereit
    /// Bisher verstandene Augen (höchstens so viele wie verlangt).
    public private(set) var augen: [Int] = []
    /// `true`, sobald eine Ansage zu Ende ist (voll, Stille oder von Hand beendet).
    public private(set) var beendet = false

    private var erkenner: SFSpeechRecognizer?
    private let maschine = AVAudioEngine()
    private var anfrage: SFSpeechAudioBufferRecognitionRequest?
    private var auftrag: SFSpeechRecognitionTask?
    private var stille: Task<Void, Never>?
    private var hoechstens = 5

    public init() {}

    /// Sprache der App (de, en, es, fr), sonst die des Geräts.
    static var sprache: Locale {
        switch Bundle.main.preferredLocalizations.first?.prefix(2) {
        case "de": Locale(identifier: "de-DE")
        case "en": Locale(identifier: "en-US")
        case "es": Locale(identifier: "es-ES")
        case "fr": Locale(identifier: "fr-FR")
        default: Locale.current
        }
    }

    /// Ob dieses Gerät Ansagen in der App-Sprache auf dem Gerät erkennen kann.
    public static var verfuegbar: Bool {
        guard let e = SFSpeechRecognizer(locale: sprache) else { return false }
        return e.supportsOnDeviceRecognition
    }

    /// Fragt beim ersten Mal nach Mikrofon und Spracherkennung und hört dann zu, bis `hoechstens` Augen verstanden sind,
    /// etwa zwei Sekunden nichts mehr kommt oder `stoppen()` gerufen wird.
    public func starten(hoechstens: Int) async {
        guard zustand != .hoert else { return }
        self.hoechstens = max(1, hoechstens)
        augen = []; beendet = false
        guard let e = SFSpeechRecognizer(locale: Self.sprache), e.supportsOnDeviceRecognition, e.isAvailable else { zustand = .nichtVerfuegbar; return }
        let sprechen = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        guard sprechen, await AVAudioApplication.requestRecordPermission() else { zustand = .verweigert; return }
        erkenner = e
        do {
            let sitzung = AVAudioSession.sharedInstance()
            try sitzung.setCategory(.record, mode: .measurement, options: .duckOthers)
            try sitzung.setActive(true, options: .notifyOthersOnDeactivation)
            let a = SFSpeechAudioBufferRecognitionRequest()
            a.shouldReportPartialResults = true
            a.requiresOnDeviceRecognition = true
            a.contextualStrings = WuerfelAnsage.hoerhilfe
            anfrage = a
            let eingang = maschine.inputNode
            let format = eingang.outputFormat(forBus: 0)
            // Ohne nutzbares Mikrofon (z. B. belegt durch ein Telefonat) würde das Anzapfen abstürzen.
            guard format.sampleRate > 0, format.channelCount > 0 else { aufraeumen(); zustand = .nichtVerfuegbar; return }
            eingang.removeTap(onBus: 0)
            eingang.installTap(onBus: 0, bufferSize: 1024, format: format) { puffer, _ in a.append(puffer) }
            maschine.prepare()
            try maschine.start()
            auftrag = e.recognitionTask(with: a) { [weak self] ergebnis, fehler in
                let text = ergebnis?.bestTranscription.formattedString
                let fertig = ergebnis?.isFinal ?? false
                Task { @MainActor in self?.verarbeite(text, fertig: fertig || fehler != nil) }
            }
            zustand = .hoert
            wecker(nach: 6)
        } catch {
            aufraeumen()
            zustand = .nichtVerfuegbar
        }
    }

    private func verarbeite(_ text: String?, fertig: Bool) {
        guard zustand == .hoert else { return }
        if let text {
            let neu = Array(WuerfelAnsage.augen(aus: text).prefix(hoechstens))
            if neu != augen { augen = neu; wecker(nach: 2.2) }
        }
        if augen.count >= hoechstens || fertig { stoppen() }
    }

    /// Beendet das Zuhören, wenn so lange nichts Neues verstanden wurde.
    private func wecker(nach sekunden: Double) {
        stille?.cancel()
        stille = Task { [weak self] in
            try? await Task.sleep(for: .seconds(sekunden))
            guard !Task.isCancelled else { return }
            self?.stoppen()
        }
    }

    public func stoppen() {
        guard zustand == .hoert else { return }
        aufraeumen()
        zustand = .bereit
        beendet = true
    }

    private func aufraeumen() {
        stille?.cancel(); stille = nil
        if maschine.isRunning { maschine.stop() }
        maschine.inputNode.removeTap(onBus: 0)
        anfrage?.endAudio(); anfrage = nil
        auftrag?.cancel(); auftrag = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
#else
import Observation

/// Ohne Mikrofon (macOS-Tests): Ansage nicht verfügbar.
@MainActor @Observable
public final class AnsageHoerer {
    public enum Zustand: Equatable { case bereit, hoert, verweigert, nichtVerfuegbar }
    public private(set) var zustand: Zustand = .nichtVerfuegbar
    public private(set) var augen: [Int] = []
    public private(set) var beendet = false
    public init() {}
    public static var verfuegbar: Bool { false }
    public func starten(hoechstens: Int) async {}
    public func stoppen() {}
}
#endif
