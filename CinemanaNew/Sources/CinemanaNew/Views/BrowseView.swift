import SwiftUI

struct BrowseView: View {
    @StateObject private var bvm = BrowseViewModel()

    var body: some View {
        NavigationView {
            List {
                if bvm.isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else {
                    ForEach(bvm.categories) { cat in
                        NavigationLink(destination: CategoryVideosView(category: cat)) {
                            HStack {
                                Image(systemName: "film.stack").foregroundColor(.red)
                                Text(cat.displayTitle).font(.subheadline)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Browse")
            .onAppear { bvm.loadCategories() }
        }
    }
}

struct CategoryVideosView: View {
    let category: VideoCategory
    @StateObject private var cvm = CategoryVideosViewModel()

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 16) {
                ForEach(cvm.videos) { item in
                    NavigationLink(destination: DetailView(video: item)) {
                        PosterCard(item: item)
                    }.buttonStyle(.plain)
                }
            }.padding()
        }
        .navigationTitle(category.displayTitle)
        .onAppear { cvm.loadVideos(categoryId: category.id) }
    }
}

class BrowseViewModel: ObservableObject {
    @Published var categories: [VideoCategory] = []
    @Published var isLoading = false
    func loadCategories() {
        isLoading = true
        NetworkService.shared.categories { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let cats) = result { self?.categories = cats }
            }
        }
    }
}

class CategoryVideosViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    func loadVideos(categoryId: String) {
        NetworkService.shared.browseVideos(categoryNb: categoryId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let items) = result { self?.videos = items }
            }
        }
    }
}
