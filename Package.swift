// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxComposableArchitecture",
    platforms: [
      .iOS(.v13)
    ],
    products: [
        .library(
            name: "RxComposableArchitecture",
            targets: ["RxComposableArchitecture"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-case-paths", exact: Version(1, 5, 6)),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: Version(6, 6, 0)),
        .package(url: "https://github.com/FluidGroup/TextureSwiftSupport", exact: Version(3, 20, 1))
    ],
    targets: [
        .target(
            name: "RxComposableArchitecture",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "TextureSwiftSupport", package: "TextureSwiftSupport")
            ]
        ),
        .testTarget(
            name: "RxComposableArchitectureTests",
            dependencies: [
                "RxComposableArchitecture",
                .product(name: "RxTest", package: "RxSwift")
            ]
        )
    ]
)
