import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var banners:       [VideoItem] = []
    @Published var newlyVideos:   [VideoItem] = []
    @Published var moviesPage1:   [VideoItem] = []
    @Published var seriesPage1:   [VideoItem] = []
    @Published var moviesPage2:   [VideoItem] = []
    @Published var groups:        [VideoGroup] = []
    @Published var groupVideos:   [String: [VideoItem]] = [:]
    @Published var categories:    [VideoCategory] = []
    @Published var searchResults: [VideoItem] = []
    @Published var isLoading  = false
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let api = NetworkService.shared

    func loadHome() {
        isLoading = true
        let g = DispatchGroup()

        g.enter()
        api.banner { [weak self] r in DispatchQueue.main.async {
            if case .success(let v) = r { self?.banners = v }; g.leave() } }

        g.enter()
        api.newlyVideos { [weak self] r in DispatchQueue.main.async {
            if case .success(let v) = r { self?.newlyVideos = v }; g.leave() } }

        // Movies page 1 (kind=1)
        g.enter()
        api.browseVideos(videoKind: 1, page: 1, perPage: 20) { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let v) = r { self?.moviesPage1 = v }; g.leave() } }

        // Series page 1 (kind=2)
        g.enter()
        api.browseVideos(videoKind: 2, page: 1, perPage: 20) { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let v) = r { self?.seriesPage1 = v }; g.leave() } }

        // Movies page 2 for variety
        g.enter()
        api.browseVideos(videoKind: 1, page: 2, perPage: 20) { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let v) = r { self?.moviesPage2 = v }; g.leave() } }

        // Groups
        g.enter()
        api.videoGroups { [weak self] r in DispatchQueue.main.async {
            if case .success(let v) = r {
                self?.groups = Array(v.prefix(8))
                for grp in v.prefix(5) { self?.loadGroupVideos(groupID: grp.id) }
            }; g.leave() } }

        // Categories
        g.enter()
        api.categories { [weak self] r in DispatchQueue.main.async {
            if case .success(let v) = r { self?.categories = v }; g.leave() } }

        g.notify(queue: .main) { [weak self] in self?.isLoading = false }
    }

    func loadGroupVideos(groupID: String) {
        api.videoListPagination(groupID: groupID) { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let v) = r, !v.isEmpty {
                    self?.groupVideos[groupID] = v
                }
            }
        }
    }

    func search(query: String, type: String = "movie") {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []; isSearching = false; return
        }
        isSearching = true; isLoading = true
        api.search(title: query, type: type) { [weak self] r in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch r {
                case .success(let v): self?.searchResults = v
                case .failure(let e): self?.errorMessage = e.localizedDescription
                }
            }
        }
    }

    func clearSearch() { searchResults = []; isSearching = false }
}
