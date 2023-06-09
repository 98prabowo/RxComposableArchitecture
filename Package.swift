// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxComposableArchitecture",
    platforms: [
      .iOS(.v11),
      .macOS(.v10_15),
      .tvOS(.v13),
      .watchOS(.v6),
    ],
    products: [
        .library(
            name: "RxComposableArchitecture",
            targets: ["RxComposableArchitecture"]),
        .library(
            name: "RxComposableArchitectureUI",
            targets: ["RxComposableArchitectureUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: Version(0, 14, 1)),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: Version(6, 6, 0)),
        .package(url: "https://github.com/shimastripe/Texture.git", from: Version(3, 1, 1))
    ],
    targets: [
        .target(
            name: "RxComposableArchitecture",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "RxComposableArchitectureTests",
            dependencies: [
                "RxComposableArchitecture",
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
        .target(
            name: "RxComposableArchitectureUI",
            dependencies: [
                "RxComposableArchitecture",
                .product(name: "AsyncDisplayKit", package: "Texture"),
            ]
        ),
        .testTarget(
            name: "RxComposableArchitectureUITests",
            dependencies: [
                "RxComposableArchitectureUI",
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
    ]
)
