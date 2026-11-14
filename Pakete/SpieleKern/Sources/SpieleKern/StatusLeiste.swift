// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// AUS-008 / T-059, zweiter Anlauf. NICHT SYNTAXGEPRÜFT (Cloud-Chat, kein swiftc).
#if canImport(UIKit)
import SwiftUI
import UIKit

// Statusleiste (Uhr, Akku) hell, solange dunkler Filz SICHTBAR oben liegt, und sonst nichts.
//
// Warum nicht über das Farbschema: Die Statusleiste fragt den Stil beim Wurzel-Controller des Fensters ab. Den Stil über
// `overrideUserInterfaceStyle` des Fensters zu setzen (erster Anlauf) macht alles im Fenster dunkel: Startseite, Spielseite, Blätter.
// `preferredColorScheme` färbt die ganze Präsentation und verliert gegen die Wahl „Hell“ an der Wurzel. Den Wurzel-Controller von SwiftUI
// (`UIHostingController`) kann die App nicht unterklassen, ohne die Szene selbst aufzubauen.
//
// Darum: Solange ein Tisch oben sichtbar ist, liegt über dem App-Fenster ein leeres, durchlässiges Fenster, dessen Controller
// `.lightContent` meldet. UIKit nimmt den Statusleisten-Stil vom obersten sichtbaren Fenster, das ihn bestimmen kann (so arbeiten auch
// Hinweis-Bibliotheken mit eigenem Fenster). Das Fenster zeichnet nichts, nimmt keine Berührung an, wird nie Schlüsselfenster und ist für
// VoiceOver leer. Ist kein Tisch mehr sichtbar, wird es versteckt und freigegeben; dann gilt wieder der Stil der App wie vorher.

/// Hält je Szene fest, welche Anker gerade eine helle Statusleiste wünschen, und zeigt oder versteckt das Statusleisten-Fenster.
@MainActor enum StatusLeisteHell {
    private static var wuensche: [ObjectIdentifier: Set<ObjectIdentifier>] = [:]
    private static var fenster: [ObjectIdentifier: UIWindow] = [:]

    static func anmelden(_ anker: AnyObject, _ szene: UIWindowScene) {
        let k = ObjectIdentifier(szene)
        wuensche[k, default: []].insert(ObjectIdentifier(anker))
        abgleichen(szene)
    }

    static func abmelden(_ anker: AnyObject, _ szene: UIWindowScene) {
        let k = ObjectIdentifier(szene)
        wuensche[k]?.remove(ObjectIdentifier(anker))
        if wuensche[k]?.isEmpty == true { wuensche[k] = nil }
        abgleichen(szene)
    }

    /// Für Tests und den Prüfweg: Wünscht gerade ein Anker in dieser Szene eine helle Leiste?
    static func aktiv(_ szene: UIWindowScene) -> Bool { !(wuensche[ObjectIdentifier(szene)]?.isEmpty ?? true) }

    private static func abgleichen(_ szene: UIWindowScene) {
        let k = ObjectIdentifier(szene)
        if aktiv(szene) {
            guard fenster[k] == nil else { return }
            let f = StatusLeisteFenster(windowScene: szene)
            f.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)
            f.rootViewController = StatusLeisteController()
            f.isHidden = false   // sichtbar, aber nie `makeKey`: Eingaben, Tastatur und Fokus bleiben im App-Fenster
            fenster[k] = f
            f.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        } else if let f = fenster.removeValue(forKey: k) {
            f.isHidden = true
            f.rootViewController = nil
            // Die App bestimmt die Leiste wieder selbst
            for w in szene.windows { w.rootViewController?.setNeedsStatusBarAppearanceUpdate() }
        }
    }
}

/// Leeres Fenster über der App: lässt jede Berührung durch und ist für VoiceOver unsichtbar.
private final class StatusLeisteFenster: UIWindow {
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }
    required init?(coder: NSCoder) { fatalError("nicht benutzt") }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
    override var canBecomeKey: Bool { false }
}

/// Controller des Statusleisten-Fensters: nur der Stil der Leiste, keine Ansicht.
private final class StatusLeisteController: UIViewController {
    override func loadView() {
        let v = UIView()
        v.backgroundColor = .clear
        v.isOpaque = false
        v.isUserInteractionEnabled = false
        v.accessibilityElementsHidden = true
        view = v
    }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var prefersStatusBarHidden: Bool { false }
}

/// Anker im Ansichtsbaum: meldet sich an, solange `hell` gilt und er in einem Fenster hängt; sonst ab.
private struct StatusLeisteAnker: UIViewRepresentable {
    let hell: Bool
    func makeUIView(context: Context) -> AnkerAnsicht {
        let v = AnkerAnsicht()
        v.isUserInteractionEnabled = false
        v.accessibilityElementsHidden = true
        return v
    }
    func updateUIView(_ v: AnkerAnsicht, context: Context) { v.hell = hell }
    static func dismantleUIView(_ v: AnkerAnsicht, coordinator: ()) { v.loesen() }

    final class AnkerAnsicht: UIView {
        var hell = false { didSet { if hell != oldValue { abgleichen() } } }
        private weak var szene: UIWindowScene?

        override func didMoveToWindow() { super.didMoveToWindow(); abgleichen() }

        func loesen() {
            guard let alt = szene else { return }
            szene = nil
            MainActor.assumeIsolated { StatusLeisteHell.abmelden(self, alt) }
        }

        private func abgleichen() {
            let soll = hell ? window?.windowScene : nil
            if soll === szene { return }
            loesen()
            if let soll {
                szene = soll
                MainActor.assumeIsolated { StatusLeisteHell.anmelden(self, soll) }
            }
        }
    }
}

/// Wann ein Bereich die Statusleiste hell braucht: Er reicht oben bis an den Rand des Fensters und deckt die Höhe der Leiste ab.
enum StatusLeisteRegel {
    /// Höhe, die der Bereich mindestens nach unten reichen muss (Statusleiste mit Dynamic Island etwa 54 pt, iPad 24 pt).
    static let leistenHoehe: CGFloat = 54
    static func bedecktOben(_ rahmen: CGRect) -> Bool { rahmen.minY <= 1 && rahmen.maxY >= leistenHoehe }
}

private struct StatusLeisteHellModifier: ViewModifier {
    let aktiv: Bool
    let nurWennOben: Bool
    @State private var sichtbar = false
    @State private var oben = false

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { g in
                    let bedeckt = StatusLeisteRegel.bedecktOben(g.frame(in: .global))
                    StatusLeisteAnker(hell: aktiv && sichtbar && (!nurWennOben || oben))
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                        .onAppear { oben = bedeckt }
                        .onChange(of: bedeckt) { _, neu in oben = neu }
                }
            }
            // Sichtbarkeit statt Fensterzugehörigkeit: Eine verdeckte oder entfernte Seite meldet sich ab.
            .onAppear { sichtbar = true }
            .onDisappear { sichtbar = false }
    }
}

public extension View {
    /// AUS-008: Statusleiste (Uhr, Akku) hell, solange diese Ansicht sichtbar ist und `aktiv` gilt. Ändert kein Farbschema.
    /// `nurWennOben`: nur, solange die Ansicht oben bis an den Fensterrand reicht (Filzkopf, der beim Schieben aus dem Bild geht).
    func statusLeisteHell(_ aktiv: Bool, nurWennOben: Bool = false) -> some View {
        modifier(StatusLeisteHellModifier(aktiv: aktiv, nurWennOben: nurWennOben))
    }
}
#endif
