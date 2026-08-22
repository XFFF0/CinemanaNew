import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var banners: [VideoItem] = []
    @Published var newlyVideos: [VideoItem] = []
    @Published var searchResults: [VideoItem] = []
    @Published var groups: [VideoGroup] = []
    @Published var groupVideos: [String: [VideoItem]] = [:]
    @Published var categories: [VideoCategory] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let api = NetworkService.shared

    func loadHome() {
        isLoading = true
        let group = DispatchGroup()

        group.enter()
        api.banner { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let items) = result { self?.banners = items }
                group.leave()
            }
        }

        group.enter()
        api.newlyVideos { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let items) = result { self?.newlyVideos = items }
                group.leave()
            }
        }

        group.enter()
        api.videoGroups { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let g) = result {
                    self?.groups = Array(g.prefix(6))
                    // load first 3 groups
                    for grp in g.prefix(3) {
                        self?.loadGroupVideos(groupID: grp.id)
                    }
                }
                group.leave()
            }
        }

        group.enter()
        api.categories { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let cats) = result { self?.categories = cats }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    func loadGroupVideos(groupID: String) {
        api.videoListPagination(groupID: groupID) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let items) = result {
                    self?.groupVideos[groupID] = items
                }
            }
        }
    }

    func search(query: String, type: String = "movie") {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []; isSearching = false; return
        }
        isSearching = true
        isLoading = true
        api.search(title: query, type: type) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let items): self?.searchResults = items
                case .failure(let e):    self?.errorMessage = e.localizedDescription
                }
            }
        }
    }

    func clearSearch() { searchResults = []; isSearching = false }
}
