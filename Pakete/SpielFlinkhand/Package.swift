// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Flinkhand: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielFlinkhand",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielFlinkhand", targets: ["SpielFlinkhand"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "FlinkhandKern"),
        .target(name: "SpielFlinkhand", dependencies: ["FlinkhandKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "FlinkhandKernTests", dependencies: ["FlinkhandKern"]),
    ],
    swiftLanguageModes: [.v5]
)
