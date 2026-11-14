// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import CoreSpotlight
import KlarGlas
import Baukasten
import SpieleKern
import WuerfelLive
import WuerfelScan
import SpielMinensuche
import SpielFarbraetsel
import SpielYacht
import SpielSchocken
import SpielRauswurf
import SpielSudoku
import SpielViererreihe
import SpielGalgenmaennchen
import SpielSolitaer
import SpielWortpfeil
import Spiel10kModul
import SpielUngleichung
import SpielKoenigsweg
import SpielSchiffsfracht
import SpielFarbflut
import SpielSpitSpeed
import SpielCrazyEights
import SpielEsel
import SpielSteckspiel
import SpielKaestchenjagd
import SpielPatolli
import SpielSechseck
import SpielFarbcode
import SpielLagerplatz
import SpielFuchsjagd
import SpielBunco
import SpielOware
import SpielChinchon
import SpielDomino
import SpielPokerwurf
import SpielBrisca
import SpielHoelzchen
import SpielHimmelsleiter
import SpielFlinkhand
import SpielKartenduell
import SpielTruco
import SpielEscoba
import SpielHerzensjagd
import SpielPechvogel
import SpielKreuzwurf
import SpielStufenstapel
import SpielFarbwechsel
import SpielIrrgang
import SpielPaarsuche
import SpielMauerbrecher
import SpielDauerlauf
import SpielWolkenhuepfer
import SpielSteinfall
import SpielBallwechsel
import SpielRomme
import SpielBackgammon
import SpielKakuro
import SpielBruecken
import SpielMahjongPaare
import SpielSchach
import SpielStadtLandFluss
import SpielHalma
import SpielMogeln
import SpielLuegenwuerfel
import SpielElferRaus
import SpielChicago
import SpielNonogramm
import SpielMauMau
import SpielSchweinerei
import SpielSchiffe
import SpielMaexchen
import SpielSiebzehn
import SpielDame
import SpielWendespiel
import SpielKalaha
import SpielZahlenfusion
import SpielHanoi
import SpielLichterAus
import SpielSchwimmen
import SpielMuehle
import SpielSchiebepuzzle
import SpielKlappbrett
import Spiel10k

final class PartieDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let konfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        konfig.delegateClass = PartieSzenenDelegate.self
        return konfig
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        MainActor.assumeIsolated { SpielAusrichtung.maske() }
    }
}

@main
struct PartieApp: App {
    @UIApplicationDelegateAdaptor(PartieDelegate.self) private var delegate
    @State private var spieler: SpielerVerzeichnis
    @State private var statistik: StatistikDienst
    @State private var favoriten: Favoriten
    @State private var icloud: IcloudVerwalter
    @Environment(\.scenePhase) private var szenenPhase
    @State private var turnier: TurnierDienst
    @AppStorage("darstellung") private var darstellungRaw = Darstellung.system.rawValue
    @AppStorage("farbenUnterscheidbar") private var farbenUnterscheidbar = false

