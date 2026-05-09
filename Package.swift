// swift-tools-version:6.3

import Foundation
import PackageDescription

// FIXME: make BuildConfigurationurable
let BuildConfiguration = "release"

let Platform: String

#if os(Linux)
Platform = "linux"
#elseif canImport(Darwin)
Platform = "mac"
#endif

let Architecture: String

#if canImport(Darwin)
Architecture = "x64_arm64"
#elseif arch(x86_64)
Architecture = "x64"
#elseif arch(arm64)
Architecture = "arm64"
#endif

// FIXME: this is clearly not right

let AvdeccBuildDir = "_build_\(Platform)_\(Architecture)_makefiles_\(BuildConfiguration)"
// Absolute paths: unsafeFlags is passed verbatim to clang/ld, whose CWD is
// not the package root, so relative paths to the artifact bundle don't
// resolve at link time.
let PackageRoot = FileManager.default.currentDirectoryPath
let AvdeccArtifactRoot = "\(PackageRoot)/.build/artifacts/avdeccswift/avdecc"
let AvdeccIncludePath = "\(AvdeccArtifactRoot)/include"
let AvdeccCxxLibPath = "\(AvdeccArtifactRoot)/\(AvdeccBuildDir)/src"
let AvdeccCxxControllerLibPath = "\(AvdeccCxxLibPath)/controller"
let AvdeccAltLibPath = "/usr/local/lib"
let AvdeccDebugSuffix = BuildConfiguration == "debug" ? "-d" : ""

var AvdeccLinkerSettings = [LinkerSetting]()

// only necessary on Linux
#if !canImport(Darwin)
AvdeccLinkerSettings += [.linkedLibrary("BlocksRuntime")]
#endif

let AvdeccUnsafeLinkerFlags: [String] = [
  "-Xlinker", "-L", "-Xlinker", AvdeccCxxLibPath,
  "-Xlinker", "-rpath", "-Xlinker", AvdeccCxxLibPath,
  "-Xlinker", "-L", "-Xlinker", AvdeccCxxControllerLibPath,
  "-Xlinker", "-rpath", "-Xlinker", AvdeccCxxControllerLibPath,
  "-Xlinker", "-L", "-Xlinker", AvdeccAltLibPath,
  "-Xlinker", "-rpath", "-Xlinker", AvdeccAltLibPath,
]

let package = Package(
  name: "AVDECCSwift",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .library(
      name: "AVDECCSwift",
      targets: ["AVDECCSwift"]
    ),
    .executable(
      name: "avdecc-discovery",
      targets: ["Discovery"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
    // .package(url: "https://github.com/lhoward/AsyncExtensions", branch: "linux"),
  ],
  targets: [
    .binaryTarget(
      name: "avdecc",
      path: "avdecc.artifactbundle.zip"
//            url: "https://github.com/PADL/AVDECCSwift/raw/main/avdecc.artifactbundle.zip",
//            checksum: "8eeb26c186329c7849c18a14837b6d78cea5d9aecb3e7fbb720274869e79a810"
    ),
    .target(
      name: "CxxAVDECC",
      dependencies: [
        "avdecc",
      ],
      // The la_avdecc submodule lives at Sources/CxxAVDECC/avdecc — its
      // .cpp/.c sources would otherwise fold into this target and trip
      // SwiftPM's "mixed language source files" check. The CxxAVDECC
      // target itself is header-only (everything Swift sees is in
      // include/AVDECCSwiftHelpers.hpp); excluding the submodule leaves
      // SwiftPM with nothing to compile, which is fine for a publicHeaders
      // target.
      exclude: ["avdecc"],
      publicHeadersPath: "include",
      cxxSettings: [
        // la_avdecc public headers + nih helper headers ship inside the
        // artifact bundle (`avdecc.artifactbundle.zip`), which SwiftPM
        // extracts to `.build/artifacts/avdeccswift/avdecc/include/...`.
        // We use that path (not the la_avdecc git submodule) because
        // SwiftPM doesn't auto-init submodules at consumer-side checkout
        // — the submodule directory is empty when AVDECCSwift is pulled
        // as a transitive dependency.
        .unsafeFlags(["-I\(AvdeccIncludePath)"]),
        // Clang blocks: Swift closures import as blocks, blocks fold into
        // std::function via the converting constructor. This is how Swift
        // drives the la_avdecc handlers without per-method bridges.
        .unsafeFlags(["-fblocks"]),
      ],
      linkerSettings: [
        .linkedLibrary("la_avdecc_cxx\(AvdeccDebugSuffix)"),
        .unsafeFlags(AvdeccUnsafeLinkerFlags),
      ] + AvdeccLinkerSettings // BlocksRuntime on Linux for Block_copy/Block_release
    ),
    .target(
      name: "AVDECCSwift",
      dependencies: [
        "CxxAVDECC",
        .product(name: "Logging", package: "swift-log"),
      ],
      cxxSettings: [
        // CxxAVDECC's public headers `#include <la/avdecc/...>`; SwiftPM
        // doesn't auto-propagate a target's own header search paths to
        // consumers, so each consuming target re-declares them. The
        // artifact bundle's include/ tree is the source of truth (see
        // CxxAVDECC target above).
        .unsafeFlags(["-I\(AvdeccIncludePath)"]),
      ],
      swiftSettings: [
        .interoperabilityMode(.Cxx),
        // Swift's clang importer needs -I flags too: it parses CxxAVDECC.h,
        // which #includes <la/avdecc/...>. cxxSettings above only affects
        // C/C++ compilation; route the same path through the importer.
        .unsafeFlags(["-Xcc", "-I\(AvdeccIncludePath)", "-Xcc", "-fblocks"]),
      ]
    ),
    .executableTarget(
      name: "Discovery",
      dependencies: [
        "AVDECCSwift",
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
      ],
      path: "Examples/Discovery",
      cxxSettings: [
        .unsafeFlags(["-I\(AvdeccIncludePath)"]),
      ],
      swiftSettings: [
        .interoperabilityMode(.Cxx),
        .unsafeFlags(["-Xcc", "-I\(AvdeccIncludePath)", "-Xcc", "-fblocks"]),
      ]
    ),
    .testTarget(
      name: "AVDECCSwiftTests",
      dependencies: [
        .target(name: "AVDECCSwift"),
      ],
      cxxSettings: [
        .unsafeFlags(["-I\(AvdeccIncludePath)"]),
      ],
      swiftSettings: [
        .interoperabilityMode(.Cxx),
        .unsafeFlags(["-Xcc", "-I\(AvdeccIncludePath)", "-Xcc", "-fblocks"]),
      ]
    ),
  ],
  cLanguageStandard: .c17,
  cxxLanguageStandard: .cxx20
)
