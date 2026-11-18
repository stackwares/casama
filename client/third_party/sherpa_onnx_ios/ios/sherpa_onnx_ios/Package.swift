// swift-tools-version: 5.9
// Empty stand-in for sherpa_onnx_ios: no SherpaOnnxC binary target (see ../../README.md).
import PackageDescription

let package = Package(
  name: "sherpa_onnx_ios",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(name: "sherpa-onnx-ios", targets: ["sherpa_onnx_ios"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "sherpa_onnx_ios",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
