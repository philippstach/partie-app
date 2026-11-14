// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Luegenwuerfel: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielLuegenwuerfel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielLuegenwuerfel", targets: ["SpielLuegenwuerfel"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "LuegenwuerfelKern"),
        .target(name: "SpielLuegenwuerfel", dependencies: ["LuegenwuerfelKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "LuegenwuerfelKernTests", dependencies: ["LuegenwuerfelKern"]),
    ],
    swiftLanguageModes: [.v5]
)
