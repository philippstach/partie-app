// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// MahjongPaare: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielMahjongPaare",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielMahjongPaare", targets: ["SpielMahjongPaare"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "MahjongPaareKern"),
        .target(name: "SpielMahjongPaare", dependencies: ["MahjongPaareKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "MahjongPaareKernTests", dependencies: ["MahjongPaareKern"]),
    ],
    swiftLanguageModes: [.v5]
)
