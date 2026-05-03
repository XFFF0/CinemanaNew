import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var homeGroups: [VideosGroup] = []
    @Published var banners: [VideoModel] = []
    @Published var newlyVideos: [VideoModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var searchQuery: String = ""
    @Published var searchResults: [VideoModel] = []
    @Published var isSearching: Bool = false

    @Published var selectedCategory: NewCategoryItem?
    @Published var categories: [NewCategoryItem] = []

    @Published var collections: [CollectionItem] = []

    func loadInitialData() async {
        await loadHomeData()
        await loadCategories()
        await loadCollections()
    }

    func loadHomeData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let groupsTask = APIService.shared.getHomeGroups(language: "en")
            async let bannersTask = APIService.shared.getBanners()
            async let newVideosTask = APIService.shared.getNewlyVideos()

            let (groups, banners, newVideos) = try await (groupsTask, bannersTask, newVideosTask)

            self.homeGroups = groups
            self.banners = banners
            self.newlyVideos = newVideos
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadCategories() async {
        do {
            let categories = try await APIService.shared.getCategories()
            self.categories = categories
        } catch {
            print("Failed to load categories: \(error)")
        }
    }

    func loadCollections() async {
        do {
            let collections = try await APIService.shared.getCollections()
            self.collections = collections
        } catch {
            print("Failed to load collections: \(error)")
        }
    }

    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            let results = try await APIService.shared.searchVideos(query: searchQuery)
            searchResults = results
        } catch {
            print("Search error: \(error)")
        }

        isSearching = false
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }

    func refresh() async {
        await loadHomeData()
        await loadCategories()
        await loadCollections()
    }
}