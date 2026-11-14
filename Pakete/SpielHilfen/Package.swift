// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// SpielHilfen: gemeinsame Bausteine für Mehrspieler-Spiele der Sammlung (Übergabe-Seite, Rangliste, Tier-Motive).
let package = Package(
    name: "SpielHilfen",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielHilfen", targets: ["SpielHilfen"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "SpielHilfen", dependencies: [.product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "SpielHilfenTests", dependencies: ["SpielHilfen"]),
    ],
    swiftLanguageModes: [.v5]
)
