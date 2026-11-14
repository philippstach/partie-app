// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Bauplan RL-K, Punkt 4 und 5 (Blatt 26): „Alle Regeln lesen“ mit Abschnitten, Listen, Beispiel-Kästen, Tabellen und dem Knopf „Inhalt“.
/// `kopf` ist ein Platz über dem ersten Abschnitt (Bauplan RS). Maße aus `werkzeug/e26.py`.
public struct RegelLeseAnsicht<Kopf: View>: View {
    let spielName: String
    let spielID: String
    let wissen: (any RegelWissen)?
    let kopf: Kopf
    /// Bauplan RS (Solitär): Wert gesetzt → die Seite springt zum Abschnitt mit diesem Titel.
    let springeZu: Binding<String?>?
    private let bloecke: [RegelBlock]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var schriftStufe
    @State private var aktuell: Int?

    public init(quelle: String, spielName: String, spielID: String, wissen: (any RegelWissen)?, springeZu: Binding<String?>? = nil, @ViewBuilder kopf: () -> Kopf = { EmptyView() }) {
        self.spielName = spielName; self.spielID = spielID; self.wissen = wissen; self.kopf = kopf(); self.springeZu = springeZu
        self.bloecke = RegelBlock.bloecke(aus: quelle)
    }

    private var gross: Bool { schriftStufe.isAccessibilitySize }

    private func text(_ s: String) -> Text {
        // Farbzeichen als Schriftzeichen, nicht als buntes Bild
        var t = s
        for z in ["♣", "♠", "♥", "♦"] { t = t.replacingOccurrences(of: z, with: z + "\u{FE0E}") }
        if let a = try? AttributedString(markdown: t, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) { return Text(a) }
        return Text(verbatim: t)
    }

