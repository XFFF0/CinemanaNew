import Foundation

/// Overwritten during CI (see .github/workflows/build.yml) with the actual
/// GitHub Actions run number and short commit SHA, so you can confirm on-device
/// that you're testing the build you think you're testing.
enum BuildInfo {
    static let label = "local-dev-build"
}
