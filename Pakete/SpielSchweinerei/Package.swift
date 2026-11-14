// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Schweinerei: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSchweinerei",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchweinerei", targets: ["SpielSchweinerei"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "SchweinereiKern"),
        .target(name: "SpielSchweinerei", dependencies: ["SchweinereiKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "SchweinereiKernTests", dependencies: ["SchweinereiKern"]),
    ],
    swiftLanguageModes: [.v5]
)