    init() {
        Rundgang.vorbereiten()   // nur mit -rundgang (UI-Rundgang)
        DesignWahl.setzeVoreinstellung(PartieGeteilt.standardDesign)   // als Erstes: ohne gespeicherte Wahl gilt der Standard (auch in der Einführung)
        StandardErkennung.fuerFotoScanEinsetzen()
        FunkEinsetzen.einsetzen()
        AnsageEinsetzen.einsetzen()   // Würfel per Sprache in den Eingabe-Blättern (KI-9)
        let spieler = SpielerVerzeichnis()
        let statistik = StatistikDienst()
        _spieler = State(initialValue: spieler)
        _statistik = State(initialValue: statistik)
        let icloud = IcloudVerwalter(spieler: spieler, statistik: statistik)
        _icloud = State(initialValue: icloud)
        let turnier = TurnierDienst()
        _turnier = State(initialValue: turnier)
        let favoriten = Favoriten()
        _favoriten = State(initialValue: favoriten)
        FavoritenAktionen.aktualisieren(favoriten.ids)
        Leiter.istSichtbar = { id in SpielKatalog.spielbar.contains { $0.id == SpielKatalog.kennung(id) } }   // T-6: Leiter nur für Spiele, die es gibt
        let spiegeln = { SpielerQuelle.bekannt = spieler.zuletztGespielt.map { ($0.name, $0.avatar, Spieler.farbenHex[$0.farbeIndex % Spieler.farbenHex.count]) } }
        spieler.nachAenderung = spiegeln
        spiegeln()
        SpielerQuelle.anmelden = { namen in for n in namen { spieler.anlegen(name: n) } }
        // Spiele melden beendete Partien; die Hülle ordnet Namen den Spielern zu und verbucht (Konzept 3/4)
        PartieMeldung.senke = { e in
            let e = spieler.zuordnen(e, computerNamen: PartieMeldung.computerNamen)
            spieler.gespielt(e.teilnehmer.compactMap(\.spielerID))
            statistik.melden(e)
            turnier.partieBeendet(e)
            WidgetAbgleich.partie(statistik, spiel: e.spiel, ich: spieler.ich?.id)
            icloud.spaeter()   // E7
            GameCenterBruecke.geteilt.partieBeendet(e, statistik: statistik, ich: spieler.ich?.id)
        }
        // Hülle in Nachtblau, im Spiel die Spielfarbe (Konzept 5.2). Die Haken lesen den beobachteten `Spielfarbe`-Zustand:
        // Ansichten, die `appFlaeche`/`accentText` benutzen, zeichnen sich beim Wechsel von selbst neu.
        KlarGlasHaken.flaeche = { MainActor.assumeIsolated { Spielfarbe.geteilt.aktuell?.color ?? Huelle.flaeche } }
        // Design-Runde 3 (Tinte): Im Spiel ist die Schrift für Knöpfe und Wörter überall die helle bzw. dunkle Schriftfarbe des Designs,
        // nicht mehr je Spielart rot, grün oder blau (rote Schrift auf dunklem Grund war schwer lesbar). Klar und Salon wie bisher.
        KlarGlasHaken.accentText = { MainActor.assumeIsolated {
            if Design.ist(.tinte), Spielfarbe.geteilt.aktuell != nil { return Color.schrift }
            return Spielfarbe.geteilt.aktuell?.textFarbe ?? Huelle.akzent
        } }
        // Designwechsel: Bausteine lesen die Spielart des offenen Spiels (Palette je Design); nach einem Wechsel die Auswahl
        // in die App Group spiegeln (Widget), Zeitleisten neu laden und die Navigationstitel umstellen.
        KlarGlasHaken.spielart = { MainActor.assumeIsolated { Spielfarbe.geteilt.gattung?.designSpielart } }
        KlarGlasHaken.spielName = { MainActor.assumeIsolated { Spielfarbe.geteilt.name } }
        // Gewinnerseite (Salon): Porträt des Siegers aus dem Spielerverzeichnis (Foto, Farbe, Zeichen); ohne Treffer nil.
        KlarGlasHaken.spielerBild = { name in
            MainActor.assumeIsolated {
                let n = name.trimmingCharacters(in: .whitespaces)
                guard let p = spieler.menschen.first(where: { $0.name.caseInsensitiveCompare(n) == .orderedSame }) else { return nil }
                return (bild: p.bildNr != nil ? SpielerBilder.daten(p.id) : nil, farbe: Spieler.farbe(p.farbeIndex), zeichen: p.zeichen)
            }
        }
        KlarGlasHaken.designGewechselt = { art in
            Task { @MainActor in
                WidgetAbgleich.designAbgleichen(art)
                Design.navigationsleisteAnwenden()
            }
        }
        WidgetAbgleich.designAbgleichen()
        Design.navigationsleisteAnwenden()
        GameCenterBruecke.geteilt.anmelden()   // Game Center im Hintergrund, nur wenn an und nicht im Kinder-Modus
        AktivitaetVerwalter.anmelden()   // E5: Live Activity für Partien mit mehreren Menschen
        // Spielstart jedes Spiels zeigt Spielart-Farbe und Miniatur wie die Startseite (Spieleabend)
        SpielRahmenHaken.istArcade = { id in SpielKatalog.modul(id)?.gattung == .arcade }
        RegelWissenAnbindung.installieren()   // KI-3: „Frag nach den Regeln“ in den Spielen (nur mit Apple Intelligence sichtbar)
        RegelLeseAnbindung.installieren()   // Blatt 26 / RL-K: „Alle Regeln lesen“ mit Abschnitten (nur Deutsch)
        SpielRahmenHaken.bild = { id in SpielKatalog.modul(id).map { .init(farbe: $0.gattung.farbe.color, miniatur: SpielMiniaturen.art($0), spielart: $0.gattung.anzeigeName) } }
    }

