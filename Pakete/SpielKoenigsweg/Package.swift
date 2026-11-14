// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Koenigsweg: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielKoenigsweg",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielKoenigsweg", targets: ["SpielKoenigsweg"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "KoenigswegKern"),
        .target(name: "SpielKoenigsweg", dependencies: ["KoenigswegKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "KoenigswegKernTests", dependencies: ["KoenigswegKern"]),
    ],
    swiftLanguageModes: [.v5]
)
