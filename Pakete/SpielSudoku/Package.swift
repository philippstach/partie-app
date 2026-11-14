// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielSudoku",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSudoku", targets: ["SpielSudoku"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../KernSudoku"),
    ],
    targets: [
        .target(name: "SpielSudoku", dependencies: [
            .product(name: "SudokuKern", package: "KernSudoku"),
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ], swiftSettings: [.enableUpcomingFeature("InferIsolatedConformances"), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
        .testTarget(name: "SpielSudokuTests", dependencies: ["SpielSudoku"]),
    ],
    swiftLanguageModes: [.v6]
)
