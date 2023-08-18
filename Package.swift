// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "IBM-1401-Emulator",
    products: [
        .executable(name: "IBM-1401-Emulator", targets: ["IBM-1401-Emulator"])
    ],
    dependencies: [
        .package(name: "Lib1401", path: "../Lib1401")
    ],
    targets: [
        .executableTarget(
            name: "IBM-1401-Emulator",
            dependencies: ["Lib1401"]),
        .testTarget(
            name: "IBM-1401-EmulatorTests",
            dependencies: ["IBM-1401-Emulator", "Lib1401"]),
    ]
)