    var body: some Scene {
        WindowGroup {
            WurzelAnsicht()
                .wuerfelScannerAnfrage()   // Anfrage eines unbekannten Würfelscanners, auf jeder Seite der App
                .environment(spieler)
                .environment(statistik)
                .environment(favoriten)
                .environment(icloud)
                .environment(turnier)
                .tint(Huelle.akzent)
                .environment(\.farbenUnterscheidbar, farbenUnterscheidbar)
                .preferredColorScheme((Darstellung(rawValue: darstellungRaw) ?? .system).farbschema)
                .onChange(of: szenenPhase) { _, neu in if neu == .active { icloud.jetzt() } }   // E7
        }
    }
}

/// Welches Spiel gerade offen ist (nil = Sammlung): bestimmt Fläche und Textfarbe der KlarGlas-Bausteine.
@Observable @MainActor
final class Spielfarbe {
    static let geteilt = Spielfarbe()
    /// ID des offenen Spiels (nil = Hülle). Farbe, Spielart und Name werden daraus gelesen, damit sie dem gewählten Design folgen.
    var spiel: String?
    private var modul: (any SpielModul)? { SpielKatalog.modul(spiel) }
    /// Spielart des offenen Spiels (nil = Hülle).
    var gattung: Gattung? { modul?.gattung }
    /// Name des offenen Spiels (Kopfzeile der Gewinnerseite in Salon).
    var name: String? { modul?.name }
    /// Farbe des offenen Spiels im gewählten Design (`SpielModul.spielFarbe`).
    var aktuell: AkzentFarbeWert? { modul?.spielFarbe }
}

enum Huelle {
    /// Fläche der Hülle: Tischgrund, Hauptknopf, Farbblock. klar: Nachtblau wie das Partie-Logo (Startseite „Spieleabend“,
    /// 05.11.2026); Tinte: Tinte; Salon: Terrakotta (Werte in `DesignWerte`).
    static var flaeche: Color {
        Design.art == .klar ? AkzentFarbeWert.nachtblau.color : Design.werte.huelleFlaeche.color
    }

    /// Akzent für Text, Symbole und Links in der Hülle (Tint). Das dunkle Nachtblau (1F3A5F) liest sich auf Schwarz mit 1,8:1 nicht;
    /// hier ein kräftiges Blau je Darstellung: hell 1658D8 (≥ 5,5:1 auf Weiß und Gruppengrund), dunkel 6FA8FF (≥ 5,8:1 auf Schwarz und Grau 2C2C2E).
    /// Tinte und Salon: der Hüllen-Akzent des Designs.
    static var akzent: Color {
        guard Design.art == .klar else { return Design.werte.huelleAkzent.color }
        return klarAkzent
    }

    private static let klarAkzent = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(Color(hex: Design.Farbe.akzentDunkel))
                                      : UIColor(Color(hex: Design.Farbe.akzentHell))
    })
}

