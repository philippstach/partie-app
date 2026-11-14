// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Hoelzchen: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielHoelzchen",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielHoelzchen", targets: ["SpielHoelzchen"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "HoelzchenKern"),
        .target(name: "SpielHoelzchen", dependencies: ["HoelzchenKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "HoelzchenKernTests", dependencies: ["HoelzchenKern"]),
    ],
    swiftLanguageModes: [.v5]
)
