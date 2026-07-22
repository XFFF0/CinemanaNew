import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthService.shared

    var body: some View {
        if auth.isAuthenticated {
            RootTabView()
        } else {
            LoginView()
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house") }
            BrowseView()
                .tabItem { Label("استعراض", systemImage: "square.grid.2x2") }
            SearchView()
                .tabItem { Label("بحث", systemImage: "magnifyingglass") }
            ProfileView()
                .tabItem { Label("حسابي", systemImage: "person") }
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading {
                    ProgressView().padding(.top, 60)
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("إعادة المحاولة") { Task { await vm.load() } }
                    }
                    .padding(.top, 60)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        if !vm.banners.isEmpty {
                            TabView {
                                ForEach(vm.banners) { banner in
                                    AsyncImage(url: URL(string: banner.imgObjUrl ?? "")) { $0.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                                        .frame(height: 200)
                                        .clipped()
                                }
                            }
                            .tabViewStyle(.page)
                            .frame(height: 200)
                        }

                        if !vm.newlyAdded.isEmpty {
                            VideoRow(title: "أضيف حديثاً", videos: vm.newlyAdded)
                        }

                        ForEach(vm.groups) { group in
                            if let items = group.items, !items.isEmpty {
                                VideoRow(title: group.name ?? "", videos: items)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Cinemana")
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .navigationDestination(for: String.self) { id in
                VideoDetailView(videoId: id)
            }
        }
    }
}

struct VideoRow: View {
    let title: String
    let videos: [VideoModel]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(videos) { video in
                        NavigationLink(value: video.id) {
                            VideoPoster(video: video)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct VideoPoster: View {
    let video: VideoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: URL(string: video.imgThumbObjUrl ?? video.imgObjUrl ?? "")) {
                $0.resizable().scaledToFill()
            } placeholder: { Color.gray.opacity(0.2) }
                .frame(width: 120, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(video.title).font(.caption).lineLimit(1).frame(width: 120, alignment: .leading)
        }
    }
}

// MARK: - Browse

struct BrowseView: View {
    @StateObject private var vm = BrowseViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("التصنيفات") {
                    ForEach(vm.categories) { category in
                        Text(category.name ?? "")
                    }
                }
                Section("المجموعات") {
                    ForEach(vm.collections) { collection in
                        Text(collection.name ?? "")
                    }
                }
            }
            .navigationTitle("استعراض")
            .task { await vm.load() }
            .overlay { if vm.isLoading { ProgressView() } }
        }
    }
}

// MARK: - Search

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            List(vm.results) { video in
                NavigationLink(destination: VideoDetailView(videoId: video.id)) {
                    HStack {
                        AsyncImage(url: URL(string: video.imgThumbObjUrl ?? "")) { $0.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                            .frame(width: 50, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        VStack(alignment: .leading) {
                            Text(video.title)
                            if let year = video.year { Text(year).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
                .onAppear {
                    if video.id == vm.results.last?.id {
                        Task { await vm.loadMore() }
                    }
                }
            }
            .searchable(text: $vm.query)
            .onSubmit(of: .search) { Task { await vm.search() } }
            .navigationTitle("بحث")
            .navigationDestination(for: String.self) { id in
                VideoDetailView(videoId: id)
            }
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @StateObject private var auth = AuthService.shared

    var body: some View {
        NavigationStack {
            List {
                Section("سجل المشاهدة") {
                    ForEach(vm.history) { video in
                        Text(video.title)
                    }
                }
                Section {
                    Button("تسجيل الخروج", role: .destructive) {
                        auth.logout()
                    }
                }
            }
            .navigationTitle("حسابي")
        }
    }
}
