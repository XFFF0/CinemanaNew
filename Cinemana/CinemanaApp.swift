import SwiftUI

@main
struct CinemanaApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var downloadManager = DownloadManager.shared
    @StateObject private var watchLaterManager = WatchLaterManager.shared
    @StateObject private var playerSettings = PlayerSettingsManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(downloadManager)
                .environmentObject(watchLaterManager)
                .environmentObject(playerSettings)
                .preferredColorScheme(.dark)
        }
    }
}