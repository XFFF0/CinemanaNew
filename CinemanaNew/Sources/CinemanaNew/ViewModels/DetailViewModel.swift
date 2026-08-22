import Foundation

class DetailViewModel: ObservableObject {
    @Published var videoFiles: [TranscodedFile] = []
    @Published var episodes: [SeasonEpisode] = []
    @Published var comments: [VideoComment] = []
    @Published var relatedVideos: [VideoItem] = []
    @Published var isLoading = false
    @Published var isLoadingComments = false

    private let api = NetworkService.shared

    func loadAll(video: VideoItem) {
        loadFiles(videoId: video.id)
        loadComments(videoId: video.id)
        if video.isSeries { loadEpisodes(rootId: video.id) }
        // fetch recommendations via browse same kind
        api.browseVideos(videoKind: video.isMovie ? 1 : 2) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let items) = result {
                    self?.relatedVideos = items.filter { $0.id != video.id }.prefix(10).map { $0 }
                }
            }
        }
    }

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

    func loadComments(videoId: String) {
        isLoadingComments = true
        api.videoComments(id: videoId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingComments = false
                if case .success(let c) = result { self?.comments = c }
            }
        }
    }

    func postComment(userId: String, videoId: String, text: String) {
        api.addComment(id: userId, videoId: videoId, comment: text) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.loadComments(videoId: videoId)
            }
        }
    }

    func addLike(userId: String, videoId: String, value: Int) {
        api.addLike(userId: userId, videoId: videoId, likeValue: value) { _ in }
    }

    func addToHistory(userId: String, videoId: String, kind: Int) {
        api.addToHistory(userId: userId, videoId: videoId, kind: kind) { _ in }
    }
}
