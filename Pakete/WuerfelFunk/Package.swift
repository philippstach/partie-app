// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Zweites Gerät als Würfelscanner: Das iPhone liest die Würfel mit WuerfelLive und schickt jeden Wurf per MultipeerConnectivity
// (direkt, ohne Server und ohne Konto) an das Spielgerät. Melder und Empfang laufen mit `swift test`, die Verbindung und Ansichten sind iOS-only.
let package = Package(
    name: "WuerfelFunk",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "WuerfelFunk", targets: ["WuerfelFunk"])],
    dependencies: [.package(path: "../WuerfelLive")],
    targets: [
        .target(name: "WuerfelFunk", dependencies: [.product(name: "WuerfelLive", package: "WuerfelLive")]),
        .testTarget(name: "WuerfelFunkTests", dependencies: ["WuerfelFunk"]),
    ]
)
