// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Kern von „Mau-Mau“: Karten, frei kombinierbare Hausregeln, Spielzustand, Runden mit Punkten, Computer. Nur Foundation, mit swift test auf dem Mac prüfbar.
let package = Package(
    name: "KernMauMau",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "MauMauKern", targets: ["MauMauKern"])],
    targets: [
        .target(name: "MauMauKern"),
        .testTarget(name: "MauMauKernTests", dependencies: ["MauMauKern"]),
    ],
    swiftLanguageModes: [.v5]
)