extension SpielModul {
    /// Farbe eines offenen Spiels: die Farbe der Spielart. Ausnahme Kreuzworträtsel (Wortpfeil, 10.11.2026): Design-Akzent 1658D8 / 6FA8FF.
    /// Designwechsel: Die Ausnahme gilt nur in „Klar & Glas“; in Tinte und Salon nimmt auch das Kreuzworträtsel die Farbe seiner Spielart.
    var spielFarbe: AkzentFarbeWert {
        id == "wortpfeil" && Design.ist(.klar) ? AkzentFarbeWert(flaeche: Design.Farbe.akzentHell, textHell: Design.Farbe.akzentHell, textDunkel: Design.Farbe.akzentDunkel)
                          : gattung.farbe
    }
    /// Tint (Knöpfe, Schalter, Systemdialoge) eines offenen Spiels; im Kreuzworträtsel der Akzent der Hülle, der in hell und dunkel lesbar ist.
    var spielTint: Color { id == "wortpfeil" && Design.ist(.klar) ? Huelle.akzent : gattung.farbe.kontrastTint }
}

/// Die einzige Liste der Spiele (Konzept 6.2).
@MainActor
enum SpielKatalog {
    /// Alle gebauten Module (auch Arcade), je Spiel genau eine Fassung. Ausgeblendet wird nur, der Code bleibt.
    static let alleModule: [any SpielModul] = [
        MinensucheModul(),
        YachtModul(),
        SchockenModul(),
        RauswurfModul(),
        SudokuModul(),
        ViererreiheModul(),
        GalgenmaennchenModul(),
        SolitaerModul(),
        WortpfeilModul(),
        ZehnKModul(),
        UngleichungModul(),
        KoenigswegModul(),
        SchiffsfrachtModul(),
        FarbflutModul(),
        SpitSpeedModul(),
        CrazyEightsModul(),
        EselModul(),
        SteckspielModul(),
        KaestchenjagdModul(),
        PatolliModul(),
        SechseckModul(),
        FarbcodeModul(),
        LagerplatzModul(),
        FuchsjagdModul(),
        BuncoModul(),
        OwareModul(),
        ChinchonModul(),
        DominoModul(),
        DominoModul(id: "dominocubano", name: "Dominó Cubano", hoechstAugen: 9, handgroesse: 10),
        PokerwurfModul(),
        BriscaModul(),
        HoelzchenModul(),
        HimmelsleiterModul(),
        FlinkhandModul(),
        KartenduellModul(),
        TrucoModul(),
        EscobaModul(),
        HerzensjagdModul(),
        PechvogelModul(),
        KreuzwurfModul(),
        StufenstapelModul(),
        FarbwechselModul(),
        IrrgangModul(),
        PaarsucheModul(),
        MauerbrecherModul(),
        DauerlaufModul(),
        WolkenhuepferModul(),
        SteinfallModul(),
        BallwechselModul(),
        RommeModul(),
        BackgammonModul(),
        BackgammonModul(id: "aceydeucey", name: "Acey-Deucey", regeln: .aceyDeucey, regelText: "Alle 15 Steine starten auf der Bar und müssen einzeln einsteigen. Zieht wie beim Backgammon, aber: Würfelst du 1 und 2 (Acey-Deucey), spielst du beide Augen, wählst dann einen beliebigen Pasch (1–6), spielst ihn und würfelst noch einmal. Steine dürfen sich auf dem Heimweg überspringen; wer zuerst alle 15 abgetragen hat, gewinnt."),
        KakuroModul(),
        BrueckenModul(),
        MahjongPaareModul(),
        SchachModul(),
        StadtLandFlussModul(),
        HalmaModul(),
        MogelnModul(),
        LuegenwuerfelModul(),
        LuegenwuerfelModul.perudo,
        ElferRausModul(),
        ChicagoModul(),
        NonogrammModul(),
        MauMauModul(),
        SchweinereiModul(),
        SchiffeModul(),
        MaexchenModul(),
        SiebzehnModul(),
        DameModul(),
        WendespielModul(),
        KalahaModul(),
        ZahlenfusionModul(),
        HanoiModul(),
        LichterAusModul(),
        SchwimmenModul(),
        MuehleModul(),
        SchiebepuzzleModul(),
        KlappbrettModul(),
        FarbraetselModul(),
    ]
    /// Frühere Kennungen (Einzel-App-Zeit) und die Speicherkennung, unter der das Spiel heute läuft.
    /// Die Speicherkennungen („…-neu“) bleiben, damit Spielstände, Statistik und Favoriten der Tester erhalten bleiben.
    /// Widget, Kurzbefehle, Spotlight, Glossar und Tabellen dürfen weiter die frühere Kennung nennen.
    nonisolated static let frueher: [String: String] = [
        "yacht": "yacht-neu", "schocken": "schocken-neu", "rauswurf": "rauswurf-neu", "sudoku": "sudoku-neu",
        "viererreihe": "viererreihe-neu", "galgenmaennchen": "galgenmaennchen-neu", "solitaer": "solitaer-neu",
        "10k": "10k-neu", "fuchsjagd": "fuchsjagd-neu", "elferraus": "elferraus-neu", "maumau": "maumau-neu",
        "schwimmen": "schwimmen-neu",
    ]
    /// Kennung, unter der das Spiel heute im Katalog steht (frühere Kennungen werden umgeleitet).
    nonisolated static func kennung(_ id: String) -> String { frueher[id] ?? id }
    /// Die 26 Spiele der Version 1.0 (Doku/START-SPIELE-1.0.md).
    static let standardModule: [any SpielModul] = Startauswahl.grundIDs.compactMap { modul($0) }
    /// Spielbare Spiele: normal die 26, im Entwicklermodus alle.
    static var spielbar: [any SpielModul] { Entwickler.an ? alleModule : standardModule }
    static var alle: [any SpielModul] { spielbar }
    /// Schlägt auch ausgeblendete Module nach; frühere Kennungen führen zum heutigen Spiel.
    static func modul(_ id: String?) -> (any SpielModul)? {
        guard let id else { return nil }
        let k = kennung(id)
        return alleModule.first { $0.id == k }
    }
}

