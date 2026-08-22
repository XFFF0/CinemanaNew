import Foundation

class DetailViewModel: ObservableObject {
    @Published var videoFiles: [TranscodedFile] = []
    @Published var episodes: [SeasonEpisode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = NetworkService.shared

    func loadFiles(videoId: String) {
        isLoading = true
        api.transcoddedFiles(id: videoId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let files) = result { self?.videoFiles = files }
            }
        }
    }

    func loadEpisodes(rootId: String) {
        api.videoSeason(id: rootId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let eps) = result { self?.episodes = eps }
            }
        }
    }
}
