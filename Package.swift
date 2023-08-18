// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "IBM-1401-Emulator",
    products: [
        .executable(name: "IBM-1401-Emulator", targets: ["IBM-1401-Emulator"])
    ],
    dependencies: [
        .package(url: "https://github.com/sanzaru/lib1401.git", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "IBM-1401-Emulator",
            dependencies: [
                .product(name: "Lib1401", package: "Lib1401"),
            ]
        ),
        .testTarget(
            name: "IBM-1401-EmulatorTests",
            dependencies: [
                "IBM-1401-Emulator",
                .product(name: "Lib1401", package: "Lib1401"),
            ]
        ),
    ]
)
