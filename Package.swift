// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VehicleRentalSystem",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(name: "VehicleRentalCore", targets: ["VehicleRentalCore"]),
        .executable(name: "VehicleRentalDemo", targets: ["VehicleRentalDemo"])
    ],
    targets: [
        .target(name: "VehicleRentalCore"),
        .executableTarget(name: "VehicleRentalDemo", dependencies: ["VehicleRentalCore"]),
        .testTarget(name: "VehicleRentalCoreTests", dependencies: ["VehicleRentalCore"])
    ]
)
