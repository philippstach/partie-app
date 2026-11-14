// swift-tools-version: 5.9
// SPDX-License-Identifier: MIT
import PackageDescription

// Reine Spiellogik ohne Oberfläche. Läuft auch auf dem Mac (`swift test`), kein Simulator nötig.
let package = Package(
    name: "MinensucheKern",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "MinensucheKern", targets: ["MinensucheKern"])],
    targets: [
        .target(name: "MinensucheKern"),
        .testTarget(name: "MinensucheKernTests", dependencies: ["MinensucheKern"]),
    ]
)
