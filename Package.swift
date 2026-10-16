// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MintSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MintSDK",
            targets: ["MintFrameworks", "VoltFramework"]
        ),
        .library(
            name: "MintFrameworks",
            targets: ["MintFrameworks"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "MintFrameworks",
            url: "https://github.com/investwell-tools/mint-ios-sdk/releases/download/1.1.1/MintFrameworks.xcframework.zip",
            checksum: "23c60452c71fa874f50fe8aede5b2cfb966a149dd34113929018810ff9722207"
        ),
        .binaryTarget(
            name: "VoltFramework",
            url: "https://github.com/investwell-tools/mint-ios-sdk/releases/download/1.1.1/VoltFramework.xcframework.zip",
            checksum: "1bcbb2a1c04ab1208bd690323dcf1945303b52a85fc3b72135a28a336c09089a"
        )
    ]
)
