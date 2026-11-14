// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Hanoi: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielHanoi",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielHanoi", targets: ["SpielHanoi"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "HanoiKern"),
        .target(name: "SpielHanoi", dependencies: ["HanoiKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "HanoiKernTests", dependencies: ["HanoiKern"]),
    ],
    swiftLanguageModes: [.v5]
)