struct WurzelAnsicht: View {
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(StatistikDienst.self) private var statistik
    @Environment(Favoriten.self) private var favoriten
    @AppStorage("startetMit") private var startetMit = ""
    @AppStorage("zuletztGespielt") private var zuletzt = ""
    @State private var offen: String?
    @State private var gestartet = false
    @AppStorage("einfuehrungVersion") private var einfuehrungVersion = ""
    @State private var einfuehrung = false
    /// T-009: Ob die Einführung als „Was ist neu?“ läuft, steht beim Öffnen fest. Würde es im Cover laufend neu berechnet, kippte es
    /// nach dem Anlegen des Spielers (hatSpieler) auf den Update-Bildschirm und übersprang den Rest der Einführung.
    @State private var einfuehrungIstUpdate = false
    @State private var fensterBreite: CGFloat = 0   // Breite des Fensters (iPad: Split View, Stage Manager), nicht des Bildschirms
    /// Designwechsel: Zähler für den einmaligen Neuaufbau der Wurzel und das Design, mit dem sie zuletzt gebaut wurde.
    @State private var aufbau = 0
    @State private var gebautMit = Design.art
    @Environment(\.accessibilityReduceMotion) private var weniger

    private func oeffnen(_ id: String?) {
        if let id, !SpielKatalog.spielbar.contains(where: { $0.id == SpielKatalog.kennung(id) }) { return }   // T-6: nicht freigegebene Spiele (nicht unter den 26) öffnen auch über Deep-Link, Siri, Spotlight und Widget nicht; im Entwicklermodus schon
        if let id, !Modi.erlaubt(id) { return }   // Kinder-Modus: gesperrte Spiele öffnen auch über Widget, Siri und Spotlight nicht
        let id = id.map(SpielKatalog.kennung)   // frühere Kennung (Widget, Kurzbefehl, Spotlight) öffnet das heutige Spiel
        if id == nil { OffenesSpiel.direktWunsch = nil }   // ein nicht eingelöster Wunsch „Weiterspielen“ gilt nur für diesen einen Start
        Spielfarbe.geteilt.spiel = id   // Farbe, Spielart und Name folgen daraus (und dem gewählten Design)
        offen = id
    }

