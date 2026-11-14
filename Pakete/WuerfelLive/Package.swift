// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Live-Würfelerkennung per Kamera (rudimentär). Erkennung und Stabilisierung laufen mit `swift test` ohne Simulator,
// Kamera und Ansicht sind iOS-only. Baut auf der Augenzählung aus WuerfelScan (F6) auf.
let package = Package(
    name: "WuerfelLive",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "WuerfelLive", targets: ["WuerfelLive"])],
    dependencies: [.package(path: "../WuerfelScan")],
    targets: [
        .target(name: "WuerfelLive", dependencies: [.product(name: "WuerfelScan", package: "WuerfelScan")], resources: [.copy("Modell")]),
        .testTarget(name: "WuerfelLiveTests", dependencies: ["WuerfelLive"]),
    ]
)
