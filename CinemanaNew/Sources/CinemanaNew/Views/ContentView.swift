import SwiftUI

struct ContentView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var searchQuery = ""
    @State private var selectedType = "movie"
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(vm: vm)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            SearchView(vm: vm)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(1)
        }
        .accentColor(.red)
        .onAppear { vm.loadHome() }
    }
}