    var body: some View {
        Group {
            if let modul = SpielKatalog.modul(offen) {
                SpielHost(modul: modul, zurueck: { oeffnen(nil) })
                    .transition(.move(edge: .trailing))
            } else {
                StartSeite(oeffnen: { oeffnen($0) })
                    .transition(.move(edge: .leading))
            }
        }
        .designWurzel()   // Designwechsel: `\.designArt` und Vordergrund (Tinte, Salon); in klar nichts
        .tint(Huelle.akzent)   // hier (in einer Ansicht) gelesen, damit der Tint dem Design folgt; Spiele setzen ihren eigenen
        .id(aufbau)
        .accessibilityHidden(einfuehrung)   // N-010: Solange die Einführung offen ist, liest VoiceOver nicht die Startseite dahinter
        // Designwechsel: Nach dem Schließen der Einstellungen die Wurzel einmal neu aufbauen, aber nur ohne offenes Spiel.
        .onReceive(NotificationCenter.default.publisher(for: .partieDesignNeuaufbau)) { _ in
            guard offen == nil, gebautMit != Design.art else { return }
            gebautMit = Design.art
            aufbau += 1
        }
        .background(GeometryReader { g in
            Color.clear.onAppear { fensterBreite = g.size.width }.onChange(of: g.size.width) { _, w in fensterBreite = w }
        })
        .animation(weniger ? nil : .easeInOut(duration: 0.25), value: offen)
        // Alternativen zum Randwisch für VoiceOver/Schaltersteuerung
        .accessibilityAction(named: offen != nil ? Text("Zur Startseite") : Text("Zuletzt gespieltes Spiel öffnen")) {
            if offen != nil { oeffnen(nil) } else if SpielKatalog.modul(zuletzt) != nil, !(Modi.kinder && Modi.gesperrt.contains(zuletzt)) { oeffnen(zuletzt) }
        }
        // Wischen: vom linken Rand zurück zur Startseite, vom rechten Rand wieder ins letzte Spiel (nur Randwisch, damit Spiele ihre Gesten behalten)
        .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { w in
            let breite = fensterBreite > 0 ? fensterBreite : UIScreen.main.bounds.width
            let letztesErlaubt = SpielKatalog.modul(zuletzt) != nil && !(Modi.kinder && Modi.gesperrt.contains(zuletzt))
            switch Randwisch.aktion(start: w.startLocation, bewegung: w.translation, breite: breite, spielOffen: offen != nil, letztesErlaubt: letztesErlaubt) {
            case .zurueckZurStartseite: oeffnen(nil)
            case .letztesSpiel: oeffnen(zuletzt)
            case nil: break
            }
        })
        .fullScreenCover(isPresented: $einfuehrung) {
            EinfuehrungBlatt(update: einfuehrungIstUpdate) { StartLayout.ausEinfuehrung(favoriten.ids); einfuehrungVersion = Version.aktuell; einfuehrung = false }   // Fund 4/44: Auswahl auf die Startseite
                .designWurzel()
                .environment(spieler)   // die Einführung legt den Spieler „Ich“ an
                .environment(favoriten)   // das Blatt liest Favoriten; ein Cover erbt das Environment nicht in jedem Host (Test-Host)
                .interactiveDismissDisabled()
        }
        .onAppear {
            guard !gestartet else { return }
            gestartet = true
            Modi.ruheAnwenden()
            WidgetAbgleich.kinderModusAbgleichen()
            if Einfuehrung.zeigen(gespeichert: einfuehrungVersion, aktuell: Version.aktuell) {
                einfuehrungIstUpdate = Einfuehrung.istUpdate(gespeichert: einfuehrungVersion, hatSpieler: !spieler.alle.isEmpty)
                einfuehrung = true
            }
            #if DEBUG
            if !startetMit.isEmpty { Testzustaende.vorbereiten(startetMit) }   // nur Debug: -testZustand kurzVorEnde|ende
            #endif
            if let id = AktionsPost.offen, SpielKatalog.modul(id) != nil { oeffnen(id); AktionsPost.offen = nil }
            else if !startetMit.isEmpty, SpielKatalog.sichtbar.contains(where: { $0.id == startetMit }) { oeffnen(startetMit) }
        }
        .onChange(of: offen) { _, neu in if let neu { zuletzt = neu; WidgetAbgleich.zuletzt(neu) } }
        .fensterTint(offen == nil ? Huelle.flaeche : (SpielKatalog.modul(offen)?.spielTint ?? Huelle.flaeche))
        .onReceive(NotificationCenter.default.publisher(for: .partieOeffneSpiel)) { n in
            if let id = n.object as? String, SpielKatalog.modul(id) != nil { oeffnen(id); AktionsPost.offen = nil }
        }
        .onAppear { SpielSpotlight.aktualisieren(); if !zuletzt.isEmpty { WidgetAbgleich.zuletzt(zuletzt) } }
        .onContinueUserActivity(CSSearchableItemActionType) { a in
            if let id = SpielSpotlight.id(aus: a), SpielKatalog.modul(id) != nil { oeffnen(id) }
        }
        .onOpenURL { url in
            // partie://spiel/<id>
            if let l = RaetselLink(url: url), SpielKatalog.sichtbar.contains(where: { $0.id == l.spiel }), RaetselPost.ablegen(l) { oeffnen(l.spiel); return }
            if url.scheme == "partie", url.host == "zufall", let id = SpielKatalog.sichtbar.randomElement()?.id { oeffnen(id); return }
            if url.scheme == "partie", url.host == "tagesraetsel", let id = WidgetAbgleich.naechstesTagesraetsel() { oeffnen(id); return }
            if url.scheme == "partie", url.host == "letztes", SpielKatalog.modul(zuletzt) != nil { oeffnen(zuletzt); return }
            if url.scheme == "partie", url.host == "spiel", let id = url.pathComponents.dropFirst().first, SpielKatalog.modul(id) != nil { oeffnen(id) }
        }
    }
}

extension Notification.Name {
    /// Designwechsel: die Einstellungen wurden geschlossen; die Wurzel prüft, ob sie neu aufbauen muss.
    static let partieDesignNeuaufbau = Notification.Name("partie.design.neuaufbau")
}

/// Zeigt ein Spiel in der Farbe seiner Spielart (Startseite „Spieleabend“: Farbe = Spielart); Farbwechsel beim Betreten, Rückstellung beim Verlassen (Konzept 5.2).
struct SpielHost: View {
    let modul: any SpielModul
    let zurueck: () -> Void
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(StatistikDienst.self) private var statistik
    @AppStorage("wuerfelQuelle") private var quelleRaw = WuerfelQuelle.app.rawValue
    @AppStorage("startetMit") private var startetMit = ""

    var body: some View {
        let umgebung = SpielUmgebung(spieler: spieler, statistik: statistik, wuerfelQuelle: WuerfelQuelle(rawValue: quelleRaw) ?? .app, zurueck: zurueck)
        modul.start(umgebung)
            .environment(\.spielUmgebung, umgebung)
            .tint(modul.spielTint)
            .fensterTint(modul.spielTint)
            .id(modul.id)

    }
}
