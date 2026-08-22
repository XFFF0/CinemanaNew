import SwiftUI

struct BrowseView: View {
    @StateObject private var bvm = BrowseViewModel()

    var body: some View {
        NavigationView {
            List {
                // Categories section
                Section("Categories") {
                    if bvm.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    } else {
                        ForEach(bvm.categories) { cat in
                            NavigationLink(destination: CategoryVideosView(category: cat)) {
                                HStack(spacing: 12) {
                                    Image(systemName: "film.stack")
                                        .foregroundColor(.red)
                                        .frame(width: 28)
                                    Text(cat.displayTitle).font(.subheadline)
                                }
                            }
                        }
                    }
                }

                // Collections section
                if !bvm.collections.isEmpty {
                    Section("Collections") {
                        ForEach(bvm.collections) { col in
                            NavigationLink(destination: CollectionVideosView(collection: col)) {
                                HStack(spacing: 12) {
                                    Image(systemName: "rectangle.stack.fill")
                                        .foregroundColor(.orange)
                                        .frame(width: 28)
                                    Text(col.displayTitle).font(.subheadline)
                                }
                            }
                        }
                    }
                }

                // Groups section
                if !bvm.groups.isEmpty {
                    Section("Groups") {
                        ForEach(bvm.groups) { grp in
                            NavigationLink(destination: GroupVideosView(group: grp)) {
                                HStack(spacing: 12) {
                                    Image(systemName: "list.bullet.rectangle.fill")
                                        .foregroundColor(.purple)
                                        .frame(width: 28)
                                    Text(grp.displayTitle).font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Browse")
            .onAppear { bvm.load() }
        }
    }
}

// MARK: - Category Videos
struct CategoryVideosView: View {
    let category: VideoCategory
    @StateObject private var cvm = GridViewModel()

    var body: some View {
        ScrollView {
            if cvm.isLoading && cvm.videos.isEmpty {
                ProgressView().padding(60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 16) {
                    ForEach(cvm.videos) { item in
                        NavigationLink(destination: DetailView(video: item)) {
                            PosterCard(item: item)
                        }.buttonStyle(.plain)
                    }
                }.padding()

                if cvm.hasMore {
                    Button("Load More") { cvm.loadMore() }
                        .buttonStyle(.bordered).tint(.red).padding()
                }
            }
        }
        .navigationTitle(category.displayTitle)
        .onAppear { cvm.loadCategory(id: category.id, kind: 1) }
    }
}

// MARK: - Collection Videos
struct CollectionVideosView: View {
    let collection: VideoCollection
    @StateObject private var cvm = GridViewModel()

    var body: some View {
        ScrollView {
            if cvm.isLoading && cvm.videos.isEmpty {
                ProgressView().padding(60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 16) {
                    ForEach(cvm.videos) { item in
                        NavigationLink(destination: DetailView(video: item)) {
                            PosterCard(item: item)
                        }.buttonStyle(.plain)
                    }
                }.padding()
            }
        }
        .navigationTitle(collection.displayTitle)
        .onAppear { cvm.loadCollection(id: collection.id) }
    }
}

// MARK: - Group Videos
struct GroupVideosView: View {
    let group: VideoGroup
    @StateObject private var cvm = GridViewModel()

    var body: some View {
        ScrollView {
            if cvm.isLoading && cvm.videos.isEmpty {
                ProgressView().padding(60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 16) {
                    ForEach(cvm.videos) { item in
                        NavigationLink(destination: DetailView(video: item)) {
                            PosterCard(item: item)
                        }.buttonStyle(.plain)
                    }
                }.padding()

                if cvm.hasMore {
                    Button("Load More") { cvm.loadMore() }
                        .buttonStyle(.bordered).tint(.red).padding()
                }
            }
        }
        .navigationTitle(group.displayTitle)
        .onAppear { cvm.loadGroup(id: group.id) }
    }
}

// MARK: - Browse ViewModel
class BrowseViewModel: ObservableObject {
    @Published var categories:   [VideoCategory] = []
    @Published var collections:  [VideoCollection] = []
    @Published var groups:       [VideoGroup] = []
    @Published var isLoading = false

    func load() {
        guard categories.isEmpty else { return }
        isLoading = true
        let g = DispatchGroup()

        g.enter()
        NetworkService.shared.categories { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let v) = r { self?.categories = v }
                g.leave()
            }
        }

        g.enter()
        NetworkService.shared.collectionsId { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let v) = r { self?.collections = v }
                g.leave()
            }
        }

        g.enter()
        NetworkService.shared.videoGroups { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let v) = r { self?.groups = v }
                g.leave()
            }
        }

        g.notify(queue: .main) { [weak self] in self?.isLoading = false }
    }
}

// MARK: - Generic Grid ViewModel
class GridViewModel: ObservableObject {
    @Published var videos:    [VideoItem] = []
    @Published var isLoading  = false
    @Published var hasMore    = true

    private var page = 1
    private var mode: Mode = .category(id: "", kind: 1)

    enum Mode {
        case category(id: String, kind: Int)
        case collection(id: String)
        case group(id: String)
    }

    func loadCategory(id: String, kind: Int) {
        mode = .category(id: id, kind: kind); page = 1; fetch()
    }
    func loadCollection(id: String) {
        mode = .collection(id: id); page = 1; fetch()
    }
    func loadGroup(id: String) {
        mode = .group(id: id); page = 1; fetch()
    }
    func loadMore() { page += 1; fetch(append: true) }

    private func fetch(append: Bool = false) {
        isLoading = true
        let api = NetworkService.shared
        let p = page

        switch mode {
        case .category(let id, let kind):
            api.browseVideos(categoryNb: id.isEmpty ? nil : id,
                             videoKind: kind, page: p) { [weak self] r in
                self?.handle(r, append: append)
            }
        case .collection(let id):
            api.getCollection(id: id) { [weak self] r in
                self?.handle(r, append: append)
            }
        case .group(let id):
            api.videoListPagination(groupID: id, page: p) { [weak self] r in
                self?.handle(r, append: append)
            }
        }
    }

    private func handle(_ result: Result<[VideoItem], Error>, append: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            if case .success(let items) = result {
                if append { self?.videos.append(contentsOf: items) }
                else       { self?.videos = items }
                self?.hasMore = items.count >= 20
            }
        }
    }
}
