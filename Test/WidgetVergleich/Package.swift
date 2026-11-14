// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Designwechsel: Beweis, dass die Widgets in „Klar & Glas“ unverändert aussehen. Werkzeug/designwechsel_widget_vergleich.sh kopiert
// die Widget-Quellen (Widget/*.swift und Widget/Geteilt) des jeweiligen Baums nach Sources/WidgetKopie (mit zwei mechanischen Änderungen:
// ohne @main-Bündel, `containerBackground(for: .widget)` als `background`, damit der Hintergrund im Bild erscheint) und zeichnet feste Szenen.
let package = Package(
    name: "WidgetVergleich",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "WidgetKopie", targets: ["WidgetKopie"])],
    dependencies: [.package(path: "../../../_Gemeinsam/Baukasten")],
    targets: [
        .target(name: "WidgetKopie", dependencies: [.product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "WidgetVergleichTests", dependencies: ["WidgetKopie", .product(name: "KlarGlas", package: "Baukasten")]),
    ]
)
