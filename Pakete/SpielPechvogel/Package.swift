// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Pechvogel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielPechvogel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielPechvogel", targets: ["SpielPechvogel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "PechvogelKern"),
        .target(name: "SpielPechvogel", dependencies: ["PechvogelKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "PechvogelKernTests", dependencies: ["PechvogelKern"]),
    ],
    swiftLanguageModes: [.v5]
)
