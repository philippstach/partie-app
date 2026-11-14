// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Kreuzwurf: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielKreuzwurf",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielKreuzwurf", targets: ["SpielKreuzwurf"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "KreuzwurfKern"),
        .target(name: "SpielKreuzwurf", dependencies: ["KreuzwurfKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "KreuzwurfKernTests", dependencies: ["KreuzwurfKern"]),
    ],
    swiftLanguageModes: [.v5]
)
