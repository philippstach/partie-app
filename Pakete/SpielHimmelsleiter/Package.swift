// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Himmelsleiter: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielHimmelsleiter",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielHimmelsleiter", targets: ["SpielHimmelsleiter"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "HimmelsleiterKern"),
        .target(name: "SpielHimmelsleiter", dependencies: ["HimmelsleiterKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "HimmelsleiterKernTests", dependencies: ["HimmelsleiterKern"]),
    ],
    swiftLanguageModes: [.v5]
)
