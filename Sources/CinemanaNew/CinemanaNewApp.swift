import SwiftUI

@main
struct CinemanaNewApp: App {
    @StateObject private var api = APIService.shared
    @StateObject private var dl  = DownloadManager.shared
    @StateObject private var wl  = WatchLaterManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
                .environmentObject(dl)
                .environmentObject(wl)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var api: APIService
    @State private var tab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:       HomeView()
                case .search:     SearchView()
                case .downloads:  DownloadsView()
                case .watchLater: WatchLaterView()
                case .profile:    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AppTabBar(selected: $tab)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.appBg)
    }
}
