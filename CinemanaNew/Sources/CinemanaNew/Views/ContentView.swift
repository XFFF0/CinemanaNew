import SwiftUI

struct ContentView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        TabView {
            HomeView(vm: vm)
                .tabItem { Label("Home",   systemImage: "house.fill") }

            SearchView(vm: vm)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            BrowseView()
                .tabItem { Label("Browse", systemImage: "square.grid.2x2.fill") }
        }
        .accentColor(.red)
        .onAppear { vm.loadHome() }
    }
}
