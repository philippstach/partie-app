// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Sechseck: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSechseck",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSechseck", targets: ["SpielSechseck"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "SechseckKern"),
        .target(name: "SpielSechseck", dependencies: ["SechseckKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "SechseckKernTests", dependencies: ["SechseckKern"]),
    ],
    swiftLanguageModes: [.v5]
)
