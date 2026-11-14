// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Kern von „Sudoku“: Spielarten 9×9, 6×6, X-Sudoku, Löser, Erzeuger, Partie. Nur Foundation, mit swift test auf dem Mac prüfbar.
let package = Package(
    name: "KernSudoku",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SudokuKern", targets: ["SudokuKern"])],
    targets: [
        .target(name: "SudokuKern"),
        .testTarget(name: "SudokuKernTests", dependencies: ["SudokuKern"]),
    ],
    swiftLanguageModes: [.v6]
)
