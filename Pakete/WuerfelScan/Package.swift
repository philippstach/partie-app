// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// F6: Echte Würfel per Kamera erkennen. Kern (Vision, CoreGraphics) läuft mit `swift test` ohne Simulator,
// die Ansichten (Kamera, Prüfblatt) sind iOS-only.
let package = Package(
    name: "WuerfelScan",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "WuerfelScan", targets: ["WuerfelScan"])],
    dependencies: [
        .package(path: "../Baukasten"),
    ],
    targets: [
        .target(name: "WuerfelScan", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
        ]),
        .testTarget(name: "WuerfelScanTests", dependencies: ["WuerfelScan"]),
    ]
)
