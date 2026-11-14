// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei (Spielerfarben und Avatare sind Spielinhalt, DESIGN.md 3.6)
import SwiftUI
import KlarGlas

extension Theme {
    static let avatars = ["😎", "🤠", "🧠", "👑", "🦁", "🐯", "🦊", "🐺", "🦄", "🐲", "👾", "🤖",
                          "🎩", "🧙", "🥷", "👻", "🎭", "🍀", "⚡", "🔥", "💎", "🌙", "🌈", "🎯"]

    /// Spielerfarben = Familienfarben (wie das Spielerverzeichnis der Sammlung); die erste ist Orange, die Farbe von 10k.
    static let playerHex: [UInt32] = [Familienfarbe.orange, .blau, .gruen, .rot, .violett, .pink, .tuerkis, .braun, .indigo, .schiefer, .limette].map(\.flaeche)

    static let playerColors: [Color] = playerHex.map { Color.familie($0) }

    static let maxPlayers = 8

    static func color(_ index: Int) -> Color { playerColors[((index % playerColors.count) + playerColors.count) % playerColors.count] }

    /// Spielerfarbe für Text: im hellen Modus abgedunkelt, damit sie lesbar bleibt.
    static func textColor(_ index: Int) -> Color {
        let hex = playerHex[((index % playerHex.count) + playerHex.count) % playerHex.count]
        return Color.spielerText(hex: hex)
    }

    static func points(_ value: Int) -> String {
        value.formatted(.number.locale(Locale(identifier: "de_DE")))
    }
}

extension Player {
    var color: Color { Theme.color(colorIndex) }
    var textColor: Color { Theme.textColor(colorIndex) }
}

/// Sheets auf dem iPad als Formular-Blatt statt Vollbild (ab iOS 18; auf dem iPhone ohne Wirkung).
/// `gross`: größeres Blatt (Seitengröße), z. B. für die Einführung mit großen Motiven.
struct FormBlatt: ViewModifier {
    var gross = false

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            if gross {
                content.presentationSizing(.page)
            } else {
                content.presentationSizing(.form)
            }
        } else {
            content
        }
    }
}

extension View {
    func formBlatt(gross: Bool = false) -> some View { modifier(FormBlatt(gross: gross)) }

    /// Einführung: auf dem iPhone Vollbild, auf dem iPad als Formular-Blatt (SPEC-1.1 §4)
    func einfuehrung<C: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
                              @ViewBuilder content: @escaping () -> C) -> some View {
        modifier(EinfuehrungsBlatt(isPresented: isPresented, onDismiss: onDismiss, inhalt: content))
    }

    /// Wie `einfuehrung(isPresented:)`, für einzelne Kapitel
    func einfuehrung<Item: Identifiable, C: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> C) -> some View {
        modifier(EinfuehrungsKapitel(item: item, inhalt: content))
    }

}

/// Nebeneinander – bei sehr großer Schrift (Bedienungshilfen) untereinander.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var spacing: CGFloat = 10
    @ViewBuilder let content: Content

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        layout { content }
    }
}

// MARK: - iPad (horizontalSizeClass == .regular)

extension Theme {
    /// Maximalbreite einer Spalte auf dem iPad (iPhone: 520)
    /// Ab dieser Fensterbreite zweispaltig: iPad quer (11″ 1.194, 13″ 1.376 pt) und große Stage-Manager-Fenster.
    /// Hochkant (11″ 834, 13″ 1.032 pt) bleibt es einspaltig mit großen Würfeln.
    static let twoColumnMinWidth: CGFloat = 1_100
    /// Spieltisch (iPad breit): Knopfleiste höchstens so breit (SPEC-1.1 §3)
    static let tischKnopfBreite: CGFloat = 720
}

/// Nur auf dem iPad: Inhalt auf `maxWidth` begrenzen und zentrieren. Auf dem iPhone unverändert.
struct WideReadableWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let maxWidth: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
                .background(Color.seitenGrund)
        } else {
            content
        }
    }
}

extension View {
    func wideReadableWidth(_ maxWidth: CGFloat = 720) -> some View { modifier(WideReadableWidth(maxWidth: maxWidth)) }
}

/// Unsichtbare Knöpfe, die nur Tastaturkurzbefehle tragen (iPad mit Tastatur).
struct KeyboardShortcutButtons<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack { content }
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
    }
}

private struct EinfuehrungsBlatt<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let inhalt: () -> C

    func body(content: Content) -> some View {
        if Geraet.aktuell == .iPad {
            content.sheet(isPresented: $isPresented, onDismiss: onDismiss) { inhalt().formBlatt(gross: true) }
        } else {
            content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss, content: inhalt)
        }
    }
}

private struct EinfuehrungsKapitel<Item: Identifiable, C: View>: ViewModifier {
    @Binding var item: Item?
    let inhalt: (Item) -> C

    func body(content: Content) -> some View {
        if Geraet.aktuell == .iPad {
            content.sheet(item: $item) { inhalt($0).formBlatt(gross: true) }
        } else {
            content.fullScreenCover(item: $item, content: inhalt)
        }
    }
}

extension EnvironmentValues {
    /// Spieltisch-Maßstab (iPad, breites Layout): große Würfel, Schrift aus 1–1,5 m lesbar (SPEC-1.1 §3)
    @Entry var tischGross = false
    /// Spieltisch: freie Höhe für die Würfelkarte (0 = unbekannt); begrenzt die Würfelgröße
    @Entry var tischHoehe: CGFloat = 0
}

