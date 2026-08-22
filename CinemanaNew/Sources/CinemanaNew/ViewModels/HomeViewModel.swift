import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var banners: [VideoItem] = []
    @Published var newlyVideos: [VideoItem] = []
    @Published var searchResults: [VideoItem] = []
    @Published var isSearching = false
    @Published var isLoading = false
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

        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    func search(query: String, type: String = "movie") {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
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

    func clearSearch() {
        searchResults = []
        isSearching = false
    }
}
