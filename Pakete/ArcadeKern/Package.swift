// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// ArcadeKern: gemeinsamer Baustein aller Arcade-Spiele (Foundation, mit swift test auf dem Mac prüfbar).
// Takt, Zufall, Kollision, Schwierigkeitskurve, Rekord. Siehe Doku/ARCADE-KONZEPT.md.
let package = Package(
    name: "ArcadeKern",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "ArcadeKern", targets: ["ArcadeKern"])],
    targets: [
        .target(name: "ArcadeKern"),
        .testTarget(name: "ArcadeKernTests", dependencies: ["ArcadeKern"]),
    ],
    swiftLanguageModes: [.v5]
)
