// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "whisper",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .watchOS(.v4),
        .tvOS(.v14)
    ],
    products: [
        .library(name: "whisper", targets: ["whisper"]),
    ],
    targets: [
        .target(
            name: "whisper",
            path: ".",
            sources: [
                "ggml/src/ggml.c",
                "ggml/src/ggml.cpp",
                "ggml/src/ggml-alloc.c",
                "ggml/src/ggml-backend.cpp",
                "ggml/src/ggml-quants.c",
                "ggml/src/ggml-metal/ggml-metal.m", // Temporarily disabled for iOS build test
                "src/whisper.cpp"
            ],
            // resources: [.process("ggml/src/ggml-metal/ggml-metal.metal")], // Temporarily disabled for iOS build test
            publicHeadersPath: "spm-headers",
            cSettings: [
                .unsafeFlags(["-Wno-shorten-64-to-32", "-O3", "-DNDEBUG"]),
                .define("GGML_USE_ACCELERATE"),
                .unsafeFlags(["-fno-objc-arc"]),
                .define("GGML_USE_METAL"), // Temporarily disabled for iOS build test
                .headerSearchPath("ggml/include"),
                .headerSearchPath("include"),
                .headerSearchPath("ggml/src"),
                .unsafeFlags(["-DGGML_VERSION=\"1.7.6\"", "-DGGML_COMMIT=\"unknown\"", "-DWHISPER_VERSION=\"1.7.6\""])
                // NOTE: NEW_LAPACK will required iOS version 16.4+
                // We should consider add this in the future when we drop support for iOS 14
                // (ref: ref: https://developer.apple.com/documentation/accelerate/1513264-cblas_sgemm?language=objc)
                // .define("ACCELERATE_NEW_LAPACK"),
                // .define("ACCELERATE_LAPACK_ILP64")
            ],
            linkerSettings: [
                .linkedFramework("Accelerate")
            ]
        )
    ],
    cxxLanguageStandard: .cxx11
)