    public var body: some View {
        let inhalt = RegelBlock.abschnitte(in: bloecke)
        NavigationStack {
            ScrollViewReader { leser in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 11) {
                        Text(verbatim: spielName).font(.caption2.weight(.semibold)).tracking(1.4).textCase(.uppercase).foregroundStyle(Color.schriftZweit)
                        kopf
                        ForEach(Array(bloecke.enumerated()), id: \.offset) { i, b in block(b, erster: i == 0 || isErsterAbschnitt(i)) }
                    }
                    .scrollTargetLayout()
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollPosition(id: $aktuell, anchor: .top)
                .onChange(of: springeZu?.wrappedValue) { _, titel in
                    guard let titel, let a = inhalt.first(where: { $0.titel == titel }) else { return }
                    withAnimation { leser.scrollTo(abschnittKennung(a.id), anchor: .top) }
                    springeZu?.wrappedValue = nil
                }
                .background(Color.seitenGrund)
                .regelFrageLeiste(spielID: spielID, wissen: wissen)
                .navigationTitle("Regeln").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } }
                    if inhalt.count > 1 {
                        ToolbarItem(placement: .topBarLeading) {
                            Menu {
                                ForEach(inhalt, id: \.id) { a in
                                    Button { withAnimation { leser.scrollTo(abschnittKennung(a.id), anchor: .top) } } label: {
                                        if aktuellerAbschnitt(inhalt) == a.id { Label(a.titel, systemImage: "circle.fill") } else { Text(a.titel) }
                                    }
                                }
                            } label: { Image(systemName: "list.bullet").accessibilityLabel(Text("Inhalt", bundle: .main)) }
                        }
                    }
                }
            }
        }
    }

    private func abschnittKennung(_ id: Int) -> String { "abschnitt-\(id)" }

    private func isErsterAbschnitt(_ i: Int) -> Bool {
        guard case .abschnitt = bloecke[i] else { return false }
        return !bloecke[..<i].contains { if case .abschnitt = $0 { return true } else { return false } }
    }

    private func aktuellerAbschnitt(_ inhalt: [(id: Int, titel: String)]) -> Int? {
        guard let a = aktuell, a >= 0, a < bloecke.count else { return inhalt.first?.id }
        for i in stride(from: a, through: 0, by: -1) { if case let .abschnitt(id, _) = bloecke[i] { return id } }
        return inhalt.first?.id
    }

    @ViewBuilder private func block(_ b: RegelBlock, erster: Bool) -> some View {
        switch b {
        case let .abschnitt(id, titel):
            VStack(alignment: .leading, spacing: 8) {
                if !erster { Color.linie.frame(height: 1).padding(.top, 22) }
                Text(verbatim: titel).font(Design.Schrift.serif(25, gewicht: .medium, relativ: .title2, hoechstens: 1.9))
                    .padding(.top, erster ? 8 : 22).accessibilityAddTraits(.isHeader)
            }.id(abschnittKennung(id))
        case let .zwischentitel(t):
            text(t).font(.body.weight(.semibold)).padding(.top, 4)
        case let .absatz(t):
            text(t).font(.body).frame(maxWidth: .infinity, alignment: .leading)
        case let .liste(punkte):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(punkte.enumerated()), id: \.offset) { _, p in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle().fill(Color.schriftZweit).frame(width: 5, height: 5).offset(y: -3)
                        text(p.text).font(.body).frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.leading, p.ebene == 0 ? 0 : 22)
                }
            }
        case let .nummern(punkte):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(punkte.enumerated()), id: \.offset) { i, p in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(verbatim: "\(i + 1)").font(Design.Schrift.serif(19, gewicht: .regular, relativ: .title3)).foregroundStyle(Color.schriftZweit).frame(minWidth: 22, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 6) {
                            text(p.text).font(.body).frame(maxWidth: .infinity, alignment: .leading)
                            if let bsp = p.beispiel { beispielKasten(bsp) }
                        }
                    }
                }
            }
        case let .beispiel(t):
            beispielKasten(t)
        case let .tabelle(kopf, zeilen, form):
            tabelle(kopf: kopf, zeilen: zeilen, form: form)
        }
    }

    private func beispielKasten(_ t: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Beispiel", bundle: .main).font(.caption2.weight(.semibold)).tracking(1.2).textCase(.uppercase).foregroundStyle(Color.schriftZweit)
            text(t).font(.callout).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Color.kartenGrund, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.linie, lineWidth: 1))
    }

    private func etikett(_ s: String) -> some View {
        Text(verbatim: s).font(.caption2.weight(.semibold)).tracking(1.2).textCase(.uppercase).foregroundStyle(Color.schriftZweit)
    }

    @ViewBuilder private func tabelle(kopf: [String], zeilen: [[String]], form: RegelBlock.Form) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch form {
            case .zwei, .a where !gross:
                HStack { ForEach(Array(kopf.enumerated()), id: \.offset) { i, k in etikett(k).frame(maxWidth: .infinity, alignment: i == 0 ? .leading : .trailing) } }
                Color.schrift.frame(height: 1).padding(.top, 6)
                ForEach(Array(zeilen.enumerated()), id: \.offset) { _, z in
                    HStack(alignment: .firstTextBaseline) {
                        ForEach(Array(z.enumerated()), id: \.offset) { i, c in
                            text(c).font(i == 0 ? .body.weight(.semibold) : .body.monospacedDigit()).frame(maxWidth: .infinity, alignment: i == 0 ? .leading : .trailing)
                                .multilineTextAlignment(i == 0 ? .leading : .trailing)
                        }
                    }.padding(.vertical, 10)
                    Color.linie.frame(height: 1)
                }
            case .b:
                Color.schrift.frame(height: 1)
                ForEach(Array(zeilen.enumerated()), id: \.offset) { _, z in
                    VStack(alignment: .leading, spacing: 3) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .firstTextBaseline) {
                                text(z.first ?? "").font(.body.weight(.semibold))
                                Spacer(minLength: 8)
                                text("Standard: " + (z.count > 1 ? z[1] : "")).font(.footnote).foregroundStyle(Color.schriftZweit)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                text(z.first ?? "").font(.body.weight(.semibold))
                                text("Standard: " + (z.count > 1 ? z[1] : "")).font(.footnote).foregroundStyle(Color.schriftZweit)
                            }
                        }
                        if let letzte = z.last, z.count > 2 { text(letzte).font(.subheadline).foregroundStyle(Color.schriftZweit) }
                    }.padding(.vertical, 10)
                    Color.linie.frame(height: 1)
                }
            default:   // C, und A bei größter Schrift: erste Zelle halbfett, darunter „Kopf: Wert“
                Color.schrift.frame(height: 1)
                ForEach(Array(zeilen.enumerated()), id: \.offset) { _, z in
                    VStack(alignment: .leading, spacing: 3) {
                        text(z.first ?? "").font(.body.weight(.semibold))
                        ForEach(Array(z.dropFirst().enumerated()), id: \.offset) { i, c in
                            let k = i + 1 < kopf.count ? kopf[i + 1] : ""
                            (Text(verbatim: k.isEmpty ? "" : k + ": ").foregroundStyle(Color.schriftZweit) + text(c)).font(.subheadline)
                        }
                    }.padding(.vertical, 10)
                    Color.linie.frame(height: 1)
                }
            }
        }
    }
}
#endif
